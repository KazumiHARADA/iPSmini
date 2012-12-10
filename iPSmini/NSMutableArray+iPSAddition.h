//
//  NSMutableArray+iPSAddition.h
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/07.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (iPSAddition)

-(void) addAll:(id)value,...;
-(id) addAllR:(id)value,...;
-(void) add:(id)obj;
-(id) addR:(id)obj;
-(void) addFromCell:(NSMutableArray *)cell;
-(void) forEachValues:(void(^)(int pos))process;
-(id) forEachValuesR:(id(^)(int pos))process :(id)to_null;
+(id) initCell;

-(void) push:(id)obj;
-(id) pop;

@end
