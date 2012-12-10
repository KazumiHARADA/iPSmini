//
//  Subr.m
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/05.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import "Subr.h"
#import "NSMutableArray+iPSAddition.h"

@implementation Subr

@synthesize s_env;

extern id car(id e);
extern id cdr(id e);
extern int isSubr(id e);
extern BOOL isString(id e);
extern BOOL isNumber(id e);

-(id) applySubr:(id)name :(id)vals
{
    int flag;
    switch (flag = isSubr(name)) {
        case 1:
            return [self applyBasicSubr:name :vals :self.s_env];
        case 2:
            return [self applyAddSubr:name :vals :self.s_env];
        default:
            [IPS error:name :1];
    }
    return @"#f";
}

-(id) applyBasicSubr:(id)name :(id)vals :(id) table
{
    if ([name isEqual:@"+"]) {
        return [self calc:name :vals];
    } else if ([name isEqual:@"-"]) {
        return [self calc:name :vals];
    } else if ([name isEqual:@"*"]) {
        return [self calc:name :vals];
    } else if ([name isEqual:@"/"]) {
        return [self calc:name :vals];
    } else if ([name isEqual:@"="]) {
        return [self numEq:vals];
    } else if ([name isEqual:@"car"]) {
        return car(car(vals));
    } else if ([name isEqual:@"cdr"]) {
        return cdr(car(vals));
    } else if ([name isEqual:@"null?"]) {
        return [self null:car(vals)];
    } else if ([name isEqual:@"eq?"]) {
        return [self eq:vals];
    } else if ([name isEqual:@"cons"]) {
        return [self cons:vals];
    } else if ([name isEqual:@"div"]) {
        return [self subrDiv:vals];
    } else if ([name isEqual:@"mod"]) {
        return [self subrMod:vals];
    }else if ([name isEqual:@">"]) {
        return [self greater:vals];
    } else if ([name isEqual:@"<"]) {
        return [self less:vals];
    } else if ([name isEqual:@"apply"]){
        return [self subrApply:vals :table];
    }
    return FALSE;
}

-(id) applyAddSubr:(id)name :(id)vals :(id)table
{
    if ([name isEqual:@"length"]) {
        return [self subrLength:vals];
    } else if ([name isEqual:@"range"]) {
        return [self range:vals];
    } else if ([name isEqual:@"append"]) {
        return [self append:vals];
    } else if ([name isEqual:@"atom?"]) {
        return [self atomQ:vals];
    } else if ([name isEqual:@"reverse"]) {
        return [self reverse:vals];
    } else if ([name isEqual:@"gcd"]) {
        return [self gcd:vals];
    } else if ([name isEqual:@"lcm"]) {
        return [self lcm:vals];
    } else if ([name isEqual:@"sort"]){
        return [self sort:vals];
    } else if ([name isEqual:@"numerator"]){
        return [self numerator:vals];
    } else if ([name isEqual:@"denominator"]){
        return [self denominator:vals];
    }
    return FALSE;
}

-(id) null:(id)e
{
    if ([e isKindOfClass:[NSString class]] == TRUE) {
        return @"#f";
    }
    
    if ([car(e) isEqual:[NSNull null]]) {
        return @"#t";
    } else {
        return @"#f";
    }
}

-(id) cons:(id)e
{
    NSMutableArray *tmp = [e[1] mutableCopy];
    [tmp insertObject:e[0] atIndex:0];
    return tmp;
}

-(id) numEq:(id)e
{
    NSDecimalNumber *num1 = [[NSDecimalNumber alloc] initWithString:e[0]];
    NSDecimalNumber *num2 = [[NSDecimalNumber alloc] initWithString:e[1]];
    
    if ([num1 compare:num2] == NSOrderedSame) {
        return @"#t";
    } else {
        return @"#f";
    }
}

