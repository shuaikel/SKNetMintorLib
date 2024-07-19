//
//  QSFileStore.h
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QSFileStore : NSObject

+ (NSString *)filePath:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
