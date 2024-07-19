//
//  QSEventFlush.m
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import "QSEventFlush.h"
#import "QSGZipUtility.h"
#import "NSString+QSFlushRecordHash.h"
#import "QSNetSessionService.h"
#import <MJExtension/MJExtension.h>

#define kreportURL @"http://test-h5-log.black-unique.com/logstores/monitor_app_error_log/track"
#define kreportProductURL @"https://front-h5-log.black-unique.com/logstores/monitor_app_error_log/track"

#define kreportWith414ErrorNotification @"kreportWith414ErrorNotification"

#pragma mark -

@interface QSAFQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;
@end

@implementation QSAFQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.field = field;
    self.value = value;
    return self;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return QSAFPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", QSAFPercentEscapedStringFromString([self.field description]), QSAFPercentEscapedStringFromString([self.value description])];
    }
}


NSString * QSAFPercentEscapedStringFromString(NSString *string) {
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";

    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];
    
    static NSUInteger const batchSize = 50;

    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;

    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);

        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];

        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];

        index += range.length;
    }

    return escaped;
}

@end


@interface QSEventFlush ()
@property (nonatomic, strong) NSOperationQueue *delegateQueue;

@property (nonatomic, assign) BOOL isDev; // 是否是测试上报

@property (nonatomic, copy) NSString *devReportURL;

@property (nonatomic, copy) NSString *proReportURL;
@end

@implementation QSEventFlush


- (instancetype)initWithFlushConfig:(QSFlushConfig *)flushConfig{
    if (self = [super init]) {
        self.isDev = flushConfig.isDev;
        self.devReportURL = flushConfig.devReportUrl.length > 0 ? flushConfig.devReportUrl : kreportURL;
        self.proReportURL = flushConfig.proReportUrl.length > 0 ? flushConfig.proReportUrl : kreportProductURL;
    }
    return self;
}

// 1. 先完成这一系列 Json 字符串的拼接
- (NSString *)buildFlushJSONStringWithEventRecords:(NSArray<QSNetEventRecordModel *> *)records {
    NSMutableArray *contents = [NSMutableArray arrayWithCapacity:records.count];
    for (QSNetEventRecordModel *record in records) {
        if ([record isValid]) {
            // 需要先添加 flush time，再进行 json 拼接
            [contents addObject:record.content];
        }
    }
    return [NSString stringWithFormat:@"%@", [contents componentsJoinedByString:@","]];
}


- (void)flushEventRecords:(NSArray<QSNetEventRecordModel *> *)records completion:(void (^)(BOOL success))completion {
    // 当在程序终止或 debug 模式下，使用线程锁
    [self requestWithRecords:records completion:^(BOOL success) {
        completion(success);
    }];
}


- (void)requestWithRecords:(NSArray<QSNetEventRecordModel *> *)records completion:(void (^)(BOOL success))completion {
    
    [QSNetSessionService.share.delegateQueue addOperationWithBlock:^{
        // 拼接 json 数据
        NSString *jsonString = [self buildFlushJSONStringWithEventRecords:records];

        NSLog(@"加入上报请求队列 ：%@",jsonString);
        // 网络请求回调处理
        QSURLSessionTaskCompletionHandler handler = ^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSLog(@"%@ network failure: %@", self, error ? error : @"Unknown error");
                return completion(NO);
            }

            NSInteger statusCode = response.statusCode;
            if (statusCode == 414) {
                // 发出通知供外部上报414错误类型
                [[NSNotificationCenter defaultCenter]postNotificationName:kreportWith414ErrorNotification object:response];
                return completion(YES);
            }

            NSString *messageDesc = nil;
            if (statusCode >= 200 && statusCode < 300) {
                messageDesc = @"\n【valid message】\n";
            }

            @try {
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSLog(@"%@ %@: %@", self, messageDesc, dict);
            } @catch (NSException *exception) {
                NSLog(@"%@: %@", self, exception);
            }

            //只有 5xx & 404 & 403 不删，其余均删；
            BOOL successCode = (statusCode < 500 || statusCode >= 600) && statusCode != 404 && statusCode != 403;
            BOOL flushSuccess = successCode;
            completion(flushSuccess);
        };

        // 转换成发送的 http 的query参数
        NSString *reportUrl = self.isDev ? self.devReportURL : self.proReportURL;
        NSString *url = [reportUrl stringByAppendingFormat:@"?%@",QS_AFQueryStringFromParameters(jsonString.mj_JSONObject)];
        NSURLRequest *request = [self buildFlushRequestWithServerURL:[NSURL URLWithString:url]];

        NSURLSessionDataTask *task = [QSNetSessionService.share dataTaskWithRequest:request completionHandler:handler];
        [task resume];
    }];
}

- (NSURLRequest *)buildFlushRequestWithServerURL:(NSURL *)serverURL{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:serverURL];
    request.timeoutInterval = 30;
    request.HTTPMethod = @"GET";
    return request;
}

// 2. 完成 HTTP 请求拼接
- (NSData *)buildBodyWithJSONString:(NSString *)jsonString isEncrypted:(BOOL)isEncrypted {
    int gzip = 1; // gzip = 9 表示加密编码
    // 使用gzip进行压缩
    NSData *zippedData = [QSGZipUtility gzipData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    // base64
    jsonString = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    int hashCode = [jsonString qs_sensorsdata_hashCode];
    jsonString = [jsonString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    NSString *bodyString = [NSString stringWithFormat:@"crc=%d&gzip=%d&data_list=%@", hashCode, gzip, jsonString];
    return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
}


NSString * QS_AFQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (QSAFQueryStringPair *pair in QS_AFQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }

    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * QS_AFQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return QS_AFQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * QS_AFQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:QS_AFQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:QS_AFQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:QS_AFQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[QSAFQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}

@end


@implementation QSFlushConfig


@end









