//
//  Bignum.m
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/13.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import "Bignum.h"
#import "gmp.h"
#import "NSMutableArray+iPSAddition.h"

#define BASE 10

@implementation Bignum

-(id) initWithString:(NSString *)str//こいつが最後の原因
{
    self = [super init];
    if (self != nil) {
        mpz_init(self->number);
        const char *cp = [str UTF8String];
        mpz_set_str(self->number,cp,BASE);
    }
    return self;
}

+(Bignum *) bigNumberWithString:(NSString *)str
{
    Bignum *num = [[Bignum alloc] initWithString:str];
    
    return num;
}

-(void) printBignum
{
    NSLog(@"%@",[self getString]);
}

-(Bignum *) addBignum:(Bignum *)num
{
    Bignum *ans = [[Bignum alloc] init];
    mpz_add(ans->number,self->number,num->number);
    mpz_clear(self->number);
    
    return ans;
}

-(Bignum *) subBignum:(Bignum *)num
{
    Bignum *result = [[Bignum alloc] initWithString:@"0"];
    mpz_init(result->number);
    mpz_sub(result->number,self->number,num->number);
    mpz_clear(self->number);
    return result;
}

-(Bignum *) mulBignum:(Bignum *)num
{
    Bignum *result = [[Bignum alloc] initWithString:@"0"];
    mpz_init(result->number);
    mpz_mul(result->number,self->number,num->number);
    mpz_clear(self->number);
    return result;
}

+(Bignum *) divBignum:(NSMutableArray *)vals
{
    Bignum *ans = [[Bignum alloc] initWithString:@"0"];
    Bignum *num1 = vals[0];
    Bignum *num2 = vals[1];
    
    mpz_div(ans->number,num1->number,num2->number);
    
    [num1 releaseBignum];
    [num2 releaseBignum];
    return ans;
    
}

+(Bignum *) modBignum:(NSMutableArray *)vals
{
    Bignum *ans = [[Bignum alloc] initWithString:@"0"];
    Bignum *num1 = vals[0];
    Bignum *num2 = vals[1];
    
    mpz_mod(ans->number,num1->number,num2->number);
    
    [num1 releaseBignum];
    [num2 releaseBignum];
    return ans;
}


+(Bignum *) gcdBignum:(NSMutableArray *)vals
{
    Bignum *ans = [[Bignum alloc] initWithString:@"0"];
    Bignum *num1 = vals[0];
    Bignum *num2 = vals[1];
    
    mpz_gcd(ans->number,num1->number,num2->number);
    
    [num1 releaseBignum];
    [num2 releaseBignum];
    return ans;
}

+(Bignum *) lcmBignum:(NSMutableArray *)vals
{
    Bignum *ans = [[Bignum alloc] initWithString:@"0"];
    Bignum *num1 = vals[0];
    Bignum *num2 = vals[1];
    
    mpz_lcm(ans->number,num1->number,num2->number);
    
    [num1 releaseBignum];
    [num2 releaseBignum];
    return ans;
}

-(id) testBignum:(Bignum *)num
{
    mpz_t result;
    mpz_init(result);
    
    Bignum *tes = [[Bignum alloc] initWithString:@"43592"];
    
    mpz_set_str(tes->number,[@"12345" UTF8String],BASE);
    
    mpz_add(result,self->number,num->number);
    
    mpz_clear(result);
    
    return tes;
}

+(Bignum *) addBignumFromArray:(NSMutableArray *)vals
{
    NSUInteger len = [vals count] - 1;
    
    int i;
    
    Bignum *ans = [[Bignum alloc] initWithString:@"0"];
    
    for (i=0;i<len;i++) {
        Bignum *tmp = vals[i];
        mpz_add(ans->number,ans->number,tmp->number);
        [tmp releaseBignum];
    }
    return ans;
}

+(Bignum *) mulBignumFromArray:(NSMutableArray *)vals
{
    NSUInteger len = [vals count] - 1;
    
    int i;
    
    Bignum *ans = [[Bignum alloc] initWithString:@"1"];
    
    for (i=0;i<len;i++) {
        Bignum *tmp = vals[i];
        mpz_mul(ans->number,ans->number,tmp->number);
        [tmp releaseBignum];
    }
    return ans;
}

