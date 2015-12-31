//
//  SignalGraphView.h
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/26.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#import "AirSensorManager.h"


@interface AirGraphView : UIView

-(void)setSensorType:(AirSensorType)type;
-(void)addAccelerationData:(AirSensorAcceleration*)data;
-(void)addGyroData:(AirSensorRotationRate*)data;
-(void)addAttitudeData:(AirSensorRotationRate*)data;
// すべてのデータを削除
-(void)clear;

@end

