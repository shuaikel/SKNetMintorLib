//
//  QSEventFlush.h
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QSNetEventRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

@class QSFlushConfig;

@interface QSEventFlush : NSObject

- (void)flushEventRecords:(NSArray<QSNetEventRecordModel *> *)records
               completion:(void (^)(BOOL success))completion;


- (instancetype)initWithFlushConfig:(QSFlushConfig*)flushConfig;

- (instancetype)init NS_UNAVAILABLE;


@end



@interface QSFlushConfig : NSObject

@property (nonatomic ,copy, nonnull) NSString *devReportUrl; // 测试上报地址

@property (nonatomic ,copy, nonnull) NSString *proReportUrl; // 生产上报地址

@property (nonatomic ,assign) BOOL isDev;



@end

NS_ASSUME_NONNULL_END
