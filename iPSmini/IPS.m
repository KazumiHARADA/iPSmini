//
//  IPS.m
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/05.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//
// error
// 1 unbound 2 arguments 3 baddot 4 improper 5 unsupported 6 extra-close
// 7 out-of-range 8 not-open 9 cannot-find 10 loop not found def unexpected

#import "IPS.h"
#import "Subr.h"
#import "NSMutableArray+iPSAddition.h"

#define CONST 1
#define QUOTE 2
#define IDENTIFIER 3
#define LAMBDA 4
#define COND 5
#define APPLICATION 6
#define DEFINE 7
#define LET 8
#define LETREC 9
#define OR 10
#define AND 11
#define MACRO 12
#define LOOP 13
#define RECUR 14

@implementation IPS

@synthesize global_table;
@synthesize local_table;
@synthesize initial_value;
@synthesize loop_table;

int loop_flag = 0;

-(void) eval:(id)str
{
    NSArray *toked = [self scan:str];
    id parsed = [self parse:toked];
    self.initial_value = parsed;
    
  //  printf("size:%ld\n",sizeof(double));
    
    [self print:[self meaning:self.initial_value :self.global_table]];
    
}


-(id) meaning:(id)e :(NSMutableArray *)table
{
    int flag = [self expressionToAction:e];

    switch (flag) {
        case CONST:
            return [self constant:e:table];
        case QUOTE:
            return [self quote:e :table];
        case IDENTIFIER:
            return [self identifier:e :table];
        case LAMBDA:
            return [self lambda:e :table];
        case COND:
            return [self cond:e :table];
        case DEFINE:
            return [self define:e :table];
        case LET:
            return [self let:e :table];
        case LETREC:
            return [self letrec:e :table];
        case OR:
            return [self or:e :table];
        case AND:
            return [self and:e :table];
        case MACRO:
            return [self macroExpand:e :table];
        case LOOP:
            return [self loop:e :table];
        case RECUR:
            return [self recur:e :table];
        case APPLICATION:
            return [self application:e :table];
    }
    
    [IPS error:@"#f" :0];
    return @"#f";
}

-(id) constant:(id)e :(NSMutableArray *)table
{
    if (isNumber(e)) {
        return e;
    } else if (isString(e)) {
        return e;
    } else if (isInternalChar(e)) {
        return e;
    } else if ([e isEqual:@"#t"]) {
        return @"#t";
    } else if ([e isEqual:@"#f"]) {
        return @"#f";
    } else {
        return [[NSMutableArray initCell] addAllR:@"primitive",e,nil];
    }
}

-(id) quote:(id)e :(NSMutableArray *)table
{
    return car(cdr(e));
}

-(id) identifier:(id) e:(NSMutableArray *)table
{
    id ans = [self lookupInTable:e :table];
    //NSLog(@"%@",table);
    
    if ([ans isEqual:@"#f"]) {
        [IPS identifierError:e];
    }
    return ans;
}

-(id) cond:(id)e :(NSMutableArray *) table
{
    return [self evcon:cdr(e) :table];
}

-(id) lambda:(id)e :(NSMutableArray *)table//(non-primitive (table args body))
{
    //NSLog(@"%@",table);
    NSMutableArray *tmp = [[NSMutableArray initCell] addR:table];
    
    [tmp addFromCell:cdr(e)];
    
    return [[NSMutableArray initCell] addAllR:@"non-primitive",tmp,nil];
}

-(id) let:(id)e :(NSMutableArray *)table
{
    if ([car(cdr(e)) isKindOfClass:[NSString class]]) {
        return [self evNamedlet:letNameOf(e) :cdr(e) :table];
    } else {
        return [self evlet:e :table];
    }
}

-(id) evNamedlet:(id)name :(id) e:(id) table
{
    NSMutableArray *tmp_table = [NSMutableArray arrayWithCapacity:0];
    
    loop_flag = 1;
    id params = letParametersOf(e);
    id args = [self letArgumentsOf:e :table];
    id body = letBodyOf(e);
    id define_entry = setDefineEntry(name,params,body);
    if ([table isEqual:self.global_table]){
        tmp_table = [self.global_table mutableCopy];
    } else {
        tmp_table = [table mutableCopy];
    }
    [self define:define_entry :tmp_table];
    id result = [self apply:[self meaning:name :tmp_table] :args :tmp_table];
    loop_flag = 0;
    return result;
}

