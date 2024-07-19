//
//  QSEventTracker.m
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import "QSEventTracker.h"
#import "QSEventFlush.h"
#import "QSFileStore.h"
#import "QSNetEventRecordModel.h"
#import <Reachability/Reachability.h>

#define kFlushEventLimit 1

BOOL QSSensorsdata_is_same_queue(dispatch_queue_t queue) {
    return strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0;
}

@interface QSEventTracker ()

@property (nonatomic, strong ,readwrite) QSNetEventStore *eventStore;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) QSEventFlush *eventFlush;

@property (nonatomic, strong) Reachability *reachability;

@end

@implementation QSEventTracker

- (instancetype)initWithQueue:(dispatch_queue_t)queue andFlushConfig:(nonnull QSFlushConfig *)flushConfig{
    self = [super init];
    if (self) {
        _queue = queue;

        dispatch_async(queue, ^{
            self.eventStore = [[QSNetEventStore alloc] initWithFilePath:[QSFileStore filePath:@"message-v3"]];
            
            
            self.eventFlush = [[QSEventFlush alloc] initWithFlushConfig:flushConfig];
        });
        
    }
    return self;
}

- (void)trackEvent:(NSDictionary *)event {
    [self trackEvent:event isSignUp:NO];
}

- (void)trackEvent:(NSDictionary *)event isSignUp:(BOOL)isSignUp {
    QSNetEventRecordModel *record = [[QSNetEventRecordModel alloc] initWithEvent:event type:@"POST"];
    [self.eventStore insertRecord:record];

    // $SignUp 事件或者本地缓存的数据是超过 flushBulkSize
    if (isSignUp || self.eventStore.count > kFlushEventLimit) {
        // 添加异步队列任务，保证数据继续入库
        dispatch_async(self.queue, ^{
            [self flushAllEventRecords];
        });
    }
}

- (void)flushAllEventRecords{
    BOOL isFlushed = [self flushRecordsWithSize:kFlushEventLimit];
    if (isFlushed) {
        NSLog(@"Events flushed!");
    }
}

- (BOOL)flushRecordsWithSize:(NSUInteger)size {
    // 从数据库中查询数据
    NSArray<QSNetEventRecordModel *> *records = [self.eventStore selectRecords:size];
    if (records.count == 0) {
        return NO;
    }

    NSMutableArray *recordIDs = [NSMutableArray arrayWithCapacity:records.count];
    for (QSNetEventRecordModel *record in records) {
        [recordIDs addObject:record.recordID];
    }
    
    // 更新数据状态
    [self.eventStore updateRecords:recordIDs status:QSEventRecordStatusFlush];

    // flush
    __weak typeof(self) weakSelf = self;
    [self.eventFlush flushEventRecords:records completion:^(BOOL success) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        void(^block)(void) = ^ {
            if (!success) {
                [strongSelf.eventStore updateRecords:recordIDs status:QSEventRecordStatusNone];
                return;
            }
            // 5. 删除数据
            if ([strongSelf.eventStore deleteRecords:recordIDs]) {
                [strongSelf flushRecordsWithSize:size];
            }
            // 数据库
            NSLog(@"数据库中数据：%@",@([self.eventStore count]));
        };
        if (QSSensorsdata_is_same_queue(strongSelf.queue)) {
            block();
        } else {
            dispatch_sync(strongSelf.queue, block);
        }
    }];
    return YES;
}

- (BOOL)canFlush {
    // 判断当前网络类型是否符合同步数据的网络策略
    if ([self.reachability currentReachabilityStatus] == NotReachable) {
        return NO;
    }
    return YES;
}

@end
