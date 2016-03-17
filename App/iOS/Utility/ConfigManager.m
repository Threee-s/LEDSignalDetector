//
//  ConfigManager.m
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/28.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#import "ConfigManager.h"
#import "FileManager.h"
#import "Log.h"


@implementation SignalInfo
@end

@implementation DebugMode
@end

@implementation CameraSettings
@end

@implementation RecordMode
@end

@implementation Range
@end

@implementation ColorSpace

-(id)init
{
    if (self = [super init]) {
        _h = [[Range alloc] init];
        _s = [[Range alloc] init];
        _v = [[Range alloc] init];
    }
    
    return self;
}

@end

@implementation ColorSettings

-(id)init
{
    if (self = [super init]) {
        _colorSpaceRed = [[ColorSpace alloc] init];
        _colorSpaceGreen = [[ColorSpace alloc] init];
        _colorSpaceCenter = [[ColorSpace alloc] init];
    }
    
    return self;
}

@end

@implementation ImageSettings
@end

@implementation ValidArea
@end

@implementation CombinePoint
@end

@implementation IntegrateRect
@end

@implementation ValidRect
@end

@implementation CompareRect
@end

@implementation CompareSignal
@end

@implementation RecogonizeSignal

-(id)init
{
    if (self = [super init]) {
        _compareSignal = [[CompareSignal alloc] init];
    }
    return self;
}

@end

@implementation DetectParams

-(id)init
{
    if (self = [super init]) {
        _imageSetting = [[ImageSettings alloc] init];
        _combinePoint = [[CombinePoint alloc] init];
        _integrateRect = [[IntegrateRect alloc] init];
        _validRectMin = [[ValidRect alloc] init];
        _validRectMax = [[ValidRect alloc] init];
        _compareRect = [[CompareRect alloc] init];
        _recogonizeSignal = [[RecogonizeSignal alloc] init];
    }
    return self;
}

@end

@implementation ConfigSettings

-(id)init
{
    if (self = [super init]) {
        _signalInfo = [[SignalInfo alloc] init];
        _debugMode = [[DebugMode alloc] init];
        _cameraSettings = [[CameraSettings alloc] init];
        _recordMode = [[RecordMode alloc] init];
        _colorSettings = [[ColorSettings alloc] init];
        _detectParams = [[DetectParams alloc] init];
    }
    return self;
}

@end

@interface ConfigManager()

@property (nonatomic, copy) NSString *confFile;

-(void)loadConf:(NSString*)confFile;
-(void)saveConf;

@end

@implementation ConfigManager

@synthesize confDic;
//@synthesize confSettings = _confSettings;

//static ConfigSettings *_confSettings;

+(ConfigManager*)sharedInstance
{
    static ConfigManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once( &onceToken, ^{
        sharedInstance = [[self alloc] init];
        //sharedInstance = [ConfigManager new];// NG for sub class?
    });
    /*
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [ConfigManager new];
            [sharedInstance loadConf:@"SmartEyeConfig.plist"];
        }
    }*/

    return sharedInstance;
}

-(id)init
{
    DEBUGLOG(@"ConfigManager init");
    if (self = [super init]) {
        _confSettings = [[ConfigSettings alloc] init];
        [self loadConf:@"SmartEyeConfig.plist"];
    }
    return self;
}

-(id)initWithConfFile:(NSString*)confFile
{
    DEBUGLOG(@"ConfigManager initWithConfFile(%@)", confFile);
    if (self = [super init]) {
        self.confFile = confFile;
        //[self loadConf];
    }
    
    return self;
}

-(void)finalize
{
    DEBUGLOG(@"ConfigManager finalize");
    [super finalize];
    [self saveConf];
}

-(void)save
{
    [self saveConf];
}

