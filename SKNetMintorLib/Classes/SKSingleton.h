//
//  SKSingleton.h
//  SKNetMintorLib
//
//  Created by shuaike on 2024/7/19.
//

#ifndef SKSingleton_h
#define SKSingleton_h

#define SKSingletonH(methodName) + (instancetype)methodName;
// .m文件
#define SKSingletonM(methodName) \
static id _instance; \
\
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [super allocWithZone:zone]; \
}); \
return _instance; \
} \
\
+ (instancetype)methodName \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[self alloc] init]; \
}); \
return _instance; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return _instance; \
}

#endif /* SKSingleton_h */