-(id) eq:(id)e
{
    [Subr checkArguments:e :3 :@"!="];
    
    if(e[0] == e[1]){
        return @"#t";
    } else {
        return @"#f";
    }
}


-(id) subrDiv:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];

    NSMutableArray *d_list = allDecimal(vals);
    
    
    
    return formatNum(@"#;0;-#",subrDivAux(d_list[0],d_list[1]));
    
}

NSDecimalNumber *subrDivAux(NSDecimalNumber *num1, NSDecimalNumber *num2)
{
    NSDecimalNumberHandler* roundingBehavior =    [NSDecimalNumberHandler
                                                   decimalNumberHandlerWithRoundingMode:NSRoundDown
                                                   scale:0
                                                   raiseOnExactness:NO
                                                   raiseOnOverflow:NO
                                                   raiseOnUnderflow:NO
                                                   raiseOnDivideByZero:NO];
    
    return [num1 decimalNumberByDividingBy:num2 withBehavior:roundingBehavior];
}

-(id) subrMod:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];

    id div = [NSDecimalNumber decimalNumberWithString:[self subrDiv:vals]];
    NSMutableArray *d_list = allDecimal(vals);
    
    id ans = subNum(d_list[0],mulNum(div, d_list[1]));
    return formatNum(@"#;0;-#",ans);
}
-(id) greater:(id)vals
{
    
    if ([vals[1] isEqual:[NSNull null]]) {
        return @"#t";
    }
    
    if ([vals[0] intValue] > [vals[1] intValue]) {
        return [self greater:cdr(vals)];
    } else {
        return @"#f";
    }
}

-(id) less:(id)vals
{
    
    if ([vals[1] isEqual:[NSNull null]]) {
        return @"#t";
    }
    
    if ([vals[0] intValue] < [vals[1] intValue]) {
        return [self less:cdr(vals)];
    } else {
        return @"#f";
    }
}

-(id) subrApply:(id)vals :(id)table
{
    
    id last_object = [vals objectAtIndex:([vals count] - 2)];
    id fun = [vals objectAtIndex:0];
    NSMutableArray *new_vals = [NSMutableArray arrayWithCapacity:0];
    
    if ([last_object isKindOfClass:[NSMutableArray class]] == FALSE) {
        [IPS error:last_object :4];
    }
    
    int tmp_pos = 1;
    while (tmp_pos != ([vals count] -2)) {
        [new_vals addObject:vals[tmp_pos]];
        tmp_pos++;
    }
    [new_vals addObjectsFromArray:vals[tmp_pos]];
    
    return [super apply:fun :new_vals :table];
}


NSDecimalNumber * addNum(NSDecimalNumber *ans,NSDecimalNumber *num)
{

    return [ans decimalNumberByAdding:num];
}

NSDecimalNumber * subNum(NSDecimalNumber *ans,NSDecimalNumber *num)
{
    return [ans decimalNumberBySubtracting:num];
}

NSDecimalNumber * mulNum(NSDecimalNumber *ans,NSDecimalNumber *num)
{
    return [ans decimalNumberByMultiplyingBy:num];
}

NSDecimalNumber * divNum(NSDecimalNumber *ans,NSDecimalNumber *num)
{
    return [ans decimalNumberByDividingBy:num];
}

NSString * formatNum(NSString *format, NSDecimalNumber *ans)
{
    id formatter = [[NSNumberFormatter alloc] init];
    [formatter setPositiveFormat:format];
    return [formatter stringFromNumber:ans];
}

NSMutableArray *allDecimal(NSMutableArray *vals)
{
    NSMutableArray *decimal_list = [NSMutableArray initCell];
    
    [vals forEachValues:^void(int pos) {
        [decimal_list add:[NSDecimalNumber decimalNumberWithString:vals[pos]]];
    }];
    return decimal_list;
}

BOOL isTheString(NSString *str, NSString *search)
{
    NSRange searchResult = [str rangeOfString:search];
    if (searchResult.location != NSNotFound) {
        return TRUE;
    } else {
        return FALSE;
    }
}