-(id) evlet:(id)e :(id)table
{
    //NSLog(@"%lu",[table count]);
    //NSLog(@"%@",table);
    //loop_flag = 1;
    id params = letParametersOf(e);
    id args = [self letArgumentsOf:e :table];
    id body = letBodyOf(e);
    id lambda_entry = setLambdaEntry(params,body);
    id closure_recode = [self lambda:lambda_entry :table];
    id result = [self applyClosure:car(cdr(closure_recode)) :args :table];
    //loop_flag = 0;
    //NSLog(@"%@",table);
 //NSLog(@"%lu",[table count]);
    return result;
}

-(id) letArgumentsOf:(id) e :(id) table
{
    id vals = car(cdr(e));
    
    NSMutableArray *result = [NSMutableArray initCell];
    [vals forEachValues:^void(int pos){
        [result add:[self meaning:car(cdr(vals[pos])) :table]];
    }];
    
    return result;
}

-(id) letrec:(id)e :(id)table
{
    loop_flag = 1;
    id define_entrys = letrecDefineEntry(car(cdr(e)));
    NSMutableArray *tmp_table = [NSMutableArray arrayWithCapacity:0];
    
    if ([table isEqual:self.global_table]){
        tmp_table = [self.global_table mutableCopy];
    } else {
        tmp_table = [table mutableCopy];
    }
    [self allDefine:define_entrys :tmp_table];
   
    id result = [self meaning:letrecMeaningEntry(e) :tmp_table];
    loop_flag = 0;
    return result;
}

-(void) allDefine:(id)entrys :(id)table
{
    [entrys forEachValues:^void(int pos){
        [self define:entrys[pos] :table];
        [entrys[pos] removeObjectAtIndex:0];
    }];
}

-(void) allDefineForLoop:(id)entrys :(id)table
{
    [entrys forEachValues:^void(int pos){
        [self defineForLoop:entrys[pos] :table];
        [entrys[pos] removeObjectAtIndex:0];
    }];
}


-(id) and:(id)e :(id)table
{
    id vals = cdr(e);
    int tmp_pos = 0;
    id result;
    
    while ([vals[tmp_pos] isEqual:[NSNull null]] != TRUE) {
        result = [self meaning:vals[tmp_pos] :table];
        if([result isEqual:@"#f"]){
            return @"#f";
        }
        tmp_pos++;
    }
    
    return result;
 
}

-(id) or:(id)e :(id)table
{
    id vals = cdr(e);
    int tmp_pos = 0;
    id result;
    
    while ([vals[tmp_pos] isEqual:[NSNull null]] != TRUE) {
        result = [self meaning:vals[tmp_pos] :table];
        if(![result isEqual:@"#f"]){
            return result;
        }
        tmp_pos++;
    }
    return result;
}

-(id) macroExpand:(id)e :(NSMutableArray *)table
{
    NSString *macro_name = car(e);
    
    if ([macro_name isEqualToString:@"time"]) {
        return [self time:e :table];
    } else if ([macro_name isEqualToString:@"if"]) {
        return [self macroIf:e :table];
    } else {
        [IPS error:macro_name :1];
    }
    return @"#f";
}

-(id) time:(id)e :(NSMutableArray *)table
{
    id d1 = [NSDate date];
    id result = [self meaning:second(e) :table];
    id d2 = [NSDate date];
    NSTimeInterval t = [d2 timeIntervalSinceDate:d1];
    printf(";time:%f\n",(double)t);
    return result;
}

-(id) macroIf:(id)e :(NSMutableArray *)table
{
  
    id test = [self meaning:Test(e) :table];
    id result;
    if ([test isEqual:@"#t"]) {
        result = [self meaning:ifTrueCase(e) :table];
    } else {
        result = [self meaning:ifFalseCase(e) :table];
    }
  
    return result;
}

-(NSMutableArray *) loopArgumentsOf:(NSMutableArray *)params :(NSMutableArray *)table
{
    NSMutableArray *result = [NSMutableArray initCell];
    
    [params forEachValues:^void(int pos) {
        [result add:[self lookupInTable:params[pos] :table]];
    }];
   
    return result;
}

