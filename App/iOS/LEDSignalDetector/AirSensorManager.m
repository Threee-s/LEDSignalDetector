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

@implementation AirSensorLocation

-(id)init
{
    if (self = [super init]) {
        _trueHeading = 0.0;
        _magneticHeading = 0.0;
        _headingX = _headingY = _headingZ = 0.0;
        _latitude = _longitude = 0.0;
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
        _location = [[AirSensorLocation alloc] init];
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


@interface AirSensorManager() <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationMan;
@property (nonatomic) CMMotionManager *motionMan;
@property (nonatomic) CMMotionActivityManager *activityMan;
@property (nonatomic) AirSensorInfo *info;
@property (nonatomic) AirSensorType activeSensorType;

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
        _locationMan = [[CLLocationManager alloc] init];
        _locationMan.delegate = self;
        
        _motionMan = [[CMMotionManager alloc] init];
        _activityMan = [[CMMotionActivityManager alloc] init];
        
        _info = [[AirSensorInfo alloc] init];
    }
    
    return self;
}

-(void)notifySensorInfo:(AirSensorType)type
{
    //DEBUGLOG_PRINTF(@"notifySensorInfo");
    
    //if (_observer != nil) {
    //    if ([_observer respondsToSelector:@selector(sensorInfo:ofType:)]) {
            [_observer sensorInfo:_info ofType:type];
    //    }
    //}
}

-(void)proximityStateDidChange:(NSNotification*)notification
{
    //DEBUGLOG_PRINTF(@"proximityStateDidChange");
    BOOL state = [UIDevice currentDevice].proximityState;// YES:proximity NO:other
    if (_observer != nil) {
        if ([_observer respondsToSelector:@selector(displayCameraView:info:)]) {
            [_observer displayCameraView:state info:_info];
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    //DEBUGLOG_PRINTF(@"locationManager didUpdateHeading");
    
    _info.rawInfo.location.magneticHeading = newHeading.magneticHeading;// 磁北
    _info.rawInfo.location.trueHeading = newHeading.trueHeading;// 真北
    [self notifySensorInfo:AirSensorTypeHeading];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //DEBUGLOG_PRINTF(@"locationManager didUpdateLocations");
    // 時間順CLLocation情報配列
    if (locations.count > 0) {
        CLLocation *currentLocation = locations.lastObject;
        //DEBUGLOG_PRINTF(@"[%f, %f]", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
        _info.rawInfo.location.latitude = currentLocation.coordinate.latitude;
        _info.rawInfo.location.longitude = currentLocation.coordinate.longitude;
        
        [self notifySensorInfo:AirSensorTypeLocation];
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    
}

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
    
    if ([CLLocationManager locationServicesEnabled] && (_activeSensorType & AirSensorTypeLocation) == AirSensorTypeLocation) {// GPS
        
        //ユーザーによる位置情報サービスの許可状態をチェック
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||//制限されている
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)// 明示的に拒否(settingsで無効)
        {
            //DEBUGLOG_PRINTF(@"Location service is unauthorized. authorizationStatus:%d", [CLLocationManager authorizationStatus]);
        } else {
            //利用許可要求をまだ行っていない状態であれば要求(制限されていない、かつ有効の場合要求)
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
                //DEBUGLOG_PRINTF(@"Location service is not determined. authorizationStatus:%d", [CLLocationManager authorizationStatus]);
                
                //許可の要求
                //アプリがフォアグラウンドにある間のみ位置情報サービスを使用する許可を要求
                //[_locationMan requestWhenInUseAuthorization];
                [_locationMan requestAlwaysAuthorization];
            }
            
            _locationMan.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
            _locationMan.distanceFilter = 20.0;
            // 位置情報取得の開始
            [_locationMan startUpdatingLocation];
        }
    }
    
    // memo:認証不要?->磁北の場合、位置情報不要。真北の場合、磁北と位置情報から計算すうるので、GPSが必要(認証が必要)。また「コンパス調整：on」にする必要がある
    if ([CLLocationManager headingAvailable] && (_activeSensorType & AirSensorTypeHeading) == AirSensorTypeHeading) {// 磁気センサー
        // 何度動いたら更新するか（デフォルトは1度）
        //_locationMan.headingFilter = kCLHeadingFilterNone;
        _locationMan.headingFilter = 20;
        
        // デバイスの度の向きを北とするか（デフォルトは画面上部）
        _locationMan.headingOrientation = CLDeviceOrientationPortrait;
        
        // 向き情報取得の開始
        [_locationMan startUpdatingHeading];
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
    if (_motionMan.deviceMotionAvailable && (_activeSensorType & AirSensorTypeAttitude) == AirSensorTypeAttitude) {// 回転角度
        _motionMan.deviceMotionUpdateInterval = 1 / FREQUENCY;
        
        // memo:CMDeviceMotionに加速度、ジャイロ、磁気データも入っている
        CMDeviceMotionHandler handler = ^(CMDeviceMotion *data, NSError *error) {
            //DEBUGLOG_PRINTF(@"CMDeviceMotionHandler");
            
            _info.rawInfo.rotation.pitch = data.attitude.pitch;
            _info.rawInfo.rotation.roll = data.attitude.roll;
            _info.rawInfo.rotation.yaw = data.attitude.yaw;
            
            [self notifySensorInfo:AirSensorTypeAttitude];
        };
        
        [_motionMan startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    // 磁力センサー (X軸・Y軸・Z軸で計測される磁力の強さ)
    if (_motionMan.magnetometerAvailable && (_activeSensorType & AirSensorTypeMagnetometer) == AirSensorTypeMagnetometer) {
        _motionMan.magnetometerUpdateInterval = 1 / FREQUENCY;
        
        CMMagnetometerHandler handler = ^(CMMagnetometerData *data, NSError *error) {
            //DEBUGLOG_PRINTF(@"CMMagnetometerHandler");
            
            _info.rawInfo.location.headingX = data.magneticField.x;
            _info.rawInfo.location.headingY = data.magneticField.y;
            _info.rawInfo.location.headingZ = data.magneticField.z;
            
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
    
    // 位置情報の取得停止
    if ([CLLocationManager locationServicesEnabled] && (_activeSensorType & AirSensorTypeLocation) == AirSensorTypeLocation) {
        [_locationMan stopUpdatingLocation];
    }
    // ヘディングイベントの停止
    if ([CLLocationManager headingAvailable] && (_activeSensorType & AirSensorTypeHeading) == AirSensorTypeHeading) {
        [_locationMan stopUpdatingHeading];
    }
    
    if (_motionMan.accelerometerActive && (_activeSensorType & AirSensorTypeAcceleration) == AirSensorTypeAcceleration) {
        [_motionMan stopAccelerometerUpdates];
    }
    
    if (_motionMan.gyroActive && (_activeSensorType & AirSensorTypeGyro) == AirSensorTypeGyro) {
        [_motionMan stopGyroUpdates];
    }
    
    if (_motionMan.deviceMotionActive && (_activeSensorType & AirSensorTypeAttitude) == AirSensorTypeAttitude) {
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
