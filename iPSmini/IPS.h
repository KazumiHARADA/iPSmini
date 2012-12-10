//
//  IPS.h
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/05.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPS : NSObject
{
    NSMutableArray *initial_value;
    NSMutableArray *global_table;
    NSMutableArray *local_table;
}

-(id) scan:(id)str;
-(id) parse:(id)tokens;
-(void) eval:(id)parsed;

-(id) meaning:(id)e :(NSMutableArray *)table;
-(id) apply:(id)fun :(id)vals :(id)table;

-(id) initWithEnv:(id)env;

-(void) print:(id) arr;
-(id) printAux:(id)arr;
+(void) error:(id)e :(int)flag;

@property (strong, nonatomic)NSMutableArray *global_table;
@property (strong, nonatomic)NSMutableArray *local_table;
@property (strong, nonatomic)NSMutableArray *initial_value;

@end
