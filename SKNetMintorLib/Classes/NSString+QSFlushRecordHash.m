//
//  NSString+QSFlushRecordHash.m
//  QSNetAnalyseDemo
//
//  Created by 帅科 on 2021/4/15.
//

#import "NSString+QSFlushRecordHash.h"

@implementation NSString (QSFlushRecordHash)

- (int)qs_sensorsdata_hashCode{
    int hash = 0;
    for (int i = 0; i<[self length]; i++) {
        NSString *s = [self substringWithRange:NSMakeRange(i, 1)];
        char *unicode = (char *)[s cStringUsingEncoding:NSUnicodeStringEncoding];
        int charactorUnicode = 0;

        size_t length = strnlen(unicode, 4);
        for (int n = 0; n < length; n ++) {
            charactorUnicode += (int)((unicode[n] & 0xff) << (n * sizeof(char) * 8));
        }
        hash = hash * 31 + charactorUnicode;
    }
    
    return hash;
}

@end
