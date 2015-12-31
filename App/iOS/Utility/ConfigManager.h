//
//  ConfigManager.h
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/28.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
typedef struct {
    int ledFreq;
} SignalInfo;

typedef struct {
    BOOL flag;
    BOOL binary;
    BOOL point;
    BOOL rect;
    BOOL signal;
} DebugMode;

typedef struct {
    int formatIndex;
    float fps;
    float exposureValue;
    float iso;
    float bias;
} CameraSettings;

typedef struct {
    int time;
} RecordMode;

typedef struct {
    int lower;
    int upper;
} Range;

typedef struct {
    Range h;
    Range s;
    Range v;
} ColorSpace;

typedef struct {
    int detectColors;
    ColorSpace colorSpaceRed;
    ColorSpace colorSpaceGreen;
} ColorSettings;

typedef struct {
    int threshold;
    int offset;
} CombinePoint;

typedef struct {
    int prop;
    int offset;
} IntegrateRect;

typedef struct {
    int width;
    int height;
} ValidRect;

typedef struct {
    int dist;
    float scale;
} CompareRect;

typedef struct {
    int diffCount;
    int invalidCount;
} CompareSignal;

typedef struct {
    float lightnessDiff;
    CompareSignal compareSignal;
} RecogonizeSignal;

typedef struct {
    CombinePoint combinePoint;
    IntegrateRect integrateRect;
    ValidRect validRect;
    CompareRect compareRect;
    RecogonizeSignal recogonizeSignal;
} DetectParams;

typedef struct {
    SignalInfo signalInfo;
    DebugMode debugMode;
    CameraSettings cameraSettings;
    RecordMode recordMode;
    ColorSettings colorSettings;
    DetectParams detectParams;
} ConfigSettings;
 */


@interface SignalInfo : NSObject
@property (nonatomic) int ledFreq;
@property (nonatomic) int imgOri;
@end

@interface DebugMode : NSObject
@property (nonatomic) BOOL flag;
@property (nonatomic) BOOL binary;
@property (nonatomic) BOOL point;
@property (nonatomic) BOOL rect;
@property (nonatomic) BOOL area;
@property (nonatomic) BOOL signal;
@property (nonatomic) BOOL log;
@end


@interface CameraSettings : NSObject
@property (nonatomic) int formatIndex;
@property (nonatomic) int fps;
@property (nonatomic) float exposureValue;
@property (nonatomic) float iso;
@property (nonatomic) float bias;
//@property (nonatomic) CGSize dimension;
@end

@interface RecordMode : NSObject
@property (nonatomic) int time;
@end

@interface Range : NSObject
@property (nonatomic) int lower;
@property (nonatomic) int upper;
@end

@interface ColorSpace : NSObject 
@property (nonatomic) Range* h;
@property (nonatomic) Range* s;
@property (nonatomic) Range* v;
@end

@interface ColorSettings : NSObject
@property (nonatomic) int detectColors;
@property (nonatomic) ColorSpace* colorSpaceRed;
@property (nonatomic) ColorSpace* colorSpaceGreen;
@end

@interface ImageSettings : NSObject
@property (nonatomic) float width;
@property (nonatomic) float height;
@property (nonatomic) int orientation;
@end

@interface ValidArea : NSObject
@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float width;
@property (nonatomic) float height;
@end

@interface CombinePoint : NSObject
@property (nonatomic) int threshold;
@property (nonatomic) int offset;
@end

@interface IntegrateRect : NSObject
@property (nonatomic) int prop;
@property (nonatomic) int offset;
@end

@interface ValidRect : NSObject
@property (nonatomic) int width;
@property (nonatomic) int height;
@end

@interface CompareRect : NSObject
@property (nonatomic) int dist;
@property (nonatomic) float scale;
@end

@interface CompareSignal : NSObject
@property (nonatomic) int diffCount;
@property (nonatomic) int invalidCount;
@end

@interface RecogonizeSignal : NSObject
@property (nonatomic) float lightnessDiff;
@property (nonatomic) CompareSignal* compareSignal;
@end

@interface DetectParams : NSObject
@property (nonatomic) ImageSettings *imageSetting;
@property (nonatomic) ValidArea* validArea;
@property (nonatomic) CombinePoint* combinePoint;
@property (nonatomic) IntegrateRect* integrateRect;
@property (nonatomic) ValidRect* validRectMin;
@property (nonatomic) ValidRect* validRectMax;
@property (nonatomic) CompareRect* compareRect;
@property (nonatomic) RecogonizeSignal* recogonizeSignal;
@end

@interface ConfigSettings : NSObject
@property (nonatomic) SignalInfo* signalInfo;
@property (nonatomic) DebugMode* debugMode;
@property (nonatomic) CameraSettings* cameraSettings;
@property (nonatomic) RecordMode* recordMode;
@property (nonatomic) ColorSettings* colorSettings;// todo:add to DetectParams
@property (nonatomic) DetectParams* detectParams;
@end


@interface ConfigManager : NSObject
{
    //ConfigSettings* _confSettings;
}
//@property (nonatomic, copy) NSMutableDictionary *confDic;// changed to ImmutableDic(NSDictionary)
@property (nonatomic) NSMutableDictionary *confDic;
@property (nonatomic) ConfigSettings* confSettings;

+(ConfigManager*)sharedInstance;
//-(ConfigSettings)confSettings;

-(void)save;
-(NSString*)description;

@end
