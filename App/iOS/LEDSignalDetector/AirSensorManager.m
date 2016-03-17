//
//  AirSensorManager.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/06.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "AirSensorManager.h"
#import "Log.h"


#define FREQUENCY 60.0

#define QUEUE_SERIAL_SENSOR_MOTION "com.threees.tre.led.sensor.motion"

@implementation AirSensorAcceleration

-(id)init
{
    if (self = [super init]) {
        _x = _y = _z = 0.0;
    }
    
    return self;
}

@end

@implementation AirSensorRotationRate

-(id)init
{
    if (self = [super init]) {
        _x = _y = _z = 0.0;
        _pitch = _roll = _yaw = 0.0;
    }
    
    return self;
}

@end

@implementation AirSensorMagnetometer

-(id)init
{
    if (self = [super init]) {
        _headingX = _headingY = _headingZ = 0.0;
    }
    
    return self;
}

@end

@implementation AirSensorActivity

-(id)init
{
    if (self = [super init]) {
        _confidence = 0;
        _unknown = _stationary = _walking = _running = _automotive = _cycling = NO;
    }
    
    return self;
}

@end

@implementation AirSensorRawInfo

-(id)init
{
    if (self = [super init]) {
        _acceleration = [[AirSensorAcceleration alloc] init];
        _rotation = [[AirSensorRotationRate alloc] init];
        _magnetometer = [[AirSensorMagnetometer alloc] init];
        _activity = [[AirSensorActivity alloc] init];
    }
    
    return self;
}

@end

@implementation AirSensorInfo

-(id)init
{
    //DEBUGLOG_PRINTF(@"AirSensorInfo init");
    
    if (self = [super init]) {
        _rawInfo = [[AirSensorRawInfo alloc] init];
    }
    
    return self;
}

@end


@interface AirSensorManager()

@property (nonatomic) CMMotionManager *motionMan;
@property (nonatomic) CMMotionActivityManager *activityMan;
@property (nonatomic) AirSensorInfo *info;
@property (nonatomic) AirSensorType activeSensorType;
@property (nonatomic) dispatch_queue_t motionQueue;

@end



@implementation AirSensorManager

+(AirSensorManager*)getInstance
{
    static AirSensorManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once( &onceToken, ^{
        sharedInstance = [AirSensorManager new];
    });
    
    return sharedInstance;
}

