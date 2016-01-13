//
//  SignalGraphView.m
//  LEDSignalDetector
//
//  Created by 文 光石 on 2014/10/29.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AirGraphView.h"
//#import <CorePlot-CocoaTouch.h>
#import "CorePlot-CocoaTouch.h"
//#import "CorePlot.h"
#import "Log.h"


// todo:ViewControllerでprotocalを実装した方が良いが、swift上で上手く行かないので、取りあえずここで
@interface AirGraphView()<CPTPlotDataSource>
//@interface SignalGraphView()

@property (nonatomic) CPTGraphHostingView* hostingView;
//@property (nonatomic, retain) CPTScatterPlot* plot;
@property (nonatomic) AirSensorType type;
@property (nonatomic) NSMutableDictionary *sensorDataList;
@property (nonatomic) NSMutableDictionary *accelerationDataList;
@property (nonatomic) NSMutableDictionary *gyroDataList;
@property (nonatomic) NSMutableDictionary *attitudeDataList;
@property (nonatomic) bool initFlag;
@property (nonatomic) int xyAxisXLen;
@property (nonatomic) int axisCount;

@end

@implementation AirGraphView

@synthesize hostingView;
@synthesize initFlag;
@synthesize xyAxisXLen;

-(id)init
{
    DEBUGLOG(@"SignalGraphView init");
    
    if (self = [super init]) {
        if (self.initFlag == false) {
            _sensorDataList = [NSMutableDictionary dictionary];
            _accelerationDataList = [NSMutableDictionary dictionary];
            _gyroDataList = [NSMutableDictionary dictionary];
            _attitudeDataList = [NSMutableDictionary dictionary];
            _axisCount = 3;
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
            _sensorDataList = [NSMutableDictionary dictionary];
            _accelerationDataList = [NSMutableDictionary dictionary];
            _gyroDataList = [NSMutableDictionary dictionary];
            _attitudeDataList = [NSMutableDictionary dictionary];
            _axisCount = 3;
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
    
    // todo:graphを随時追加可能にする
    [self addScatterPlot:@"AxisX" withColor:[self getScatterColorWithSensorAxis:AirSensorAxisX]];
    [self addScatterPlot:@"AxisY" withColor:[self getScatterColorWithSensorAxis:AirSensorAxisY]];
    [self addScatterPlot:@"AxisZ" withColor:[self getScatterColorWithSensorAxis:AirSensorAxisZ]];
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

-(void)setupXYPlotSpace
{
    CPTGraph *graph = self.hostingView.hostedGraph;
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    // x/y軸の表示範囲(x:3s * 30fps y:明度数2000)
    //plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(3)];// 3個しかない
    //xyAxisXLen = self.bounds.size.width - graph.paddingLeft - graph.paddingRight - graph.plotAreaFrame.paddingLeft - graph.plotAreaFrame.paddingRight;
    xyAxisXLen = 1 * 60;// 1s (sensor frequency 1/100)
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithInt:0] length:[NSNumber numberWithInt:xyAxisXLen]];// 3個しかない
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithInt:-1200] length:[NSNumber numberWithInt:2400]];
}

-(void)addScatterPlot:(NSString*)identifier withColor:(CPTColor*)scatterColor
{
    // plotを作成する
    CPTScatterPlot *scatterPlot = [[CPTScatterPlot alloc] init];
    scatterPlot.dataSource = self;
    scatterPlot.identifier = identifier;
    scatterPlot.interpolation = CPTScatterPlotInterpolationCurved;
    scatterPlot.title = identifier;

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
    y.majorIntervalLength = [NSNumber numberWithInt:200];// 2000/200 = 10
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

-(CPTColor*)getScatterColorWithSensorAxis:(AirSensorAxis)axis
{
    CPTColor* scatterColor = [CPTColor redColor];
    
    if (axis == AirSensorAxisX) {
        scatterColor = [CPTColor redColor];
    } else if (axis == AirSensorAxisY) {
        scatterColor = [CPTColor blueColor];
    } else if (axis == AirSensorAxisZ) {
        scatterColor = [CPTColor greenColor];
    }
    
    return scatterColor;
}

-(void)addSensorData:(double)data toList:(NSMutableDictionary*)dataList forAxis:(NSString*)axis
{
    //DEBUGLOG(@"%f", data);
    
    NSMutableArray *axisDataList = [dataList objectForKey:axis];
    if (axisDataList == nil) {
        axisDataList = [NSMutableArray array];
        [dataList setObject:axisDataList forKey:axis];
    }
    
    NSNumber *numData = [NSNumber numberWithDouble:data*1000];
    [axisDataList addObject:numData];
    
    // グラフ表示範囲超えた場合、古いデータ削除。(todo:今後全データのフラグを見る場合、ScrollViewで対応)
    int sub = (int)[axisDataList count] - self.xyAxisXLen;
    if (sub >= 0) {
        NSRange deleteRan = NSMakeRange(0, sub);
        [axisDataList removeObjectsInRange:deleteRan];
    }
}

-(void)updateGraph:(CPTGraph*)graph
{
    if (graph != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [graph reloadData];// 1/100且つ多いデータがたまると表示に遅延発生。とりあえず1sのデータ描画
            //[graph reloadDataIfNeeded];// NG
            //[graph needsDisplay];// NG
        });
    }
}

