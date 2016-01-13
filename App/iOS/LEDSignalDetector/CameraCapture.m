//
//  CameraCapture.m
//  LEDSignal
//
//  Created by 文 光石 on 2014/09/15.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CameraCapture.h"
#import "FileManager.h"
#import "Log.h"

#define QUEUE_SERIAL_VIDEO_CAPTURE "com.threees.tre.led.video-capture"
#define QUEUE_SERIAL_SAMPLING "com.threees.tre.led.sampling"
#define QUEUE_SERIAL_SESSION "com.threees.tre.led.session"

static void *ExposureDurationContext = &ExposureDurationContext;
static void *ISOContext = &ISOContext;
static void *ExposureTargetOffsetContext = &ExposureTargetOffsetContext;

typedef NS_ENUM( NSInteger, CameraManualSetupResult ) {
    CameraManualSetupResultSuccess,
    CameraManualSetupResultCameraNotAuthorized,
    CameraManualSetupResultSessionConfigurationFailed
};

@class Log;

@implementation CaptureImageInfo

-(id)init
{
    if (self = [super init]) {
        _sampleBuffer = nil;
        _size = CGSizeZero;
    }
    
    return self;
}

@end

@interface CameraCapture()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

// todo:strong??
@property (nonatomic, strong) AVCaptureSession* session;
@property (nonatomic, strong) AVCaptureDevice* videoDevice;
@property (nonatomic, strong) AVCaptureVideoDataOutput* videoOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput* movieOutput;
@property (nonatomic) CameraManualSetupResult setupResult;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic) BOOL exposureCheanged;// 露出変更完了後キャプチャする
@property (nonatomic) CameraSetting currentSettings;
@property (nonatomic) BOOL record;

@property (nonatomic) int stabilityCount;
@property (nonatomic) BOOL isCalibrating;

@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) dispatch_queue_t samplingQueue; // For sampling buffer of video captured.

-(void)setupCaptureDevice;
-(float)calculateExposureDurationSecond:(float)value;
-(float)calculateExposureDurationValue:(float)second;
-(void)setCameraCurrentSetting:(CameraSetting)settings;

@end

@implementation CameraCapture

@synthesize session;
@synthesize videoOutput;
@synthesize movieOutput;
@synthesize exposureCheanged;
@synthesize currentSettings;

@synthesize videoViewController;
@synthesize imageView;
@synthesize record;
@synthesize validRect;
//@synthesize dataUpdater;
@synthesize cameraObserver;


static float EXPOSURE_DURATION_POWER = 5; // Higher numbers will give the slider more sensitivity at shorter durations
static float EXPOSURE_MINIMUM_DURATION = 1.0/1000; // Limit exposure duration to a useful range
static int VIDEO_MAXIMUM_FRAME_RATE = 240;


static CameraCapture *sharedInstance = nil;

+(CameraCapture*)getInstance
{
    if (!sharedInstance) {
        sharedInstance = [CameraCapture new];
    }
    return sharedInstance;
}

-(id)init
{
    if (self = [super init]) {
        self.record = NO;
        currentSettings.fps = 30;
        _isCalibrating = YES;
    }
    
    return self;
}

- (void)eventHandler:(id)data
{
    DEBUGLOG(@"AVCaptureSession event : %@", [data name]);
}

-(float)calculateExposureDurationSecond:(float)value
{
    double p = pow( value, EXPOSURE_DURATION_POWER ); // Apply power function to expand slider's low-end range
    double minDurationSeconds = MAX(CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION);
    double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
    double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
    DEBUGLOG(@"durationSec(%f - %f)", minDurationSeconds, maxDurationSeconds);
    
    return (float)newDurationSeconds;
}

-(float)calculateExposureDurationValue:(float)second
{
    double minDurationSeconds = MAX(CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION);
    double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
    // Map from duration to non-linear UI range 0-1
    double p = ( second - minDurationSeconds ) / ( maxDurationSeconds - minDurationSeconds ); // Scale to 0-1
    double value = pow( p, 1 / EXPOSURE_DURATION_POWER ); // Apply inverse power
    
    return (float)value;
}

-(void)setCameraCurrentSetting:(CameraSetting)settings
{
    DEBUGLOG(@"setCameraCurrentSetting");
    /*currentSettings.mode = settings.mode;
    currentSettings.orientaion = settings.orientaion;
    currentSettings.format = settings.format;
    currentSettings.fps = settings.fps;
    currentSettings.exposureValue = settings.exposureValue;
    currentSettings.exposureDuration = [self calculateExposureDurationSecond:settings.exposureValue];
    currentSettings.iso = settings.iso;
    currentSettings.bias = settings.bias;*/
    currentSettings = settings;
    
    DEBUGLOG(@"current bias:%f", currentSettings.bias);
    DEBUGLOG(@"current exposureValue:%f", currentSettings.exposureValue);
    DEBUGLOG(@"current exposureDuration:%f", currentSettings.exposureDuration);
    DEBUGLOG(@"current iso:%f", currentSettings.iso);
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *device = [self videoDevice];
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
            {
                [device setFocusMode:focusMode];
                [device setFocusPointOfInterest:point];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
            {
                [device setExposureMode:exposureMode];
                [device setExposurePointOfInterest:point];
            }
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
        else
        {
            DEBUGLOG(@"%@", error);
        }
    });
}

-(void)addObservers
{
    [self addObserver:self forKeyPath:@"videoDevice.exposureDuration" options:NSKeyValueObservingOptionNew context:ExposureDurationContext];
    [self addObserver:self forKeyPath:@"videoDevice.ISO" options:NSKeyValueObservingOptionNew context:ISOContext];
    [self addObserver:self forKeyPath:@"videoDevice.exposureTargetOffset" options:NSKeyValueObservingOptionNew context:ExposureTargetOffsetContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDevice];
}

-(void)removeObservers
{
    [self removeObserver:self forKeyPath:@"videoDevice.exposureDuration" context:ExposureDurationContext];
    [self removeObserver:self forKeyPath:@"videoDevice.ISO" context:ISOContext];
    [self removeObserver:self forKeyPath:@"videoDevice.exposureTargetOffset" context:ExposureTargetOffsetContext];
}

