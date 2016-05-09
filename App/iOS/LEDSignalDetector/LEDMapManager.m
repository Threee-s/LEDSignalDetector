//
//  LEDMapManager.m
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/09/18.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#import "LEDMapManager.h"
#import "Log.h"


@implementation LEDMapLocation

-(id)init
{
    if (self = [super init]) {
        double latitude = 0.0;
        double longitude = 0.0;
        _coor = CLLocationCoordinate2DMake(latitude, longitude);
    }
    
    return self;
}

@end

@implementation LEDMapHeading

-(id)init
{
    if (self = [super init]) {
        _trueHeading = 0.0;
        _magneticHeading = 0.0;
    }
    
    return self;
}

@end

@implementation LEDMapInfo

-(id)init
{
    if (self = [super init]) {
        _location = [[LEDMapLocation alloc] init];
        _heading = [[LEDMapHeading alloc] init];
    }
    
    return self;
}

@end


@interface LEDMapManager() <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationMan;
@property (nonatomic) LEDMapLocation *location;
@property (nonatomic) LEDMapHeading *heading;

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
        _locationMan = [[CLLocationManager alloc] init];
        _locationMan.delegate = self;
        _location = [[LEDMapLocation alloc] init];
        _heading = [[LEDMapHeading alloc] init];
    }
    
    return self;
}

-(void)start
{
    if ([CLLocationManager locationServicesEnabled]) {// GPS
        
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
    if ([CLLocationManager headingAvailable]) {// 磁気センサー
        // 何度動いたら更新するか（デフォルトは1度）
        // memo:同期でも非同期でも設定度数以上の変化がなければ、値が更新されない（どの方法でも値は同じ。ただ、取得方法が違うだけ）。
        //_locationMan.headingFilter = kCLHeadingFilterNone;//全ての角度
        _locationMan.headingFilter = 1;// todo:引数で渡す
        
        // デバイスのどの向きを北とするか（デフォルトは画面上部）
        _locationMan.headingOrientation = CLDeviceOrientationPortrait;
        
        // 向き情報取得の開始
        [_locationMan startUpdatingHeading];
    }
}

-(void)stop
{
    // 位置情報の取得停止
    if ([CLLocationManager locationServicesEnabled]) {
        [_locationMan stopUpdatingLocation];
    }
    // ヘディングイベントの停止
    if ([CLLocationManager headingAvailable]) {
        [_locationMan stopUpdatingHeading];
    }
}

-(void)startWithType:(LEDMapType)type
{
    if ([CLLocationManager locationServicesEnabled] && (type & LEDMapTypeLocation) == LEDMapTypeLocation) {// GPS
        
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
    if ([CLLocationManager headingAvailable] && (type & LEDMapTypeHeading) == LEDMapTypeHeading) {// 磁気センサー
        // 何度動いたら更新するか（デフォルトは1度）
        // memo:同期でも非同期でも設定度数以上の変化がなければ、値が更新されない（どの方法でも値は同じ。ただ、取得方法が違うだけ）。
        //_locationMan.headingFilter = kCLHeadingFilterNone;//全ての角度
        _locationMan.headingFilter = 1;// todo:引数で渡す
        
        // デバイスのどの向きを北とするか（デフォルトは画面上部）
        _locationMan.headingOrientation = CLDeviceOrientationPortrait;
        
        // 向き情報取得の開始
        [_locationMan startUpdatingHeading];
    }
}

-(void)stopWithType:(LEDMapType)type
{
    // 位置情報の取得停止
    if ([CLLocationManager locationServicesEnabled] && (type & LEDMapTypeLocation) == LEDMapTypeLocation) {
        [_locationMan stopUpdatingLocation];
    }
    // ヘディングイベントの停止
    if ([CLLocationManager headingAvailable] && (type & LEDMapTypeHeading) == LEDMapTypeHeading) {
        [_locationMan stopUpdatingHeading];
    }
}

-(LEDMapLocation*)getCurrentLocation
{
    return _location;
}

-(LEDMapHeading*)getCurrentHeading
{
    //LEDMapHeading *heading = [[LEDMapHeading alloc] init];
    //CLLocationDirection magneticHeading = _locationMan.heading.magneticHeading;
    //heading.magneticHeading = magneticHeading;
    
    //return heading;
    return _heading;
}

-(LEDMapInfo*)getCurrentMapInfo
{
    LEDMapInfo *mapInfo = [[LEDMapInfo alloc] init];
    mapInfo.location = _location;
    mapInfo.heading = _heading;
    
    return mapInfo;
}

-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    //DEBUGLOG_PRINTF(@"locationManager didUpdateHeading");
    
    _heading.magneticHeading = newHeading.magneticHeading;// 磁北
    _heading.trueHeading = newHeading.trueHeading;// 真北
    if ([_delegate respondsToSelector:@selector(mapManager:currentDirection:)]) {
        [_delegate mapManager:self currentDirection:_heading];
    }
    
    // todo: check valid area for starting camera
    
    // todo: check signals of neighboring

}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //DEBUGLOG_PRINTF(@"locationManager didUpdateLocations");
    // 時間順CLLocation情報配列
    if (locations.count > 0) {
        CLLocation *currentLocation = locations.lastObject;
        
        DEBUGLOG_PRINTF(@"latitude:%f longitude:%f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
        CLLocationCoordinate2D coor2d = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
        _location.coor = coor2d;
        
        if ([_delegate respondsToSelector:@selector(mapManager:currentPostion:)]) {
            [_delegate mapManager:self currentPostion:_location];
        }
        
        // todo: check valid area for starting camera
        
        // todo: check signals of neighboring
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    
}

@end
