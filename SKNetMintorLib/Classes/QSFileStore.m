//
//  QSFileStore.m
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import "QSFileStore.h"

@implementation QSFileStore

+ (NSString *)filePath:(NSString *)key {
    NSString *filename = [NSString stringWithFormat:@"qs_sensorsanalytics-%@.plist", key];
    NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
    NSLog(@"filepath for %@ is %@", key, filepath);
    return filepath;
}

@end
