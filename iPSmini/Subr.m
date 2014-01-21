//
//  Subr.m
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/05.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import "Subr.h"
#import "Bignum.h"
#import "NSMutableArray+iPSAddition.h"

@implementation Subr

@synthesize s_env;

extern id car(id e);
extern id cdr(id e);
extern int isSubr(id e);
extern BOOL isString(id e);
extern BOOL isNumber(id e);
extern BOOL isInternalChar(id e);

-(id) applySubr:(id)name :(id)vals
{
    int flag;
    switch (flag = isSubr(name)) {
        case 1:
            return [self applyBasicSubr:name :vals :self.s_env];
        case 2:
            return [self applyAddSubr:name :vals :self.s_env];
        case 3:
            return [self applyStringSubr:name :vals :self.s_env];
        case 4:
            return [self applyCharSubr:name :vals :self.s_env];
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
        return [self subrCar:vals];
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
    } else if ([name isEqual:@"number?"]){
        return [self numberQ:vals];
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

-(id) applyCharSubr:(id)name :(id)vals :(id)table
{
    if ([name isEqual:@"char?"]) {
        return [self charQ:vals];
    } else if ([name isEqual:@"char=?"]) {
        return [self charEqual:vals];
    } else if ([name isEqual:@"char>?"]) {
        return [self charGreater:vals];
    } else if ([name isEqual:@"char<?"]) {
        return [self charLess:vals];
    } else if ([name isEqual:@"char->integer"]) {
        return [self charInteger:vals];
    } else if ([name isEqual:@"integer->char"]) {
        return [self integerChar:vals];
    }
    return FALSE;
}

-(id) applyStringSubr:(id)name :(id)vals :(id)table
{
    if ([name isEqual:@"string?"]) {
        return [self stringQ:vals];
    } else if ([name isEqual:@"make-string"]) {
        return [self makeString:vals];
    } else if ([name isEqual:@"string-length"]) {
        return [self stringLength:vals];
    } else if ([name isEqual:@"string-ref"]) {
        return [self stringRef:vals];
    } else if ([name isEqual:@"substring"]) {
        return [self subString:vals];
    } else if ([name isEqual:@"string-append"]) {
        return [self stringAppend:vals];
    } else if ([name isEqual:@"string=?"]) {
        return [self stringEqual:vals];
    } else if ([name isEqual:@"string>?"]) {
        return [self stringGreater:vals];
    } else if ([name isEqual:@"string<?"]) {
        return [self stringLess:vals];
    }  else if ([name isEqual:@"print"]) {
        return [self subrPrint:vals];
    }
    return FALSE;
}


-(id) subrCar:(id)e
{
    [Subr checkArguments:e :2 :@"!="];
    
    return car(car(e));
}

-(id) numberQ:(id)e
{
    [Subr checkArguments:e :2 :@"!="];
    
    if (isNumber(e[0])) {
        return @"#t";
    } else {
        return @"#f";
    }
    
}

-(id) subrPrint:(id)vals
{
    NSFileHandle *output = [self currentOutputPort:vals];
    NSMutableString *result = [NSMutableString stringWithCapacity:0];
    int tmp_pos = 0;
    while ([vals[tmp_pos] isEqual:[NSNull null]] != TRUE) {
        [result appendString:[self legiblePrint:vals[tmp_pos]]];
        tmp_pos++;
    }
    [result appendString:@"\n"];
    NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
    [output writeData:data];
    return @"#<undef>";
}

-(id) currentOutputPort:(id)vals
{
    return [NSFileHandle fileHandleWithStandardOutput];
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
    
    //NSLog(@"%@",e);
    
    if([e[0] isEqual:e[1]]){
        return @"#t";
    } else {
        return @"#f";
    }
}


-(id) subrDiv:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    
    NSMutableArray *list = allBignum(vals);
    Bignum *ans = [Bignum divBignum:list];
    NSString *result = [ans getString];
    
    [ans releaseBignum];
    
    return result;
}

-(id) subrMod:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    
    NSMutableArray *list = allBignum(vals);
    Bignum *ans = [Bignum modBignum:list];
    NSString *result = [ans getString];
    
    [ans releaseBignum];
    
    return result;
    
    
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

NSMutableArray *allBignum(NSMutableArray *vals)
{
    NSMutableArray *big_list = [NSMutableArray initCell];
    
    [vals forEachValues:^void(int pos) {
        [big_list add:[Bignum bigNumberWithString:vals[pos]]];
    }];
    return big_list;
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

Bignum *nume(NSString *exp)
{
    NSString *result = [exp stringByReplacingOccurrencesOfString:@"/" withString:@" / "];
    NSArray *result2 = [result componentsSeparatedByString:@" "];
    return [Bignum bigNumberWithString:result2[0]];
}

Bignum *deno(NSString *exp)
{
    NSString *result = [exp stringByReplacingOccurrencesOfString:@"/" withString:@" / "];
    NSArray *result2 = [result componentsSeparatedByString:@" "];
    if ([result2 count] == 1){
        return [Bignum bigNumberWithString:@"1"];
    }
    return [Bignum bigNumberWithString:result2[2]];
}

NSString *makeAns(NSMutableArray *ans)
{
    NSString *result;
    
    if ([ans[1] isEqualBignum:@"1"]){
        result = [[NSString alloc] initWithFormat:@"%@",[ans[0] getString]];
    } else {
        result = [[NSString alloc] initWithFormat:@"%@/%@",[ans[0] getString],[ans[1] getString]];
    }
    
    [ans[1] releaseBignum];
    [ans[0] releaseBignum];
    return result;
}

NSString * formatNum(NSString *format, NSDecimalNumber *ans)
{
    id formatter = [[NSNumberFormatter alloc] init];
    [formatter setPositiveFormat:format];
    return [formatter stringFromNumber:ans];
}


NSDecimalNumber *nume_d(NSString *exp)
{
    NSString *result = [exp stringByReplacingOccurrencesOfString:@"/" withString:@" / "];
    NSArray *result2 = [result componentsSeparatedByString:@" "];
    return [NSDecimalNumber decimalNumberWithString:result2[0]];
}

NSDecimalNumber *deno_d(NSString *exp)
{
    NSString *result = [exp stringByReplacingOccurrencesOfString:@"/" withString:@" / "];
    NSArray *result2 = [result componentsSeparatedByString:@" "];
    if ([result2 count] == 1){
        return [NSDecimalNumber decimalNumberWithString:@"1"];
    }
    return [NSDecimalNumber decimalNumberWithString:result2[2]];
}

id inexact(id vals)
{
    NSMutableArray *arr = [NSMutableArray initCell];
    
    [vals forEachValues:^void(int pos) {
        if (isTheString(vals[pos], @"/")) {
            id ans = [nume_d(vals[pos]) decimalNumberByDividingBy:deno_d(vals[pos])];
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

NSString * calcFix(NSString *operator,NSMutableArray *vals)
{
    id ans;
    
    if ([operator isEqualToString:@"+"]) {
        ans = [Bignum addBignumFromArray:vals];
    } else if ([operator isEqualToString:@"-"]) {
        ans = [Bignum subBignumFromArray:vals];
    } else if ([operator isEqualToString:@"*"]) {
        ans = [Bignum mulBignumFromArray:vals];
    } else if ([operator isEqualToString:@"/"]) {
        ans = [Bignum divBignumFromArray:vals];
    }
    
    if ([ans isKindOfClass:[NSMutableArray class]]){
        return makeAns(ans);
    } else {
        NSString *str = [ans getString];
        [ans releaseBignum];
        return str;
    }
}

NSString *calcFrac(NSString *operator,NSMutableArray *vals)
{
    id ans;
    
    if ([operator isEqualToString:@"+"]) {
        ans = [Bignum addFracBignumFromArray:vals];
    } else if ([operator isEqualToString:@"-"]) {
        ans = [Bignum subFracBignumFromArray:vals];
    } else if ([operator isEqualToString:@"*"]) {
        ans = [Bignum mulFracBignumFromArray:vals];
    } else if ([operator isEqualToString:@"/"]) {
        ans = [Bignum divFracBignumFromArray:vals];
    }
    return makeAns(ans);
}


NSString * calcExact(NSString *name,NSMutableArray *vals)
{
    if (isFracNum(vals)) {
        NSMutableArray *frac_list = allFrac(vals);
        return calcFrac(name,frac_list);
    } else {
        NSMutableArray *big_list = allBignum(vals);
        return calcFix(name,big_list);
    }
}

NSMutableArray *allDecimal(NSMutableArray *vals)
{
    NSMutableArray *decimal_list = [NSMutableArray initCell];
    
    [vals forEachValues:^void(int pos) {
        [decimal_list add:[NSDecimalNumber decimalNumberWithString:vals[pos]]];
    }];
    return decimal_list;
}

NSString * calcInexact(NSString *operator, NSMutableArray *vals,NSDecimalNumber *ans)
{
    if ([vals[0] isEqual:[NSNull null]]) {
        return formatNum(@"#.##########;0;-#.##########",ans);
    }
    
    if ([operator isEqual:@"+"]) {
        return calcInexact(operator,cdr(vals),[ans decimalNumberByAdding:car(vals)]);
    } else if ([operator isEqual:@"-"]) {
        return calcInexact(operator,cdr(vals),[ans decimalNumberBySubtracting:car(vals)]);
    } else if ([operator isEqual:@"*"]) {
        return calcInexact(operator,cdr(vals),[ans decimalNumberByMultiplyingBy:car(vals)]);
    } else if ([operator isEqual:@"/"]) {
        return calcInexact(operator,cdr(vals),[ans decimalNumberByDividingBy:car(vals)]);
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
    
    NSMutableArray *list = allBignum(vals);
    Bignum *ans = [Bignum gcdBignum:list];
    NSString *result = [ans getString];
    
    [ans releaseBignum];
    
    return result;
}

-(id) lcm:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    
    NSMutableArray *list = allBignum(vals);
    Bignum *ans = [Bignum lcmBignum:list];
    NSString *result = [ans getString];
    
    [ans releaseBignum];
    
    return result;
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
    
    return [[NSString alloc] initWithFormat:@"%@",nume_d(vals[0])];
}

-(id) denominator:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    
    return [[NSString alloc] initWithFormat:@"%@",deno_d(vals[0])];
}

-(id) charQ:(id)vals
{
    NSRange range;
    NSString *expression = @"^#\\\\.$";

    [Subr checkArguments:vals :2 :@"!="];
    
    range = [vals[0] rangeOfString:expression options:NSRegularExpressionSearch];
    
    if (range.location != NSNotFound) {
        return @"#t";
    } else {
        return @"#f";
    }
}

-(id)charEqual:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    
    const char *c1 = [vals[0] UTF8String];
    const char *c2 = [vals[1] UTF8String];
    
    if (c1[2] == c2[2]) {
        return @"#t";
    } else {
        return @"#f";
    }
    
}

-(id) charGreater:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    
    const char *c1 = [vals[0] UTF8String];
    const char *c2 = [vals[1] UTF8String];
    
    if (c1[2] > c2[2]) {
        return @"#t";
    } else {
        return @"#f";
    }
}

-(id) charLess:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    const char *c1 = [vals[0] UTF8String];
    const char *c2 = [vals[1] UTF8String];
    
    if (c1[2] < c2[2]) {
        return @"#t";
    } else {
        return @"#f";
    }
    
}

-(id) charInteger:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    
    const char *c1 = [vals[0] UTF8String];
    
    return [[NSString alloc] initWithFormat:@"%d",c1[2]];
}

-(id) integerChar:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    return [[NSString alloc] initWithFormat:@"#\\%c",[vals[0] intValue]];
}