-(void)setSensorType:(AirSensorType)type
{
    _type = type;
    
    if (type == AirSensorTypeAccelerationHigh) {
        _axisCount = 3;
    } else if (type == AirSensorTypeGyro) {
        _axisCount = 3;
    } else if (type == AirSensorTypeAttitude) {
        _axisCount = 3;
    } else {
        _axisCount = 0;
    }
}

-(void)addAccelerationData:(AirSensorAcceleration*)data
{
    //DEBUGLOG(@"addAccelerationData");
    if (data != nil) {
        CPTGraph *graph = self.hostingView.hostedGraph;

        [self addSensorData:data.x toList:_accelerationDataList forAxis:@"AxisX"];
        [self addSensorData:data.y toList:_accelerationDataList forAxis:@"AxisY"];
        [self addSensorData:data.z toList:_accelerationDataList forAxis:@"AxisZ"];
        
        if (_type == AirSensorTypeAccelerationHigh) {
            [self updateGraph:graph];
        }
    }
}

-(void)addGyroData:(AirSensorRotationRate*)data
{
    if (data != nil) {
        CPTGraph *graph = self.hostingView.hostedGraph;
        
        [self addSensorData:data.x toList:_gyroDataList forAxis:@"AxisX"];
        [self addSensorData:data.y toList:_gyroDataList forAxis:@"AxisY"];
        [self addSensorData:data.z toList:_gyroDataList forAxis:@"AxisZ"];
        
        if (_type == AirSensorTypeGyro) {
            [self updateGraph:graph];
        }
    }
}

-(void)addAttitudeData:(AirSensorRotationRate*)data
{
    if (data != nil) {
        CPTGraph *graph = self.hostingView.hostedGraph;
        
        [self addSensorData:data.pitch toList:_attitudeDataList forAxis:@"AxisX"];
        [self addSensorData:data.roll toList:_attitudeDataList forAxis:@"AxisY"];
        [self addSensorData:data.yaw toList:_attitudeDataList forAxis:@"AxisZ"];
        
        if (_type == AirSensorTypeAttitude) {
            [self updateGraph:graph];
        }
    }
}

-(void)clear
{
    if (_accelerationDataList != nil && _accelerationDataList.count > 0) {
        [_accelerationDataList removeAllObjects];
    }
    
    if (_gyroDataList != nil && _gyroDataList.count > 0) {
        [_gyroDataList removeAllObjects];
    }
    
    if (_attitudeDataList != nil && _attitudeDataList.count) {
        [_attitudeDataList removeAllObjects];
    }
}

// # CPTPlotDataSource protocol

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
    //DEBUGLOG(@"numberForPlot(%@):[%lu, %lu]", (NSString*)plot.identifier, (unsigned long)fieldEnum, (unsigned long)idx);
    
    NSNumber* num = [NSNumber numberWithInt:-1]; // error
    NSDictionary* dataList = [NSDictionary dictionary];
    NSArray* axisDataList;
    
    if (_type == AirSensorTypeAccelerationHigh) {
        dataList = _accelerationDataList;
    } else if (_type == AirSensorTypeGyro) {
        dataList = _gyroDataList;
    } else if (_type == AirSensorTypeAttitude) {
        dataList = _attitudeDataList;
    }
    
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            num = [NSNumber numberWithUnsignedInteger:idx];
            break;
        case CPTScatterPlotFieldY:
            axisDataList = (NSArray*)[dataList objectForKey:(NSString*)plot.identifier];
            if (axisDataList != nil) {
                num = [axisDataList objectAtIndex:idx];
            }
            break;
    }
    
    return num;
}

// 1graphのデータ数(X軸で良い?)
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSDictionary* dataList = [NSDictionary dictionary];
    uint num = 0;
    
    if (_type == AirSensorTypeAccelerationHigh) {
        dataList = _accelerationDataList;
    } else if (_type == AirSensorTypeGyro) {
        dataList = _gyroDataList;
    } else if (_type == AirSensorTypeAttitude) {
        dataList = _attitudeDataList;
    }
    
    NSArray* axisDataList = (NSArray*)[dataList objectForKey:(NSString*)plot.identifier];
    if (axisDataList != nil) {
        num = (uint)[axisDataList count];
    }
    
    //DEBUGLOG(@"numberOfRecordsForPlot:[%u]", num);
    
    return num;
}

@end