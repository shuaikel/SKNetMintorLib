//
//  QSNetEventRecordModel.m
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import "QSNetEventRecordModel.h"
#import <MJExtension/MJExtension.h>


static long recordIndex = 0;

@implementation QSNetEventRecordModel

- (BOOL)isValid {
    return self.content.length > 0;
}

- (instancetype)initWithEvent:(NSDictionary *)event type:(NSString *)type{
    if (self = [super init]) {
        _recordID = [NSString stringWithFormat:@"QS_SA_%ld", recordIndex];
        
        _type = type;
        // 转String
        NSData *data = [event mj_JSONData];
        _content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return self;
}

- (instancetype)initWithRecordID:(NSString *)recordID content:(NSString *)content {
    if (self = [super init]) {
        _recordID = recordID;
        _content = content;
    }
    return self;
}

@end


@implementation QSNetEventRecordItemModel

@end