+(Bignum *) subBignumFromArray:(NSMutableArray *)vals
{
    int i;
    Bignum *tmp = vals[0];
    
    Bignum *ans = [[Bignum alloc] initWithString:@"0"];
    mpz_add(ans->number,ans->number,tmp->number);
    
    [tmp releaseBignum];
    [vals removeObjectAtIndex:0];
    
    NSUInteger len = [vals count] - 1;
    
    for (i=0;i<len;i++) {
        Bignum *tmp = vals[i];
        mpz_sub(ans->number,ans->number,tmp->number);
        [tmp releaseBignum];
    }
    return ans;
}

+(NSMutableArray *) divBignumFromArray:(NSMutableArray *)vals
{
    int i;
    Bignum *tmp = vals[0];
    
    Bignum *nume = [[Bignum alloc] initWithString:@"0"];
    mpz_add(nume->number,nume->number,tmp->number);
    
    [tmp releaseBignum];
    [vals removeObjectAtIndex:0];
    
    Bignum *deno = [[Bignum alloc] initWithString:@"1"];
    
    NSUInteger len = [vals count] - 1;
    
    for (i=0;i<len;i++) {
        Bignum *tmp = vals[i];
        mpz_mul(deno->number,deno->number,tmp->number);
        [tmp releaseBignum];
    }
    
    Bignum *gcd = [[Bignum alloc] initWithString:@"0"];
    mpz_gcd(gcd->number,nume->number,deno->number);
    
    mpz_div(nume->number,nume->number,gcd->number);
    mpz_div(deno->number,deno->number,gcd->number);
    
    [gcd releaseBignum];
    
    NSMutableArray *result = [NSMutableArray initCell];
    return [result addAllR:nume,deno,nil];
}

+(NSMutableArray *) addFracBignumFromArray:(NSMutableArray *)vals
{
    int i;
    Bignum *nume1 = vals[0][0];
    Bignum *deno1 = vals[0][1];
    [vals removeObjectAtIndex:0];
    
    NSUInteger len = [vals count] - 1;
    Bignum *lcm = [[Bignum alloc] initWithString:@"0"];
    
    for (i=0;i<len;i++) {
        Bignum *nume2 = vals[i][0];
        Bignum *deno2 = vals[i][1];
        mpz_lcm(lcm->number,deno1->number,deno2->number);
        mpz_div(deno1->number,lcm->number,deno1->number);
        mpz_div(deno2->number,lcm->number,deno2->number);
        mpz_mul(nume1->number,nume1->number,deno1->number);
        mpz_mul(nume2->number,nume2->number,deno2->number);
        mpz_add(nume1->number,nume1->number,nume2->number);
        mpz_set(deno1->number,lcm->number);
        [nume2 releaseBignum];
        [deno2 releaseBignum];
    }
    
    Bignum *gcd = [[Bignum alloc] initWithString:@"0"];
    mpz_gcd(gcd->number,nume1->number,deno1->number);
    
    mpz_div(nume1->number,nume1->number,gcd->number);
    mpz_div(deno1->number,deno1->number,gcd->number);
    
    [gcd releaseBignum];
    [lcm releaseBignum];
    
    NSMutableArray *result = [NSMutableArray initCell];
    return [result addAllR:nume1,deno1,nil];
}