// for auto mode
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ExposureDurationContext)
    {
        NSString *duration = nil;
        double newDurationSeconds = CMTimeGetSeconds([change[NSKeyValueChangeNewKey] CMTimeValue]);
        //NSLog(@"exposureMode: %ld", self.videoDevice.exposureMode);
        //NSLog(@"newDurationSeconds:%f", newDurationSeconds);
        //NSLog(@"device exposureDuration:%f", CMTimeGetSeconds(self.videoDevice.exposureDuration));
        DEBUGLOG(@"newDurationSeconds:%f", newDurationSeconds);
        DEBUGLOG(@"device exposureDuration:%f", CMTimeGetSeconds(self.videoDevice.exposureDuration));
        
        //if (self.videoDevice.exposureMode != AVCaptureExposureModeCustom) {
        if (currentSettings.mode == CameraModeAuto || currentSettings.mode == CameraModePv) {
            double durationSeconds = [self calculateExposureDurationSecond:newDurationSeconds];
            // todo:別方法で返す
            if ( newDurationSeconds < 1 ) {
                int digits = MAX( 0, 2 + floor( log10( newDurationSeconds ) ) );
                duration = [NSString stringWithFormat:@"1/%.*f", digits, 1/newDurationSeconds];
            } else {
                duration = [NSString stringWithFormat:@"%.2f", newDurationSeconds];
            }
            
            // todo:return by observer method
            if (self.cameraObserver != nil) {
                currentSettings.exposureValue = [self calculateExposureDurationValue:durationSeconds];
                currentSettings.exposureDuration = durationSeconds;
                if ([self.cameraObserver respondsToSelector:@selector(currentSettingChanged:)]) {
                    [self.cameraObserver currentSettingChanged:currentSettings];
                }
            }
        }
    }
    else if (context == ISOContext)
    {
        float newISO = [change[NSKeyValueChangeNewKey] floatValue];
        //NSLog(@"exposureMode: %ld", self.videoDevice.exposureMode);
        //NSLog(@"newISO: %f", newISO);
        //NSLog(@"ISO: %f", self.videoDevice.ISO);
        //NSLog(@"device exposureDuration:%f", CMTimeGetSeconds(self.videoDevice.exposureDuration));
        //NSLog(@"current exposureDuration:%f", CMTimeGetSeconds(AVCaptureExposureDurationCurrent));
        DEBUGLOG(@"newISO: %f", newISO);
        DEBUGLOG(@"device ISO: %f", self.videoDevice.ISO);
        //if (self.videoDevice.exposureMode != AVCaptureExposureModeCustom) {
        if (currentSettings.mode == CameraModeAuto || currentSettings.mode == CameraModeATv) {
            // todo:return by observer method
            // activeFormatが変わった場合、format情報変更通知(plist更新/debug画面更新など)
            if (self.cameraObserver != nil) {
                currentSettings.iso = newISO;
                if ([self.cameraObserver respondsToSelector:@selector(currentSettingChanged:)]) {
                    [self.cameraObserver currentSettingChanged:currentSettings];
                }
            }
        }
    }
    else if (context == ExposureTargetOffsetContext)
    {
        float newExposureTargetOffset = [change[NSKeyValueChangeNewKey] floatValue];
        
        if(self.videoDevice) {
            if ( self.videoDevice.exposureMode == AVCaptureExposureModeCustom ) {
                if (_isCalibrating) {// todo: delete?
                    // todo: not here. use timer?
#if true
                    // todo:ISO上限値によって、暗すぎる場合、もっと高い値のformatに切り替えるd
                    if (currentSettings.mode == CameraModeATv) {// change ISO
                        float currentISO = self.videoDevice.ISO;
                        // todo:差分？0の時が適正露出なので、0との差分で調整
                        float newISO = powf(2, 0 - newExposureTargetOffset) * currentISO;
                        newISO = newISO > self.videoDevice.activeFormat.maxISO? self.videoDevice.activeFormat.maxISO : newISO;
                        newISO = newISO < self.videoDevice.activeFormat.minISO? self.videoDevice.activeFormat.minISO : newISO;
                        
                        CMTime expDuration = CMTimeMakeWithSeconds(currentSettings.exposureDuration, 1000*1000*1000);
                        NSError *error = nil;
                        if ([self.videoDevice lockForConfiguration:&error]) {
                            // memo:AVCaptureExposureDurationCurrentの場合、実際SSが変わってしまう
                            //[self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:newISO completionHandler:^(CMTime syncTime) {}];
                            [self.videoDevice setExposureModeCustomWithDuration:expDuration ISO:newISO completionHandler:^(CMTime syncTime) {}];
                            [self.videoDevice unlockForConfiguration];
                        }
                    } else if (currentSettings.mode == CameraModePv) {// change exposure duration
                    }
#else
                    CGFloat currentISO = self.videoDevice.ISO;
                    CGFloat biasISO = 0;
                    
                    //Assume 0,3 as our limit to correct the ISO
                    if(newExposureTargetOffset > 0.3f) //decrease ISO
                        biasISO = -50;
                    else if(newExposureTargetOffset < -0.3f) //increase ISO
                        biasISO = 50;
                    
                    if(biasISO){
                        //Normalize ISO level for the current device
                        CGFloat newISO = currentISO+biasISO;
                        newISO = newISO > self.videoDevice.activeFormat.maxISO? self.videoDevice.activeFormat.maxISO : newISO;
                        newISO = newISO < self.videoDevice.activeFormat.minISO? self.videoDevice.activeFormat.minISO : newISO;
                        
                        NSError *error = nil;
                        if ([self.videoDevice lockForConfiguration:&error]) {
                            [self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:newISO completionHandler:^(CMTime syncTime) {}];
                            [self.videoDevice unlockForConfiguration];
                        }
                    }
#endif
                } else {
                    if (currentSettings.mode == CameraModeATv) {// change ISO
                        // todo:ss/isoが固定になっている場合、環境によって、EVが大幅(とりあえず適当に+/-2EV)変わった時調整
                        if (fabsf(newExposureTargetOffset) >= 2) {
                            float currentISO = self.videoDevice.ISO;
                            // todo:差分？0の時が適正露出なので、0との差分で調整
                            float newISO = powf(2, 0 - newExposureTargetOffset) * currentISO;
                            newISO = newISO > self.videoDevice.activeFormat.maxISO? self.videoDevice.activeFormat.maxISO : newISO;
                            newISO = newISO < self.videoDevice.activeFormat.minISO? self.videoDevice.activeFormat.minISO : newISO;
                            
                            CMTime expDuration = CMTimeMakeWithSeconds(currentSettings.exposureDuration, 1000*1000*1000);
                            NSError *error = nil;
                            if ([self.videoDevice lockForConfiguration:&error]) {
                                // memo:AVCaptureExposureDurationCurrentの場合、実際SSが変わってしまう
                                //[self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:newISO completionHandler:^(CMTime syncTime) {}];
                                [self.videoDevice setExposureModeCustomWithDuration:expDuration ISO:newISO completionHandler:^(CMTime syncTime) {}];
                                [self.videoDevice unlockForConfiguration];
                            }
                        }
                    }
                }
            }
        }
        
        if (self.cameraObserver != nil) {
            currentSettings.offset = newExposureTargetOffset;
            if ([self.cameraObserver respondsToSelector:@selector(currentSettingChanged:)]) {
                [self.cameraObserver currentSettingChanged:currentSettings];
            }
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

-(void)setupCaptureDevice
{
    // test
    self.record = NO;
    
    self.exposureCheanged = NO;
    
    
    
    dispatch_queue_t samplingQueue = dispatch_queue_create(QUEUE_SERIAL_SAMPLING, DISPATCH_QUEUE_SERIAL);
    [self setSamplingQueue:samplingQueue];
    
    //セッション作成
    self.session = [[AVCaptureSession alloc] init];
    
    
    // from AVCamManual
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
    
    dispatch_queue_t sessionQueue = dispatch_queue_create(QUEUE_SERIAL_SESSION, DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];
    
    self.setupResult = CameraManualSetupResultSuccess;
    
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session setup until the access request has completed to avoid
            // asking the user for audio access if video access is denied.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = CameraManualSetupResultCameraNotAuthorized;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        default:
        {
            // The user has previously denied access.
            self.setupResult = CameraManualSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    dispatch_async(self.sessionQueue, ^{// async:not blocked(context returned soon) for procsuring seral queue
        
        if ( self.setupResult != CameraManualSetupResultSuccess ) {
            return;
        }
        
        // test
        NSArray *devices = [AVCaptureDevice devices];
        for (AVCaptureDevice *device in devices) {
            DEBUGLOG(@"Device name: %@", [device localizedName]);
            if ([device hasMediaType:AVMediaTypeVideo]) {
                if ([device position] == AVCaptureDevicePositionBack) {
                    DEBUGLOG(@"Device position : back");
                } else {
                    DEBUGLOG(@"Device position : front");
                }
            }
        }
        
        //デバイス取得
        self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if (self.videoDevice != nil) {
            DEBUGLOG(@"AVCaptureDevice: %@", [self.videoDevice localizedName]);
            
            NSArray *events = [NSArray arrayWithObjects:
                               AVCaptureSessionRuntimeErrorNotification,
                               AVCaptureSessionErrorKey,
                               AVCaptureSessionDidStartRunningNotification,
                               AVCaptureSessionDidStopRunningNotification,
                               AVCaptureSessionWasInterruptedNotification,
                               AVCaptureSessionInterruptionEndedNotification,
                               nil];
            
            for (id e in events) {
                [[NSNotificationCenter defaultCenter]
                 addObserver:self
                 selector:@selector(eventHandler:)
                 name:e
                 object:session];
            }
            
            
#if 1
            // input/outputではないので、不要かも
            //[self.session beginConfiguration];
            NSError *error = nil;
            
            if ([self.videoDevice lockForConfiguration:&error] == YES) {
                // 露出モード(シャッタスピード、ISO)設定
                // todo:fpsに影響が出るので、exposureDuration > (minFrameDuration=maxFrameDuration)にならないようにチェック
                if ([self.videoDevice isExposureModeSupported:AVCaptureExposureModeCustom]) {
                    //self.videoDevice.exposureMode = AVCaptureExposureModeCustom;
                }
                DEBUGLOG(@"active format:%@", self.videoDevice.activeFormat);
                
                DEBUGLOG(@"exposureMode: %ld", self.videoDevice.exposureMode);
                DEBUGLOG(@"ISO: %f", self.videoDevice.ISO);
                DEBUGLOG(@"exposureDuration: %f", CMTimeGetSeconds(self.videoDevice.exposureDuration));
                DEBUGLOG(@"bias: %f", self.videoDevice.exposureTargetBias);
                DEBUGLOG(@"offset: %f", self.videoDevice.exposureTargetOffset);
                
                // todo: foucus(とりあえず自動)
                if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                    self.videoDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
                }
                DEBUGLOG(@"focusMode: %ld", self.videoDevice.focusMode);
                
                [self.videoDevice unlockForConfiguration];
            }
#else
            NSError *error = nil;
            AVCaptureDeviceFormat *selectedFormat = nil;
            //AVFrameRateRange *selectedFrameRateRange = nil;
            
            // todo:formatsからactiveFormatを選ぶ
            DEBUGLOG(@"active format:%@", self.videoDevice.activeFormat);
            
            // @memo 先にactiveFormatを設定したほうが安全
            // 最大fps=240のformatを選択(420v/f?とりあえず、最初に見つかったformat)
            for (AVCaptureDeviceFormat *format in [self.videoDevice formats]) {
                DEBUGLOG(@"format:%@", format);
                CMFormatDescriptionRef desc = format.formatDescription;
                // AVCaptureDeviceFormatに映像サイズがないので(静止サイズはある)、下記の方法で取得
                CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
                //DEBUGLOG(@"format:%@ dimensions:(%d x %d)", format, dimensions.width, dimensions.height);
                
                for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                    DEBUGLOG(@"frame[%f, %f] demensions[%d, %d]", range.minFrameRate, range.maxFrameRate, dimensions.width, dimensions.height);
                    // todo:widthについて再検討。最大解像度になっている。画像が拡大されている。切出し？zoom?
                    if (range.maxFrameRate == VIDEO_MAXIMUM_FRAME_RATE) {
                        selectedFormat = format;
                        //selectedFrameRateRange = range;
                        break;
                    }
                }
                
                if (selectedFormat != nil) {
                    break;
                }
            }
            
            // todo:複数同時設定時(batch).nestしてもok.範囲を最小限にする? activeFormatとmin/maxDurationは同時に設定する必要がある。
            [self.session beginConfiguration];
            
            if ([self.videoDevice lockForConfiguration:&error] == YES) {
                // format/fps設定
                if (selectedFormat != nil) {
                    self.videoDevice.activeFormat = selectedFormat;
                    self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, self.cameraSettings.fps);
                    self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, self.cameraSettings.fps);
                }
                DEBUGLOG(@"minFrame:[%lld, %d, %d, %lld]", self.videoDevice.activeVideoMinFrameDuration.epoch, self.videoDevice.activeVideoMinFrameDuration.flags, self.videoDevice.activeVideoMinFrameDuration.timescale, self.videoDevice.activeVideoMinFrameDuration.value);
                DEBUGLOG(@"maxFrame:[%lld, %d, %d, %lld]", self.videoDevice.activeVideoMaxFrameDuration.epoch, self.videoDevice.activeVideoMaxFrameDuration.flags, self.videoDevice.activeVideoMaxFrameDuration.timescale, self.videoDevice.activeVideoMaxFrameDuration.value);
                DEBUGLOG(@"active format:%@", selectedFormat);
                
                // 露出モード(シャッタスピード、ISO)設定
                // todo:fpsに影響が出るので、exposureDuration > (minFrameDuration=maxFrameDuration)にならないようにチェック
                if ([self.videoDevice isExposureModeSupported:AVCaptureExposureModeCustom]) {
                    self.videoDevice.exposureMode = AVCaptureExposureModeCustom;
                    /* todo:前回設定値(configから)
                    DEBUGLOG(@"cameraSettings.exposureDuration: %f", self.cameraSettings.exposureDuration);
                    double exposureDuration = [self calculateExposureDurationSecond:self.cameraSettings.exposureDuration];
                    [self.videoDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds(exposureDuration, 1000*1000*1000) ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
                        // todo:スレッドが違うので、方法検討
                        self.exposureCheanged = YES;
                    }];
                     */
                }
                DEBUGLOG(@"exposureMode: %ld", self.videoDevice.exposureMode);
                DEBUGLOG(@"ISO: %f", self.videoDevice.ISO);
                
                // todo: foucus(とりあえず自動)
                if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                    self.videoDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
                }
                DEBUGLOG(@"focusMode: %ld", self.videoDevice.focusMode);
                
                // zoomin
                //float zoomFactor = 1.0f;
                //float zoomRate = 1.0f;
                if ([self.videoDevice isRampingVideoZoom] == NO) {// zoom中ではない
                    // 最大光学zoom?
                    self.videoDevice.videoZoomFactor = self.videoDevice.activeFormat.videoZoomFactorUpscaleThreshold;
                    // 一定速度(rate)でzoom移動
                    //[device rampToVideoZoomFactor:zoomFactor withRate:zoomRate];
                    //[self.videoDevice unlockForConfiguration];
                }
                
                DEBUGLOG(@"videoZoomFactor: %f", self.videoDevice.videoZoomFactor);
                
                // test(照明)
                /*
                 if ([device hasTorch] == YES) {
                 if ([device isTorchModeSupported:AVCaptureTorchModeOn] == YES) {
                 device.torchMode = AVCaptureTorchModeOn;
                 [device unlockForConfiguration];
                 DEBUGLOG(@"AVCaptureTorchModeOn");
                 }
                 }
                 */
                
                DEBUGLOG(@"lensAperture: %f", self.videoDevice.lensAperture);
                
                [self.videoDevice unlockForConfiguration];
            }
#endif
            
            
            // todo:範囲を最小限にする? activeFormatとmin/maxDurationは同時に設定する必要がある。
            // clients may add or remove outputs, alter the sessionPreset, or configure individual AVCaptureInput or Output properties.
            // input/outputをまとめて設定
            [self.session beginConfiguration];
            
            //入力作成
            //背面カメラ.AVCaptureDviceが無いiOSシミュレーターではdeviceがnil.落ちる
            AVCaptureDeviceInput* deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:NULL];
            if (deviceInput != nil) {
                if ([self.session canAddInput:deviceInput]) {
                    [self.session addInput:deviceInput];
                    DEBUGLOG(@"add input device");
                } else {
                    self.setupResult = CameraManualSetupResultSessionConfigurationFailed;
                }
            }
            
            //ビデオデータ出力作成
            //AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
            self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
            if (videoOutput != nil) {
                if ([self.session canAddOutput:videoOutput]) {
                    [self.session addOutput:videoOutput];
                    DEBUGLOG(@"add output device");
                }
                
                // todo:色空間について検討(パフォーマンス影響あるか)
                // Each pixel in that format has one byte for blue, green, red, and alpha, in that order.
                // Other supported colorspaces are kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange and kCVPixelFormatType_420YpCbCr8BiPlanarFullRange on newer devices and kCVPixelFormatType_422YpCbCr8 on the iPhone 3G. The VideoRange or FullRange suffix simply indicates whether the bytes are returned between 16 - 235 for Y and 16 - 240 for UV or full 0 - 255 for each component.
                NSDictionary* settings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
                if (currentSettings.pixelFormat == CameraPixelFormatTypeBGR) {
                    settings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_24BGR]};// memo:error.is not a supported pixel format type.
                }
                //NSDictionary* settings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
                videoOutput.videoSettings = settings;
                //videoOutput.minFrameDuration = CMTimeMake(1, 15);//@memo 実際出力最小fps.deprecated (15fps) activeVideoMinFrameDurationで設定
                
                // ビデオ出力のキャプチャの画像情報のキューを設定(todo:終了時リリースdispatch_release(queue))
                //dispatch_queue_t queue = dispatch_queue_create("LEDQ", NULL);
                dispatch_queue_t queue = dispatch_queue_create(QUEUE_SERIAL_VIDEO_CAPTURE, DISPATCH_QUEUE_SERIAL);
                [videoOutput setSampleBufferDelegate:self queue:queue];
                //[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
                
                // YES(default):場合によって、frameが処理されず破棄される可能性がある？
                // frameが破棄されると信号周期と同期が取れないので、とりあえずNOにして、破棄されないようにする(100%保証？)
                // todo:破棄される場合、callbackが呼ばれない？呼ばれない場合、fps(単位時間)で破棄されたかどうか(callbackの呼ばれた時間)の判断が必要かも
                //[videoOutput setAlwaysDiscardsLateVideoFrames:YES];
                [videoOutput setAlwaysDiscardsLateVideoFrames:NO];
            }
            
            // ビデオファイル出力作成
            if (self.record == YES) {
                self.movieOutput = [[AVCaptureMovieFileOutput alloc] init];
                if (self.movieOutput != nil) {
                    if ([self.session canAddOutput:self.movieOutput]) {
                        [self.session addOutput:self.movieOutput];
                    }
                    
                    CMTime maxDuration = CMTimeMakeWithSeconds(60, 600);
                    self.movieOutput.maxRecordedDuration = maxDuration;
                    //self.movieOutput.minFreeDiskSpaceLimit = 500000000;
                }
            }
            
            AVCaptureConnection *videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
            if (videoConnection != nil) {
                // カメラの向きを設定する
                if ([videoConnection isVideoOrientationSupported]) {
                    if (currentSettings.orientaion == CameraOrientaionPortrait) {
                        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                        DEBUGLOG(@"AVCaptureVideoOrientationPortrait:%ld", (long)videoConnection.videoOrientation);
                    } else if (currentSettings.orientaion == CameraOrientaionLandscape) {
                        [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                        DEBUGLOG(@"AVCaptureVideoOrientationLandscapeRight:%ld", (long)videoConnection.videoOrientation);
                    }
                    // memo:デフォルト向きにする。向きを設定すると、物理的(バッファー)向き変換が行われるので、パフォーマンスが落ちる。向き情報を保存し、画像処理で合わせる
                    // default:LandscapeRight
                    DEBUGLOG(@"AVCaptureVideoOrientation:%ld", (long)videoConnection.videoOrientation);
                }
                
                if ([videoConnection isVideoStabilizationSupported]) {
                    if (currentSettings.isMode == CameraImageStabilizationModeOn) {
                        videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                    }
                }
                
                if ([videoConnection isEnabled] == NO) {
                    // outputDeviceで処理されるかどうかのフラグ?NOを設定した場合、streamが止まる
                    videoConnection.enabled = YES;// デフォルトでYES
                }
                DEBUGLOG(@"videoConnection.enabled: %d", videoConnection.enabled);
                
                //[videoConnection setVideoMinFrameDuration:CMTimeMake(1, 4)];//@memo 実際出力最小fps. deprecated 1/4(4fps) activeVideoMinFrameDurationで設定
                
                DEBUGLOG(@"videoMaxScaleAndCropFactor: %f", videoConnection.videoMaxScaleAndCropFactor);
                DEBUGLOG(@"videoScaleAndCropFactor: %f", videoConnection.videoScaleAndCropFactor);
            }
            
            // todo: パフォーマンスが落ちる場合、画質を調整
            if ([self.session canSetSessionPreset:AVCaptureSessionPresetMedium] == YES) {
                // @memo activeFormatと相互排他になるので、設定しない
                // todo:ただ、設定しないと、画像サイズが1920x1080になり、表示が拡大されて表示される！
                // inputDevice:1280x720->1920x1080(zoomin)->598x375(center-crop)
                // callbackで生データから表示サイズ588x375のImage作成？そもそも1920x1080で画像が拡大される...?
                // sessionPresetを設定しても、上で設定したactiveFormatが変わらない(outがinの範囲内から？)ので、とりあえず設定。
                //self.session.sessionPreset = AVCaptureSessionPresetMedium;
                //DEBUGLOG(@"AVCaptureSessionPresetMedium");
            }
            
            // activeFormatを変更する場合、自動的にAVCaptureSessionPresetInputPriorityが設定されるらしい？
            if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh] == YES) {
                self.session.sessionPreset = AVCaptureSessionPresetHigh;
                DEBUGLOG(@"AVCaptureSessionPresetHigh");
            }
            
            //DEBUGLOG(@"active format:%@", selectedFormat);
            DEBUGLOG(@"exposureMode: %ld", self.videoDevice.exposureMode);
            DEBUGLOG(@"ISO: %f", self.videoDevice.ISO);
            DEBUGLOG(@"videoZoomFactor: %f", self.videoDevice.videoZoomFactor);
            
            [self.session commitConfiguration];
            
            /* todo:未確認
             AVCaptureVideoPreviewLayer* videoLayer = (AVCaptureVideoPreviewLayer*)[AVCaptureVideoPreviewLayer layerWithSession:self.session];
             if (videoLayer != nil) {
             videoLayer.frame = self.videoViewController.view.bounds;
             videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
             [self.videoViewController.view.layer addSublayer:videoLayer];
             }
             */
            
            /*
             // カメラへのアクセス確認
             NSString *mediaType = AVMediaTypeVideo;
             [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
             if (granted)
             {
             //Granted access to mediaType
             [self setDeviceAuthorized:YES];
             }
             else {
             //Not granted access to mediaType
             dispatch_async(dispatch_get_main_queue(), ^{
             [[[UIAlertView alloc] initWithTitle:@"AVCam!"
             message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
             ￼￼￼delegate:self
             cancelButtonTitle:@"OK"
             otherButtonTitles:nil] show];
             [self setDeviceAuthorized:NO];
             });
             }
             }];
             */
            
