//
//  Load.m
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/05.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import "Load.h"
#import "IPS.h"



//#define DEBUG_LOAD

@implementation Load

-(void) initFileLoad:(id)path :(id)m_env
{
    // NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"init.ips"];
    //NSLog(@"%@",path);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSArray *line = [text componentsSeparatedByString:@"\n"];
        NSMutableArray *lines = [NSMutableArray arrayWithCapacity:0];
        [lines addObjectsFromArray:line];
        [lines addObject:[NSNull null]];
        
        NSMutableString *str = [[NSMutableString alloc] init];
        
        int tmp_pos = 0;
        int open = 0,close = 0;
        
        while ([lines[tmp_pos] isEqual:[NSNull null]] != TRUE) {
            if([lines[tmp_pos] isEqual:@""] != TRUE){
                [str appendString:@" "];
                [str appendString:[self tidyString:lines[tmp_pos]]];
                NSArray *toked = [[IPS alloc] scan:str];
                open = strCount(toked, @"(");
                close = strCount(toked, @")");
                NSMutableArray *tidied = [self tidyArray:toked];
#ifdef DEBUG_LOAD
                NSLog(@"tidied-%@",tidied);
#endif
                if (open == close) {
                    if ([tidied[0] isEqual:[NSNull null]] != TRUE) {
                        id parsed = [[IPS alloc] parse:[self tidyArray:toked]];
                        [[[IPS alloc] initWithEnv:m_env] meaning:parsed :m_env];
                        [str deleteCharactersInRange:NSMakeRange(0,str.length)];
                    }
                }
            }
            tmp_pos++;
        }
        
    }
    
}

-(void) schemeFileLoad:(NSMutableArray *)arguments :(NSMutableArray *)env
{
    id path;
    if ([arguments[0] isAbsolutePath]) {
        path = arguments[0];
    } else {
        NSString *current = [[NSTask alloc] currentDirectoryPath];
        path = [current stringByAppendingPathComponent:arguments[0]];
    }
    
    [arguments addObject:[NSNull null]];
    
    NSMapTable *entry = [NSMapTable strongToStrongObjectsMapTable];
    [entry setObject:arguments forKey:@"*argv*"];
    [env insertObject:entry atIndex:0];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [self initFileLoad:path :env];
    } else {
        [IPS error:path :9];
    }
    int num = 0;
    while (![env[num] isEqual:[NSNull null]]) {
        if ([env[num] objectForKey:@"main"] != NULL){
            NSMutableArray *apply_entry = [env[num] objectForKey:@"main"];
            [[IPS alloc] apply:apply_entry :arguments :env];
        }
        num++;
    }
}

int strCount(id toked,NSString * str)
{
    int tmp_pos = 0;
    int count = 0;
    while ([toked[tmp_pos] isEqual:[NSNull null]] != TRUE) {
        if ([toked[tmp_pos] isEqualToString:str]) {
            count++;
        }
        tmp_pos++;
    }
    return count;
}

-(void)appendStringFromArray:(NSArray *)arr :(NSMutableString *)str {
    int tmp_pos = 0;
    
    while ([arr[tmp_pos] isEqual:[NSNull null]] != TRUE) {
        [str appendString:arr[tmp_pos]];
        [str appendString:@" "];
        tmp_pos++;
    }
}

-(NSMutableArray *) tidyArray:(NSArray *)toked
{
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:3];
    int pos = 0;
    
    [tmp addObjectsFromArray:toked];
    
    while ([tmp[pos] isEqual:[NSNull null]] != TRUE) {
        if ([tmp[pos] isEqualToString:@""]) {
            [tmp removeObjectAtIndex:pos];
            continue;
        }
        pos++;
    }
    return tmp;
}

-(NSString *) tidyString:(NSString *)str
{
    
    NSString *result = [str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    
    return subStringToExp(subStringToExp(result, @"^ + "),@";+.*$");
    
}

NSString *subStringToExp(NSString *str,NSString *reg_exp)
{
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:reg_exp
                                                                         options:0
                                                                           error:nil];
    
    NSString *result = [reg stringByReplacingMatchesInString:str
                                                     options:0
                                                       range:NSMakeRange(0,str.length)
                                                withTemplate:@""];
    return result;
}

//waiting for key in

+(NSString *) waitingForKeyIn:(char *)str
{
    int open = 0,close = 0,i = 0;
    char tmp[5000];
    
    subNewLine(str);
    subTab(str);
    
    for(;;){
        while (str[i] != '\0'){
            if (str[i] == '('){
                open++;
            } else if (str[i] == ')'){
                close++;
            }
            i++;
        }
        
        if (str[0] == '\0'){
            printf("    > ");
            fgets(tmp,5000,stdin);
            subNewLine(tmp);
            subTab(tmp);
            strcat(str,tmp);
            continue;
        }
        if (open == close) {
            NSString *result = [[NSString stringWithUTF8String:str] copy];
            return result;
        } else if (open < close) {
            [IPS error:@"#f" :6];
        } else {
            printf("    > ");
            fgets(tmp,5000,stdin);
            strcat(str, " ");
            subNewLine(tmp);
            subTab(tmp);
            strcat(str,tmp);
        }
    }
}

void subNewLine(char *str){
    char *p;
    
    p = strrchr(str,'\n');
    if (p != NULL) {
        *p = '\0';
    } else {
        exit(1);
    }
}

void subTab(char *str){
    char *p;
    char tmp[5000] = {};
    int i = 0;
    
    p = str;
    
    while (*p != '\0'){
        if (*p == '\t'){
            p++;
            continue;
        }
        tmp[i] = *p;
        i++,p++;
    }
    tmp[i+1] = '\0';
    strcpy(str,tmp);
}


@end
