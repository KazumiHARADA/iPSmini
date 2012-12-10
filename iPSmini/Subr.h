//
//  Subr.h
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/05.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IPS.h"

@interface Subr : IPS
{
    id s_env;
}

-(id) applySubr:(id)name :(id)vals;
-(id) initWithTable:(id)table;

@property (strong, nonatomic)NSMutableArray *s_env;
@end

