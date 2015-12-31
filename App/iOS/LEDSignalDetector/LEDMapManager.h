//
//  LEDMapManager.h
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/09/18.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class LEDMapManager;

@protocol LEDMapManagerDelegate <NSObject>

@optional

-(void)mapManager:(LEDMapManager*)mapManager currentPostion:(CLLocationCoordinate2D)pos;
-(void)mapManager:(LEDMapManager*)mapManager signalsOfNeighboring:(NSArray*)signals;
// 検知範囲(カメラ起動エリアなど)。GPS/磁気センサーで場所と方向で判断
-(void)mapManager:(LEDMapManager*)mapManager isValidArea:(BOOL)flag;

@end

@interface LEDMapManager : NSObject

@property (nonatomic, weak) id<LEDMapManagerDelegate> delegate;

+(LEDMapManager*)getInstance;
-(void)start;
-(void)stop;

@end


