//
//  QSNetDataBase.m
//  VipCard_iOS
//
//  Created by 帅科 on 2021/4/19.
//  Copyright © 2021 tantu.com. All rights reserved.
//

#import "QSNetDataBase.h"
#import <sqlite3.h>

// QSNetDataBase
static NSString *const kDatabaseTableName =  @"QSDataCache";
static NSString *const kDatabaseColumnStatus = @"status";

@interface QSNetDataBase ()

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, assign) BOOL isCreatedTable;
@property (nonatomic, assign) NSUInteger count;

@end

@implementation QSNetDataBase{
    sqlite3 *_database;
    CFMutableDictionaryRef _dbStmtCache;
}


- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = filePath;
        _serialQueue = dispatch_queue_create("cn.sensorsdata.QSSADatabaseSerialQueue", DISPATCH_QUEUE_SERIAL);
        [self createStmtCache];
        [self open];
        [self createTable];
    }
    return self;
}

- (void)createStmtCache {
    CFDictionaryKeyCallBacks keyCallbacks = kCFCopyStringDictionaryKeyCallBacks;
    CFDictionaryValueCallBacks valueCallbacks = { 0 };
    _dbStmtCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &keyCallbacks, &valueCallbacks);
}

- (BOOL)open {
    if (self.isOpen) {
        return YES;
    }
    if (_database) {
        [self close];
    }
    sqlite3_config(SQLITE_CONFIG_SERIALIZED);
    if (sqlite3_open_v2([self.filePath UTF8String], &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
        _database = NULL;
        NSLog(@"Failed to open SQLite db");
        return NO;
    }
    NSLog(@"Success to open SQLite db");
    self.isOpen = YES;
    return YES;
}

- (void)close {
    if (_dbStmtCache) CFRelease(_dbStmtCache);
    _dbStmtCache = NULL;

    if (_database) sqlite3_close(_database);
    _database = NULL;

    _isCreatedTable = NO;
    _isOpen = NO;
    NSLog(@"%@ close database", self);
}

- (BOOL)insertRecords:(NSArray<QSNetEventRecordModel *> *)records {

    if (records.count == 0) {
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }

    if (sqlite3_exec(_database, "BEGIN TRANSACTION", 0, 0, 0) != SQLITE_OK) {
        return NO;
    }

    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@(type, content) values(?, ?)",kDatabaseTableName];
    sqlite3_stmt *insertStatement = [self dbCacheStmt:query];
    if (!insertStatement) {
        return NO;
    }
    BOOL success = YES;
    for (QSNetEventRecordModel *record in records) {
        if (![record isValid]) {
            success = NO;
            break;
        }
        sqlite3_bind_text(insertStatement, 1, [record.type UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, [record.content UTF8String], -1, SQLITE_TRANSIENT);
        if (sqlite3_step(insertStatement) != SQLITE_DONE) {
            success = NO;
            break;
        }
        sqlite3_reset(insertStatement);
    }
    BOOL bulkInsertResult = sqlite3_exec(_database, success ? "COMMIT" : "ROLLBACK", 0, 0, 0) == SQLITE_OK;
    self.count = [self messagesCount];
    return bulkInsertResult;
}

- (BOOL)insertRecord:(QSNetEventRecordModel *)record {
    if (![record isValid]) {
        NSLog(@"%@ input parameter is invalid for addObjectToDatabase", self);
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@(type, content) values(?, ?)",kDatabaseTableName];
    sqlite3_stmt *insertStatement = [self dbCacheStmt:query];
    int rc;
    if (insertStatement) {
        sqlite3_bind_text(insertStatement, 1, [record.type UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, [record.content UTF8String], -1, SQLITE_TRANSIENT);
        rc = sqlite3_step(insertStatement);
        if (rc != SQLITE_DONE) {
            NSLog(@"insert into %@ table of sqlite fail, rc is %d", kDatabaseTableName,rc);
            return NO;
        }
        self.count++;
        NSLog(@"insert into %@ table of sqlite success, current count is %lu", kDatabaseTableName,self.count);
        return YES;
    } else {
        NSLog(@"insert into dataCache table of sqlite error");
        return NO;
    }
}



- (BOOL)deleteRecords:(NSArray<NSString *> *)recordIDs {
    if ((self.count == 0) || (recordIDs.count == 0)) {
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }
    NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE id IN (%@);", kDatabaseTableName,[recordIDs componentsJoinedByString:@","]];
    sqlite3_stmt *stmt;

    if (sqlite3_prepare_v2(_database, query.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        NSLog(@"Prepare delete records query failure: %s", sqlite3_errmsg(_database));
        return NO;
    }
    BOOL success = YES;
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        NSLog(@"Failed to delete record from %@, error: %s", kDatabaseTableName,sqlite3_errmsg(_database));
        success = NO;
    }
    sqlite3_finalize(stmt);
    self.count = [self messagesCount];
    return success;
}


- (BOOL)updateRecords:(NSArray<NSString *> *)recordIDs status:(QSEventRecordStatus)status{
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ = %d WHERE id IN (%@);", kDatabaseTableName, kDatabaseColumnStatus, status, [recordIDs componentsJoinedByString:@","]];
    return [self execUpdateSQL:sql];
}

- (NSArray<QSNetEventRecordModel *> *)selectRecords:(NSUInteger)recordSize {
    NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    if ((self.count == 0) || (recordSize == 0)) {
        return [contentArray copy];
    }
    if (![self databaseCheck]) {
        return [contentArray copy];
    }
    NSString *query = [NSString stringWithFormat:@"SELECT id,content FROM %@ WHERE %@ = 0 ORDER BY id ASC LIMIT %lu", kDatabaseTableName,kDatabaseColumnStatus, (unsigned long)recordSize];
    sqlite3_stmt *stmt = [self dbCacheStmt:query];
    if (!stmt) {
        NSLog(@"Failed to prepare statement, error:%s", sqlite3_errmsg(_database));
        return [contentArray copy];
    }

    NSMutableArray<NSString *> *invalidRecords = [NSMutableArray array];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int index = sqlite3_column_int(stmt, 0);
        char *jsonChar = (char *)sqlite3_column_text(stmt, 1);
        if (!jsonChar) {
            NSLog(@"Failed to query column_text, error:%s", sqlite3_errmsg(_database));
            [invalidRecords addObject:[NSString stringWithFormat:@"%d", index]];
            continue;
        }
        NSString *recordID = [NSString stringWithFormat:@"%d", index];
        NSString *content = [NSString stringWithUTF8String:jsonChar];
        QSNetEventRecordModel *record = [[QSNetEventRecordModel alloc] initWithRecordID:recordID content:content];
        [contentArray addObject:record];
    }
    [self deleteRecords:invalidRecords];

    return [contentArray copy];
}

// MARK: Internal APIs for database CRUD
- (BOOL)createTable {
    if (!self.isOpen) {
        return NO;
    }
    if (self.isCreatedTable) {
        return YES;
    }
    NSString *sql = [NSString stringWithFormat:@"create table if not exists %@ (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, content TEXT)", kDatabaseTableName];
    if (sqlite3_exec(_database, sql.UTF8String, NULL, NULL, NULL) != SQLITE_OK) {
        NSLog(@"Create %@ table fail.", kDatabaseTableName);
        self.isCreatedTable = NO;
        return NO;
    }
    if (![self createColumn:kDatabaseColumnStatus inTable:kDatabaseTableName]) {
        NSLog(@"Alert table %@ add %@ fail.", kDatabaseTableName, kDatabaseColumnStatus);
        self.isCreatedTable = NO;
        return NO;
    }
    self.isCreatedTable = YES;
    // 如果数据在上传过程中，App 被强杀或者 crash，可能存在状态不对的数据
    // 重置所有数据状态，重新上传
    [self resetAllRecordsStatus];
    self.count = [self messagesCount];
    NSLog(@"Create %@ table success, current count is %lu", kDatabaseTableName, self.count);
    return YES;
}

- (BOOL)createColumn:(NSString *)columnName inTable:(NSString *)tableName {
    if ([self columnExists:kDatabaseColumnStatus inTable:kDatabaseTableName]) {
        return YES;
    }

    NSString *query = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ INTEGER NOT NULL DEFAULT (0);", tableName, columnName];
    sqlite3_stmt *stmt;

    if (sqlite3_prepare_v2(_database, query.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        NSLog(@"Prepare create column query failure: %s", sqlite3_errmsg(_database));
        return NO;
    }
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        NSLog(@"Failed to create column, error: %s", sqlite3_errmsg(_database));
        return NO;
    }
    sqlite3_finalize(stmt);
    return YES;
}


- (BOOL)columnExists:(NSString *)columnName inTable:(NSString *)tableName {
    if (!columnName) {
        return NO;
    }
    return [[self columnsInTable:tableName] containsObject:columnName];
}

- (NSArray<NSString *>*)columnsInTable:(NSString *)tableName {
    NSMutableArray<NSString *> *columns = [NSMutableArray array];
    NSString *query = [NSString stringWithFormat: @"PRAGMA table_info('%@');", tableName];
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_database, query.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        NSLog(@"Prepare PRAGMA table_info query failure: %s", sqlite3_errmsg(_database));
        return columns;
    }

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        char *name = (char *)sqlite3_column_text(stmt, 1);
        if (!name) {
            continue;
        }
        NSString *column = [NSString stringWithUTF8String:name];
        if (column) {
            [columns addObject:column];
        }
    }
    sqlite3_finalize(stmt);
    return columns;
}

- (BOOL)resetAllRecordsStatus {
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ = %d WHERE %@ = (%d);", kDatabaseTableName, kDatabaseColumnStatus, QSEventRecordStatusNone, kDatabaseColumnStatus, QSEventRecordStatusFlush];
    return [self execUpdateSQL:sql];
}

- (BOOL)execUpdateSQL:(NSString *)sql {
    if (![self databaseCheck]) {
        return NO;
    }

    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_database, sql.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
        NSLog(@"Prepare update records query failure: %s", sqlite3_errmsg(_database));
        return NO;
    }
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        NSLog(@"Failed to update records from %@, error: %s", kDatabaseTableName,sqlite3_errmsg(_database));
        return NO;
    }
    sqlite3_finalize(stmt);
    return YES;
}

