//
//  AirSensorManager.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/06.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    AirSensorAxisX = 0,
    AirSensorAxisY,
    AirSensorAxisZ,
} AirSensorAxis;

typedef enum {
    AirSensorTypeNone         = 0x00,
    AirSensorTypeAcceleration = 1 << 1,
    AirSensorTypeRotationRate = 1 << 2,
    AirSensorTypeLocation     = 1 << 3,
    AirSensorTypeHeading      = 1 << 4,
    AirSensorTypeActivity     = 1 << 5,
    AirSensorTypeMagnetometer = 1 << 6,
    AirSensorTypeGyro         = 1 << 7,
    AirSensorTypeAttitude     = 1 << 8,
    AirSensorTypeProximity    = 1 << 9,
} AirSensorType;

typedef enum {
    AirSensorNotifyTypeAcceleration,
    AirSensorNotifyTypeRotationRate,
    AirSensorNotifyTypeLocationCoordinate,
    AirSensorNotifyTypeLocationHeading,
    AirSensorNotifyTypeActivity
} AirSensorNotifyType;

/*
typedef struct {
    double x;
    double y;
    double z;
} AirSensorAcceleration;

typedef struct {
    double x;
    double y;
    double z;
} AirSensorRotationRate;

typedef struct {
    double heading;
} AirSensorLocation;

typedef struct {
    int confidence;
    BOOL stationary;
    BOOL walking;
    BOOL running;
    BOOL cycling;
    BOOL unknown;
} AirSensorActivity;

typedef struct {
    AirSensorAcceleration acceleration;
    AirSensorRotationRate rotation;
    AirSensorLocation location;
    AirSensorActivity activity;
} AirSensorRawInfo;
 */

@interface AirSensorAcceleration : NSObject

@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;

@end

@interface AirSensorRotationRate : NSObject

@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;
@property (nonatomic) double pitch;
@property (nonatomic) double roll;
@property (nonatomic) double yaw;

@end

@interface AirSensorLocation : NSObject

@property (nonatomic) double magneticHeading;
@property (nonatomic) double trueHeading;
@property (nonatomic) double headingX;
@property (nonatomic) double headingY;
@property (nonatomic) double headingZ;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;

@end

@interface AirSensorActivity : NSObject

@property (nonatomic) int confidence;
@property (nonatomic) BOOL unknown;
@property (nonatomic) BOOL stationary;
@property (nonatomic) BOOL walking;
@property (nonatomic) BOOL running;
@property (nonatomic) BOOL automotive;
@property( nonatomic) BOOL cycling;

@end

@interface AirSensorRawInfo : NSObject

@property (nonatomic) AirSensorAcceleration *acceleration;
@property (nonatomic) AirSensorRotationRate *rotation;
@property (nonatomic) AirSensorLocation *location;
@property (nonatomic) AirSensorActivity *activity;

@end

@interface AirSensorInfo : NSObject

//@property (nonatomic) AirSensorRawInfo rawInfo;
@property (nonatomic) AirSensorRawInfo *rawInfo;

@end


// todo:API名検討
@protocol AirSensorObserver <NSObject>

@optional

// カメラ画面表示するか。接近センサーで判断
-(void)displayCameraView:(BOOL)flag info:(AirSensorInfo*)info;
// カメラでキャプチャするか。加速度/ジャイロセンサーで判断
-(void)capture:(AirSensorInfo*)info;
// raw info
-(void)sensorInfo:(AirSensorInfo*)info ofType:(AirSensorType)type;

@end



// todo:汎用的にする
@interface AirSensorManager : NSObject

@property (nonatomic, weak) id<AirSensorObserver> observer;

+(AirSensorManager*)getInstance;
-(void)setSensorType:(AirSensorType)type;
-(void)addSensorType:(AirSensorType)type;
-(void)deleteSensorType:(AirSensorType)type;
-(void)start;
-(void)stop;

@end