-(NSString*)description
{
    NSString *des = @"";
    
    NSString *colorSpaceDes = [NSString stringWithFormat: @"Red -> H[%d, %d], S[%d, %d], V[%d, %d]¥nGreen -> H[%d, %d], S[%d, %d], V[%d, %d]¥nCenter -> H[%d, %d], S[%d, %d], V[%d, %d]",
                               _confSettings.colorSettings.colorSpaceRed.h.lower,
                               _confSettings.colorSettings.colorSpaceRed.h.upper,
                               _confSettings.colorSettings.colorSpaceRed.s.lower,
                               _confSettings.colorSettings.colorSpaceRed.s.upper,
                               _confSettings.colorSettings.colorSpaceRed.v.lower,
                               _confSettings.colorSettings.colorSpaceRed.v.upper,
                               _confSettings.colorSettings.colorSpaceGreen.h.lower,
                               _confSettings.colorSettings.colorSpaceGreen.h.upper,
                               _confSettings.colorSettings.colorSpaceGreen.s.lower,
                               _confSettings.colorSettings.colorSpaceGreen.s.upper,
                               _confSettings.colorSettings.colorSpaceGreen.v.lower,
                               _confSettings.colorSettings.colorSpaceGreen.v.upper,
                               _confSettings.colorSettings.colorSpaceCenter.h.lower,
                               _confSettings.colorSettings.colorSpaceCenter.h.upper,
                               _confSettings.colorSettings.colorSpaceCenter.s.lower,
                               _confSettings.colorSettings.colorSpaceCenter.s.upper,
                               _confSettings.colorSettings.colorSpaceCenter.v.lower,
                               _confSettings.colorSettings.colorSpaceCenter.v.upper];
    des = [NSString stringWithFormat:@"ColorSpace:¥n[¥n%@¥n]¥n", colorSpaceDes];
    
    return des;
}