BOOL isFracNum(id vals)
{
    
    int tmp_pos = 0;
    while ([vals[tmp_pos] isEqual:[NSNull null]] != TRUE) {
        if (isTheString(vals[tmp_pos],@"/")){
            return TRUE;
        }
        tmp_pos++;
    }
    return FALSE;
}

BOOL isInexact(id vals)
{
    int tmp_pos = 0;
    while ([vals[tmp_pos] isEqual:[NSNull null]] != TRUE) {
        if (isTheString(vals[tmp_pos], @".")) {
            return TRUE;
        }
        tmp_pos++;
    }
    return FALSE;
}

NSDecimalNumber *nume(NSString *exp)
{
    NSString *result = [exp stringByReplacingOccurrencesOfString:@"/" withString:@" / "];
    NSArray *result2 = [result componentsSeparatedByString:@" "];
    return [NSDecimalNumber decimalNumberWithString:result2[0]];
}

NSDecimalNumber *deno(NSString *exp)
{
    NSString *result = [exp stringByReplacingOccurrencesOfString:@"/" withString:@" / "];
    NSArray *result2 = [result componentsSeparatedByString:@" "];
    if ([result2 count] == 1){
        return [NSDecimalNumber decimalNumberWithString:@"1"];
    }
    return [NSDecimalNumber decimalNumberWithString:result2[2]];
}

NSDecimalNumber *gcdAux(NSDecimalNumber *num1 ,NSDecimalNumber *num2)
{
    if ([formatNum(@"#;0;-#", num2) intValue] == 0){
        return num1;
    }
    return gcdAux(num2, subNum(num1,mulNum(subrDivAux(num1, num2),num2)));
}

NSDecimalNumber *lcmAux(NSDecimalNumber *num1 ,NSDecimalNumber *num2)
{
    NSString *str = [[NSString alloc] initWithFormat:@"%d",abs([formatNum(@"#;0;-#",mulNum(num1, num2)) intValue])];
    NSDecimalNumber *num3 = [NSDecimalNumber decimalNumberWithString:str];
    
    return subrDivAux(num3,gcdAux(num1, num2));
}

NSMutableArray* reducation(NSDecimalNumber *num1,NSDecimalNumber *num2)
{
    NSDecimalNumber *gcd = gcdAux(num1,num2);
    NSDecimalNumber *new_ans1 = divNum(num1, gcd);
    NSDecimalNumber *new_ans2 = divNum(num2, gcd);
    NSMutableArray *arr_ans = [NSMutableArray initCell];
    
    return [arr_ans addAllR:new_ans1,new_ans2,nil];
}

NSMutableArray* dividing(NSString *operator,NSMutableArray *vals,id ans)
{
    if ([ans isKindOfClass:[NSDecimalNumber class]]){
        return reducation(ans,vals[0]);
    } else {
        NSDecimalNumber *nume = mulNum(ans[0],[NSDecimalNumber decimalNumberWithString:@"1"]);
        NSDecimalNumber *deno = mulNum(ans[1],vals[0]);
        return reducation(nume, deno);
    }
}

NSString *makeAns(NSMutableArray *ans)
{
    if ([ans[1] isEqual:[NSDecimalNumber decimalNumberWithString:@"1"]]){
        return [[NSString alloc] initWithFormat:@"%@",ans[0]];
    } else {
        return [[NSString alloc] initWithFormat:@"%@/%@",ans[0],ans[1]];
    }
}

id inexact(id vals)
{
    NSMutableArray *arr = [NSMutableArray initCell];
    
    [vals forEachValues:^void(int pos) {
        if (isTheString(vals[pos], @"/")) {
            id ans = divNum(nume(vals[pos]),deno(vals[pos]));
            NSString *ans_str = formatNum(@"#.##############################;0;-#.##############################", ans);
            [arr add:ans_str];
        } else {
            [arr add:vals[pos]];
        }
    }];
    return arr;
}

