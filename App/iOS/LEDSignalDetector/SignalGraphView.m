//
//  SignalGraphView.m
//  LEDSignalDetector
//
//  Created by 文 光石 on 2014/10/29.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SignalGraphView.h"
#import "SmartEyeW.h"
#import "Log.h"


// todo:ViewControllerでprotocalを実装した方が良いが、swift上で上手く行かないので、取りあえずここで
@interface SignalGraphView()<CPTPlotDataSource>
//@interface SignalGraphView()

@property (nonatomic, retain) CPTGraphHostingView* hostingView;
//@property (nonatomic, retain) CPTScatterPlot* plot;
@property (nonatomic) NSMutableDictionary *signalDataList;
//@property (nonatomic) NSMutableArray* signalDataList;
@property (nonatomic) bool initFlag;
@property (nonatomic) int xyAxisXLen;

@end

@implementation SignalGraphView

@synthesize hostingView;
//@synthesize plot;
@synthesize signalDataList;
//@synthesize signalDataList;
@synthesize initFlag;
@synthesize xyAxisXLen;

-(id)init
{
    DEBUGLOG(@"SignalGraphView init");
    
    if (self = [super init]) {
        if (self.initFlag == false) {
            self.signalDataList = [NSMutableDictionary dictionary];
            //self.signalDataList = [NSMutableArray array];
            [self setup];
            self.initFlag = true;
        }
    }
    
    return self;
}

// storyboardでviewを作成する場合、この関数が呼ばれる
-(id)initWithCoder:(NSCoder *)aDecoder
{
    DEBUGLOG(@"SignalGraphView init:(NSCoder*)coder");
    
    if (self = [super initWithCoder:aDecoder]) {
        if (self.initFlag == false) {
            self.signalDataList = [NSMutableDictionary dictionary];
            //self.signalDataList = [NSMutableArray array];
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
    [self setupXYPlotSpace];
    [self setupAxes];
    
    // test OK
    /*
    NSMutableArray* testDataList = [NSMutableArray array];
    for(int i=0; i<60; ++i){
        SignalW* data = [[SignalW alloc] init];
        data.signalId = 1001;
        data.pixel = rand() % 2000;
        [testDataList addObject:data];
    }
    [self.signalDataList setValue:testDataList forKey:[NSString stringWithFormat:@"%d", 1001]];
     */
    
    
    NSArray* keys = [self.signalDataList allKeys];
    if (keys != nil && keys.count > 0) {
        for (NSString* key in keys) {
            SignalW* signal = (SignalW*)[self.signalDataList objectForKey:key];
            [self addScatterPlot:key withColor:[self getScatterColorWithSignal:signal]];
        }
    }
    
    DEBUGLOG(@"setupSignalGraph:%lu", (unsigned long)[signalDataList count]);
}

-(void)setupHostingView
{
    self.hostingView = [[CPTGraphHostingView alloc] initWithFrame:self.bounds];// frameはNG
    [self addSubview:hostingView];
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
    NSString *title = @"LED Signal Graph";
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

-(void)setupXYPlotSpace
{
    CPTGraph *graph = self.hostingView.hostedGraph;
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    // x/y軸の表示範囲(x:3s * 30fps y:明度数2000)
    //plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(3)];// 3個しかない
    //xyAxisXLen = self.bounds.size.width - graph.paddingLeft - graph.paddingRight - graph.plotAreaFrame.paddingLeft - graph.plotAreaFrame.paddingRight;
    xyAxisXLen = 3 * 30;
    //plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(xyAxisXLen)];// 3個しかない
    //plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(2000)];
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithInt:0] length:[NSNumber numberWithInt:xyAxisXLen]];// 3個しかない
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithInt:0] length:[NSNumber numberWithInt:2000]];
}

-(void)addScatterPlot:(NSString*)identifier withColor:(CPTColor*)scatterColor
{
    // plotを作成する
    CPTScatterPlot *scatterPlot = [[CPTScatterPlot alloc] init];
    scatterPlot.dataSource = self;
    scatterPlot.identifier = identifier;
    scatterPlot.interpolation = CPTScatterPlotInterpolationCurved;

    // スタイルとシンボル作成
    CPTMutableLineStyle *scatterLineStyle = [scatterPlot.dataLineStyle mutableCopy];
    scatterLineStyle.lineWidth = 1;
    scatterLineStyle.lineColor = scatterColor;
    scatterPlot.dataLineStyle = scatterLineStyle;
    
    CPTMutableLineStyle *scatterSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    scatterSymbolLineStyle.lineColor = scatterColor;
    CPTPlotSymbol *scatterSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    scatterSymbol.fill = [CPTFill fillWithColor:scatterColor];
    scatterSymbol.lineStyle = scatterSymbolLineStyle;
    scatterSymbol.size = CGSizeMake(6.0f, 6.0f);
    //scatterPlot.plotSymbol = scatterSymbol;// 各点のシンボル(⭕️とか)
    
    // graphへ追加
    CPTGraph *graph = self.hostingView.hostedGraph;
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    [graph addPlot:scatterPlot toPlotSpace:plotSpace];
    //[graph addPlot:scatterPlot];
    //[plotSpace scaleToFitPlots:[NSArray arrayWithObjects:scatterPlot, nil]];
}

-(void)deleteScatterPlot:(NSString*)identifier
{
    CPTGraph *graph = self.hostingView.hostedGraph;
    [graph removePlotWithIdentifier:identifier];
}

