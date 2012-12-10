//
//  main.m
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/05.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Load.h"
#import "IPS.h"

NSString *path = @"/Users/harada/Desktop/iPSmini/iPSmini/init.ips";

int main(int argc,char *argv[]){
    @autoreleasepool {
        NSString *str = [[NSString alloc] init];
        NSMutableArray *m_env = [NSMutableArray arrayWithCapacity:3];
        
        char tmp[5000];
        
        [m_env addObject:[NSNull null]];
        [[Load alloc] initFileLoad:path :m_env];
        for(;;){
            @try {
                    printf("iPS> ");
                    fflush(stdout);
                    fgets(tmp,5000,stdin);
                    str = [Load waitingForKeyIn:tmp];
                    [[[IPS alloc] initWithEnv:m_env] eval:str];
            }
            @catch (NSException *err) {
                id ename = [err name];
                if ([ename isEqualToString:@"eval"]) {
                    printf("*** ERROR: %s\n",[[err reason] UTF8String]);
                } else if ([ename isEqualToString:@"NSDecimalNumberOverflowException"]){                    printf("*** ERROR: NSDecimalNumberOverflow\n");
                }
            }
        }
    }
	return 0;
}