-(id) loop:(id)e :(NSMutableArray *)table
{
    /*
    NSMutableArray *params = letParametersOf(e);
    NSMutableArray *body = letBodyOf(e);
    NSMutableArray *tmp_table = [NSMutableArray arrayWithCapacity:0];
    
    
    if ([table isEqual:self.global_table]){
        tmp_table = [self.global_table mutableCopy];
    } else {
        tmp_table = [table mutableCopy];
    }
    
    //self.loop_table = [self.global_table mutableCopy];
    NSLog(@"%lu",[self.loop_table count]);
    NSLog(@"%@",loopDefineEntry(second(e)));
    [self allDefineForLoop:loopDefineEntry(second(e)) :tmp_table];
    
   // NSLog(@"%@",self.loop_table);
    
    id result;
    while (1){
        @autoreleasepool {
        NSMutableArray *args = [self loopArgumentsOf:params :self.loop_table];
        NSMutableArray *closure_recode = [self lambda:setLambdaEntry(params, body) :self.loop_table];
            result = [self applyClosure:car(cdr(closure_recode)) :args :self.loop_table];
        
        if (![result isKindOfClass:[NSString class]] && [result[0] isKindOfClass:[NSMapTable class]]) {
            tmp_table = result;
            continue;
        } else {
            break;
        }
        }
        
    }
    
    return result;
    */
    
    NSMutableArray *params = letParametersOf(e);
    NSMutableArray *body = letBodyOf(e);
    NSMutableArray *tmp_table = [NSMutableArray arrayWithCapacity:0];
    
    if ([table isEqual:self.global_table]){
        tmp_table = [self.global_table mutableCopy];
    } else {
        tmp_table = [table mutableCopy];
    }
    
    loop_flag = 1;
    [self allDefine:loopDefineEntry(second(e)) :tmp_table];
    
    id result;
    while (1){
        @autoreleasepool {
            NSMutableArray *args = [self loopArgumentsOf:params :tmp_table];
            NSMutableArray *closure_recode = [self lambda:setLambdaEntry(params, body) :tmp_table];
            result = [self applyClosure:car(cdr(closure_recode)) :args :tmp_table];
            
            if (![result isKindOfClass:[NSString class]] && [result[0] isKindOfClass:[NSMapTable class]]) {
                tmp_table = result;
                continue;
            } else {
                loop_flag = 0;
                break;
            }
        }
    }
    
    return result;
}

-(id) recur:(id)e :(NSMutableArray *)table
{
    /*id loop_keys = [self lookupInTable:@"loop_keys" :self.loop_table];
    
    NSMutableArray *tmp_table = [NSMutableArray arrayWithCapacity:0];
   
    if ([loop_keys isEqual:@"#f"]) { //recur only
        
        [IPS error:@"#f" :10];
   
    } else { //loop~recur
        
        NSMutableArray *tmp = [e mutableCopy];
        [tmp removeObjectAtIndex:0];
        
        [tmp forEachValues:^void(int pos) {
            NSMapTable *entry = [NSMapTable strongToStrongObjectsMapTable];
            [entry setObject:[self meaning:tmp[pos] :self.loop_table] forKey:loop_keys[pos]];
            [tmp_table push:entry];
        }];
    }
    [self.loop_table removeObjectsInRange:NSMakeRange(0,[loop_keys count])];
    [self.loop_table addObjectsFromArray:tmp_table];

    return tmp_table;
    */
    id loop_keys = [self lookupInTable:@"loop_keys" :table];
    
    NSMutableArray *tmp_table = [NSMutableArray arrayWithCapacity:0];
    
    if ([loop_keys isEqual:@"#f"]) { //recur only
        
        [IPS error:@"#f" :10];
        
    } else { //loop~recur
        
        NSMutableArray *tmp = [e mutableCopy];
        [tmp removeObjectAtIndex:0];
        
        [tmp forEachValues:^void(int pos) {
            NSMapTable *entry = [NSMapTable strongToStrongObjectsMapTable];
            [entry setObject:[self meaning:tmp[pos] :table] forKey:loop_keys[pos]];
            [tmp_table push:entry];
        }];
    }
    [table removeObjectsInRange:NSMakeRange(0,[loop_keys count])];
    [tmp_table addObjectsFromArray:table];
    
    return tmp_table;
}

-(id) application:(id)e :(NSMutableArray *)table
{
    return [self apply:[self meaning:car(e) :table] :[self evlis:cdr(e):table] :table];
}

-(id) define:(id)e :(NSMutableArray *)table
{
    NSMapTable *entry = [NSMapTable strongToStrongObjectsMapTable];
    id tmp_value = [e objectAtIndex:2];
    id tmp_name = [e objectAtIndex:1];

    //tmp_value = [self meaning:tmp_value :[self nullTable]];//nullで渡していい。
    tmp_value = [self meaning:tmp_value :table];
    [entry setObject:tmp_value forKey:tmp_name];
    [table insertObject:entry atIndex:0];//tableに書くように変えた。
    return tmp_name;
    
}