-(void)setupAxes
{
    CPTGraph *graph = self.hostingView.hostedGraph;
    //CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    
    // スタイル作成
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineColor = [CPTColor brownColor];
    lineStyle.lineWidth = 1.0f;
    CPTMutableTextStyle *axisTextStyle = [[CPTMutableTextStyle alloc] init];
    axisTextStyle.color = [CPTColor blackColor];
    axisTextStyle.fontName = @"Helvetica-Bold";
    axisTextStyle.fontSize = 9.0f;
    
    // X軸の設定
    CPTXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = [NSNumber numberWithInt:30];// main目盛り単位(30fps=1s間隔) 90/30=5個
    x.minorTicksPerInterval = 29;// main目盛り単位(30fps)
    x.majorTickLineStyle = lineStyle;// 線(細さ、色など)
    x.minorTickLineStyle = lineStyle;
    x.axisLineStyle = lineStyle;
    x.majorTickLength = 7.0f;// 目盛り線の長さ
    x.minorTickLength = 3.0f;
    x.labelTextStyle = axisTextStyle;
    //x.title = @"Time(s)";
    
    // Y軸の設定
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength = [NSNumber numberWithInt:200];;// 2000/200=10
    y.minorTicksPerInterval = 4;// 40
    y.majorTickLineStyle = lineStyle;
    y.minorTickLineStyle = lineStyle;
    y.axisLineStyle = lineStyle;
    y.majorTickLength = 7.0f;
    y.minorTickLength = 3.0f;
    y.labelTextStyle = axisTextStyle;
    //y.title = @"Lightness";
    //y.titleOffset = 35.0f;
    lineStyle.lineWidth = 0.5f;
    y.majorGridLineStyle = lineStyle;
}

-(CPTColor*)getScatterColorWithSignal:(SignalW*)signal
{
    // todo:signalデータによって色を生成
    //CPTColor* scatterColor = [CPTColor colorWithComponentRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    CPTColor* scatterColor = [CPTColor redColor];
    
    return scatterColor;
}

// 信号を検出した場合、signalDataに必ず検出したすべての信号データがある。
-(void)setSignalData:(NSArray*)signalData
{
    DEBUGLOG(@"SignalGraphView setSignalData");
    if (signalData != nil && signalData.count > 0) {
        CPTGraph *graph = self.hostingView.hostedGraph;
        
        for (SignalW* signal in signalData) {
            bool found = false;
            if (signal != nil) {
                NSString* signalId = [NSString stringWithFormat:@"%lu", signal.signalId];
                DEBUGLOG(@"signalId:%@", signalId);
                
                NSArray* keys = [self.signalDataList allKeys];
                if (keys != nil && keys.count > 0) {
                    for (NSString* key in keys) {
                        DEBUGLOG(@"key:%@", key);
                        if ([signalId compare:key] == NSOrderedSame) {
                            NSMutableArray* dataList = (NSMutableArray*)[self.signalDataList objectForKey:key];
                            if (dataList != nil) {
                                [dataList addObject:signal];
                                
                                // グラフ表示範囲超えた場合、古いデータ削除。(todo:今後全データのフラグを見る場合、ScrollViewで対応)
                                int sub = (int)[dataList count] - self.xyAxisXLen;
                                if (sub >= 0) {
                                    NSRange deleteRan = NSMakeRange(0, sub);
                                    [dataList removeObjectsInRange:deleteRan];
                                }
                            }
                            found = true;
                            break;
                        }
                    }
                    
                    if (found == false) {
                        NSMutableArray* newDataList = [NSMutableArray array];
                        [newDataList addObject:signal];
                        [self.signalDataList setObject:newDataList forKey:signalId];
                        // plot追加(OK)
                        [self addScatterPlot:signalId withColor:[self getScatterColorWithSignal:signal]];
                        DEBUGLOG(@"add scatter plot(%@)", signalId);
                    }
                }
            }
        }
        
        // todo:plot削除処理追加。for文が逆。良い方法再検討
        
        // グラフ更新
        //[graph reloadDataIfNeeded];// NG
        [graph reloadData];
    }
}

-(void)clear
{
    if (self.signalDataList != nil && self.signalDataList.count > 0) {
        [self.signalDataList removeAllObjects];
    }
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
    DEBUGLOG(@"numberForPlot(%@):[%lu, %lu]", (NSString*)plot.identifier, (unsigned long)fieldEnum, (unsigned long)idx);
    
    NSNumber* num = [NSNumber numberWithInt:-1]; // error
    SignalW* data;// switch内で宣言できない
    NSMutableArray* dataList;
    
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            num = [NSNumber numberWithUnsignedInteger:idx];
            break;
        case CPTScatterPlotFieldY:
            dataList = (NSMutableArray*)[self.signalDataList objectForKey:(NSString*)plot.identifier];
            if (dataList != nil) {
                data = [dataList objectAtIndex:idx];
                num = [NSNumber numberWithInt:data.pixel];
            }
            break;
    }
    
    return num;
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    DEBUGLOG(@"numberOfRecordsForPlot(%@):[%lu]", (NSString*)plot.identifier, (unsigned long)[signalDataList count]);
    
    uint num = 0;
    NSMutableArray* dataList = (NSMutableArray*)[self.signalDataList objectForKey:(NSString*)plot.identifier];
    if (dataList != nil) {
        num = (uint)[dataList count];
    }
    
    return num;
}

@end