-(id) stringQ:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    
    NSRange range;
    NSString *expression = @"^\".*\"$";
    
    range = [vals[0] rangeOfString:expression options:NSRegularExpressionSearch];
    
    if (range.location != NSNotFound) {
        return @"#t";
    } else {
        return @"#f";
    }
}

-(id) makeString:(id)vals
{
    NSUInteger vals_count = [vals count];
    char elem;
    if (!((vals_count != 2) || (vals_count != 3))) {
        [IPS error:@"#f" :2];
    }
    
    int count = [vals[0] intValue];
    if (vals_count == 2) {
        elem = ' ';
    } else {
        elem = [vals[1] UTF8String][2];
    }
    NSMutableString *result = [NSMutableString stringWithCapacity:0];
    [result appendString:@"\""];
    while (count != 0) {
        [result appendFormat:@"%c",elem];
        count--;
    }
    [result appendString:@"\""];
    return result;
}

-(id) stringLength:(id)vals
{
    [Subr checkArguments:vals :2 :@"!="];
    
    return [[NSString alloc] initWithFormat:@"%ld",([vals[0] length] -2)];
}

-(id) stringRef:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    
    int loc = [vals[1] intValue];
    NSUInteger len = ([vals[0] length] -2);
    
    if (loc > len) {
        [IPS error:@"" :7];
    }
    
    NSString *tidied = [vals[0] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSString *ref = [tidied substringWithRange:NSMakeRange(loc,1)];
    NSString *result = [[NSString alloc] initWithFormat:@"#\\%@",ref];
    return result;
}