#if 0
            // UIを操作する場合、mainスレッドで行う
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.cameraObserver != nil) {
                    CameraFormat format = { 0 };
                    format.minExposureOffset = self.videoDevice.minExposureTargetOffset;
                    format.maxExposureOffset = self.videoDevice.maxExposureTargetOffset;
                    format.minExposureBias = self.videoDevice.minExposureTargetBias;
                    format.maxExposureBias = self.videoDevice.maxExposureTargetBias;
                    format.minISO = self.videoDevice.activeFormat.minISO;
                    format.maxISO = self.videoDevice.activeFormat.maxISO;
                    //format.minExposureDuration = self.videoDevice.activeFormat.minExposureDuration;
                    format.minFPS = 2;
                    for (AVFrameRateRange *range in self.videoDevice.activeFormat.videoSupportedFrameRateRanges) {
                        if (format.maxFPS < range.maxFrameRate) {
                            format.maxFPS = range.maxFrameRate;
                        }
                    }
                    format.minZoom = 1.0;
                    format.maxZoom = self.videoDevice.activeFormat.videoZoomFactorUpscaleThreshold;
                    //format.maxZoom = self.videoDevice.activeFormat.videoMaxZoomFactor;
                    
                    [self.cameraObserver activeFormatChanged:format];
                }
            });
