//
//  Load.h
//  iPSmini
//
//  Created by 原田　一美 on 2012/12/05.
//  Copyright (c) 2012年 原田　一美. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Load : NSObject
{
    
}
-(void) initFileLoad:(id)path :(id)m_env;
-(void) schemeFileLoad:(id)filename :(id)env;
+(NSString *) waitingForKeyIn:(char *)str;

@end
