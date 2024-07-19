//
//  QSGZipUtility.h
//  QSNetAnalyseDemo
//
//  Created by 帅科 on 2021/4/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QSGZipUtility : NSObject
+ (NSData *)gzipData:(NSData *)pUncompressedData;
@end

NS_ASSUME_NONNULL_END
