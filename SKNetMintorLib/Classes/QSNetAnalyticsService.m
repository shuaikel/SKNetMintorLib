//
//  QSNetAnalyticsService.m
//  QSNetAnalyseDemo
//
//  Created by 帅科 on 2021/4/19.
//

#import "QSNetAnalyticsService.h"
#import "QSEventTracker.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Reachability.h"
#import <CoreTelephony/CTCarrier.h>

static QSNetAnalyticsService *sharedInstance = nil;

@interface QSNetAnalyticsService ()
@property (nonatomic ,strong) QSEventTracker *eventTracker;
@property (nonatomic ,strong) dispatch_queue_t queue;
@property (nonatomic ,strong) NSTimer *timer;
@property (nonatomic ,strong) QSFlushConfig *flushConfig;
@end

@implementation QSNetAnalyticsService


+ (void)startMonitoringWithFlushConfig:(QSFlushConfig *)flushConfig{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[QSNetAnalyticsService alloc]init];
        sharedInstance.flushConfig = flushConfig;
    });
}


+ (QSNetAnalyticsService *)share{
    NSAssert(sharedInstance, @"请先使用 startMonitoring: 初始化");
    return sharedInstance;
}


- (instancetype)init{
    if (self = [super init]) {

        NSString *serialQueueLabel = [NSString stringWithFormat:@"com.QSsensorsdata.serialQueue.%p", self];
        _queue = dispatch_queue_create([serialQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        
        self.eventTracker = [[QSEventTracker alloc]initWithQueue:self.queue andFlushConfig:self.flushConfig];
        
        [self flush];
        
        
        [self setupListeners];
        
    }
    return self;
}

- (void)setupListeners {
    // 监听 App 启动或结束事件
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];

}

- (void)applicationDidBecomeActive:(NSNotification*)noti{
    [self startFlushTimer];
}

- (void)applicationDidEnterBackground:(NSNotification*)noti{
    [self stopFlushTimer];
    
    UIApplication *application = UIApplication.sharedApplication;
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    // 结束后台任务
    void (^endBackgroundTask)(void) = ^() {
        [application endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    };

    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        endBackgroundTask();
    }];
    
    dispatch_async(self.queue, ^{
        [self.eventTracker flushAllEventRecords];
        endBackgroundTask();
    });
}

- (void)startFlushTimer {
    NSLog(@"starting flush timer.");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((self.timer && [self.timer isValid])) {
            return;
        }
        
        double interval = 10;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:self
                                                    selector:@selector(flush)
                                                    userInfo:nil
                                                     repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        
    });
}

- (void)stopFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
        }
        self.timer = nil;
    });
}


- (void)flush{
    dispatch_async(self.queue, ^{
        [self.eventTracker flushAllEventRecords];
    });
}

- (void)trackWithProperties:(NSDictionary *)propertyDict{
    dispatch_async(self.queue, ^{
        [self.eventTracker trackEvent:propertyDict];
    });
}


+ (NSString *)currentNetworkStatus {
    NSString *network = @"NULL";
    @try {
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        NetworkStatus status = [reachability currentReachabilityStatus];
        
        if (status == ReachableViaWiFi) {
            network = @"WIFI";
        } else if (status == ReachableViaWWAN) {
            static CTTelephonyNetworkInfo *netinfo = nil;
            NSString *currentRadioAccessTechnology = nil;
            
            if (!netinfo) {
                netinfo = [[CTTelephonyNetworkInfo alloc] init];
            }
#ifdef __IPHONE_12_0
            if (@available(iOS 12.1, *)) {
                currentRadioAccessTechnology = netinfo.serviceCurrentRadioAccessTechnology.allValues.lastObject;
            }
#endif
            //测试发现存在少数 12.0 和 12.0.1 的机型 serviceCurrentRadioAccessTechnology 返回空
            if (!currentRadioAccessTechnology) {
                currentRadioAccessTechnology = netinfo.currentRadioAccessTechnology;
            }
            
            if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
                network = @"2G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
                network = @"2G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
                network = @"3G";
            } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
                network = @"4G";
            } else if (@available(iOS 14.0, *)) {
                if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyNRNSA] ||
                    [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyNR]) {
                    network = @"5G";
                }
            } else {
            
                
                network = @"UNKNOWN";
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"%@: %@", self, exception);
    }
    return network;
}

+ (NSString *)carrierName {
    
    NSString *carrierName = nil;
    @try {
        CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = nil;
        
#ifdef __IPHONE_12_0
        if (@available(iOS 12.1, *)) {
            // 排序
            NSArray *carrierKeysArray = [telephonyInfo.serviceSubscriberCellularProviders.allKeys sortedArrayUsingSelector:@selector(compare:)];
            carrier = telephonyInfo.serviceSubscriberCellularProviders[carrierKeysArray.firstObject];
            if (!carrier.mobileNetworkCode) {
                carrier = telephonyInfo.serviceSubscriberCellularProviders[carrierKeysArray.lastObject];
            }
        }
#endif
        if (!carrier) {
            carrier = telephonyInfo.subscriberCellularProvider;
        }
        if (carrier != nil) {
            NSString *networkCode = [carrier mobileNetworkCode];
            NSString *countryCode = [carrier mobileCountryCode];
            //中国运营商
            if (countryCode && [countryCode isEqualToString:@"460"] && networkCode) {
                //中国移动
                if ([networkCode isEqualToString:@"00"] || [networkCode isEqualToString:@"02"] || [networkCode isEqualToString:@"07"] || [networkCode isEqualToString:@"08"]) {
                    carrierName= @"中国移动";
                }
                //中国联通
                if ([networkCode isEqualToString:@"01"] || [networkCode isEqualToString:@"06"] || [networkCode isEqualToString:@"09"]) {
                    carrierName= @"中国联通";
                }
                //中国电信
                if ([networkCode isEqualToString:@"03"] || [networkCode isEqualToString:@"05"] || [networkCode isEqualToString:@"11"]) {
                    carrierName= @"中国电信";
                }
                //中国卫通
                if ([networkCode isEqualToString:@"04"]) {
                    carrierName= @"中国卫通";
                }
                //中国铁通
                if ([networkCode isEqualToString:@"20"]) {
                    carrierName= @"中国铁通";
                }
            } else if (countryCode && networkCode) { //国外运营商解析
                
                NSBundle *sensorsBundle = [NSBundle bundleForClass:[QSNetAnalyticsService class]];
                //文件路径
                NSString *jsonPath = [sensorsBundle pathForResource:@"QSNetMintorLib.bundle/qs_mcc_mnc_mini.json" ofType:nil];
                NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
                if (jsonData) {
                    NSDictionary *dicAllMcc =  [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
                    if (dicAllMcc) {
                        NSString *mccMncKey = [NSString stringWithFormat:@"%@%@", countryCode, networkCode];
                        carrierName = dicAllMcc[mccMncKey];
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"%@: %@", self, exception);
    }
    return carrierName;
}


@end
