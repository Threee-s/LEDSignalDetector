//
//  LEDMapManager.h
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/09/18.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

typedef enum {
    LEDMapTypeLocation,
    LEDMapTypeHeading,
} LEDMapType;

@class LEDMapManager;

@interface LEDMapLocation : NSObject

@property (nonatomic) CLLocationCoordinate2D coor;

@end

@interface LEDMapHeading : NSObject

@property (nonatomic) double magneticHeading;
@property (nonatomic) double trueHeading;

@end

@protocol LEDMapManagerDelegate <NSObject>

@optional

-(void)mapManager:(LEDMapManager*)mapManager currentPostion:(LEDMapLocation*)pos;
-(void)mapManager:(LEDMapManager *)mapManager currentDirection:(LEDMapHeading*)dir;
// todo:周辺信号情報を返す(登録された場合)
-(void)mapManager:(LEDMapManager*)mapManager signalsOfNeighboring:(NSArray*)signals;
// todo:検知範囲(カメラ起動エリアなど)。GPS/磁気センサーで場所と方向で判断(登録された場合)
-(void)mapManager:(LEDMapManager*)mapManager isValidArea:(BOOL)flag;
// 交差点周辺に着いた場合(曲がっているどうかで判断?)
-(void)mapManager:(LEDMapManager*)mapManager isNearToCrossing:(BOOL)flag;

@end

// todo:AirSensorManagerを使わない。直接CoreLocationを使用
@interface LEDMapManager : NSObject

@property (nonatomic, weak) id<LEDMapManagerDelegate> delegate;

+(LEDMapManager*)getInstance;
-(void)start;
-(void)stop;
-(void)startWithType:(LEDMapType)type;
-(void)stopWithType:(LEDMapType)type;
-(LEDMapHeading*)getCurrentHeading;

@end