-(id) defineForLoop:(id)e :(NSMutableArray *)table
{
    NSMapTable *entry = [NSMapTable strongToStrongObjectsMapTable];
    id tmp_value = [e objectAtIndex:2];
    id tmp_name = [e objectAtIndex:1];
    
    //tmp_value = [self meaning:tmp_value :[self nullTable]];//nullで渡していい。
    tmp_value = [self meaning:tmp_value :table];
    [entry setObject:tmp_value forKey:tmp_name];
    [self.loop_table insertObject:entry atIndex:0];//tableに書くように変えた。
    //NSLog(@"%@",self.loop_table);
    return tmp_name;
    
}


-(id) apply:(id)fun :(id)vals :(id)table
{

    if ([car(fun) isEqual:@"primitive"]) {
        
        return [self applyPrimitive:car(cdr(fun)) :vals :table];
        
    } else if ([car(fun) isEqual:@"non-primitive"]) {
        
        return [self applyClosure:car(cdr(fun)) :vals :table];
        
    } else {
        
        [IPS error:@"#f":0];
        
    }
    return @"#f";
}

-(id) evlis:(id)args :(id)table
{
    NSMutableArray *result = [NSMutableArray initCell];
    [args forEachValues:^void(int pos){
        [result add:[self meaning:args[pos] :table]];
    }];
    return result;
}

-(id) applyPrimitive:(id)name :(id)vals :(id)table
{
    id subr = [[Subr alloc] initWithTable:table];
    return [subr applySubr:name :vals];
}

-(id) applyClosure:(id)closure :(id)vals :(id)table
{
    id result;
    
    if (loop_flag == 1) {
        return [self applyClosureForLoopAux:closure :vals :table :setMeaningEntrys(closure) :result];
    }
    
    return [self applyClosureAux:closure :vals :table :setMeaningEntrys(closure) :result];
}

-(id) applyClosureAux:(id)closure :(id)vals :(id)table :(id)meaning_entrys :(id)result
{
    if ([meaning_entrys[0] isEqual:[NSNull null]]) {
        return result;
    }
     //NSLog(@"%@",first(closure));
    self.local_table = extendTable(newEntry(second(closure), vals),self.global_table);//仮引数と実引数の拡張
    
    if ([first(closure) count] != 1) {
        
        NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *entry = [first(closure) mutableCopy];
        [self.local_table removeLastObject];
        [tmp addObjectsFromArray:self.local_table];
        [tmp addObjectsFromArray:entry];
        self.local_table = tmp;
    }
    /*
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *entry = [first(closure) mutableCopy];
    [entry removeLastObject];
    [tmp addObjectsFromArray:entry];
    [tmp addObjectsFromArray:self.local_table];
    self.local_table = tmp;
    */
    
    //NSLog(@"%@",closure);
    //NSLog(@"%@",self.local_table);
    result = [self meaning:meaning_entrys[0] :self.local_table];
    
    return [self applyClosureAux:closure :vals :self.local_table :cdr(meaning_entrys) :result];
}

//fixme
/*
-(id) applyClosureForLoop:(id)closure :(id)vals :(id)table
{
    id result;
    return [self applyClosureAux:closure :vals :table :setMeaningEntrys(closure) :result];
}*/

-(id) applyClosureForLoopAux:(id)closure :(id)vals :(id)table :(id)meaning_entrys :(id)result
{
    if ([meaning_entrys[0] isEqual:[NSNull null]]) {
        return result;
    }
    self.local_table = extendTable(newEntry(second(closure), vals),table);
    //NSLog(@"local-%@",self.local_table);
    result = [self meaning:meaning_entrys[0] :self.local_table];
    
    return [self applyClosureForLoopAux:closure :vals :self.local_table :cdr(meaning_entrys) :result];
}


-(id) evcon:(id)lines :(NSMutableArray *)table
{
    if ([questionOf(lines) isEqual:@"else"]) {
        return [self meaning:answerOf(lines) :table];
    } else {
        if ([[self meaning:questionOf(lines) :table] isEqual:@"#t"]) {
            return [self meaning:answerOf(lines) :table];
        } else {
            return [self evcon:cdr(lines) :table];
        }
    }
}

-(id) lookupInTable:(id)e :(NSMutableArray *)table
{
    int num = 0;
    while (![table[num] isEqual:[NSNull null]]) {
        if ([table[num] objectForKey:e] != NULL){
            return [table[num] objectForKey:e];
        }
        num++;
    }
    return @"#f";
}



-(int) expressionToAction:(id)e
{
    if(isAtom(e)) {
        return [self atomToAction:e];
    } else {
        return [self listToAction:e];
    }
    
}

-(int) atomToAction:(id)e
{
    if (isNumber(e)) {
        return CONST;
    } else if (isString(e)) {
        return CONST;
    } else if (isInternalChar(e)) {
        return CONST;
    } else if (isSubr(e)) {
        return CONST;
    } else {
        return IDENTIFIER;
    }
}