-(id) stringAppend:(id)vals
{
    int tmp_pos = 0;
    NSMutableString *append = [NSMutableString stringWithCapacity:0];
    while (tmp_pos < ([vals count] -1)) {
        [append appendString:vals[tmp_pos]];
        tmp_pos++;
    }
    NSString *tidied = [append stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSString *result = [[NSString alloc] initWithFormat:@"\"%@\"",tidied];
    return result;
}

-(id) subString:(id)vals
{
    [Subr checkArguments:vals :4 :@"!="];
    
    NSUInteger length = ([vals[0] length] -2);
    int start = [vals[1] intValue];
    int end = [vals[2] intValue];
    
    if (start > length) {
        [IPS error:@"start " :7];
    } else if (end > length) {
        [IPS error:@"end " :7];
    } else if (start > end) {
        [IPS error:@"#f" :11];//fix me
    } else {
        NSString *tidied = [vals[0] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        NSString *str = [tidied substringWithRange:NSMakeRange([vals[1] intValue], ([vals[2] intValue] - [vals[1] intValue]))];
        return [[NSString alloc] initWithFormat:@"\"%@\"",str];
    }
    return @"#f";
}

-(id) stringEqual:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    
    if ([vals[0] compare:vals[1]] == NSOrderedSame) {
        return @"#t";
    } else {
        return @"#f";
    }
}

-(id) stringGreater:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    if ([vals[0] compare:vals[1]] == NSOrderedDescending) {
        return @"#t";
    } else {
        return @"#f";
    }
}

