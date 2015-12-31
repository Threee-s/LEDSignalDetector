//
//  SignalGraphView.h
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/26.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#ifndef LEDSignalDetector_SignalGraphView_h
#define LEDSignalDetector_SignalGraphView_h

#import "CorePlot-CocoaTouch.h"
//#import <CorePlot.h>

enum {
    PlotFieldX = (int)CPTScatterPlotFieldX,
    PlotFieldY = (int)CPTScatterPlotFieldY,
};

@interface CorePlotW : NSObject

// NG??何故かswiftでは見えない(戻り値がvoidの場合（swiftに定義がある場合？？）見えるが...)
//+(id)plotRangeWithLocation:(NSDecimal)loc length:(NSDecimal)len;

@end


@interface SignalGraphView : UIView

-(void)setSignalData:(NSArray*)signalData;
// すべてのデータを削除
-(void)clear;

@end

@interface PedestrianSignalView : UIView

@end

@interface VehicleSignalView : UIView

@end

#endif
