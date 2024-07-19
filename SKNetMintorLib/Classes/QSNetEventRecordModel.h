//
//  QSNetEventRecordModel.h
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, QSEventRecordStatus) {
    QSEventRecordStatusNone,
    QSEventRecordStatusFlush,
};

NS_ASSUME_NONNULL_BEGIN

@interface QSNetEventRecordModel : NSObject

@property (nonatomic ,assign) QSEventRecordStatus status;

@property (nonatomic ,copy ,readonly) NSString *content;

@property (nonatomic, copy) NSString *recordID;

@property (nonatomic, copy) NSString *type;

- (BOOL)isValid;

- (instancetype)initWithRecordID:(NSString *)recordID content:(NSString *)content;

- (instancetype)initWithEvent:(NSDictionary *)event type:(NSString *)type;

@end


@interface QSNetEventRecordItemModel : NSObject

@property (nonatomic ,copy) NSString *userId;

@property (nonatomic ,copy) NSString *method;

@property (nonatomic ,copy) NSString *requestUrl;
@property (nonatomic ,copy) NSDictionary *requestHeaders;
@property (nonatomic ,copy) NSString *requestBody;
@property (nonatomic ,copy) NSString *requestErrorMsg;


@property (nonatomic ,copy) NSString *responseUrl;
@property (nonatomic ,copy) NSString *responseHeaders;
@property (nonatomic ,copy) NSString *responseBody;
@property (nonatomic ,copy) NSString *responseErrorMsg;

@property (nonatomic ,copy) NSString *fetchStartDate;
@property (nonatomic ,copy) NSString *fetchEndDate;

@property (nonatomic ,copy) NSString *netWorkType;
@property (nonatomic ,copy) NSString *carrier;
@property (nonatomic ,copy) NSString *model;
@property (nonatomic ,copy) NSString *appVersion;

@end

NS_ASSUME_NONNULL_END