-(void)loadConf:(NSString*)confFile
{
    self.confFile = confFile;
    if (self.confFile != nil) {
        self.confDic = [FileManager loadConfigFromPlist:self.confFile];
        if (self.confDic != nil) {
            NSDictionary* dic = [self.confDic valueForKey:@"SignalInfo"];
            if (dic != nil) {
                NSNumber *num = [dic valueForKey:@"Frequency"];
                if (num != nil) {
                    _confSettings.signalInfo.ledFreq = [num intValue];
                }
            }
            
            dic = [self.confDic valueForKey:@"DebugMode"];
            if (dic != nil) {
                NSNumber *num = [dic valueForKey:@"Flag"];
                if (num != nil) {
                    _confSettings.debugMode.flag = [num boolValue];
                }
                
                num = [dic valueForKey:@"Binary"];
                if (num != nil) {
                    _confSettings.debugMode.binary = [num boolValue];
                }
                
                num = [dic valueForKey:@"Point"];
                if (num != nil) {
                    _confSettings.debugMode.point = [num boolValue];
                }
                
                num = [dic valueForKey:@"Rect"];
                if (num != nil) {
                    _confSettings.debugMode.rect = [num boolValue];
                }
                
                num = [dic valueForKey:@"Area"];
                if (num != nil) {
                    _confSettings.debugMode.area = [num boolValue];
                }
                
                num = [dic valueForKey:@"Signal"];
                if (num != nil) {
                    _confSettings.debugMode.signal = [num boolValue];
                }
            }
            
            dic = [self.confDic valueForKey:@"CameraSettings"];
            if (dic != nil) {
                NSNumber *num = [dic valueForKey:@"FormatIndex"];
                if (num != nil) {
                    _confSettings.cameraSettings.formatIndex = [num intValue];
                }
                
                num = [dic valueForKey:@"VideoFPS"];
                if (num != nil) {
                    _confSettings.cameraSettings.fps = [num intValue];
                }
                
                num = [dic valueForKey:@"ExposureValue"];
                if (num != nil) {
                    _confSettings.cameraSettings.exposureValue = [num floatValue];
                }
                
                num = [dic valueForKey:@"ISO"];
                if (num != nil) {
                    _confSettings.cameraSettings.iso = [num floatValue];
                }
                
                num = [dic valueForKey:@"ExposureBias"];
                if (num != nil) {
                    _confSettings.cameraSettings.bias = [num floatValue];
                }
            }
            
            dic = [self.confDic valueForKey:@"RecordMode"];
            if (dic != nil) {
                NSNumber *num = [dic valueForKey:@"Time"];
                if (num != nil) {
                    _confSettings.recordMode.time = [num intValue];
                }
            }
            
            dic = [self.confDic valueForKey:@"ColorSettings"];
            if (dic != nil) {
                NSNumber *num = [dic valueForKey:@"DetectColors"];
                if (num != nil) {
                    _confSettings.colorSettings.detectColors = [num intValue];
                }
                
                NSDictionary *csDic = [dic valueForKey:@"ColorSpaceRed"];
                if (csDic != nil) {
                    NSDictionary *rangeDic = [csDic valueForKey:@"H"];
                    if (rangeDic != nil) {
                        num = [rangeDic valueForKey:@"Lower"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceRed.h.lower = [num intValue];
                        }
                        
                        num = [rangeDic valueForKey:@"Upper"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceRed.h.upper = [num intValue];
                        }
                    }
                    
                    rangeDic = [csDic valueForKey:@"S"];
                    if (rangeDic != nil) {
                        num = [rangeDic valueForKey:@"Lower"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceRed.s.lower = [num intValue];
                        }
                        
                        num = [rangeDic valueForKey:@"Upper"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceRed.s.upper = [num intValue];
                        }
                    }
                    
                    rangeDic = [csDic valueForKey:@"V"];
                    if (rangeDic != nil) {
                        num = [rangeDic valueForKey:@"Lower"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceRed.v.lower = [num intValue];
                        }
                        
                        num = [rangeDic valueForKey:@"Upper"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceRed.v.upper = [num intValue];
                        }
                    }
                }
                
                csDic = [dic valueForKey:@"ColorSpaceGreen"];
                if (csDic != nil) {
                    NSDictionary *rangeDic = [csDic valueForKey:@"H"];
                    if (rangeDic != nil) {
                        num = [rangeDic valueForKey:@"Lower"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceGreen.h.lower = [num intValue];
                        }
                        
                        num = [rangeDic valueForKey:@"Upper"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceGreen.h.upper = [num intValue];
                        }
                    }
                    
                    rangeDic = [csDic valueForKey:@"S"];
                    if (rangeDic != nil) {
                        num = [rangeDic valueForKey:@"Lower"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceGreen.s.lower = [num intValue];
                        }
                        
                        num = [rangeDic valueForKey:@"Upper"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceGreen.s.upper = [num intValue];
                        }
                    }
                    
                    rangeDic = [csDic valueForKey:@"V"];
                    if (rangeDic != nil) {
                        num = [rangeDic valueForKey:@"Lower"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceGreen.v.lower = [num intValue];
                        }
                        
                        num = [rangeDic valueForKey:@"Upper"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceGreen.v.upper = [num intValue];
                        }
                    }
                }
                
                csDic = [dic valueForKey:@"ColorSpaceCenter"];
                if (csDic != nil) {
                    NSDictionary *rangeDic = [csDic valueForKey:@"H"];
                    if (rangeDic != nil) {
                        num = [rangeDic valueForKey:@"Lower"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceCenter.h.lower = [num intValue];
                        }
                        
                        num = [rangeDic valueForKey:@"Upper"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceCenter.h.upper = [num intValue];
                        }
                    }
                    
                    rangeDic = [csDic valueForKey:@"S"];
                    if (rangeDic != nil) {
                        num = [rangeDic valueForKey:@"Lower"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceCenter.s.lower = [num intValue];
                        }
                        
                        num = [rangeDic valueForKey:@"Upper"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceCenter.s.upper = [num intValue];
                        }
                    }
                    
                    rangeDic = [csDic valueForKey:@"V"];
                    if (rangeDic != nil) {
                        num = [rangeDic valueForKey:@"Lower"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceCenter.v.lower = [num intValue];
                        }
                        
                        num = [rangeDic valueForKey:@"Upper"];
                        if (num != nil) {
                            _confSettings.colorSettings.colorSpaceCenter.v.upper = [num intValue];
                        }
                    }
                }
            }
            
            dic = [self.confDic valueForKey:@"DetectParams"];
            if (dic != nil) {
                NSDictionary *paramsDic = [dic valueForKey:@"ValidArea"];
                if (paramsDic != nil ) {
                    NSNumber *num = [paramsDic valueForKey:@"X"];
                    if (num != nil) {
                        _confSettings.detectParams.validArea.x = [num floatValue];
                    }
                    
                    num = [paramsDic valueForKey:@"Y"];
                    if (num != nil) {
                        _confSettings.detectParams.validArea.y = [num floatValue];
                    }
                    
                    num = [paramsDic valueForKey:@"Width"];
                    if (num != nil) {
                        _confSettings.detectParams.validArea.width = [num floatValue];
                    }
                    
                    num = [paramsDic valueForKey:@"Height"];
                    if (num != nil) {
                        _confSettings.detectParams.validArea.height = [num floatValue];
                    }
                }
                
                paramsDic = [dic valueForKey:@"CombinePoint"];
                if (paramsDic != nil) {
                    NSNumber *num = [paramsDic valueForKey:@"Threshold"];
                    if (num != nil) {
                        _confSettings.detectParams.combinePoint.threshold = [num intValue];
                    }
                    
                    num = [paramsDic valueForKey:@"Offset"];
                    if (num != nil) {
                        _confSettings.detectParams.combinePoint.offset = [num intValue];
                    }
                }
                
                paramsDic = [dic valueForKey:@"IntegrateRect"];
                if (paramsDic != nil) {
                    NSNumber *num = [paramsDic valueForKey:@"Prop"];
                    if (num != nil) {
                        _confSettings.detectParams.integrateRect.prop = [num intValue];
                    }
                    
                    num = [paramsDic valueForKey:@"Offset"];
                    if (num != nil) {
                        _confSettings.detectParams.integrateRect.offset = [num intValue];
                    }
                }
                
                paramsDic = [dic valueForKey:@"ValidRect"];
                if (paramsDic != nil) {
                    NSDictionary *minDic = [paramsDic valueForKey:@"Min"];
                    if (minDic != nil) {
                        NSNumber *num = [minDic valueForKey:@"Width"];
                        if (num != nil) {
                            _confSettings.detectParams.validRectMin.width = [num intValue];
                        }
                        
                        num = [minDic valueForKey:@"Height"];
                        if (num != nil) {
                            _confSettings.detectParams.validRectMin.height = [num intValue];
                        }
                    }
                    
                    NSDictionary *maxDic = [paramsDic valueForKey:@"Max"];
                    if (maxDic != nil) {
                        NSNumber *num = [maxDic valueForKey:@"Width"];
                        if (num != nil) {
                            _confSettings.detectParams.validRectMax.width = [num intValue];
                        }
                        
                        num = [maxDic valueForKey:@"Height"];
                        if (num != nil) {
                            _confSettings.detectParams.validRectMax.height = [num intValue];
                        }
                    }
                }
                
                paramsDic = [dic valueForKey:@"CompareRect"];
                if (paramsDic != nil) {
                    NSNumber *num = [paramsDic valueForKey:@"Dist"];
                    if (num != nil) {
                        _confSettings.detectParams.compareRect.dist = [num intValue];
                    }
                    
                    num = [paramsDic valueForKey:@"Scale"];
                    if (num != nil) {
                        _confSettings.detectParams.compareRect.scale = [num floatValue];
                    }
                }
                
                paramsDic = [dic valueForKey:@"RecogonizeSignal"];
                if (paramsDic != nil) {
                    NSNumber *num = [paramsDic valueForKey:@"LightnessDiff"];
                    if (num != nil) {
                        _confSettings.detectParams.recogonizeSignal.lightnessDiff = [num floatValue];
                    }
                    
                    NSDictionary *compDic = [paramsDic valueForKey:@"CompareSignal"];
                    if (compDic != nil) {
                        num = [compDic valueForKey:@"DiffCount"];
                        if (num != nil) {
                            _confSettings.detectParams.recogonizeSignal.compareSignal.diffCount = [num intValue];
                        }
                        
                        num = [compDic valueForKey:@"InvalidCount"];
                        if (num != nil) {
                            _confSettings.detectParams.recogonizeSignal.compareSignal.invalidCount = [num intValue];
                        }
                    }
                }
            }
        }
    }
}