-(id)init
{
    //DEBUGLOG_PRINTF(@"AirSensorManager init");
    if (self = [super init]) {
        _motionMan = [[CMMotionManager alloc] init];
        _activityMan = [[CMMotionActivityManager alloc] init];
        
        _info = [[AirSensorInfo alloc] init];
        _motionQueue = dispatch_queue_create(QUEUE_SERIAL_SENSOR_MOTION, DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

-(void)notifySensorInfo:(AirSensorType)type
{
    //DEBUGLOG_PRINTF(@"notifySensorInfo");
    
    //if (_observer != nil) {
    //    if ([_observer respondsToSelector:@selector(sensorInfo:ofType:)]) {
//            [_observer sensorInfo:_info ofType:type];
    //    }
    //}
}

-(void)proximityStateDidChange:(NSNotification*)notification
{
    //DEBUGLOG_PRINTF(@"proximityStateDidChange");
    BOOL state = [UIDevice currentDevice].proximityState;// YES:proximity NO:other
    if (_observer != nil) {
        if ([_observer respondsToSelector:@selector(displayCameraView:info:)]) {
            [_observer displayCameraView:!state info:_info]; // proximity:not display
        }
    }
}



-(void)controlAcceleration
{
    
}

-(void)controlGyro
{
    
}

-(void)controlLocation
{
    
}

// acce(low,high)/gyro/attri/magnet
-(void)controlMotion
{
    
}

-(void)controlProximity
{
    
}

// todo:accelerometer/gyro/motionどれを使うか判断。motionは複数のセンサーを使うので、できれば避けるほうが良いかも?


// todo:起動後変更できないな(指定されていないセンサーを停止する必要がある)。下同。起動時と起動中分ける？
-(void)setSensorType:(AirSensorType)type
{
    _activeSensorType = type;
}

-(void)addSensorType:(AirSensorType)type
{
    _activeSensorType |= type;
}

-(void)deleteSensorType:(AirSensorType)type
{
    _activeSensorType &= ~type;
}

-(void)startWithType:(AirSensorType)type
{
    if ((type & AirSensorTypeProximity) == AirSensorTypeProximity) {
        // 近接センサオン
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        
        // 近接センサ監視
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(proximityStateDidChange:)
                                                     name:UIDeviceProximityStateDidChangeNotification
                                                   object:nil];
    }
    
    if (_motionMan.accelerometerAvailable && !_motionMan.accelerometerActive && (type & AirSensorTypeAcceleration) == AirSensorTypeAcceleration) {// 加速度(方向[-/+]と速度)
        _motionMan.accelerometerUpdateInterval = 1 / FREQUENCY;
        
        CMAccelerometerHandler handler = ^(CMAccelerometerData *data, NSError *error) {
            //DEBUGLOG_PRINTF(@"CMAccelerometerHandler");
            //NSLog(@"Accelerometer time:%f", data.timestamp);
            _info.rawInfo.acceleration.x = data.acceleration.x;
            _info.rawInfo.acceleration.y = data.acceleration.y;
            _info.rawInfo.acceleration.z = data.acceleration.z;
            
            [self notifySensorInfo:AirSensorTypeAcceleration];
        };
        
        [_motionMan startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    // ジャイロスコープ (X軸・Y軸・Z軸を中心にしてどの方向に"回転"したか)
    if (_motionMan.gyroAvailable && !_motionMan.gyroActive && (type & AirSensorTypeGyro) == AirSensorTypeGyro) {// 角速度(方向[-/+]と速度)
        _motionMan.gyroUpdateInterval = 1 / FREQUENCY;
        
        CMGyroHandler handler = ^(CMGyroData *data, NSError *error) {
            //DEBUGLOG_PRINTF(@"CMGyroHandler");
            
            _info.rawInfo.rotation.x = data.rotationRate.x;
            _info.rawInfo.rotation.y = data.rotationRate.y;
            _info.rawInfo.rotation.z = data.rotationRate.z;
            
            [self notifySensorInfo:AirSensorTypeGyro];
        };
        
        [_motionMan startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    // 磁力センサー (X軸・Y軸・Z軸で計測される磁力の強さ)
    if (_motionMan.magnetometerAvailable && !_motionMan.magnetometerActive && (type & AirSensorTypeMagnetometer) == AirSensorTypeMagnetometer) {
        _motionMan.magnetometerUpdateInterval = 1 / FREQUENCY;
        
        CMMagnetometerHandler handler = ^(CMMagnetometerData *data, NSError *error) {
            //DEBUGLOG_PRINTF(@"CMMagnetometerHandler");
            
            _info.rawInfo.magnetometer.headingX = data.magneticField.x;
            _info.rawInfo.magnetometer.headingY = data.magneticField.y;
            _info.rawInfo.magnetometer.headingZ = data.magneticField.z;
            
            [self notifySensorInfo:AirSensorTypeMagnetometer];
        };
        
        [_motionMan startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    // デバイスの姿勢に関する情報 (オイラー角(ロール・ピッチ・ヨー)や行列(マトリックス)の形)
    if (_motionMan.deviceMotionAvailable && !_motionMan.deviceMotionActive && (type & AirSensorTypeMotion) == AirSensorTypeMotion) {// 回転角度
        _motionMan.deviceMotionUpdateInterval = 1 / FREQUENCY;
        
        // memo:CMDeviceMotionに加速度、ジャイロ、磁気データも入っている
        CMDeviceMotionHandler handler = ^(CMDeviceMotion *data, NSError *error) {
            //DEBUGLOG_PRINTF(@"CMDeviceMotionHandler");
            
            // memo:画面が上向きの場合、すべて0(基準)。start時frameを指定することで基準点を設定可能(ただ上向きは同じ)。未確認
            _info.rawInfo.rotation.pitch = data.attitude.pitch; // X軸中心のラジアン角: -π/2〜π/2(-90度〜90度) 自分向き:-
            _info.rawInfo.rotation.roll = data.attitude.roll;// Y軸中心のラジアン角: -π〜π(-180度〜180度) 時計回り:+
            // memo:水平が基準点。開始時縦になっても横になっても(どの方向になっても)0からスタート
            _info.rawInfo.rotation.yaw = data.attitude.yaw;// Z軸中心のラジアン角: -π〜π(-180度〜180度) 右->左:+
            
            // todo:Attitude or gyroで信号判断処理をOn/Off。->On/Offのcallback追加。
            //      ->gyroは加速度と同じで、動いた一瞬の角の加速度(どの方向にまわったか判断)。止まったら0になるので、Attitude使用
            // pitchだけでOK->上向き：0 立てる:π/2 -> π/4~π/2にする ->立てている状態で傾いた時も値が変わる。ただπ/4~π/2で判断すれも良さそう
            // yaw(傾き)は見なくて良い。横向きキャプチャでも特に問題ないはず。中途半端な向きも問題ないはず。矩形が多少大きくなるかも->とりあえず無視
            BOOL detectFlag = NO;
            if (data.attitude.pitch > M_PI_4 && data.attitude.pitch < M_PI_2) {
                detectFlag = YES;
            }
            
            [_observer ifNeededToDetect:detectFlag];
            
            _info.rawInfo.acceleration.x = data.userAcceleration.x;
            _info.rawInfo.acceleration.y = data.userAcceleration.y;
            _info.rawInfo.acceleration.z = data.userAcceleration.z;
            _info.rawInfo.acceleration.timestamp = data.timestamp;
            
            _info.rawInfo.rotation.x = data.rotationRate.x;
            _info.rawInfo.rotation.y = data.rotationRate.y;
            _info.rawInfo.rotation.z = data.rotationRate.z;
            _info.rawInfo.rotation.timestamp = data.timestamp;
            
            [self notifySensorInfo:AirSensorTypeAttitude | AirSensorTypeAccelerationHigh];
        };
        
        [_motionMan startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
        //[_motionMan startDeviceMotionUpdatesToQueue:_motionQueue withHandler:handler];
    }
    
    if ([CMMotionActivityManager isActivityAvailable] && (type & AirSensorTypeActivity) == AirSensorTypeActivity) {
        CMMotionActivityHandler handler = ^(CMMotionActivity *activity) {
            // 状態が更新されるたびにリアルタイムでラベル更新
            //DEBUGLOG_PRINTF(@"CMMotionActivityHandler");
            
            _info.rawInfo.activity.confidence = activity.confidence;
            _info.rawInfo.activity.unknown = activity.unknown;
            _info.rawInfo.activity.stationary = activity.stationary;
            _info.rawInfo.activity.walking = activity.walking;
            _info.rawInfo.activity.running = activity.running;
            _info.rawInfo.activity.automotive = activity.automotive;
            _info.rawInfo.activity.cycling = activity.cycling;
            
            [self notifySensorInfo:AirSensorTypeActivity];
        };
        
        [_activityMan startActivityUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
}

-(void)stopWithType:(AirSensorType)type
{
    if ((type & AirSensorTypeProximity) == AirSensorTypeProximity) {
        // 近接センサオフ
        [UIDevice currentDevice].proximityMonitoringEnabled = NO;
        
        // 近接センサ監視解除
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIDeviceProximityStateDidChangeNotification
                                                      object:nil];
    }
    
    if (_motionMan.accelerometerActive && (type & AirSensorTypeAcceleration) == AirSensorTypeAcceleration) {
        [_motionMan stopAccelerometerUpdates];
    }
    
    if (_motionMan.gyroActive && (type & AirSensorTypeGyro) == AirSensorTypeGyro) {
        [_motionMan stopGyroUpdates];
    }
    
    if (_motionMan.magnetometerActive && (type & AirSensorTypeMagnetometer) == AirSensorTypeMagnetometer) {
        [_motionMan stopMagnetometerUpdates];
    }
    
    if (_motionMan.deviceMotionActive && (type & AirSensorTypeMotion) == AirSensorTypeMotion) {
        [_motionMan stopDeviceMotionUpdates];
    }
    
    if ([CMMotionActivityManager isActivityAvailable] && (type & AirSensorTypeActivity) == AirSensorTypeActivity) {
        [_activityMan stopActivityUpdates];
    }
}

// todo:すべてcurrentQueueにすると、キューにたまるので、リアルタイムにならない可能性がある
// todo:全部Motionから取得する。別々に通知するのではなく、まとめて一緒に通知
// todo:許可処理->OK(一応追加)
-(void)start
{
    if ((_activeSensorType & AirSensorTypeProximity) == AirSensorTypeProximity) {
        // 近接センサオン
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        
        // 近接センサ監視
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(proximityStateDidChange:)
                                                     name:UIDeviceProximityStateDidChangeNotification
                                                   object:nil];
    }
    
    if (_motionMan.accelerometerAvailable && (_activeSensorType & AirSensorTypeAcceleration) == AirSensorTypeAcceleration) {// 加速度(方向[-/+]と速度)
        _motionMan.accelerometerUpdateInterval = 1 / FREQUENCY;
        
        CMAccelerometerHandler handler = ^(CMAccelerometerData *data, NSError *error) {
            //DEBUGLOG_PRINTF(@"CMAccelerometerHandler");
            //NSLog(@"Accelerometer time:%f", data.timestamp);
            _info.rawInfo.acceleration.x = data.acceleration.x;
            _info.rawInfo.acceleration.y = data.acceleration.y;
            _info.rawInfo.acceleration.z = data.acceleration.z;
            
            [self notifySensorInfo:AirSensorTypeAcceleration];
        };
        
        [_motionMan startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    // ジャイロスコープ (X軸・Y軸・Z軸を中心にしてどの方向に"回転"したか)
    if (_motionMan.gyroAvailable && (_activeSensorType & AirSensorTypeGyro) == AirSensorTypeGyro) {// 角速度(方向[-/+]と速度)
        _motionMan.gyroUpdateInterval = 1 / FREQUENCY;
        
        CMGyroHandler handler = ^(CMGyroData *data, NSError *error) {
            //DEBUGLOG_PRINTF(@"CMGyroHandler");
            
            _info.rawInfo.rotation.x = data.rotationRate.x;
            _info.rawInfo.rotation.y = data.rotationRate.y;
            _info.rawInfo.rotation.z = data.rotationRate.z;
            
            [self notifySensorInfo:AirSensorTypeGyro];
        };
        
        [_motionMan startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    // デバイスの姿勢に関する情報 (オイラー角(ロール・ピッチ・ヨー)や行列(マトリックス)の形)
    if (_motionMan.deviceMotionAvailable && (_activeSensorType & AirSensorTypeMotion) == AirSensorTypeMotion) {// 回転角度
        _motionMan.deviceMotionUpdateInterval = 1 / FREQUENCY;
        
        // memo:CMDeviceMotionに加速度、ジャイロ、磁気データも入っている
        CMDeviceMotionHandler handler = ^(CMDeviceMotion *data, NSError *error) {
            //DEBUGLOG_PRINTF(@"CMDeviceMotionHandler");
            
            // memo:画面が上向きの場合、すべて0(基準)。start時frameを指定することで基準点を設定可能(ただ上向きは同じ)。未確認
            _info.rawInfo.rotation.pitch = data.attitude.pitch; // X軸中心のラジアン角: -π/2〜π/2(-90度〜90度) 自分向き:-
            _info.rawInfo.rotation.roll = data.attitude.roll;// Y軸中心のラジアン角: -π〜π(-180度〜180度) 時計回り:+
            // memo:水平が基準点。開始時縦になっても横になっても(どの方向になっても)0からスタート
            _info.rawInfo.rotation.yaw = data.attitude.yaw;// Z軸中心のラジアン角: -π〜π(-180度〜180度) 右->左:+
            
            _info.rawInfo.acceleration.x = data.userAcceleration.x;
            _info.rawInfo.acceleration.y = data.userAcceleration.y;
            _info.rawInfo.acceleration.z = data.userAcceleration.z;
            _info.rawInfo.acceleration.timestamp = data.timestamp;
            
            _info.rawInfo.rotation.x = data.rotationRate.x;
            _info.rawInfo.rotation.y = data.rotationRate.y;
            _info.rawInfo.rotation.z = data.rotationRate.z;
            _info.rawInfo.rotation.timestamp = data.timestamp;
            
            [self notifySensorInfo:AirSensorTypeAttitude | AirSensorTypeAccelerationHigh];
        };
        
        [_motionMan startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    // 磁力センサー (X軸・Y軸・Z軸で計測される磁力の強さ)
    if (_motionMan.magnetometerAvailable && (_activeSensorType & AirSensorTypeMagnetometer) == AirSensorTypeMagnetometer) {
        _motionMan.magnetometerUpdateInterval = 1 / FREQUENCY;
        
        CMMagnetometerHandler handler = ^(CMMagnetometerData *data, NSError *error) {
            //DEBUGLOG_PRINTF(@"CMMagnetometerHandler");
            
            _info.rawInfo.magnetometer.headingX = data.magneticField.x;
            _info.rawInfo.magnetometer.headingY = data.magneticField.y;
            _info.rawInfo.magnetometer.headingZ = data.magneticField.z;
            
            [self notifySensorInfo:AirSensorTypeMagnetometer];
        };
        
        [_motionMan startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    if ([CMMotionActivityManager isActivityAvailable] && (_activeSensorType & AirSensorTypeActivity) == AirSensorTypeActivity) {
        CMMotionActivityHandler handler = ^(CMMotionActivity *activity) {
            // 状態が更新されるたびにリアルタイムでラベル更新
            //DEBUGLOG_PRINTF(@"CMMotionActivityHandler");
            
            _info.rawInfo.activity.confidence = activity.confidence;
            _info.rawInfo.activity.unknown = activity.unknown;
            _info.rawInfo.activity.stationary = activity.stationary;
            _info.rawInfo.activity.walking = activity.walking;
            _info.rawInfo.activity.running = activity.running;
            _info.rawInfo.activity.automotive = activity.automotive;
            _info.rawInfo.activity.cycling = activity.cycling;
            
            [self notifySensorInfo:AirSensorTypeActivity];
        };
        
        [_activityMan startActivityUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
}

-(void)stop
{
    if ((_activeSensorType & AirSensorTypeProximity) == AirSensorTypeProximity) {
        // 近接センサオフ
        [UIDevice currentDevice].proximityMonitoringEnabled = NO;
        
        // 近接センサ監視解除
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIDeviceProximityStateDidChangeNotification
                                                      object:nil];
    }
    
    if (_motionMan.accelerometerActive && (_activeSensorType & AirSensorTypeAcceleration) == AirSensorTypeAcceleration) {
        [_motionMan stopAccelerometerUpdates];
    }
    
    if (_motionMan.gyroActive && (_activeSensorType & AirSensorTypeGyro) == AirSensorTypeGyro) {
        [_motionMan stopGyroUpdates];
    }
    
    if (_motionMan.deviceMotionActive && (_activeSensorType & AirSensorTypeMotion) == AirSensorTypeMotion) {
        [_motionMan stopDeviceMotionUpdates];
    }
    
    if (_motionMan.magnetometerActive && (_activeSensorType & AirSensorTypeMagnetometer) == AirSensorTypeMagnetometer) {
        [_motionMan stopMagnetometerUpdates];
    }
    
    if ([CMMotionActivityManager isActivityAvailable] && (_activeSensorType & AirSensorTypeActivity) == AirSensorTypeActivity) {
        [_activityMan stopActivityUpdates];
    }
}

@end
