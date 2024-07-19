//
//  QSNetAnalyticsService.h
//  QSNetAnalyseDemo
//
//  Created by 帅科 on 2021/4/19.
//

#import <Foundation/Foundation.h>
#import "QSEventFlush.h"

NS_ASSUME_NONNULL_BEGIN

@interface QSNetAnalyticsService : NSObject

+(instancetype)share;

+ (void)startMonitoringWithFlushConfig:(QSFlushConfig*)flushConfig;

- (void)trackWithProperties:(nullable NSDictionary *)propertyDict;


+ (NSString *)currentNetworkStatus;

+ (NSString *)carrierName;

@end

NS_ASSUME_NONNULL_END