#endif
            /*
            CameraCurrentSetting currentSettings;
            currentSettings.iso = self.videoDevice.ISO;
            currentSettings.bias = self.videoDevice.exposureTargetBias;
            [self.cameraObserver currentSettingChanged:currentSettings];
            */
        }
    });
    
    
}

-(void)startChanging
{
    _isCalibrating = YES;
}

-(void)endChanging
{
    _isCalibrating = NO;
}

-(void)changeCameraDataType:(CameraDataType)type
{
    currentSettings.type = type;
}

-(void)setupCaptureDeviceWithSetting:(CameraSetting)settings
{
    [self setCameraCurrentSetting:settings];
    [self setupCaptureDevice];
    
    // then change setup
    if (settings.mode != CameraModeAuto) {
        [self changeCaptureDeviceSetup:settings];
    }
}

-(void)changeCaptureDeviceSetup:(CameraSetting)settings
{
    //[self setCameraCurrentSetting:settings];

    // current settings may be changed when active format was changed.
    [self changeActiveFormatWithIndex:currentSettings.format];
    //[self changeExposureDuration:currentSettings.exposureValue];
    //[self changeISO:currentSettings.iso];
    //[self changeExposureBias:currentSettings.bias];
    //[self switchFPS:currentSettings.fps];
    
    //[self changeFocusMode:AVCaptureFocusModeAutoFocus];// auto
    //[self changeVideoZoom:(float) withRate:(float)];// none
    
    _isCalibrating = YES;
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(exposureCalibrated:) userInfo:nil repeats:NO];
}

-(void)exposureCalibrated:(NSTimer*)timer
{
    _isCalibrating = NO;
}