-(int) listToAction:(id)e
{
    if (isAtom(car(e))) {
        if ([car(e) isEqual:@"quote"]){
            return QUOTE;
        } else if ([car(e) isEqual:@"lambda"]) {
            return LAMBDA;
        } else if ([car(e) isEqual:@"cond"]){
            return COND;
        } else if ([car(e) isEqual:@"define"]){
            return DEFINE;
        } else if ([car(e) isEqual:@"let"]){
            return LET;
        } else if ([car(e) isEqual:@"letrec"]){
            return LETREC;
        } else if ([car(e) isEqual:@"and"]){
            return AND;
        } else if ([car(e) isEqual:@"or"]){
            return OR;
        } else if (isMacro(car(e))){
            return MACRO;
        } else if ([car(e) isEqual:@"loop"]){
            return LOOP;
        } else if ([car(e) isEqual:@"recur"]){
            return RECUR;
        } else {
            return APPLICATION;
        }
    } else {
        return APPLICATION;
    }
}

BOOL isAtom(id e)
{
    if ([e isKindOfClass:[NSString class]] == TRUE) {
        return TRUE;
    } else {
        return FALSE;
    }
}

BOOL isMacro(id e)
{
    NSArray *macro = [[NSArray alloc] initWithObjects:@"time",@"if",nil];
    return [macro containsObject:e];
}

BOOL isBasicSubr(id e)
{
    NSArray *basic_subr =[[NSArray alloc] initWithObjects:@"#t",@"#f",@"+",
                          @"-",@"*",@"/",@"=",@"car",@"cdr",@"null?",@"eq?",
                          @"cons",@"div",@"mod",@">",@"<",@"apply",@"number?", nil];
    return [basic_subr containsObject:e];
}

BOOL isAddSubr(id e)
{
    NSArray *add_subr =[[NSArray alloc] initWithObjects:@"length",@"append",
                        @"range",@"atom?",@"reverse",@"gcd",@"lcm",@"sort",
                        @"numerator",@"denominator",nil];
    return [add_subr containsObject:e];
}

BOOL isStringSubr(id e)
{
    NSArray *add_subr =[[NSArray alloc] initWithObjects:@"string?",@"make-string",
                        @"string-ref",@"substring",@"string-append",
                        @"string=?",@"string<?",@"string>?",@"string-length",@"print",nil];
    return [add_subr containsObject:e];
}

BOOL isCharSubr(id e)
{
    NSArray *add_subr =[[NSArray alloc] initWithObjects:@"char?",@"char=?",
                        @"char>?",@"char<?",@"char->integer",
                        @"integer->char",nil];
    return [add_subr containsObject:e];
}


int isSubr(id e)
{
    if (isBasicSubr(e)) {
        return 1;
    } else if (isAddSubr(e)) {
        return 2;
    } else if (isStringSubr(e)) {
        return 3;
    } else if (isCharSubr(e)) {
        return 4;
    }
    return FALSE;
}


BOOL isMatch(id e,NSString *expression)
{
    NSRange range = [e rangeOfString:expression options:NSRegularExpressionSearch];
    
    if (range.location != NSNotFound) {
        return TRUE;
    } else {
        return FALSE;
    }
}

BOOL isNumber(id e)
{
    return isMatch(e,@"^[-]?\\d+(\\.\\d+)?$|^[-]?\\d+(\\/\\d+)?$");
}

BOOL isString(id e)
{
    return isMatch(e,@"^\"(.|\n)*\"$");
}

BOOL isInternalChar(id e)
{
    return isMatch(e,@"#\\\\.$");
}

BOOL isPreChar(id e)
{
    return isMatch(e,@"^#¥.$");
}


id car(id e)
{
    return e[0];
}

id cdr(id e)
{
    NSMutableArray * tmp = [e mutableCopy];
    [tmp removeObjectAtIndex:0];
    return tmp;
}

id first(id e)
{
    return car(e);
}

id second(id e)
{
    return car(cdr(e));
}

id third(id e)
{
    return car(cdr(cdr(e)));
}
id fourth(id e)
{
    return car(cdr(cdr(cdr(e))));
}

id questionOf(id lines)
{
    return car(car(lines));
}

id answerOf(id lines)
{
    return car(cdr(car(lines)));
}
id Test(id e)
{
    return second(e);
}
id ifTrueCase(id e)
{
    return third(e);
}

id ifFalseCase(id e)
{
    return fourth(e);
}

id letNameOf(id e)
{
    return car(cdr(e));
}