NSMutableArray *changeFracType(NSString *val)
{
    NSMutableArray *ans = [NSMutableArray initCell];
    return [ans addAllR:nume(val),deno(val),nil];
}

NSMutableArray *allFrac(NSMutableArray *vals)
{
    NSMutableArray *frac_list = [NSMutableArray initCell];
    
    [vals forEachValues:^void(int pos) {
        [frac_list add:changeFracType(vals[pos])];
    }];
    return frac_list;
}

-(id) calc:(id)name :(id)vals
{
    if (isInexact(vals)){
        id new_vals = inexact(vals);
        NSMutableArray *decimal_list = allDecimal(new_vals);
        return calcInexact(name, cdr(decimal_list), car(decimal_list));
    } else {
        return calcExact(name, vals);
    }
}

NSString * calcFix(NSString *operator,NSMutableArray *vals,id ans)
{
    if ([vals[0] isEqual:[NSNull null]]) {
        if ([ans isKindOfClass:[NSMutableArray class]]){
            return makeAns(ans);
        } else {
            return formatNum(@"#;0;-#", ans);
        }
    }
    
    if ([operator isEqualToString:@"+"]) {
        return calcFix(operator, cdr(vals), addNum(ans, car(vals)));
    } else if ([operator isEqualToString:@"-"]) {
        return calcFix(operator, cdr(vals), subNum(ans, car(vals)));
    } else if ([operator isEqualToString:@"*"]) {
        return calcFix(operator, cdr(vals), mulNum(ans, car(vals)));
    } else if ([operator isEqualToString:@"/"]) {
        return calcFix(operator, cdr(vals), dividing(operator, vals, ans));
    }
    return @"#f";
}

NSMutableArray *calcFracAux1(NSString *operator,NSDecimalNumber *nume1,NSDecimalNumber *deno1,NSDecimalNumber *nume2,NSDecimalNumber *deno2,NSDecimalNumber *lcm_num)
{
    NSDecimalNumber *new_nume1 = mulNum(nume1,subrDivAux(lcm_num,deno1));
    NSDecimalNumber *new_nume2 = mulNum(nume2,subrDivAux(lcm_num,deno2));
    
    if ([operator isEqualToString:@"+"]) {
        return reducation(addNum(new_nume1,new_nume2),lcm_num);
    } else {
        return reducation(subNum(new_nume1,new_nume2),lcm_num);
    }
}
NSMutableArray *calcFracAux2(NSString *operator,NSDecimalNumber *nume1,NSDecimalNumber *deno1,NSDecimalNumber *nume2,NSDecimalNumber *deno2)
{
    if ([operator isEqualToString:@"*"]) {
        return reducation(mulNum(nume1,nume2),mulNum(deno1,deno2));
    } else {
        return reducation(mulNum(nume1,deno2),mulNum(deno1,nume2));
    }
}

NSString *calcFrac(NSString *operator,id vals,NSMutableArray *ans)
{
    if ([vals[0] isEqual:[NSNull null]]) {
        return makeAns(ans);
    }
    if ([operator isEqual:@"+"]||[operator isEqual:@"-"]){
        NSMutableArray *result = calcFracAux1(operator,ans[0],ans[1],vals[0][0],vals[0][1],lcmAux(ans[1],vals[0][1]));
        return calcFrac(operator,cdr(vals),result);
    } else if ([operator isEqual:@"*"]||[operator isEqual:@"/"]) {
        NSMutableArray *result = calcFracAux2(operator,ans[0],ans[1],vals[0][0],vals[0][1]);
        return calcFrac(operator,cdr(vals),result);
    }
    return @"#f";
}


NSString * calcExact(NSString *name,NSMutableArray *vals)
{
    if (isFracNum(vals)) {
        NSMutableArray *frac_list = allFrac(vals);
        return calcFrac(name,cdr(frac_list),car(frac_list));
    } else {
        NSMutableArray *decimal_list = allDecimal(vals);
        return calcFix(name,cdr(decimal_list),car(decimal_list));
    }
}

