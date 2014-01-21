//
//  Bignum.h
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/13.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "gmp.h"

@interface Bignum : NSObject
{
    mpz_t number;
}

-(Bignum *) initWithString:(NSString *)str;
+(Bignum *) bigNumberWithString:(NSString *)str;
-(NSString *) getString;
-(void) printBignum;
-(void) releaseBignum;
-(BOOL) isEqualBignum:(NSString *)num;

-(Bignum *) addBignum:(Bignum *)num;
-(Bignum *) subBignum:(Bignum *)num;
-(Bignum *) mulBignum:(Bignum *)num;
+(Bignum *) divBignum:(NSMutableArray *)vals;
+(Bignum *) modBignum:(NSMutableArray *)vals;

+(Bignum *) gcdBignum:(NSMutableArray *)vals;
+(Bignum *) lcmBignum:(NSMutableArray *)vals;

+(Bignum *) addBignumFromArray:(NSMutableArray *)vals;
+(Bignum *) subBignumFromArray:(NSMutableArray *)vals;
+(Bignum *) mulBignumFromArray:(NSMutableArray *)vals;
+(NSMutableArray *) divBignumFromArray:(NSMutableArray *)vals;

+(NSMutableArray *) addFracBignumFromArray:(NSMutableArray *)vals;
+(NSMutableArray *) subFracBignumFromArray:(NSMutableArray *)vals;
+(NSMutableArray *) mulFracBignumFromArray:(NSMutableArray *)vals;
+(NSMutableArray *) divFracBignumFromArray:(NSMutableArray *)vals;

-(id) testBignum:(Bignum *)num; //delete after
+(void) allRelease:(NSMutableArray *)vals;
@end