- (BOOL)deleteAllRecords{
    if (self.count == 0) {
        return NO;
    }
    if (![self databaseCheck]) {
        return NO;
    }
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@",kDatabaseTableName];
    if (sqlite3_exec(_database, sql.UTF8String, NULL, NULL, NULL) != SQLITE_OK) {
        NSLog(@"Failed to delete all records");
        return NO;
    }
    self.count = 0;
    return YES;
}

- (BOOL)databaseCheck {
    if (![self open]) {
        return NO;
    }
    if (![self createTable]) {
        return NO;
    }
    return YES;
}

- (sqlite3_stmt *)dbCacheStmt:(NSString *)sql {
    if (sql.length == 0 || !_dbStmtCache) return NULL;
    sqlite3_stmt *stmt = (sqlite3_stmt *)CFDictionaryGetValue(_dbStmtCache, (__bridge const void *)(sql));
    if (!stmt) {
        int result = sqlite3_prepare_v2(_database, sql.UTF8String, -1, &stmt, NULL);
        if (result != SQLITE_OK) {
            NSLog(@"sqlite stmt prepare error (%d): %s", result, sqlite3_errmsg(_database));
            return NULL;
        }
        CFDictionarySetValue(_dbStmtCache, (__bridge const void *)(sql), stmt);
    } else {
        sqlite3_reset(stmt);
    }
    return stmt;
}


//MARK: execute sql statement to get total event records count stored in database
- (NSUInteger)messagesCount {
    NSString *query = [NSString stringWithFormat:@"select count(*) from %@",kDatabaseTableName];
    int count = 0;
    sqlite3_stmt *statement = [self dbCacheStmt:query];
    if (statement) {
        while (sqlite3_step(statement) == SQLITE_ROW)
            count = sqlite3_column_int(statement, 0);
    } else {
        NSLog(@"Failed to get count form QSNetDataBase");
    }
    return (NSUInteger)count;
}

- (void)dealloc {
    [self close];
}


@end
