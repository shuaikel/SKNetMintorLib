//
//  QSNetEventStore.h
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QSNetEventRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface QSNetEventStore : NSObject

//serial queue for database read and write
@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;

/// All event record count
@property (nonatomic, readonly) NSUInteger count;

/**
 *  @abstract
 *  根据传入的文件路径初始化
 *
 *  @param filePath 传入的数据文件路径
 *
 *  @return 初始化的结果
 */
- (instancetype)initWithFilePath:(NSString *)filePath;

/// insert single record
/// @param record event record
- (BOOL)insertRecord:(QSNetEventRecordModel *)record;


- (BOOL)updateRecords:(NSArray<NSString *> *)recordIDs status:(QSEventRecordStatus)status;


/// delete records with IDs
/// @param recordIDs event record IDs
- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs;


/// delete all records from database
- (BOOL)deleteAllRecords;


- (NSArray<QSNetEventRecordModel *> *)selectRecords:(NSUInteger)recordSize;

@end

NS_ASSUME_NONNULL_END