-(BOOL)changeActiveFormatWithIndex:(int)index
{
    __block BOOL ret = NO;
    
    DEBUGLOG(@"changeActiveFormatWithIndex");
    dispatch_async(self.sessionQueue, ^{
        if (self.videoDevice != nil) {
            NSError *error = nil;
            for (int i = 0; i < [[self.videoDevice formats] count]; i++) {
                // todo:check format and current settings
                if (i == index) {
                    CameraSetting activeSettings = currentSettings;
                    AVCaptureDeviceFormat *format = (AVCaptureDeviceFormat*)[[self.videoDevice formats] objectAtIndex:index];
                    DEBUGLOG(@"format[%d]:%@", i, format);
                    DEBUGLOG(@"before");
                    DEBUGLOG(@"current bias:%f", currentSettings.bias);
                    DEBUGLOG(@"current offset:%f", currentSettings.offset);
                    DEBUGLOG(@"current exposureValue:%f", currentSettings.exposureValue);
                    DEBUGLOG(@"current exposureDuration:%f", currentSettings.exposureDuration);
                    DEBUGLOG(@"current iso:%f", currentSettings.iso);
                    DEBUGLOG(@"device exposureTargetBias:%f", self.videoDevice.exposureTargetBias);
                    DEBUGLOG(@"device exposureDuration:%f", CMTimeGetSeconds(self.videoDevice.exposureDuration));
                    DEBUGLOG(@"device ISO:%f", self.videoDevice.ISO);
                    CMFormatDescriptionRef desc = format.formatDescription;
                    // AVCaptureDeviceFormatに映像サイズがないので(静止サイズはある)、下記の方法で取得
                    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
                    //DEBUGLOG(@"format:%@ dimensions:(%d x %d)", format, dimensions.width, dimensions.height);
                    
                    float currentFps = activeSettings.fps;
                    // 実際1rangeしかない?
                    for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                        DEBUGLOG(@"frame[%f, %f] demensions[%d, %d]", range.minFrameRate, range.maxFrameRate, dimensions.width, dimensions.height);
                        // todo:widthについて再検討。最大解像度になっている。画像が拡大されている。切出し？zoom?
                        
                        // 範囲内にあるまでloop。ない場合、最後のrangeの最小/最大値を取る
                        currentFps = currentSettings.fps;
                        if (currentFps < range.minFrameRate) {
                            currentFps = range.minFrameRate;
                        } else if (currentFps > range.maxFrameRate) {
                            currentFps = range.maxFrameRate;
                        } else {
                            break;
                        }
                    }
                    activeSettings.fps = currentFps;
                    
                    // check ISO
                    float currentISO = activeSettings.iso;
                    // todo:差分？
                    float currentOffset = activeSettings.offset;
                    float newISO = powf(2, 0 - currentOffset) * currentISO;
                    DEBUGLOG(@"ISO:[%.1f-%.1f]", format.minISO, format.maxISO);
                    if (newISO < format.minISO) {
                        newISO = format.minISO;
                    } else if (newISO > format.maxISO) {
                        newISO = format.maxISO;
                    }
                    activeSettings.iso = newISO;
                    
                    // check Bias
                    if (currentSettings.bias < self.videoDevice.minExposureTargetBias) {
                        activeSettings.bias = self.videoDevice.minExposureTargetBias;
                    } else if (currentSettings.bias > self.videoDevice.maxExposureTargetBias) {
                        activeSettings.bias = self.videoDevice.maxExposureTargetBias;
                    }
                    
                    // check exposureDuration
                    DEBUGLOG(@"SS:[%.6f-%.6f]", CMTimeGetSeconds(format.minExposureDuration), CMTimeGetSeconds(format.maxExposureDuration));
                    //float minValue = [self calculateExposureDurationValue:CMTimeGetSeconds(format.minExposureDuration)];
                    //float maxValue = [self calculateExposureDurationValue:CMTimeGetSeconds(format.maxExposureDuration)];
                    // the range is 0-1
                    float minValue = 0.0;
                    float maxValue = 1.0;
                    if (currentSettings.exposureValue < minValue) {
                        activeSettings.exposureValue = minValue;
                    } else if (currentSettings.exposureValue > maxValue) {
                        activeSettings.exposureValue = maxValue;
                    }
                    //activeSettings.exposureDuration = [self calculateExposureDurationSecond:activeSettings.exposureValue];
                    
                    activeSettings.offset = self.videoDevice.exposureTargetOffset;
                    // 最大光学倍率の半分か1
                    // memo:最大光学倍率よりも出力映像サイズがセンサーサイズより小さい場合、どうscalingするか。
                    //      センサーサイズより小さい場合、中心から出力サイズ分切り取って、zoomに縮小する(thresholdの場合、縮小なし。以上の場合拡大->画質落ちる)
                    activeSettings.zoom = MAX(format.videoZoomFactorUpscaleThreshold / 2, 1.0);
                    // memo:手ぶれがひどくなるので
                    //activeSettings.zoom = format.videoZoomFactorUpscaleThreshold;
                    
                    // todo:範囲を最小限にする? activeFormatとmin/maxDurationは同時に設定する必要がある。
                    // 先にactiveFormatを設定してからその他を設定
                    // memo:ISOとSSは別々関数で設定(お互い現在値)しているので、同時反映時実際値が変わらないかも。
                    // 両方値を設定する関数を追加するか、begin/commitをなくす（FPSは関数内でbegin/commitする）。
                    //[self.session beginConfiguration];
                    if ([self.videoDevice lockForConfiguration:&error]) {
                        
                        if ([self.videoDevice isExposureModeSupported:AVCaptureExposureModeCustom]) {
                            // set after calibration
                            self.videoDevice.exposureMode = AVCaptureExposureModeCustom;
                        }
                        self.videoDevice.activeFormat = format;
                        //self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, currentSettings.fps);
                        //self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, currentSettings.fps);
                        [self.videoDevice unlockForConfiguration];
                        
                        currentSettings.format = index;
                    }
                    
                    DEBUGLOG(@"active bias:%f", activeSettings.bias);
                    DEBUGLOG(@"active offset:%f", activeSettings.offset);
                    DEBUGLOG(@"active exposureValue:%f", activeSettings.exposureValue);
                    DEBUGLOG(@"active exposureDuration:%f", activeSettings.exposureDuration);
                    DEBUGLOG(@"active iso:%f", activeSettings.iso);
                    
                    DEBUGLOG(@"sessionPreset:%@", self.session.sessionPreset);
                    
                    //[self changeExposureBias:activeSettings.bias];
                    
                    //[self changeExposureDuration:activeSettings.exposureValue];
                    //[self changeISO:activeSettings.iso];
                    // @memo:ISOとssは設定完了まで時間がかかるので、お互いの現在値で別々に設定すると、
                    // 両方共現在値(現activeFormatデフォルト値)になるので、設定が反映されない。
                    // 同時に設定するか、それぞれ設定完了(ハンドルあり)してから設定する必要がある。とりあえず前者で対応
                    [self changeExposureWithDuration:activeSettings.exposureValue ISO:activeSettings.iso];
                    [self changeVideoZoom:activeSettings.zoom withRate:0];
                    //[self switchFPS:activeSettings.fps];// todo:activeFormatと同時設定。現状固定で良いので、とりあえず設定しない
                    
                    //[self.session commitConfiguration];
                    
                    //currentSettings = activeSettings;// set above (changexxx)
                    DEBUGLOG(@"after");
                    DEBUGLOG(@"current bias:%f", currentSettings.bias);
                    DEBUGLOG(@"current offset:%f", currentSettings.offset);
                    DEBUGLOG(@"current exposureValue:%f", currentSettings.exposureValue);
                    DEBUGLOG(@"current exposureDuration:%f", currentSettings.exposureDuration);
                    DEBUGLOG(@"current iso:%f", currentSettings.iso);
                    DEBUGLOG(@"device exposureTargetBias:%f", self.videoDevice.exposureTargetBias);
                    DEBUGLOG(@"device exposureTargetOffset:%f", self.videoDevice.exposureTargetOffset);
                    DEBUGLOG(@"device exposureDuration:%f", CMTimeGetSeconds(self.videoDevice.exposureDuration));
                    DEBUGLOG(@"device ISO:%f", self.videoDevice.ISO);
                    // activeFormatが変わった場合、format情報変更通知(plist更新/debug画面更新など)
                    if (self.cameraObserver != nil) {
                        //dispatch_async(dispatch_get_main_queue(), ^{
                        CameraFormat format = [self getVideoActiveFormatInfo];
                        if ([self.cameraObserver respondsToSelector:@selector(activeFormatChanged:)]) {
                            [self.cameraObserver activeFormatChanged:format];
                        }
                        
                        if ([self.cameraObserver respondsToSelector:@selector(currentSettingChanged:)]) {
                            [self.cameraObserver currentSettingChanged:currentSettings];
                        }
                        //});
                    }
                    
                    //return YES;
                    ret = YES;
                    break;
                }
            }
        }
    });
    
    return ret;
}

-(void)changeFocusMode:(AVCaptureFocusMode)mode
{
    NSError *error = nil;
    
    if (self.videoDevice != nil) {
        // todo: foucus(とりあえず自動)
        if ([self.videoDevice isFocusModeSupported:mode]) {
            if ([self.videoDevice lockForConfiguration:&error]) {
                self.videoDevice.focusMode = mode;
                [self.videoDevice unlockForConfiguration];
            }
        }
        
        DEBUGLOG(@"focusMode: %ld", (long)self.videoDevice.focusMode);
    }
}

-(void)changeVideoZoom:(float)zoom withRate:(float)rate
{
    NSError *error = nil;
    
    if (self.videoDevice != nil) {
        if ([self.videoDevice isRampingVideoZoom] == NO) {// zoom中ではない
            if ([self.videoDevice lockForConfiguration:&error]) {
                // 最大光学zoom?
                //self.videoDevice.videoZoomFactor = self.videoDevice.activeFormat.videoZoomFactorUpscaleThreshold;
                // 一定速度(rate)でzoom移動
                if (rate > 0) {
                    [self.videoDevice rampToVideoZoomFactor:zoom withRate:rate];
                } else {
                    self.videoDevice.videoZoomFactor = zoom;
                }
                [self.videoDevice unlockForConfiguration];
                currentSettings.zoom = zoom;
            }
        }
        
        DEBUGLOG(@"videoZoomFactor: %f", self.videoDevice.videoZoomFactor);
    }
}

// todo:check range
// AVCaptureExposureModeCustomの場合、exposureTargetOffsetに影響があるが、全体露出に影響がない(duration/ISOを自動変更できないので)
-(void)changeExposureBias:(float)value
{
    NSError *error = nil;
    
    if (self.videoDevice != nil) {
        if (self.videoDevice.exposureMode == AVCaptureExposureModeCustom) {
            if ([self.videoDevice lockForConfiguration:&error]) {
                [self.videoDevice setExposureTargetBias:value completionHandler:nil];
                [self.videoDevice unlockForConfiguration];
                DEBUGLOG(@"exposureTargetBias: %f changed.", self.videoDevice.exposureTargetBias);
                currentSettings.bias = value;
            } else {
                DEBUGLOG(@"%@", error);
            }
        }
    }
}

// todo:check range
-(NSString*)changeISO:(float)value
{
    NSError *error = nil;
    NSString *strISO = nil;
    
    if (self.videoDevice != nil) {
        if (self.videoDevice.exposureMode == AVCaptureExposureModeCustom) {
            //float isoValue = self.videoDevice.activeFormat.minISO + (self.videoDevice.activeFormat.maxISO - self.videoDevice.activeFormat.minISO) * value;
            if ([self.videoDevice lockForConfiguration:&error]) {
                [self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:value completionHandler:nil];
                [self.videoDevice unlockForConfiguration];
                DEBUGLOG(@"ISO: %f changed.", self.videoDevice.ISO);
                currentSettings.iso = value;
                strISO = [NSString stringWithFormat:@"ISO: %f changed.", self.videoDevice.ISO];
            } else {
                DEBUGLOG(@"%@", error);
            }
        }
    }
    
    return strISO;
}

// todo:check range
// 0の場合、変更なしと判断(duration/ISOは正数になっているが、biasは?todo:調査)
-(float)changeExposureDuration:(float)value
{
    NSError *error = nil;
    float durationSeconds = -1;
    
    if (self.videoDevice != nil) {
        //DEBUGLOG(@"active format:%@", self.videoDevice.activeFormat);
        
        durationSeconds = [self calculateExposureDurationSecond:value];
        
        if (self.videoDevice.exposureMode == AVCaptureExposureModeCustom) {
            if ([self.videoDevice lockForConfiguration:&error]) {
                CMTime expDuration = CMTimeMakeWithSeconds(durationSeconds, 1000*1000*1000);
                [self.videoDevice setExposureModeCustomWithDuration:expDuration ISO:AVCaptureISOCurrent completionHandler:nil];
                [self.videoDevice unlockForConfiguration];
                DEBUGLOG(@"exposureDuration: %f changed.", CMTimeGetSeconds(self.videoDevice.exposureDuration));
                
                currentSettings.exposureValue = value;
                currentSettings.exposureDuration = durationSeconds;
                
                DEBUGLOG(@"exposureValue:%f", currentSettings.exposureValue);
                DEBUGLOG(@"exposureDuration:%f", currentSettings.exposureDuration);
                DEBUGLOG(@"exposureDuration(sec):%f", CMTimeGetSeconds(expDuration));

                // todo:別方法で返す
                /*
                if ( durationSeconds < 1 ) {
                    int digits = MAX( 0, 2 + floor( log10( durationSeconds ) ) );
                    DEBUGLOG(@"digits:%d", digits);
                    duration = [NSString stringWithFormat:@"1/%.*f", digits, 1/durationSeconds];
                    DEBUGLOG(@"duration:%@", duration);
                } else {
                    duration = [NSString stringWithFormat:@"%.2f", durationSeconds];
                }*/
            } else {
                DEBUGLOG(@"%@", error);
            }
        }
    }
    
    return durationSeconds;
}

