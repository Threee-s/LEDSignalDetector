//
//  SmartEyeW.h
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/26.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#ifndef LEDSignalDetector_SmartEyeW_h
#define LEDSignalDetector_SmartEyeW_h

#import <AVFoundation/AVFoundation.h>

// test. struct?
#if true
@interface SignalW : NSObject

@property (nonatomic) int kind;// 車両用/歩行者用(必要であれば、もうちょっと細かく)
@property (nonatomic) int type;// LEDかどうか
@property (nonatomic) int color;// 青/黄/赤
@property (nonatomic) int state;// 点/滅
@property (nonatomic) int level;// 何%点なのか(option)
@property (nonatomic) CGRect rect;// 信号位置範囲
@property (nonatomic) int pixel;// 矩形内有効画素数(vの数)
@property (nonatomic) float distance;
@property (nonatomic) unsigned long rectId;// 矩形を一意に識別するため、同じ矩形の場合、既存矩形idに統合
@property (nonatomic) unsigned long signalId;// 信号矩形を一時に識別するため。ただの矩形の場合0
@property (nonatomic) NSMutableArray *currentRects;// 現在保存中の矩形一覧(デバッグ用)

- (NSString *)description;

@end

@interface DebugInfoW : NSObject

@property (nonatomic, copy) NSString *des;
//@property (nonatomic) NSMutableArray *currentRects;// 現在保存中の矩形一覧(デバッグ用)

- (NSString *)description;
- (void)addInfo:(NSString*)info;

@end



#else

struct SignalW {
    
    int kind;
    int type;
    int color;
    int state;
    int level;
    CGRect rect;
    int pixel;
    unsigned long rectId;
    unsigned long signalId;
    
};

#endif


@interface SmartEyeW : NSObject

/* test */

+(UIImage*)captureImageFromCamera;//カメラから画像取得。未確認
+(UIImage*)DetectEdgeWithImage:(UIImage*)image;//エッジ抽出
+(UIImage*)BGR2HSVWithImage:(UIImage*)image;//HSVへ変換
+(UIImage*)colorExtractionWithImage:(UIImage*)image//特定色抽出。png/jpegなど種類によって違う？？
//code:(int)code
                       chanel1Lower:(int)ch1Lower
                       chanel1upper:(int)ch1Upper
                       chanel2Lower:(int)ch2Lower
                       chanel2Upper:(int)ch2Upper
                       chanel3Lower:(int)ch3Lower
                       chanel3Upper:(int)ch3Upper;
+(UIImage*)detectLEDArea:(UIImage*)image;
+(UIImage*)detectLED:(UIImage*)image;

+(void)testRecognize;
+(UIImage*)testInRange:(UIImage*)image;

/*  */

+(void)setConfig;
// todo:信号リストを返す。取りあえずログで判断
+(UIImage*)detectSignal:(UIImage*)image inRect:(CGRect)rect signals:(NSMutableArray*)signalList debugInfo:(DebugInfoW*)info/*TBD*/;
+(void)detectSignalWithSampleBuffer:(CMSampleBufferRef)sampleBuffer inRect:(CGRect)rect signals:(NSMutableArray*)signalList debugInfo:(DebugInfoW*)info/*TBD*/;

+(UIImage*)loadImage:(NSString*)fileName;
+(UIImage*)loadVideoFromFile:(NSString*)fileName;


@end

#endif
