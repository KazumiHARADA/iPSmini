//
//  NSMutableArray+iPSAddition.m
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/07.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import "NSMutableArray+iPSAddition.h"

@implementation NSMutableArray (iPSAddition)


-(void) add:(id) obj
{
    [self insertObject:obj atIndex:([self count] - 1)];
}

-(id) addR:(id) obj
{
    [self insertObject:obj atIndex:([self count] - 1)];
    return self;
}

-(void) addAll:(id)value, ...
{
	va_list argp;
	va_start(argp,value);
    id tmp = value;
	while(tmp != nil){
		[self insertObject:tmp atIndex:([self count] - 1)];
		tmp = va_arg(argp,id);
	}
	va_end(argp);
}

-(id) addAllR:(id)value, ...
{
	va_list argp;
	va_start(argp,value);
    id tmp = value;
	while(tmp != nil){
		[self insertObject:tmp atIndex:([self count] - 1)];
		tmp = va_arg(argp,id);
	}
	va_end(argp);
    
    return self;
}

-(void) addFromCell:(NSMutableArray *) cell
{
    [self removeLastObject];
    [self addObjectsFromArray:cell];
}

-(void) forEachValues:(void(^)(int pos))process
{
    int tmp_pos=0;
    while (self[tmp_pos] != [NSNull null]) {
        process(tmp_pos);
        tmp_pos++;
    }
}

-(id) forEachValuesR:(id(^)(int pos))process :(id)to_null
{
    int tmp_pos=0;
    id result;
    while (self[tmp_pos] != [NSNull null]) {
        if ([(result = process(tmp_pos)) isEqual:@"cont"]){
            tmp_pos++;
        } else {
            return result;
        }
    }
    return to_null;
}


BOOL isExactNullAtLast(NSMutableArray *arr)
{
    return [[arr lastObject] isEqual:[NSNull null]];
}

+(id) initCell
{
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:0];
    [tmp addObject:[NSNull null]];
    return tmp;
}

-(void) push:(id)obj
{
    [self insertObject:obj atIndex:0];
}

-(id) pop
{
    id ans = [self objectAtIndex:0];
    [self removeObjectAtIndex:0];
    return ans;
}

@end
