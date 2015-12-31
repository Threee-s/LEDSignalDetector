//
//  LEDMapManager.m
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/09/18.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#import "LEDMapManager.h"
#import "AirSensorManager.h"
#import "Log.h"


@interface LEDMapManager() <AirSensorObserver>

@property (nonatomic) AirSensorManager *sensorManager;

@end

@implementation LEDMapManager

+(LEDMapManager*)getInstance
{
    static LEDMapManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once( &onceToken, ^{
        sharedInstance = [LEDMapManager new];
    });
    
    return sharedInstance;
}

-(id)init
{
    DEBUGLOG_PRINTF(@"LEDMapManager init");
    if (self = [super init]) {
        _sensorManager = [AirSensorManager getInstance];
        _sensorManager.observer = self;
        [_sensorManager addSensorType:AirSensorTypeLocation];
    }
    
    return self;
}

-(void)start
{
    [_sensorManager start];
}

-(void)stop
{
    [_sensorManager stop];
}

-(void)sensorInfo:(AirSensorInfo *)info ofType:(AirSensorType)type
{
    if (type == AirSensorNotifyTypeLocationCoordinate) {
        DEBUGLOG_PRINTF(@"latitude:%f longitude:%f", info.rawInfo.location.latitude, info.rawInfo.location.longitude);
        CLLocationCoordinate2D coor2d = CLLocationCoordinate2DMake(info.rawInfo.location.latitude, info.rawInfo.location.longitude);
        
        if (_delegate != nil) {
            if ([_delegate respondsToSelector:@selector(mapManager:currentPostion:)]) {
                [_delegate mapManager:self currentPostion:coor2d];
            }
            
            // todo: check valid area for starting camera
            
            // todo: check signals of neighboring
        }
    }
}

@end
