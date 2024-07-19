//
//  QSEventTracker.h
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QSNetEventStore.h"
#import "QSEventFlush.h"
NS_ASSUME_NONNULL_BEGIN

@interface QSEventTracker : NSObject

@property (nonatomic, strong, readonly) QSNetEventStore *eventStore;

- (instancetype)initWithQueue:(dispatch_queue_t)queue andFlushConfig:(QSFlushConfig*)flushConfig;

- (void)trackEvent:(NSDictionary *)event;
- (void)trackEvent:(NSDictionary *)event isSignUp:(BOOL)isSignUp;

- (void)flushAllEventRecords;

@end

NS_ASSUME_NONNULL_END
