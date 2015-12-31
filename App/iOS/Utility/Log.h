//
//  Log.h
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/23.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#ifndef LEDSignalDetector_Log_h
#define LEDSignalDetector_Log_h

#ifndef DEBUG_LOG
//#define DEBUG_LOG// test
#endif


#ifdef DEBUG_LOG

    #define DEBUGLOG(...) NSLog(__VA_ARGS__)
    #define DEBUGLOG_PRINTF(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
    #define DEBUGLOG_METHOD NSLog(@"%s", __func__)
    #define DEBUGLOG_METHOD_AND_ABORT LOG_METHOD; abort()

    #define DEBUGLOG_POINT(p) NSLog(@"%f, %f", p.x, p.y)
    #define DEBUGLOG_SIZE(p) NSLog(@"%f, %f", p.width, p.height)
    #define DEBUGLOG_RECT(p) NSLog(@"%f, %f - %f, %f", p.origin.x, p.origin.y, p.size.width, p.size.height)

#else

    #define DEBUGLOG(...)
    #define DEBUGLOG_PRINTF(FORMAT, ...)
    #define DEBUGLOG_METHOD
    #define DEBUGLOG_METHOD_AND_ABORT

    #define DEBUGLOG_POINT(p)
    #define DEBUGLOG_SIZE(p)
    #define DEBUGLOG_RECT(p)

#endif

/*
#ifndef WINCPP
#import <Foundation/Foundation.h>
@interface Log : NSObject

+(void)debug:(NSString*)log;

@end
#endif
 */

#endif