id letBodyOf(id e)
{
    return cdr(cdr(e));
}
id letParametersOf(id e)
{
    id vals = car(cdr(e));
    NSMutableArray *result = [NSMutableArray initCell];
    
    [vals forEachValues:^void(int pos){
         [result add:car(vals[pos])];
    }];
    
    return result;
}

NSMutableArray * nullTable()
{
   return [NSMutableArray initCell];
}

BOOL dotCheck(id c_vals)
{
    int tmp_pos = 0;
    while ([c_vals[tmp_pos] isEqual:[NSNull null]] != TRUE) {
        if ([c_vals[tmp_pos] isEqualToString:@"."]) {
            return TRUE;
        }
        tmp_pos++;
    }
    return FALSE;
}

id dotEntry(id c_vals,int pos)
{
    NSMutableArray *arr = [NSMutableArray initCell];
    
    [c_vals forEachValues:^void(int pos) {
        [arr add:c_vals[pos]];
    }];
    return arr;
}

id newEntry(id c_vals,id vals)
{
    NSMutableArray *new_entry = [NSMutableArray arrayWithCapacity:0];
    NSMapTable *entry = [NSMapTable strongToStrongObjectsMapTable];
    int tmp_pos = 0;
    
    if ([c_vals isKindOfClass:[NSString class]] == TRUE) {
        [entry setObject:dotEntry(vals,tmp_pos) forKey:c_vals];
        [new_entry addObject:entry];
        return new_entry;
    }
    if (([c_vals count] != [vals count]) && (!dotCheck(c_vals))) {
        [IPS error:@"#f" :2];
    }
    
    while ([c_vals[tmp_pos] isEqual:[NSNull null]] != TRUE){
        if ([c_vals[tmp_pos] isEqualToString:@"."] == FALSE){
            [entry setObject:vals[tmp_pos] forKey:c_vals[tmp_pos]];
            tmp_pos++;
        } else {
            if ([c_vals[tmp_pos + 2] isEqual:[NSNull null]] == TRUE) {
                [entry setObject:dotEntry(vals, tmp_pos) forKey:c_vals[tmp_pos + 1]];
                break;
            } else {
                [IPS error:@"#f" :3];
            }
        }
    }
    
    [new_entry addObject:entry];
    return new_entry;
    
}

id setLambdaEntry(id params, id body)
{
    
    NSMutableArray *lambda_entry = [NSMutableArray initCell];
    
    [lambda_entry addAll:@"lambda",params,nil];
    [lambda_entry addFromCell:body];
    return lambda_entry;
}

id setDefineEntry(id name, id params, id body)
{
    return [[NSMutableArray initCell] addAllR:@"define",name,setLambdaEntry(params,body),nil];
}

id setMeaningEntrys(id closure)
{
    NSMutableArray *meaning_entrys = [NSMutableArray initCell];
    id lists = cdr(cdr(closure));
    
    [lists forEachValues:^void(int pos) {
        [meaning_entrys add:lists[pos]];
    }];
    
    return meaning_entrys;
}

id letrecMeaningEntry(id e)
{
    NSMutableArray *lambda_exp = [NSMutableArray initCell];
    [lambda_exp addAll:@"lambda",nullTable(),nil];
    [lambda_exp addFromCell:cdr(cdr(e))];
    
    return [[NSMutableArray initCell] addR:lambda_exp];
}

id letrecDefineEntry(id vals)
{
    NSMutableArray *result = [NSMutableArray initCell];
    NSMutableArray *tmp = [vals mutableCopy];
 
    [tmp forEachValues:^void(int pos) {
        [tmp[pos] insertObject:@"define" atIndex:0];
        [result add:tmp[pos]];
    }];
    
    return result;
}

id loopDefineEntry(id vals)
{
    NSMutableArray *result = [NSMutableArray initCell];
    NSMutableArray *tmp = [vals mutableCopy];
    NSMutableArray *loop_keys = [NSMutableArray initCell];
    NSMutableArray *key_list = [NSMutableArray initCell];
    
    [vals forEachValues:^void(int pos) {
        [key_list add:car(vals[pos])];
    }];
    
    [loop_keys addAll:@"define",@"loop_keys",
     [[NSMutableArray initCell] addAllR:@"quote",key_list,nil],nil];
    
    [result add:loop_keys];
    
    [tmp forEachValues:^void(int pos) {
        [tmp[pos] insertObject:@"define" atIndex:0];
        [result add:tmp[pos]];
    }];
    
    return result;
}


