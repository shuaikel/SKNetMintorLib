//
//  QSNetSessionService.h
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QSSecurityPolicy.h"
#import "SKSingleton.h"
NS_ASSUME_NONNULL_BEGIN

typedef void(^QSURLSessionTaskCompletionHandler)(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error);

@interface QSNetSessionService : NSObject

SKSingletonH(share)

@property (nonatomic, strong ,readonly) NSOperationQueue *delegateQueue;

@property (nonatomic, strong) QSSecurityPolicy *securityPolicy;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(QSURLSessionTaskCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
