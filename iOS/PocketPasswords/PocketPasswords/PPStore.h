//
//  PPStore.h
//  PocketPasswords
//
//  Created by Lukhnos Liu on 3/25/15.
//  Copyright (c) 2015 Lukhnos Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPStore : NSObject
+ (PPStore *)sharedInstance;
- (void)loadStore:(NSString *)path passphrase:(NSString *)passphrase;
- (void)clearStore;
- (NSArray *)rowAtIndex:(NSUInteger)index;
- (NSString *)titleAtIndex:(NSUInteger)index;
@property NSMutableArray *indices;
@property NSMutableString *text;
@property (readonly) NSUInteger count;
@property (readonly) NSArray *headerRow;
@end

