//
//  HistogramGraphView.m
//  LEDSignalDetector
//
//  Created by 文 光石 on 2015/03/13.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HistogramGraphView.h"
#import "CorePlot-CocoaTouch.h"
#import "Log.h"

@interface HistogramGraphView() <CPTPlotDataSource>

@property (nonatomic) CPTGraphHostingView* hostingView;
@property (nonatomic) NSMutableArray *binDataList;
@property (nonatomic) bool initFlag;

@end

// todo:直接opencvでhistogramのgraphを描画してもよいかも
@implementation HistogramGraphView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(id)init
{
    DEBUGLOG(@"HistogramGraphView init");
    
    if (self = [super init]) {
        if (self.initFlag == false) {
            [self setup];
            self.initFlag = true;
        }
    }
    
    return self;
}

// storyboardでviewを作成する場合、この関数が呼ばれる
-(id)initWithCoder:(NSCoder *)aDecoder
{
    DEBUGLOG(@"HistogramGraphView init:(NSCoder*)coder");
    
    if (self = [super initWithCoder:aDecoder]) {
        if (self.initFlag == false) {
            [self setup];
            self.initFlag = true;
        }
    }
    
    return self;
}

-(void)setup
{
    DEBUGLOG(@"SignalGraphView setupSignalGraph");
    
    [self setupHostingView];
    [self setupGraph];
}

-(void)setupHostingView
{
    self.hostingView = [[CPTGraphHostingView alloc] initWithFrame:self.bounds];// frameはNG
    [self addSubview:_hostingView];
}

-(void)setupGraph
{
    CPTGraph* graph = [[CPTXYGraph alloc] initWithFrame:self.bounds];
    
    // padding
    graph.paddingTop = 10.0f;
    graph.paddingLeft = 10.0f;
    graph.paddingRight = 10.0f;
    graph.paddingBottom = 10.0f;
    [graph applyTheme:[CPTTheme themeNamed:kCPTSlateTheme]];
    
    //グラフタイトルを作る
    NSString *title = @"Sensor Graph";
    graph.title = title;
    
    //テキストスタイルの作成と設定
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor blackColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 10.0f;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, -10.0f);
    
    //プロットエリアのパディング設定(描画範囲。0の場合、view全体になる。タイトルなどと重なる)
    [graph.plotAreaFrame setPaddingLeft:40.0f];
    [graph.plotAreaFrame setPaddingRight:20.0f];
    [graph.plotAreaFrame setPaddingTop:30.0f];
    [graph.plotAreaFrame setPaddingBottom:20.0f];
    
    self.hostingView.hostedGraph = graph;
}

-(void)setBinData:(NSArray*)bins
{
    
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
    DEBUGLOG(@"numberForPlot(%@):[%lu, %lu]", (NSString*)plot.identifier, (unsigned long)fieldEnum, (unsigned long)idx);
    
    NSNumber* num = [NSNumber numberWithInt:-1]; // error
    
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            num = [NSNumber numberWithUnsignedInteger:idx];
            break;
        case CPTScatterPlotFieldY:
            num = (NSNumber*)[_binDataList objectAtIndex:idx];
            break;
    }
    
    return num;
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    DEBUGLOG(@"numberOfRecordsForPlot(%@):[%lu]", (NSString*)plot.identifier, (unsigned long)[_binDataList count]);
    
    NSUInteger num = 0;
    if (_binDataList != nil) {
        num = [_binDataList count];
    }
    
    return num;
}

@end