+(NSMutableArray *) subFracBignumFromArray:(NSMutableArray *)vals
{
    int i;
    Bignum *nume1 = vals[0][0];
    Bignum *deno1 = vals[0][1];
    [vals removeObjectAtIndex:0];
    
    NSUInteger len = [vals count] - 1;
    Bignum *lcm = [[Bignum alloc] initWithString:@"0"];
    
    for (i=0;i<len;i++) {
        Bignum *nume2 = vals[i][0];
        Bignum *deno2 = vals[i][1];
        mpz_lcm(lcm->number,deno1->number,deno2->number);
        mpz_div(deno1->number,lcm->number,deno1->number);
        mpz_div(deno2->number,lcm->number,deno2->number);
        mpz_mul(nume1->number,nume1->number,deno1->number);
        mpz_mul(nume2->number,nume2->number,deno2->number);
        mpz_sub(nume1->number,nume1->number,nume2->number);
        mpz_set(deno1->number,lcm->number);
        [nume2 releaseBignum];
        [deno2 releaseBignum];
    }
    
    Bignum *gcd = [[Bignum alloc] initWithString:@"0"];
    mpz_gcd(gcd->number,nume1->number,deno1->number);
    
    mpz_div(nume1->number,nume1->number,gcd->number);
    mpz_div(deno1->number,deno1->number,gcd->number);
    
    [gcd releaseBignum];
    [lcm releaseBignum];
    
    NSMutableArray *result = [NSMutableArray initCell];
    return [result addAllR:nume1,deno1,nil];
}


+(NSMutableArray *) mulFracBignumFromArray:(NSMutableArray *)vals
{
    int i;
    Bignum *nume1 = vals[0][0];
    Bignum *deno1 = vals[0][1];
    [vals removeObjectAtIndex:0];
    
    NSUInteger len = [vals count] - 1;
    Bignum *gcd = [[Bignum alloc] initWithString:@"0"];
    
    for (i=0;i<len;i++) {
        Bignum *nume2 = vals[i][0];
        Bignum *deno2 = vals[i][1];
        mpz_mul(nume1->number,nume1->number,nume2->number);
        mpz_mul(deno1->number,deno1->number,deno2->number);
        mpz_gcd(gcd->number,nume1->number,deno1->number);
        mpz_div(nume1->number,nume1->number,gcd->number);
        mpz_div(deno1->number,deno1->number,gcd->number);
        [nume2 releaseBignum];
        [deno2 releaseBignum];
    }
    
    [gcd releaseBignum];
    
    NSMutableArray *result = [NSMutableArray initCell];
    return [result addAllR:nume1,deno1,nil];
}

+(NSMutableArray *) divFracBignumFromArray:(NSMutableArray *)vals
{
    int i;
    Bignum *nume1 = vals[0][0];
    Bignum *deno1 = vals[0][1];
    [vals removeObjectAtIndex:0];
    
    NSUInteger len = [vals count] - 1;
    Bignum *gcd = [[Bignum alloc] initWithString:@"0"];
    
    for (i=0;i<len;i++) {
        Bignum *nume2 = vals[i][0];
        Bignum *deno2 = vals[i][1];
        mpz_mul(nume1->number,nume1->number,deno2->number);
        mpz_mul(deno1->number,deno1->number,nume2->number);
        mpz_gcd(gcd->number,nume1->number,deno1->number);
        mpz_div(nume1->number,nume1->number,gcd->number);
        mpz_div(deno1->number,deno1->number,gcd->number);
        [nume2 releaseBignum];
        [deno2 releaseBignum];
    }
    
    [gcd releaseBignum];
    
    NSMutableArray *result = [NSMutableArray initCell];
    return [result addAllR:nume1,deno1,nil];
}


-(NSString *) getString
{
    char *str = NULL;
    char *cp;
    cp = mpz_get_str(str,BASE,self->number);
    NSString *result = [[NSString alloc] initWithFormat:@"%s",cp];
    free(cp);
    free(str);
    return result;
}

-(void) releaseBignum
{
    mpz_clear(self->number);
}

+(void) allRelease:(NSMutableArray *)vals
{
    int pos = 0;
    while (![vals[pos] isEqual:[NSNull null]]) {
        Bignum *tmp = vals[pos];
        mpz_clear(tmp->number);
        pos++;
    }
}

-(BOOL) isEqualBignum:(NSString *)s_num
{
    Bignum *num = [[Bignum alloc] initWithString:s_num];
    
    int ans = mpz_cmp(self->number,num->number);
    
    [num releaseBignum];
    
    if (ans == 0) {
        return TRUE;
    } else {
        return FALSE;
    }
}

@end
