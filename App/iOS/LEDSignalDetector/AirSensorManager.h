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
    AirSensorTypeNone              = 0x00,
    AirSensorTypeMotion                = 0x0001,
    AirSensorTypeAccelerationLow   = AirSensorTypeMotion << 1,
    AirSensorTypeAccelerationHigh  = AirSensorTypeAccelerationLow << 1,
    AirSensorTypeAcceleration      = AirSensorTypeAccelerationHigh << 1,
    AirSensorTypeGyro         = AirSensorTypeAcceleration << 1,
    AirSensorTypeRotationRate = AirSensorTypeGyro << 1,
    //AirSensorTypeLocation     = AirSensorTypeRotationRate << 1,
    //AirSensorTypeHeading      = AirSensorTypeLocation << 1,
    AirSensorTypeActivity     = AirSensorTypeRotationRate << 1,
    AirSensorTypeMagnetometer = AirSensorTypeActivity << 1,
    AirSensorTypeAttitude     = AirSensorTypeMagnetometer << 1,
    AirSensorTypeProximity    = AirSensorTypeAttitude << 1,
} AirSensorType;

typedef enum {
    AirSensorMovementDirectionNone,
    AirSensorMovementDirectionUp,
    AirSensorMovementDirectionDown,
    AirSensorMovementDirectionLeft,
    AirSensorMovementDirectionRight,
} AirSensorMovementDirection;

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
@property (nonatomic) NSTimeInterval timestamp;

@end

@interface AirSensorRotationRate : NSObject

@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;
@property (nonatomic) double pitch;
@property (nonatomic) double roll;
@property (nonatomic) double yaw;
@property (nonatomic) NSTimeInterval timestamp;

@end

@interface AirSensorMagnetometer : NSObject

@property (nonatomic) double headingX;
@property (nonatomic) double headingY;
@property (nonatomic) double headingZ;

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
@property (nonatomic) AirSensorMagnetometer *magnetometer;
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
// カメラでキャプチャするか。加速度/ジャイロセンサーで判断.todo:不要
-(void)capture:(AirSensorInfo*)info;
// 信号検出処理を行うか
-(void)ifNeededToDetect:(BOOL)flag;
// 移動距離と方向。加速度/ジャイロセンサーで判断(移動方向:加速度の+/-だけで良い？)
-(void)movedDistance:(float)distance inDirection:(AirSensorMovementDirection)direction;
// raw info
-(void)sensorInfo:(AirSensorInfo*)info ofType:(AirSensorType)type;

@end



// todo:汎用的にする。GPSを分離する->MapManagerとか
@interface AirSensorManager : NSObject

@property (nonatomic, weak) id<AirSensorObserver> observer;

+(AirSensorManager*)getInstance;
-(void)setSensorType:(AirSensorType)type;
-(void)addSensorType:(AirSensorType)type;
-(void)deleteSensorType:(AirSensorType)type;
-(void)start;
-(void)stop;
-(void)startWithType:(AirSensorType)type;
-(void)stopWithType:(AirSensorType)type;

@end