id extendTable(id entry,id table)
{
    NSMutableArray *new_table = [NSMutableArray arrayWithCapacity:0];
    [new_table addObjectsFromArray:entry];
    [new_table addObjectsFromArray:table];
    return new_table;
}


-(id) initWithEnv:(id)env
{
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:1];
    [tmp addObject:[NSNull null]];
    self.global_table = env;
    self.local_table = tmp;
    return self;
}


NSString * replace(NSString *str, NSString *before, NSString *after)
{
    return [str stringByReplacingOccurrencesOfString:before withString:after];
}

//-- scan --

-(NSArray *) scan:(NSString *)str
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:0];
    NSRegularExpression *regexp2 = [NSRegularExpression regularExpressionWithPattern:@"\".*?\"|[^\"]*|.*"
                                                                             options:0
                                                                               error:nil];
    while ([str isEqualToString:@""] != TRUE) {
        NSTextCheckingResult *match = [regexp2 firstMatchInString:str options:0 range:NSMakeRange(0, str.length)];
        NSString *match_string = [str substringWithRange:[match rangeAtIndex:0]];
        [result addObjectsFromArray:scanAux(match_string)];
        NSUInteger str_len = [match_string length];
        str = [str stringByReplacingOccurrencesOfString:match_string
                                             withString:@""
                                                options:0
                                                  range:NSMakeRange(0,str_len)
               ];
    }
    [result addObject:[NSNull null]];
    return result;
}

NSString * regExpReplace(NSString *str ,NSString *reg_exp ,NSString *template)
{
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:reg_exp
                                                                            options:0
                                                                              error:nil];
    
    NSString *replaced = [regexp stringByReplacingMatchesInString:str
                                                          options:0
                                                            range:NSMakeRange(0,str.length)
                                                     withTemplate:template];
    return replaced;
}

NSArray * scanAux(NSString * str)
{
    if (isString(str)) {
        return [[NSArray array] arrayByAddingObject:str];
    }
    
    NSString *result = replace(replace(replace(str, @"(", @"( "), @")", @" )"), @"'",@"' ");
    
    NSString *replaced = regExpReplace(result, @";+.*$|\n|\t" ,@" ");
    
    NSArray *tokens = [replaced componentsSeparatedByString:@" "];
    
    return tokens;
}

//-- parse --
int parsed_pos = 0;
NSMutableArray *parsed;

-(id) parse:(NSArray *) arr
{
    //初期化
    parsed = [NSMutableArray initCell];
    parsed_pos = 0;
    
    id result = [self parseAux:arr];
    return tidyParsed(result);
}

NSString * get(id toked)
{
    NSString *tmp = [toked objectAtIndex:parsed_pos];
    parsed_pos++;
    return tmp;
}

void unget()
{
    parsed_pos--;
}

-(id) parseAux:(NSArray *) arr
{
    NSString *s = get(arr);
    
    if ([s isEqualToString:@"'"] == TRUE) {
        return [[NSMutableArray initCell] addAllR:@"quote",[self parseAux2:arr],nil];
    }
    unget();
    return [self parseAux2:arr];
}

-(id) parseAux2:(NSArray *) arr
{
    NSString *s = get(arr);
    
    if ([s isEqualToString:@"("] == TRUE) {
        unget();
        [self readList:arr];
        return parsed;
        
    } else {
        unget();
        return [self readAtom:arr];
    }
    
}

-(void) readList:(NSArray *) arr
{
    NSString *s = get(arr);
    NSMutableArray *tmp = [NSMutableArray initCell];
    
    while ([s isEqualToString:@")"] != TRUE) {
        s = get(arr);
        if ([s isEqualToString:@"("] == TRUE) {
            unget();
            tmp = [self readListAux:arr];
            [parsed add:tmp];
        } else if ([s isEqualToString:@""] == TRUE) {
            continue;
        } else if ([s isEqualToString:@")"] == FALSE) {
            [parsed add:s];
        }
    }
}

-(NSMutableArray *) readListAux:(NSArray *) arr
{
    NSString *s = get(arr);
    NSMutableArray *tmp = [NSMutableArray initCell];
    
    while ([s isEqualToString:@")"] != TRUE) {
        s = get(arr);
        if ([s isEqualToString:@"("] == TRUE) {
            unget();
            [tmp add:[self readListAux:arr]];
        } else if ([s isEqualToString:@""] == TRUE) {
            continue;
        } else if ([s isEqualToString:@")"] == FALSE) {
            [tmp add:s];
        }
    }
    return tmp;
}

-(NSString *) readAtom:(NSArray *) arr
{
    NSString *s = get(arr);
    return s;
}