-(void)saveConf
{
    if (self.confFile != nil && self.confDic != nil) {
        NSMutableDictionary *signalInfoDic = [[NSMutableDictionary alloc] init];
        [signalInfoDic setValue:[NSNumber numberWithInt:_confSettings.signalInfo.ledFreq] forKey:@"Frequency"];
        [self.confDic setValue:signalInfoDic forKey:@"SignalInfo"];
        
        NSMutableDictionary *debugModeDic = [[NSMutableDictionary alloc] init];
        [debugModeDic setValue:[NSNumber numberWithBool:_confSettings.debugMode.flag] forKey:@"Flag"];
        [debugModeDic setValue:[NSNumber numberWithBool:_confSettings.debugMode.binary] forKey:@"Binary"];
        [debugModeDic setValue:[NSNumber numberWithBool:_confSettings.debugMode.point] forKey:@"Point"];
        [debugModeDic setValue:[NSNumber numberWithBool:_confSettings.debugMode.rect] forKey:@"Rect"];
        [debugModeDic setValue:[NSNumber numberWithBool:_confSettings.debugMode.area] forKey:@"Area"];
        [debugModeDic setValue:[NSNumber numberWithBool:_confSettings.debugMode.signal] forKey:@"Signal"];
        [self.confDic setValue:debugModeDic forKey:@"DebugMode"];
        
        NSMutableDictionary *cameraSettingsDic = [[NSMutableDictionary alloc] init];
        [cameraSettingsDic setValue:[NSNumber numberWithInt:_confSettings.cameraSettings.formatIndex] forKey:@"FormatIndex"];
        [cameraSettingsDic setValue:[NSNumber numberWithInt:_confSettings.cameraSettings.fps] forKey:@"VideoFPS"];
        [cameraSettingsDic setValue:[NSNumber numberWithFloat:_confSettings.cameraSettings.exposureValue] forKey:@"ExposureValue"];
        [cameraSettingsDic setValue:[NSNumber numberWithFloat:_confSettings.cameraSettings.iso] forKey:@"ISO"];
        [cameraSettingsDic setValue:[NSNumber numberWithInt:_confSettings.cameraSettings.bias] forKey:@"ExposureBias"];
        [self.confDic setValue:cameraSettingsDic forKey:@"CameraSettings"];
        
        NSMutableDictionary *recordMode = [[NSMutableDictionary alloc] init];
        [recordMode setValue:[NSNumber numberWithInt:_confSettings.recordMode.time] forKey:@"Time"];
        [self.confDic setValue:recordMode forKey:@"RecordMode"];
        
        NSMutableDictionary *colorSettingsDic = [[NSMutableDictionary alloc] init];
        [colorSettingsDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.detectColors] forKey:@"DetectColors"];
        NSMutableDictionary *colorSpaceRed = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *redHDic = [[NSMutableDictionary alloc] init];
        [redHDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceRed.h.lower] forKey:@"Lower"];
        [redHDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceRed.h.upper] forKey:@"Upper"];
        [colorSpaceRed setValue:redHDic forKey:@"H"];
        NSMutableDictionary *redSDic = [[NSMutableDictionary alloc] init];
        [redSDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceRed.s.lower] forKey:@"Lower"];
        [redSDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceRed.s.upper] forKey:@"Upper"];
        [colorSpaceRed setValue:redSDic forKey:@"S"];
        NSMutableDictionary *redVDic = [[NSMutableDictionary alloc] init];
        [redVDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceRed.v.lower] forKey:@"Lower"];
        [redVDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceRed.v.upper] forKey:@"Upper"];
        [colorSpaceRed setValue:redVDic forKey:@"V"];
        [colorSettingsDic setValue:colorSpaceRed forKey:@"ColorSpaceRed"];
        
        NSMutableDictionary *colorSpaceGreen = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *greenHDic = [[NSMutableDictionary alloc] init];
        [greenHDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceGreen.h.lower] forKey:@"Lower"];
        [greenHDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceGreen.h.upper] forKey:@"Upper"];
        [colorSpaceGreen setValue:greenHDic forKey:@"H"];
        NSMutableDictionary *greenSDic = [[NSMutableDictionary alloc] init];
        [greenSDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceGreen.s.lower] forKey:@"Lower"];
        [greenSDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceGreen.s.upper] forKey:@"Upper"];
        [colorSpaceGreen setValue:greenSDic forKey:@"S"];
        NSMutableDictionary *greenVDic = [[NSMutableDictionary alloc] init];
        [greenVDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceGreen.v.lower] forKey:@"Lower"];
        [greenVDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceGreen.v.upper] forKey:@"Upper"];
        [colorSpaceGreen setValue:greenVDic forKey:@"V"];
        [colorSettingsDic setValue:colorSpaceGreen forKey:@"ColorSpaceGreen"];
        
        NSMutableDictionary *colorSpaceCenter = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *centerHDic = [[NSMutableDictionary alloc] init];
        [centerHDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceCenter.h.lower] forKey:@"Lower"];
        [centerHDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceCenter.h.upper] forKey:@"Upper"];
        [colorSpaceCenter setValue:centerHDic forKey:@"H"];
        NSMutableDictionary *centerSDic = [[NSMutableDictionary alloc] init];
        [centerSDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceCenter.s.lower] forKey:@"Lower"];
        [centerSDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceCenter.s.upper] forKey:@"Upper"];
        [colorSpaceCenter setValue:centerSDic forKey:@"S"];
        NSMutableDictionary *centerVDic = [[NSMutableDictionary alloc] init];
        [centerVDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceCenter.v.lower] forKey:@"Lower"];
        [centerVDic setValue:[NSNumber numberWithInt:_confSettings.colorSettings.colorSpaceCenter.v.upper] forKey:@"Upper"];
        [colorSpaceCenter setValue:centerVDic forKey:@"V"];
        [colorSettingsDic setValue:colorSpaceCenter forKey:@"ColorSpaceCenter"];
        
        [self.confDic setValue:colorSettingsDic forKey:@"ColorSettings"];
        
        NSMutableDictionary *detectParamsDic = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *validDic = [[NSMutableDictionary alloc] init];
        [validDic setValue:[NSNumber numberWithFloat:_confSettings.detectParams.validArea.x] forKey:@"X"];
        [validDic setValue:[NSNumber numberWithFloat:_confSettings.detectParams.validArea.y] forKey:@"Y"];
        [validDic setValue:[NSNumber numberWithFloat:_confSettings.detectParams.validArea.width] forKey:@"Width"];
        [validDic setValue:[NSNumber numberWithFloat:_confSettings.detectParams.validArea.height] forKey:@"Height"];
        [detectParamsDic setValue:validDic forKey:@"ValidArea"];
        
        NSMutableDictionary *combineDic = [[NSMutableDictionary alloc] init];
        [combineDic setValue:[NSNumber numberWithInt:_confSettings.detectParams.combinePoint.threshold] forKey:@"Threshold"];
        [combineDic setValue:[NSNumber numberWithInt:_confSettings.detectParams.combinePoint.offset] forKey:@"Offset"];
        [detectParamsDic setValue:combineDic forKey:@"CombinePoint"];
        
        NSMutableDictionary *integrateRectDic = [[NSMutableDictionary alloc] init];
        [integrateRectDic setValue:[NSNumber numberWithInt:_confSettings.detectParams.integrateRect.prop] forKey:@"Prop"];
        [integrateRectDic setValue:[NSNumber numberWithInt:_confSettings.detectParams.integrateRect.offset] forKey:@"Offset"];
        [detectParamsDic setValue:integrateRectDic forKey:@"IntegrateRect"];
        
        NSMutableDictionary *validRectDic = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *minDic = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *maxDic = [[NSMutableDictionary alloc] init];
        [minDic setValue:[NSNumber numberWithInt:_confSettings.detectParams.validRectMin.width] forKey:@"Width"];
        [minDic setValue:[NSNumber numberWithInt:_confSettings.detectParams.validRectMin.height] forKey:@"Height"];
        [validRectDic setValue:minDic forKey:@"Min"];
        [maxDic setValue:[NSNumber numberWithInt:_confSettings.detectParams.validRectMax.width] forKey:@"Width"];
        [maxDic setValue:[NSNumber numberWithInt:_confSettings.detectParams.validRectMax.height] forKey:@"Height"];
        [validRectDic setValue:maxDic forKey:@"Max"];
        [detectParamsDic setValue:validRectDic forKey:@"ValidRect"];
        
        NSMutableDictionary *compareRectDic = [[NSMutableDictionary alloc] init];
        [compareRectDic setValue:[NSNumber numberWithInt:_confSettings.detectParams.compareRect.dist] forKey:@"Dist"];
        [compareRectDic setValue:[NSNumber numberWithFloat:_confSettings.detectParams.compareRect.scale] forKey:@"Scale"];
        [detectParamsDic setValue:compareRectDic forKey:@"CompareRect"];
        
        NSMutableDictionary *recogonizeSignalDic = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *compSignalDic = [[NSMutableDictionary alloc] init];
        [compareRectDic setValue:[NSNumber numberWithFloat:_confSettings.detectParams.recogonizeSignal.lightnessDiff] forKey:@"LightnessDiff"];
        [compSignalDic setValue:[NSNumber numberWithInt:_confSettings.detectParams.recogonizeSignal.compareSignal.diffCount] forKey:@"DiffCount"];
        [compSignalDic setValue:[NSNumber numberWithFloat:_confSettings.detectParams.recogonizeSignal.compareSignal.invalidCount] forKey:@"InvalidCount"];
        [recogonizeSignalDic setValue:compSignalDic forKey:@"CompareSignal"];
        [detectParamsDic setValue:recogonizeSignalDic forKey:@"RecogonizeSignal"];
        
        [self.confDic setValue:detectParamsDic forKey:@"DetectParams"];
        
        [FileManager saveToPlist:self.confFile WithDictionary:self.confDic];
    }
}

@end