-(float)changeExposureWithDuration:(float)duration ISO:(float)iso
{
    NSError *error = nil;
    float durationSeconds = -1;
    
    if (self.videoDevice != nil) {
        //DEBUGLOG(@"active format:%@", self.videoDevice.activeFormat);
        
        durationSeconds = [self calculateExposureDurationSecond:duration];
        
        if (self.videoDevice.exposureMode == AVCaptureExposureModeCustom) {
            if ([self.videoDevice lockForConfiguration:&error]) {
                CMTime expDuration = CMTimeMakeWithSeconds(durationSeconds, 1000*1000*1000);
                [self.videoDevice setExposureModeCustomWithDuration:expDuration ISO:iso completionHandler:^(CMTime syncTime) {
                    
                }];
                [self.videoDevice unlockForConfiguration];
                DEBUGLOG(@"exposureDuration: %f changed.", CMTimeGetSeconds(self.videoDevice.exposureDuration));
                DEBUGLOG(@"ISO: %f changed.", self.videoDevice.ISO);
                
                currentSettings.iso = iso;
                currentSettings.exposureValue = duration;
                currentSettings.exposureDuration = durationSeconds;
                
                DEBUGLOG(@"exposureValue:%f", currentSettings.exposureValue);
                DEBUGLOG(@"exposureDuration:%f", currentSettings.exposureDuration);
                DEBUGLOG(@"exposureDuration(sec):%f", CMTimeGetSeconds(expDuration));
                
            } else {
                DEBUGLOG(@"%@", error);
            }
        }
    }
    
    return durationSeconds;
}

// todo:check range
// todo:activeFormatと同時に設定
-(void)switchFPS:(float)fps
{
    // sessionの設定などがないので、わざわざ停止する必要はない？
    //if (self.session.isRunning) {
    //    [self.session stopRunning];
    //}
    
    //AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (self.videoDevice != nil) {
        //DEBUGLOG(@"active format:%@", self.videoDevice.activeFormat);
        //CGFloat fps = strFPS.doubleValue;
#if true
        // todo:シャッタースピードに影響が出る可能性があるば、fps優先なので、問題無い。ただ、SSが変わった時、通知/表示?する
        if ([self.videoDevice lockForConfiguration:nil]) {
            self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)fps);
            self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)fps);
            [self.videoDevice unlockForConfiguration];
            currentSettings.fps = fps;
        }
#else
        AVCaptureDeviceFormat *selectedFormat = nil;
        int32_t maxWidth = 0;
        AVFrameRateRange *frameRateRange = nil;
        
        for (AVCaptureDeviceFormat *format in [self.videoDevice formats]) {
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            
            for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                DEBUGLOG(@"frame[%f, %f] demensions[%d, %d]", range.minFrameRate, range.maxFrameRate, dimensions.width, dimensions.height);
                // todo:widthについて再検討。最大解像度になっている。画像が拡大されている。切出し？zoom?
                if (range.minFrameRate <= fps && fps <= range.maxFrameRate && dimensions.width >= maxWidth) {
                    selectedFormat = format;
                    frameRateRange = range;
                    maxWidth = dimensions.width;
                }
            }
        }
        
        if (selectedFormat) {
            
            // activeFormatとmin/maxDurationは同時に設定する必要がある。
            [self.session beginConfiguration];
            
            if ([self.videoDevice lockForConfiguration:nil]) {
                
                // <AVCaptureDeviceFormat: 0x174018180 'vide'/'420f' 3264x2448, { 2- 30 fps}, HRSI:3264x2448, fov:58.040, max zoom:153.00 (upscales @1.00), AF System:2, ISO:29.0-1856.0, SS:0.000013-0.500000>
                DEBUGLOG(@"selected format:%@", selectedFormat);
                self.videoDevice.activeFormat = selectedFormat;
                self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)fps);
                self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)fps);
                [self.videoDevice unlockForConfiguration];
            }
            
            [self.session commitConfiguration];
        }
#endif
        
        //if (!self.session.isRunning) {
        //    [self.session startRunning];
        //}
    }
}

-(void)setFocusPoint:(CGPoint)point
{
    //AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (self.videoDevice != nil) {
        DEBUGLOG(@"active format:%@", self.videoDevice.activeFormat);
        if (self.videoDevice.isFocusPointOfInterestSupported) {
            if ([self.videoDevice lockForConfiguration:nil]) {
                [self.videoDevice setFocusPointOfInterest:point];
                [self.videoDevice unlockForConfiguration];
            }
        }
    }
}

-(void)startCapture
{
    DEBUGLOG(@"startCapture...");
    
    dispatch_async([self sessionQueue], ^{
        switch ( self.setupResult ) {
            case CameraManualSetupResultSuccess: {
                // セッションを開始
                if (self.session.running == NO) {
                    DEBUGLOG(@"startCapture");
                    [self addObservers];
                    [self.session startRunning];
                    
                    DEBUGLOG(@"bias:%f", self.videoDevice.exposureTargetBias);
                    DEBUGLOG(@"exposureValue:%f", currentSettings.exposureValue);
                    DEBUGLOG(@"exposureDuration:%f", CMTimeGetSeconds(self.videoDevice.exposureDuration));
                    DEBUGLOG(@"iso:%f", self.videoDevice.ISO);
                    
                    if (self.record == YES) {
                        NSDateFormatter* df = [[NSDateFormatter alloc] init];
                        [df setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
                        NSDate *now = [NSDate date];
                        NSString *strNow = [df stringFromDate:now];
                        NSURL* fileURL = [FileManager getURLWithFileName:[NSString stringWithFormat:@"movie_%@.mov", strNow]];
                        if (fileURL != nil) {
                            [self.movieOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];
                        }
                    }
                    
                    
                    DEBUGLOG(@"startRunning...");
                }
                break;
            }
            case CameraManualSetupResultCameraNotAuthorized: {
                break;
            }
            case CameraManualSetupResultSessionConfigurationFailed: {
                break;
            }
        }
    });
}

-(void)stopCapture
{
    DEBUGLOG(@"stopCapture...");
    
    dispatch_async([self sessionQueue], ^{
        if ( self.setupResult == CameraManualSetupResultSuccess ) {
            // セッションを停止
            if (self.session.running == YES) {
                if (self.record == YES) {
                    [self.movieOutput stopRecording];
                }
                [self.session stopRunning];
                [self removeObservers];
                DEBUGLOG(@"stopCapture");
                DEBUGLOG(@"bias:%f", self.videoDevice.exposureTargetBias);
                DEBUGLOG(@"exposureValue:%f", currentSettings.exposureValue);
                DEBUGLOG(@"exposureDuration:%f", CMTimeGetSeconds(self.videoDevice.exposureDuration));
                DEBUGLOG(@"iso:%f", self.videoDevice.ISO);
                DEBUGLOG(@"stopRunning.");
            }
        }
    });
}

-(int)getVideoActiveFormatInFormats:(NSMutableArray*)formats
{
    int index = 0;
    //formats = [[NSMutableArray alloc] init];
    
    if (self.videoDevice != nil && formats != nil) {
        for (int i = 0; i < [[self.videoDevice formats] count]; i++) {
            AVCaptureDeviceFormat *format = (AVCaptureDeviceFormat*)[[self.videoDevice formats] objectAtIndex:i];
            //[formats addObject:[NSString stringWithFormat:@"%@", format]];
            //if (self.videoDevice.activeFormat == format) {
            //    index = i;
            //}
            
            CMFormatDescriptionRef desc = format.formatDescription;
            // AVCaptureDeviceFormatに映像サイズがないので(静止サイズはある)、下記の方法で取得
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            NSString *dim = [NSString stringWithFormat:@"[%d x %d]", dimensions.width, dimensions.height];
            
            NSString *ss = [NSString stringWithFormat:@"SS:[%.6f-%.6f]", CMTimeGetSeconds(format.minExposureDuration), CMTimeGetSeconds(format.maxExposureDuration)];
            
            NSString *iso = [NSString stringWithFormat:@"ISO:[%.1f-%.1f]", format.minISO, format.maxISO];
            
            NSString *zoom = [NSString stringWithFormat:@"zoom:%.2f/@%.2f", format.videoMaxZoomFactor, format.videoZoomFactorUpscaleThreshold];
            
            NSString *frameRanges = @"fps:";
            NSArray *frameRageRanges = format.videoSupportedFrameRateRanges;
            for (int i = 0; i < frameRageRanges.count; i++) {
                AVFrameRateRange *fRange = [frameRageRanges objectAtIndex:i];
                NSString *frameRange = [NSString stringWithFormat:@"[%d-%d]", (int)fRange.minFrameRate, (int)fRange.maxFrameRate];
                frameRanges = [NSString stringWithFormat:@"%@%@", frameRanges, frameRange];
            }
            
            NSString *fov = [NSString stringWithFormat:@"fov:%.3f", format.videoFieldOfView];
            
            NSString *devFormat = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@", format.mediaType, dim, ss, iso, zoom, frameRanges, fov];
            
            [formats addObject:devFormat];
        }
        
        index = currentSettings.format;
    }
    
    return index;
}

-(CameraFormat)getVideoActiveFormatInfo
{
    CameraFormat format = { 0 };
    format.minExposureOffset = self.videoDevice.minExposureTargetBias;
    format.maxExposureOffset = self.videoDevice.minExposureTargetBias;
    format.minExposureBias = self.videoDevice.minExposureTargetBias;
    format.maxExposureBias = self.videoDevice.maxExposureTargetBias;
    format.minISO = self.videoDevice.activeFormat.minISO;
    format.maxISO = self.videoDevice.activeFormat.maxISO;
    format.minExposureValue = 0.0;
    format.maxExposureValue = 1.0;
    format.minExposureDuration = CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration);
    format.maxExposureDuration = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
    format.minFPS = 2;
    for (AVFrameRateRange *range in self.videoDevice.activeFormat.videoSupportedFrameRateRanges) {
        if (format.maxFPS < range.maxFrameRate) {
            format.maxFPS = range.maxFrameRate;
            format.minFPS = range.minFrameRate;
        }
    }
    format.minZoom = 1.0;
    format.maxZoom = self.videoDevice.activeFormat.videoZoomFactorUpscaleThreshold;
    //format.maxZoom = self.videoDevice.activeFormat.videoMaxZoomFactor;
    
    CMFormatDescriptionRef desc = self.videoDevice.activeFormat.formatDescription;
    // AVCaptureDeviceFormatに映像サイズがないので(静止サイズはある)、下記の方法で取得(encode済み)
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
    format.maxWidth = dimensions.width;
    format.maxHeight = dimensions.height;
    
    return format;
}