id tidyParsed(id parse_result)
{
    int tmp_pos = 0;
    NSMutableArray *arr = [NSMutableArray initCell];
    NSMutableArray *result = [NSMutableArray initCell];
    
    if ([parse_result isKindOfClass:[NSString class]] == TRUE){
        if (isPreChar(parse_result)){
            NSString *str = replace(parse_result, @"¥", @"\\");
            return str;
        }
        return parse_result;
    }
    
    while ([parse_result[tmp_pos] isEqual:[NSNull null]] != TRUE) {
        if ([parse_result[tmp_pos] isKindOfClass:[NSArray class]] == TRUE) {
            
            [result add:tidyParsed(parse_result[tmp_pos])];
            
        } else if ([parse_result[tmp_pos] isEqual:@"'"]){
            
            [arr addAll:@"quote",parse_result[++tmp_pos],nil];
            [result add:arr];
            arr = [NSMutableArray initCell];
            
        } else if (isPreChar(parse_result[tmp_pos])){
            
            NSString *str = replace(parse_result[tmp_pos], @"¥", @"\\");
            [result add:str];
            
        } else {
            [result add:parse_result[tmp_pos]];
        }
        tmp_pos++;
    }
    
    return result;
}


//-- print --
-(void) print:(id) arr
{
    printf("%s\n",[[self printAux:arr] UTF8String]);
    fflush(stdout);
}

-(id) printAux:(id)arr
{
    NSMutableString *ans = [NSMutableString stringWithCapacity:0];
    
    if ([arr isKindOfClass:[NSString class]] == TRUE) {
        return arr;
    } else if ([arr[0] isEqual:@"primitive"] == TRUE){
        return [[NSString alloc] initWithFormat:@"#<subr %@>",self.initial_value];
    } else if ([arr[0] isEqual:@"non-primitive"] == TRUE) {
        return [[NSString alloc] initWithFormat:@"#<closure %@>",self.initial_value];
    }
    
    [ans appendString:@"("];
    
    [arr forEachValues:^void(int pos) {
        if ([arr[pos] isKindOfClass:[NSArray class]] == TRUE) {
			[ans appendString:@"("];
			[ans appendFormat:@"%@ ",printAux2(arr[pos])];
			[ans appendString:@") "];
		} else {
			[ans appendFormat:@"%@ ",arr[pos]];
		}
    }];
    
	[ans appendString:@")"];
    
    return replace(replace(ans, @" )",@")"), @" )",@")");
}

NSMutableString * printAux2(id array)
{
    NSMutableString *ans = [NSMutableString stringWithCapacity:100];
    
    [array forEachValues:^void(int pos) {
        if ([array[pos] isKindOfClass:[NSArray class]] == TRUE) {
			[ans appendString:@"("];
			[ans appendFormat:@"%@ ",printAux2(array[pos])];
            [ans appendString:@") "];
        } else if([array[pos] isKindOfClass:[NSMapTable class]] == TRUE){
            [ans appendString:@" "];
        } else {
            [ans appendFormat:@"%@ ",array[pos]];
        }
    }];
    return ans;
}

+(void) identifierError:(id)e
{
    NSRange searchResult = [e rangeOfString:@"#"];
    if (searchResult.location != NSNotFound) {
        [IPS error:e :5];
    }
    [IPS error:e :1];
}

+(void) error:(id)e :(int)flag
{
    NSMutableString *error_msg = [NSMutableString stringWithCapacity:0];
    
    switch (flag) {
        case 1:
            [error_msg setString:@"unbound variable: "];
            [error_msg appendString:e];
            break;
        case 2:
            [error_msg setString:@"wrong number of arguments"];
            break;
        case 3:
            [error_msg setString:@"bad dot syntax"];
            break;
        case 4:
            [error_msg setString:@"improper list not allowed: "];
            [error_msg appendString:e];
            break;
        case 5:
            [error_msg setString:@"unsupported #-syntax: "];
            [error_msg appendString:e];
            break;
        case 6:
            [error_msg setString:@"extra close parenthesis"];
            break;
        case 7:
            [error_msg setString:e];
            [error_msg appendString:@"argument out of range"];
            break;
        case 8:
            [error_msg setString:@"couldn't open such file: "];
            [error_msg appendString:e];
            break;
        case 9:
            [error_msg setString:@"cannot find "];
            [error_msg appendString:e];
            break;
        case 10:
            [error_msg setString:@"loop not found (loop-recur contruction)"];
            break;
        default:
            [error_msg setString:@"unexpected exception"];
            break;
    }
    
    id err = [NSException
              exceptionWithName:@"eval"
              reason:error_msg
              userInfo:nil];
    @throw err;
}

@end