NSString * calcInexact(NSString *operator, NSMutableArray *vals,NSDecimalNumber *ans)
{
    if ([vals[0] isEqual:[NSNull null]]) {
        return formatNum(@"#.##########;0;-#.##########",ans);
    }
    
    if ([operator isEqual:@"+"]) {
        return calcInexact(operator,cdr(vals),addNum(ans, car(vals)));
    } else if ([operator isEqual:@"-"]) {
        return calcInexact(operator,cdr(vals),subNum(ans, car(vals)));
    } else if ([operator isEqual:@"*"]) {
        return calcInexact(operator,cdr(vals),mulNum(ans, car(vals)));
    } else if ([operator isEqual:@"/"]) {
        return calcInexact(operator,cdr(vals),divNum(ans, car(vals)));
    }
    return @"#f";
}

-(id) subrLength:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    
    return [[NSString alloc] initWithFormat:@"%ld",([vals[0] count] -1)];
}

-(id) range:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    
    NSMutableArray *result = [NSMutableArray initCell];
    int num = [vals[0] intValue];

    for (int i=0;i<num;i++) {
        [result add:[[NSString alloc] initWithFormat:@"%d",i]];
    }
    return result;
}

-(id) atomQ:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    
    if ([vals[0] isKindOfClass:[NSString class]]) {
        return @"#t";
    } else {
        return @"#f";
    }
}

-(id) append:(id)vals
{
    [Subr checkArguments:vals :1 :@"<"];
    NSMutableArray *result = [NSMutableArray initCell];
    
    [vals forEachValues:^void(int pos){
        [result addFromCell:vals[pos]];
    }];
    return result;
}

-(id) reverse:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    
    NSMutableArray *result = [NSMutableArray initCell];
    [vals[0] forEachValues:^void(int pos){
        [result insertObject:vals[0][pos] atIndex:0];
    }];
    return result;
}

-(id) gcd:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    
    NSMutableArray *d_list = allDecimal(vals);
    return formatNum(@"#;0;-#", gcdAux(d_list[0], d_list[1]));
    
}

-(id) lcm:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    
    NSMutableArray *d_list = allDecimal(vals);
    return formatNum(@"#;0;-#", lcmAux(d_list[0], d_list[1]));

}

-(id) sort:(id)vals
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:0];
    [vals[0] removeLastObject];
    [result addObjectsFromArray:[vals[0] sortedArrayUsingFunction:compareFloat context:nil]];
    [result addObject:[NSNull null]];
    return result;
}

NSComparisonResult compareFloat(id value1, id value2, void *context)
{
    float floatValue1 = [(NSNumber*)value1 floatValue];
    float floatValue2 = [(NSNumber*)value2 floatValue];
    
    if(floatValue1 > floatValue2){
        return NSOrderedDescending;
    } else if (floatValue1 < floatValue2){
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}

-(id) numerator:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    
    return [[NSString alloc] initWithFormat:@"%@",nume(vals[0])];
}

-(id) denominator:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    
    return [[NSString alloc] initWithFormat:@"%@",deno(vals[0])];
}

-(id) initWithTable:(id)table
{
    self = [super init];
    if (self != nil) {
        s_env = table;
    }
    return self;
}

+(void) checkArguments:(id)vals :(int)num :(NSString *)operator
{
    if ([operator isEqualToString:@"!="]){
        if ([vals count] != num) {
            [IPS error:@"#f":2];
        }
    } else if ([operator isEqualToString:@">"]) {
        if ([vals count] > num) {
            [IPS error:@"#f":2];
        }
    } else if ([operator isEqualToString:@"<"]) {
        if ([vals count] < num) {
            [IPS error:@"#f":2];
        }
    }
}

@end