-(CameraSetting)getCameraCurrentSettings
{
    return currentSettings;
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error {
    BOOL recordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            recordedSuccessfully = [value boolValue];
        }
    }
    
    if (recordedSuccessfully == YES) {
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:nil];
    }
}


//delegateメソッド。各フレームにおける処理(LEDQキューからフレーム順に呼ばれる)
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //[Log debug:(@"@@captureOutput called.")];
    
    CMTime presTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    //DEBUGLOG(@"<<*********************>>");
    ////DEBUGLOG(@"presTimestamp:%lld", presTimestamp.value);
    ////DEBUGLOG(@"presTimestamp:%lld", presTimestamp.value / presTimestamp.timescale);// int64 / int32 = int
    ////DEBUGLOG(@"presTimestamp:%f", (float)presTimestamp.value / presTimestamp.timescale);
//    DEBUGLOG(@"presTimestamp:%fs", CMTimeGetSeconds(presTimestamp));
    //NSLog(@"presTimestamp:%f", (float)presTimestamp.value / presTimestamp.timescale);
    //NSLog(@"presTimestamp:%fs", CMTimeGetSeconds(presTimestamp));
    
    /*
    DEBUGLOG(@"<<*********************>>");
    CMItemCount num = CMSampleBufferGetNumSamples(sampleBuffer);
    DEBUGLOG(@"num:%ld", num);
    
    CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
    DEBUGLOG(@"duration:%lld", duration.value);
    DEBUGLOG(@"duration:%lld", duration.value / duration.timescale);
    DEBUGLOG(@"duration:%f", (float)duration.value / duration.timescale);
    DEBUGLOG(@"duration:%fs", CMTimeGetSeconds(duration));
    
    CMTime presTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    DEBUGLOG(@"presTimestamp:%lld", presTimestamp.value);
    DEBUGLOG(@"presTimestamp:%lld", presTimestamp.value / presTimestamp.timescale);
    DEBUGLOG(@"presTimestamp:%f", (float)presTimestamp.value / presTimestamp.timescale);
    DEBUGLOG(@"presTimestamp:%fs", CMTimeGetSeconds(presTimestamp));
    
    CMTime decodeTimestamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer);
    DEBUGLOG(@"decodeTimestamp:%lld", decodeTimestamp.value);
    DEBUGLOG(@"decodeTimestamp:%lld", decodeTimestamp.value / decodeTimestamp.timescale);
    DEBUGLOG(@"decodeTimestamp:%f", (float)decodeTimestamp.value / decodeTimestamp.timescale);
    DEBUGLOG(@"decodeTimestamp:%fs", CMTimeGetSeconds(decodeTimestamp));
    
    CMTime outputDuration = CMSampleBufferGetOutputDuration(sampleBuffer);
    DEBUGLOG(@"outputDuration:%lld", outputDuration.value);
    DEBUGLOG(@"outputDuration:%lld", outputDuration.value / outputDuration.timescale);
    DEBUGLOG(@"outputDuration:%f", (float)outputDuration.value / outputDuration.timescale);
    DEBUGLOG(@"outputDuration:%fs", CMTimeGetSeconds(outputDuration));
    
    CMTime outputPresTimestamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    DEBUGLOG(@"outputPresTimestamp:%lld", outputPresTimestamp.value);
    DEBUGLOG(@"outputPresTimestamp:%lld", outputPresTimestamp.value / outputPresTimestamp.timescale);
    DEBUGLOG(@"outputPresTimestamp:%f", (float)outputPresTimestamp.value / outputPresTimestamp.timescale);
    DEBUGLOG(@"outputPresTimestamp:%fs", CMTimeGetSeconds(outputPresTimestamp));
    
    CMTime outputDecodeTimestamp = CMSampleBufferGetOutputDecodeTimeStamp(sampleBuffer);
    DEBUGLOG(@"outputDecodeTimestamp:%lld", outputDecodeTimestamp.value);
    DEBUGLOG(@"outputDecodeTimestamp:%lld", outputDecodeTimestamp.value / outputDecodeTimestamp.timescale);
    DEBUGLOG(@"outputDecodeTimestamp:%f", (float)outputDecodeTimestamp.value / outputDecodeTimestamp.timescale);
    DEBUGLOG(@"outputDecodeTimestamp:%fs", CMTimeGetSeconds(outputDecodeTimestamp));
    
    size_t size = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    DEBUGLOG(@"size:%ld", size);
    DEBUGLOG(@"<<*********************>>");
     */
    
    // 画像の取得 todo:UIImageに変換する必要がある？SWに渡す最適な画像形式について検討。
    // @todo:ここから非同期シリアルキューにする？処理が遅い場合、キューに溜めるので、メモリ増えるかも。frameがdropされるより良いかも？
    //CaptureImageInfo *info = [self imageFromSampleBufferRef:sampleBuffer];

    CaptureImageInfo *info = [[CaptureImageInfo alloc] init];
    info.dataType = currentSettings.type;
    if ((currentSettings.type & CameraDataTypeImage) == CameraDataTypeImage) {
        info.image = [self imageFromSampleBufferRef:sampleBuffer];
    }
    if ((currentSettings.type & CameraDataTypePixel) == CameraDataTypePixel) {
        info.sampleBuffer = sampleBuffer;
    }
    
    // todo: デバイス回転もチェック
    if (currentSettings.orientaion == CameraOrientaionPortrait) {
        // 変換なし
        info.transfrom = CGAffineTransformIdentity;
        info.orientation = UIImageOrientationUp;
    } else {
        // 右(時計方向)回転
        info.transfrom = CGAffineTransformMakeRotation(90.0 * M_PI / 180.0f);
        info.orientation = UIImageOrientationRight;
    }
    
    //info.image = [self imageFromSampleBufferRef:sampleBuffer];
    //self.image = info.image;
    //DEBUGLOG(@"UIImage orientation:%ld width:%f height:%f", (long)self.image.imageOrientation, self.image.size.width, self.image.size.height);
    //[self.cameraObserver imageCaptured:self.image];
    [self.cameraObserver captureImageInfo:info];

    
    
#if false // 無効。CaptureViewControllerに画像を返して解析
    
 #if false
    // 落ちる！todo:Layerで検討してみる。or 表示画面を切り出し部分にする（それ以外の部分表示しない）？
    
    // 指定範囲の画像を切り出し
  #if false
    float scale = [[UIScreen mainScreen] scale];
    CGRect scaledRect = CGRectMake(self.validRect.origin.x * scale,
                                   self.validRect.origin.y * scale,
                                   self.validRect.size.width * scale,
                                   self.validRect.size.height * scale);
    
    CGImageRef clipImageRef = CGImageCreateWithImageInRect(self.image.CGImage, scaledRect);
    UIImage *clipedImage = [UIImage imageWithCGImage:clipImageRef
                                               scale:scale
                                         orientation:UIImageOrientationUp];
  #else
    CGImageRef clipImageRef = CGImageCreateWithImageInRect(self.image.CGImage, self.validRect);
    UIImage *clipedImage = [UIImage imageWithCGImage:clipImageRef];
  #endif
    
    
    // LED信号機検出
    NSMutableArray* signals = [NSMutableArray array];
    UIImage* ledImage = [SmartEyeW detectSignal:clipedImage signals:signals];
//    [Log debug:(@"@@detectSignal called.")];
    
    // 合成
    UIGraphicsBeginImageContext(self.imageView.bounds.size);
    [self.image drawInRect:self.imageView.bounds];
    [ledImage drawInRect:self.validRect];
    UIImage *compImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
 #else
    
    // LED信号機検出
    // todo:メモリが増えて落ちるな。
    CGImageRef clipImageRef = CGImageCreateWithImageInRect(self.image.CGImage, self.validRect);
    UIImage *clipedImage = [UIImage imageWithCGImage:clipImageRef];
    NSMutableArray* signals = [NSMutableArray array];
    UIImage* ledImage = [SmartEyeW detectSignal:clipedImage signals:signals];
