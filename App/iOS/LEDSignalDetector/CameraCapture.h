//
//  CameraCapture.h
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/26.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#ifndef LEDSignalDetector_CameraCapture_h
#define LEDSignalDetector_CameraCapture_h

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM( NSInteger, CameraMode) {
    CameraModeAuto    = 0,
    CameraModePv,  // ISO (custom mode -> auto exposure duration)
    CameraModeMPv, // ISO (custom mode -> fixed exposure duration)
    CameraModeTv,  // exposure duration (custom mode -> fixed ISO)
    CameraModeATv, // exposure duration (custom mode -> auto ISO)
    CameraModeMv   // ISO/exposure duration (custom mode -> fixed ISO/exposure duration)
};

typedef NS_ENUM (NSInteger, CameraOrientaion) {
    //CameraOrientaionDefault = 0, // Landscape
    CameraOrientaionPortrait = 0, // home button on the down
    CameraOrientaionLandscape     // home button on the left
    // memo:横縦向きだけで良い。その他詳細向きは不要。left/right,up/downはただ表示時回転情報の違いなので(回転情報が一致すれば、leftもrightも最終的に同じ結果が得られる)。
};

typedef NS_ENUM (NSInteger, CameraDataType) {
    CameraDataTypeImage = 1 << 0,
    CameraDataTypePixel = 1 << 1,
};

typedef NS_ENUM (NSInteger, CameraImageStabilizationMode) {
    CameraImageStabilizationModeOff = 0,
    CameraImageStabilizationModeOn,
};

typedef NS_ENUM (NSInteger, CameraPixelFormatType) {
    CameraPixelFormatTypeBGRA = 0,
    CameraPixelFormatTypeBGR,
};

/*typedef struct {
    CameraMode mode;
    CameraOrientaion orientaion;
    CameraDataType type;
    CameraImageStabilizationMode isMode;
    int format;// index in settings
    int fps;
    float exposureValue;
    float iso;
    float bias;
} CameraSetting;*/

typedef struct {
    float minExposureOffset;
    float maxExposureOffset;
    float minExposureBias;
    float maxExposureBias;
    float minISO;
    float maxISO;
    float minExposureValue;
    float maxExposureValue;
    float minExposureDuration;
    float maxExposureDuration;
    float minFPS;
    float maxFPS;
    float minZoom;
    float maxZoom;
    int maxWidth;// formatからdemension取得(encoded後、アスペクト比とか関連あるようだ)。実際映像サイズなのか要確認
    int maxHeight;
} CameraFormat;

typedef struct {
    CameraMode mode;
    CameraOrientaion orientaion;
    CameraDataType type;
    CameraImageStabilizationMode isMode;
    CameraPixelFormatType pixelFormat;
    int format;// index in formats setting
    int fps;
    float exposureDuration;
    float exposureValue;
    float iso;
    float offset;
    float bias;
    float zoom;
    CGRect validRect;
//} CameraCurrentSetting;// for auto mode
} CameraSetting;

@interface CaptureImageInfo : NSObject

@property (nonatomic) CMSampleBufferRef sampleBuffer;
@property (nonatomic) UIImage *image;
@property (nonatomic) UIImageOrientation orientation;
@property (nonatomic) CMTime timeStamp;
@property (nonatomic) CGSize size;
@property (nonatomic) CGAffineTransform transfrom;
@property (nonatomic) CameraDataType dataType;

@end

@protocol CameraCaptureObserver <NSObject>

@optional
-(void)imageCaptured:(UIImage*)image;
-(void)captureImageInfo:(CaptureImageInfo*)info;
// todo:add videoCaptured(Recorded)
-(void)activeFormatChanged:(CameraFormat)format;
-(void)currentSettingChanged:(CameraSetting)settings;
-(void)didCalibrate:(CameraSetting)settings;

@end

@interface CameraCapture : NSObject

@property (nonatomic, weak) UIViewController* videoViewController;// ImagePicker関連
@property (nonatomic, weak) UIImageView* imageView;
@property (nonatomic) CGRect validRect;
//@property (nonatomic, retain) id<SignalDataUpdater> dataUpdater;
@property (nonatomic, weak) id<CameraCaptureObserver> cameraObserver;

+(CameraCapture*)getInstance;

-(void)setupCaptureDeviceWithSetting:(CameraSetting)settings;
-(void)startChanging;
-(void)endChanging;
-(void)changeCaptureDeviceSetup:(CameraSetting)settings;// input/output/session/connectionに分ける？
-(BOOL)changeActiveFormatWithIndex:(int)index;
-(void)changeFocusMode:(AVCaptureFocusMode)mode;
-(void)changeVideoZoom:(float)zoom withRate:(float)rate;
-(void)switchFPS:(float)fps;
-(void)changeExposureBias:(float)value;
-(NSString*)changeISO:(float)value;
-(float)changeExposureDuration:(float)value;
-(void)setFocusPoint:(CGPoint)point;
//-(void)setValidRect:(CGRect)rect;// NG.propertyのsetterなので、無限loopになる可能性がある。
-(void)startCapture;
-(void)stopCapture;
-(void)loadVideoFromPicker;
-(void)changeCameraDataType:(CameraDataType)type;

// todo:統一する
-(int)getVideoActiveFormatInFormats:(NSMutableArray*)formats;
-(CameraFormat)getVideoActiveFormatInfo;
-(CameraSetting)getCameraCurrentSettings;

@end

#endif
