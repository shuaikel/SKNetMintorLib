//
//  QSNetDataBase.h
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QSNetEventRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface QSNetDataBase : NSObject

//serial queue for database read and write
@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;


@property (nonatomic, assign, readonly) BOOL isCreatedTable;

@property (nonatomic, assign, readonly) NSUInteger count;


/// init method
/// @param filePath path for database file
- (instancetype)initWithFilePath:(NSString *)filePath;


/// open database, return YES or NO
- (BOOL)open;


/// create default event table, return YES or NO
- (BOOL)createTable;

/// fetch first records with a certain size
/// @param recordSize record size
- (NSArray<QSNetEventRecordModel *> *)selectRecords:(NSUInteger)recordSize;


/// bulk insert event records
/// @param records event records
- (BOOL)insertRecords:(NSArray<QSNetEventRecordModel *> *)records;


/// insert single record
/// @param record event record
- (BOOL)insertRecord:(QSNetEventRecordModel *)record;

/// update records' status
/// @param recordIDs event recordIDs
/// @param status status
- (BOOL)updateRecords:(NSArray<NSString *> *)recordIDs status:(QSEventRecordStatus)status;

/// delete records with IDs
/// @param recordIDs event record IDs
- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs;


///// delete first records with a certain size
///// @param recordSize record size
//- (BOOL)deleteFirstRecords:(NSUInteger)recordSize;


/// delete all records from database
- (BOOL)deleteAllRecords;

@end

NS_ASSUME_NONNULL_END