-(id) stringLess:(id)vals
{
    [Subr checkArguments:vals :3 :@"!="];
    
    if ([vals[0] compare:vals[1]] == NSOrderedAscending) {
        return @"#t";
    } else {
        return @"#f";
    }
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

-(NSString *) legiblePrint:(NSArray *)arr
{
    return [self legiblePrintAux:arr];
}

-(id) legiblePrintAux:(id)arr
{
    NSMutableString *ans = [NSMutableString stringWithCapacity:0];
	int tmp_pos = 0;
    if ([arr isKindOfClass:[NSString class]] == TRUE) {
        return [self legiblePrintCore:arr];
    } else if ([arr[0] isEqual:@"primitive"] == TRUE){
        return [[NSString alloc] initWithFormat:@"#<subr %@>",super.initial_value];
    } else if ([arr[0] isEqual:@"non-primitive"] == TRUE) {
        return [[NSString alloc] initWithFormat:@"#<closure %@>",super.initial_value];
    }
    
    [ans appendString:@"("];
    
	while (![arr[tmp_pos] isEqual:[NSNull null]]) {
		if ([arr[tmp_pos] isKindOfClass:[NSArray class]] == TRUE) {
			[ans appendString:@"("];
			[ans appendFormat:@"%@ ",[self legiblePrintAux2:arr[tmp_pos]]];
			[ans appendString:@") "];
		} else {
            [ans appendFormat:@"%@ ",[self legiblePrintCore:arr[tmp_pos]]];
		}
        tmp_pos++;
	}
    
	[ans appendString:@")"];
    return [[ans stringByReplacingOccurrencesOfString:@" )" withString:@")"] stringByReplacingOccurrencesOfString:@" )" withString:@")"];
}

-(NSMutableString *) legiblePrintAux2:(NSArray *)array
{
    
	int tmp_pos = 0;
    NSMutableString *ans = [NSMutableString stringWithCapacity:100];
    
	while (![array[tmp_pos] isEqual:[NSNull null]]) {
		if ([array[tmp_pos] isKindOfClass:[NSArray class]] == TRUE) {
			[ans appendString:@"("];
			[ans appendFormat:@"%@ ",[self legiblePrintAux2:array[tmp_pos]]];
            [ans appendString:@") "];
        } else if([array[tmp_pos] isKindOfClass:[NSMapTable class]] == TRUE){
            [ans appendString:@" "];
        } else {
            [ans appendFormat:@"%@ ",[self legiblePrintCore:array[tmp_pos]]];
        }
        tmp_pos++;
    }
    return ans;
}

-(NSString *) legiblePrintCore:(NSString *)str
{
    if (isString(str)) {
        return [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    } else if (isInternalChar(str)) {
        return [[str stringByReplacingOccurrencesOfString:@"#" withString:@""] stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    }
    return str;
}
@end