//    [Log debug:(@"@@detectSignal called.")];
    
    // todo:ここで解放OK?
    CGImageRelease(clipImageRef);
 #endif
    
 #if false
    // 必要であれば、画像をphotoに保存
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    //[library writeImageToSavedPhotosAlbum
 #endif
    
 #if true
    // 画像を画面に表示
    //dispatch_async(dispatch_get_main_queue(), ^{// 別スレッド
    //dispatch_sync(dispatch_get_main_queue(), ^{// 現スレッド(ログ見ると別スレッドになっている？！両方ともメインスレッド？)
        if (ledImage != nil) {
        //if (self.image != nil) {
            //self.imageView.image = self.image;
            //self.imageView.image = clipedImage;
            //self.imageView.image = ledImage;
            //self.imageView.image = compImage;
            //[Log debug:(@"@@set image.")];
            // graphデータ更新
            //[self.dataUpdater signalGraphData:signals];
            [self.dataUpdater signalGraphData:signals detectedImage:ledImage captureImage:clipedImage];
        } else {
            [Log debug:(@"@@ledImage is nil.")];
        }
    //});// 上位で必要に応じてmainスレッドにアタッチする
 #endif
    
    
#endif

}

- (unsigned char*)createPixelDataFromSampleBufferRef:(CMSampleBufferRef)sampleBuffer
{
    unsigned char* pixelData = nil;
    CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    unsigned char* base = (unsigned char*)CVPixelBufferGetBaseAddress(buffer);
    int width = (int)CVPixelBufferGetWidth(buffer);
    int height = (int)CVPixelBufferGetHeight(buffer);
    memcpy(pixelData, base, width * height);
    
    return pixelData;
}

// CMSampleBufferRefをUIImageへ
- (UIImage*)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBuffer
{
    // この処理時間大体0.001s
    //[Log debug:@"==== CMSampleBufferRef to UIImage start ===="];
    //CaputureImageInfo *imageInfo = [[CaputureImageInfo alloc] init];
    // イメージバッファの取得
    //CVImageBufferRef    buffer;// OK
    // videoなので、video pixelにもなる
    CVPixelBufferRef buffer;// 中身はCVImageBufferRefを再定義しただけ
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // イメージバッファのロック
    CVPixelBufferLockBaseAddress(buffer, 0);
    // イメージバッファ情報の取得
    uint8_t*    base;
    size_t      width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    // Get the pixel buffer width and height
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    // Get the number of bytes per row for the pixel buffer
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    //DEBUGLOG(@"witdh:%zu height:%zu", width, height);
    
#if false
    size_t bufferSize = CVPixelBufferGetDataSize(buffer); // == bytesPerRow * height?
    CGSize resolution = CGSizeMake(width, height);
    // variables for grayscaleBuffer
    void *grayscaleBuffer = 0;
    size_t grayscaleBufferSize = 0;
    
    // the pixelFormat differs between iPhone 3G and later models
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(buffer);
    
    if (pixelFormat == '2vuy') { // iPhone 3G
        // kCVPixelFormatType_422YpCbCr8     = '2vuy',
        /* Component Y'CbCr 8-bit 4:2:2, ordered Cb Y'0 Cr Y'1 */
        
        // copy every second byte (luminance bytes form Y-channel) to new buffer
        grayscaleBufferSize = bufferSize/2;
        grayscaleBuffer = malloc(grayscaleBufferSize);
        if (grayscaleBuffer == NULL) {
            NSLog(@"ERROR in %@:%@:%d: couldn't allocate memory for grayscaleBuffer!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
            return nil; }
        memset(grayscaleBuffer, 0, grayscaleBufferSize);
        void *sourceMemPos = base + 1;
        void *destinationMemPos = grayscaleBuffer;
        void *destinationEnd = grayscaleBuffer + grayscaleBufferSize;
        while (destinationMemPos <= destinationEnd) {
            memcpy(destinationMemPos, sourceMemPos, 1);
            destinationMemPos += 1;
            sourceMemPos += 2;
        }
    }
    
    if (pixelFormat == '420v' || pixelFormat == '420f') {
        // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange = '420v',
        // kCVPixelFormatType_420YpCbCr8BiPlanarFullRange  = '420f',
        // Bi-Planar Component Y'CbCr 8-bit 4:2:0, video-range (luma=[16,235] chroma=[16,240]).
        // Bi-Planar Component Y'CbCr 8-bit 4:2:0, full-range (luma=[0,255] chroma=[1,255]).
        // baseAddress points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct
        // i.e.: Y-channel in this format is in the first third of the buffer!
        bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0);
        base = CVPixelBufferGetBaseAddressOfPlane(buffer,0);
        grayscaleBufferSize = resolution.height * bytesPerRow;
        grayscaleBuffer = malloc(grayscaleBufferSize);
        if (grayscaleBuffer == NULL) {
            NSLog(@"ERROR in %@:%@:%d: couldn't allocate memory for grayscaleBuffer!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), __LINE__);
            return nil; }
        memset(grayscaleBuffer, 0, grayscaleBufferSize);
        memcpy (grayscaleBuffer, base, grayscaleBufferSize);
    }
    
    // do whatever you want with the grayscale buffer
    
    // clean-up
    free(grayscaleBuffer);
#endif
    
    // ビットマップコンテキストの作成
    CGColorSpaceRef colorSpace;
    CGContextRef    cgContext;
    // Create a device-dependent RGB color space
    colorSpace = CGColorSpaceCreateDeviceRGB();
    //colorSpace = CVImageBufferGetColorSpace((CVImageBuffer)buffer);
    // Create a bitmap graphics context with the sample buffer data
    cgContext = CGBitmapContextCreate(
                                      base,
                                      width,
                                      height,
                                      8,
                                      bytesPerRow,
                                      colorSpace,
                                      // 32bit/ARGB
                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // 画像の作成
    CGImageRef  cgImage;
    UIImage*    image;
    UIImageOrientation imgOri = UIImageOrientationRight;
    // todo: デバイス回転もチェック
    if (currentSettings.orientaion == CameraOrientaionPortrait) {
        imgOri = UIImageOrientationUp;
    }
    //UIDeviceOrientation devOri = [UIDevice currentDevice].orientation;
    // context(キャプチャーデータが入っているbuffer)からImageを作成
    // Create a Quartz image from the pixel data in the bitmap graphics context
    cgImage = CGBitmapContextCreateImage(cgContext);
    
    // Free up the context and color space
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(cgContext);
    
    image = [UIImage imageWithCGImage:cgImage scale:1.0f
                            // todo:デバイスの向きによって変更する必要がある。
                            // Device:portraitの場合、キャプチャ基準向き(LandRight)から右に回転したので、Right
                            // Landscapeの場合、基準と同じなので、Upにする ->Device向きと関係ない(表示時関係あるけど)。キャプチャ向きによって画像向きを設定
                          //orientation:UIImageOrientationRight];// defaultはRightなので、合わせる todo:writerInputにtransformを持たせる？
             // todo:回転処理がまだよく理解できていないので、とりあえずpotrait
             // bufferの回転があるので、コストがかかるが、image->video処理で同じ変換処理が必要？なので、変わらないかも。
             // ただ、基本transform情報を持っといて、描画/再生時同時に変換したほうが、パフォーマンスが良いかも。
                          //orientation:UIImageOrientationUp];
                          orientation:imgOri];
    // Free up the context and color space
    CGImageRelease(cgImage);
    
    // イメージバッファのアンロック
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    //imageInfo.image = image;
    //imageInfo.size = CGSizeMake(width, height);
    //imageInfo.timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    //[Log debug:@"==== CMSampleBufferRef to UIImage end ===="];
    
    return image;
}



// ImagePickerのObjective-c版(Swift版である程度確認済。リアルタイム検出NG)
-(void)loadVideoFromPicker
{
    // カメラが利用できるか確認
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        // カメラかライブラリからの読み込み指定。カメラを指定
        [imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
        
        // MobileCoreServicesヘッダ必要。
        //[imagePickerController setMediaTypes:[[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil]];
        
        // トリミングなどを行うか否か
        [imagePickerController setAllowsEditing:NO];
        // Delegateをセット
        [imagePickerController setDelegate:self];
        
        // アニメーションをしてカメラUIを起動(todo 上記設定処理と分離)
        [self.videoViewController presentViewController:imagePickerController animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 撮影画像(1枚のみ??)を取得
    UIImage *originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
    // 撮影した写真をUIImageViewへ設定
    self.imageView.image = originalImage;
    
#if false
    // 検出器生成
    NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:options];
    
    // 検出
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:originalImage.CGImage];
    NSDictionary *imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:6] forKey:CIDetectorImageOrientation];
    NSArray *array = [detector featuresInImage:ciImage options:imageOptions];
    
    // 検出されたデータを取得
    for (CIRectangleFeature *rectFeature in array) {
        // todo LED信号機
    }
#endif
    
    // カメラUIを閉じる
    [self.videoViewController dismissViewControllerAnimated:YES completion:nil];
}

@end