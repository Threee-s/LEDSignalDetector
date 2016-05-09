//
//  SmartEyeW.mm
//  SmartEye
//
//  Created by 文 光石 on 2014/10/06.
//  Copyright (c) 2014年 TreeeS. All rights reserved.
//

#import <Foundation/Foundation.h>

//.mmにしないとc++のヘッダファイル認識出来ない
#import <iostream>
#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/core/core.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/imgcodecs/ios.h>

#import "SmartEyeW.h"
#import "FileManager.h"
#import "ConfigManager.h"
#import "SmartEye.h"
//#include "SmartEyeLog.h"
#include "Log.h"


using namespace std;
using namespace cv;

@implementation SignalW

/*
@synthesize kind;
@synthesize type;
@synthesize color;
@synthesize state;
@synthesize level;
@synthesize rect;
@synthesize pixel;
@synthesize distance;
@synthesize rectId;
@synthesize signalId;
*/

- (NSString *)description
{
    NSString *des = @"SignalW";
    
    des = [NSString stringWithFormat:@"rectId:%lu, signalId:%lu, kind:%d, type:%d, color:%d, state:%d, level:%d rect:[%.2f, %.2f, %.2f, %.2f], pixel:%d", _rectId, _signalId, _kind, _type, _color, _state, _level, _rect.origin.x, _rect.origin.y, _rect.size.width, _rect.size.height, _pixel];
    
    return des;
}

@end

@interface DebugInfoW()


@end

@implementation DebugInfoW

- (NSString *)description
{
    return _des;
}

- (void)addInfo:(NSString*)info
{
    
}

@end

@implementation ContourPoint

- (id)initWithX:(float)x andY:(float)y
{
    if (self = [super init]) {
        _x = x;
        _y = y;
    }
    
    return self;
}

- (NSDictionary*)jsonDic
{
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setValue:[NSNumber numberWithFloat:_x] forKey:@"x"];
    [dic setValue:[NSNumber numberWithFloat:_y] forKey:@"y"];
    
    return dic;
}

@end

@implementation CollectionInfoW

- (id)init
{
    if (self = [super init]) {
        _imageContours = [[NSMutableArray alloc] init];
        _pattern = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSDictionary*)jsonDic
{
    //NSDictionary* dic = @{@"contours": _imageContours, @"pattern": _pattern};
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setValue:_imageContours forKey:@"contours"];
    [dic setValue:_pattern forKey:@"pattern"];
    
    return dic;
}

- (NSString*)description
{
    return _des;
}

@end


@interface SmartEyeW()

// todo:内部関数化
+(BOOL)isValidPixel:(int)pixel inScopeLower:(int)lower andUpper:(int)upper;
+(void)matFromUIImage:(UIImage*)image mat:(Mat&)mat;// todo:memory?
+(void)matFromSampleBufferRef:(CMSampleBufferRef)sampleBuffer mat:(Mat&)mat;// memo:share memory
+(void)matFromCGImage:(CGImageRef)image mat:(Mat&)mat;// allocate memory

@end

@implementation SmartEyeW : NSObject

+(BOOL)isValidPixel:(int)pixel inScopeLower:(int)lower andUpper:(int)upper
{
    if (lower <= upper){
        if ((lower <= pixel) && (pixel <= upper)) {
            return TRUE;
        } else {
            return FALSE;
        }
    } else {
        if ((pixel <= upper) || (lower <= pixel)) {
            return TRUE;
        } else {
            return FALSE;
        }
    }
}

+(void)matFromUIImage:(UIImage*)image mat:(Mat&)mat
{
    // todo:buffer/image orientation?
    UIImageToMat(image, mat);
}

+(void)matFromSampleBufferRef:(CMSampleBufferRef)sampleBuffer mat:(Mat&)mat
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    unsigned char* base = (unsigned char*)CVPixelBufferGetBaseAddress(pixelBuffer);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    mat = Mat(width, height, CV_8UC4, base);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

// todo:呼び出し元でメモリ解放
+(void)matFromCGImage:(CGImageRef)image mat:(Mat&)mat
{
    // ピクセルバッファを作成するためのオプションを設定
    NSDictionary *options = @{
                              (NSString *)kCVPixelBufferCGImageCompatibilityKey : @(YES),
                              (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES),
                              };
    
    CVPixelBufferRef buffer = NULL;
    // memo:orientationによって、image.size.widthと異なる(orientation:0のサイズを取っている?)
    // image.size.xxxはorientationの情報を見て、システムが正常に回転した後の画像のxxxになっている（実際表示上の向きのxxxと同じ。デバイス/UIInterfaceなどの向きと関係ある）。
    // CGImageGetxxxは実際のバッファーからxxxの情報を取得する。例えば、landscapeでキャプチャーした場合、実際のデータはlandscape形式で作成されるとので、デバイスがportraitで正常に表示されても、landscapeデータのxxxになる
    size_t imageWidth = CGImageGetWidth(image);
    size_t imageHeight = CGImageGetHeight(image);
    //CGFloat width = size.width;
    //CGFloat height = size.height;
    
    //DEBUGLOG(@"UIImage orientation(before):%ld width:%d height:%d", (long)image->orientation, imageWidth, imageHeight);
    
    // ピクセルバッファを作成
    CVPixelBufferCreate(kCFAllocatorDefault,
                        imageWidth,
                        imageHeight,
                        kCVPixelFormatType_32ARGB,// 4byte -> size:imageWidth * 4 * imageHeight
                        (__bridge CFDictionaryRef)options,
                        &buffer);
    
    // ピクセルバッファをロック(readonly:1?)
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    // ピクセルバッファのベースアドレスのポインタを返す(描画用)
    void *base = CVPixelBufferGetBaseAddress(buffer);
    size_t width = CVPixelBufferGetWidth(buffer);// == imageWidth
    size_t height = CVPixelBufferGetHeight(buffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);//imageWidth * 4
    
    // memo:CGImageGetxxxと同じ
    DEBUGLOG(@"PixelImage(before) width:%zu height:%zu bytesPerRow:%zu", width, height, bytesPerRow);
    
    // カラースペースとコンテキストの作成
    CGColorSpaceRef rgbColorSpace = CGImageGetColorSpace(image);
    // memo:向きはあくまでの付加？情報(正しく表示される向き)。実際物理(バッファー)データと向きの情報は異なる可能性がある。
    // transform変換処理を行う場合、バッファーデータ（の向き：ピクセル？配置情報）を基準に変換する必要がある(contextが変換後描画できる配置にする)。
    CGContextRef context = CGBitmapContextCreate(
                                                 base,
                                                 width,
                                                 height,
                                                 8, // RGBのbit数(メモリ内のピクセルの各成分に使用するビット数) bitsPerComponent
                                                 //4 * width, // size per line (bytes) // 向き変換する時、heightになるので
                                                 bytesPerRow,// 向きと関係ないかも。実際変換後の向きに合わせる必要がある
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    // カラースペースとコンテキストを解放
    //CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    mat = Mat((int)width, (int)height, CV_8UC4, base);
    
    // ピクセルバッファのロックを解除
    CVPixelBufferUnlockBaseAddress(buffer, 0);
}

+(UIImage*)captureImageFromCamera
{
    // 0:デフォルトカメラをオープン
    VideoCapture cap(0);//AV Foundation didn't find any attached Video Input Devices!
    if(!cap.isOpened()) {// SimulatorでNG
        return nil;
    }
    
    Mat frame;
    cap >> frame;
    
    return MatToUIImage(frame);
}

+(UIImage*)loadImage:(NSString*)fileName
{
    string strName([fileName UTF8String]);
    Mat image = imread(strName);
    //namedWindow("lenna");// exception. not implemented. needed GTK++
    //imshow("lenna", image);
    //waitKey(0);
    
    return MatToUIImage(image);
}

+(UIImage*)loadVideoFromFile:(NSString*)fileName
{
    string strName([fileName UTF8String]);
    VideoCapture video(strName);
    
    /*
     //namedWindow("hoge");
     while(1){
     Mat frame;
     video >> frame;
     //フレームが空か、ボタンが押された時か一周したときに出る。
     if(frame.empty() || waitKey(30) >= 0 || video.get(CV_CAP_PROP_POS_AVI_RATIO) == 1){
     break;
     }
     //imshow("hoge", frame);
     }*/
    
    Mat frame;
    video >> frame;
    
    return MatToUIImage(frame);
}

+(UIImage*)DetectEdgeWithImage:(UIImage *)image
{
    Mat mat;
    UIImageToMat(image, mat);
    
    Mat gray;
    cvtColor(mat, gray, CV_BGR2GRAY);
    
    Mat edge;
    Canny(gray, edge, 200, 200);
    
    UIImage *edgeImg = MatToUIImage(edge);
    
    return edgeImg;
}

+(UIImage*)BGR2HSVWithImage:(UIImage*)image
{
    Mat bgr;
    UIImageToMat(image, bgr);
    
    Mat hsv;
    //cvtColor(bgr, hsv, CV_BGR2HSV);
    cvtColor(bgr, hsv, CV_RGB2HSV);
    
    return MatToUIImage(hsv);
}

+(UIImage*)colorExtractionWithImage:(UIImage*)image
//code:(int)code
                       chanel1Lower:(int)ch1Lower
                       chanel1upper:(int)ch1Upper
                       chanel2Lower:(int)ch2Lower
                       chanel2Upper:(int)ch2Upper
                       chanel3Lower:(int)ch3Lower
                       chanel3Upper:(int)ch3Upper
{
    Mat src;
    UIImageToMat(image, src);//RGBになる
    
    Mat colorImage;
    //int code = CV_BGR2HSV;
    int code = CV_RGB2HSV;
    
    int lower[3];
    int upper[3];
    
    Mat lut = Mat(256, 1, CV_8UC3);
    
    cvtColor(src, colorImage, code);
    
    lower[0] = ch1Lower;
    lower[1] = ch2Lower;
    lower[2] = ch3Lower;
    
    upper[0] = ch1Upper;
    upper[1] = ch2Upper;
    upper[2] = ch3Upper;
    
    for (int i = 0; i < 256; i++){
        for (int k = 0; k < 3; k++){
            if (lower[k] <= upper[k]){
                if ((lower[k] <= i) && (i <= upper[k])){
                    lut.data[i*lut.step+k] = 255;
                }else{
                    lut.data[i*lut.step+k] = 0;
                }
            }else{
                if ((i <= upper[k]) || (lower[k] <= i)){
                    lut.data[i*lut.step+k] = 255;
                }else{
                    lut.data[i*lut.step+k] = 0;
                }
            }
        }
    }
    
    //LUTを使用して二値化
    LUT(colorImage, lut, colorImage);
    
    //Channel毎に分解
    std::vector<Mat> planes;
    split(colorImage, planes);
    
    //マスクを作成
    Mat maskImage;
    bitwise_and(planes[0], planes[1], maskImage);
    bitwise_and(maskImage, planes[2], maskImage);
    
    //マスクをかけた画像
    Mat maskedImage;
    src.copyTo(maskedImage, maskImage);
    
    return MatToUIImage(maskedImage);
    
    //出力
    //Mat dst;
    //cvtColor(maskedImage, dst, CV_HSV2RGB);//RGBに変換
    
    //return MatToUIImage(dst);//落ちる？！
}

+(UIImage*)detectLEDArea:(UIImage*)image
{
    Mat bgr;
    UIImageToMat(image, bgr);// RGBになっている？（imageがRGBなので？）
    
    Mat hsv;
    cvtColor(bgr, hsv, CV_RGB2HSV);//BGR2HSVの場合、色が合わない
    
    int lower[3];
    int upper[3];
    
    Mat lut = Mat(256, 1, CV_8UC3);//256行1列の8bit3チャンネル
    
    lower[0] = 170;
    lower[1] = 100;
    lower[2] = 70;
    
    upper[0] = 10;
    upper[1] = 255;
    upper[2] = 255;
    
    int hCnt = 0;
    int sCnt = 0;
    int vCnt = 0;// 赤/青部分の明るさが>Xの数
    // 下記方法NG.フィルタ用配列なので、実際の画素ではない。値が常に同じ（上記範囲によって変動）
    // フィルタをかけてから、値を取得
    
    for (int i = 0; i < 256; i++){
        
        //todo Hは0~180なので、256ループでOK?HSVについて確認。thresholdで抽出してみる
        if ([SmartEyeW isValidPixel:i inScopeLower:lower[0] andUpper:upper[0]] == TRUE) {
            lut.data[i*lut.step] = 255;
            hCnt++;
            
            if ([SmartEyeW isValidPixel:i inScopeLower:lower[1] andUpper:upper[1]] == TRUE) {
                lut.data[i*lut.step + 1] = 255;
                sCnt++;
            } else {
                lut.data[i*lut.step + 1] = 0;
            }
            
            // todo 平均明るさ計算してみる（OR閾値を設定して判断）。点滅判断。
            // 色の部分（信号以外もある）が大体決まっているので、明るさで点滅判断。
            // 輪郭などで信号部分を別途抽出し、明るさ判断
            // 赤/青と関係なく、どちらか/両方で点滅すれば、信号と判断。最後のframeの色で、信号色判断
            if ([SmartEyeW isValidPixel:i inScopeLower:lower[2] andUpper:upper[2]] == TRUE) {
                lut.data[i*lut.step + 2] = 255;
                vCnt++;
            } else {
                lut.data[i*lut.step + 2] = 0;
            }
        } else {
            lut.data[i*lut.step] = 0;
            lut.data[i*lut.step + 1] = 0;
            lut.data[i*lut.step + 2] = 0;
        }
        
    }
    
    //cout << "Count of [H, S, V] : " << "[" << hCnt << ", " << sCnt << ", " << vCnt << "]" << endl;
    
    //LUTを使用して二値化(0/255に変換)
    LUT(hsv, lut, hsv);
    
    //Channel毎に分解(各チャンネルの0/255値取得)
    // hsvは色抽出前（色空間変換後のオリジナル画像）
    std::vector<Mat> planes;
    split(hsv, planes);
    
#if false
    // test
    int vRows = planes[2].rows;
    int vCols = planes[2].cols;
    vCnt = 0;
    
    cout << "rows:" << vRows << " cols:" << vCols << endl;
    for (int i = 0; i < vRows; i++) {
        for (int j = 0; j < vCols; j++) {
            uchar pixelV = planes[2].at<uchar>(i, j);
            //cout << pixelV << endl;
            //NSLog(@"[%d, %d] : 0x%x(%d)", i, j, pixelV, pixelV);
            // 指定色範囲内ではななく、全体(オリジナル画像）のVになっている？（255の数が多いので）
            if (pixelV == 0xff) {
                vCnt++;
            }
        }
    }
    
    
    cout << "Count of [H, S, V] : " << "[" << hCnt << ", " << sCnt << ", " << vCnt << "]" << endl;
#endif
    
    //マスクを作成。各チャンネル指定範囲内の値が255になる(指定色抽出。SとVは指定範囲内)
    Mat maskImage;
    bitwise_and(planes[0], planes[1], maskImage);
    bitwise_and(maskImage, planes[2], maskImage);
    
#if true
    // test
    // 行数 列数 次元数 各次元のサイズ
    cout << "rows:" << maskImage.rows << " cols:" << maskImage.cols << " dims:" << maskImage.dims << " size:[ ";
    
    for (int i = 0; i < maskImage.dims; i++) {
        cout << maskImage.size[i] << " ";
    }
    cout << "]" << endl;
    
    // total()?要素の総数
    int rows = maskImage.rows;
    int cols = maskImage.cols;
    int hsvCnt[3] = { 0 };
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            Vec3b pixel = maskImage.at<Vec3b>(i, j);
            //cout << pixel << endl;
            for (int k = 0; k < 3; k++) {
                if (pixel.val[k] == 0xff) {
                    hsvCnt[k]++;
                }
            }
        }
    }
    
    
    cout << "Count of [H, S, V] : " << "[" << hsvCnt[0] << ", " << hsvCnt[1] << ", " << hsvCnt[2] << "]" << endl;
#endif
    
#if false
    // 輪郭の検出
    Mat contourImage;
    maskImage.copyTo(contourImage);
    std::vector<std::vector<Point> > contours;
    std::vector<Vec4i> hierarchy;
    // 2値画像，輪郭（出力），階層構造（出力），輪郭抽出モード，輪郭の近似手法
    // todo:詳細確認。
    //findContours(contourImage, contours, hierarchy, RETR_TREE, CHAIN_APPROX_SIMPLE);
    findContours(contourImage, contours, CV_RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
    
    // todo:contoursの内容確認。信号領域抽出。
    int contourSize = (int)contours.size();
    cout << "contourSize : " << contourSize << endl;
    for (int pos = 0; pos < contourSize; pos++) {
        vector<Point> contour = contours.at(pos);
        int pointSize = (int)contour.size();
        //NSLog(@"pointSize : %d", pointSize);
        for (int pos2 = 0; pos2 < pointSize; pos2++) {
            Point point = contour.at(pos2);
            cout << "[" << point.x << ", " << point.y << "]";
        }
        cout << endl;
    }
    
    //#if true
    // 輪郭の描画
    // 画像，輪郭，描画輪郭指定インデックス，色，太さ，種類，階層構造，描画輪郭の最大レベル
    drawContours(bgr,
                 contours,
                 -1,//contour_index,
                 Scalar(0, 0, 100),
                 3,
                 CV_AA,
                 hierarchy,
                 0//max_level
                 );
    return MatToUIImage(bgr);
    
#else
    return MatToUIImage(maskImage);
#endif
    
}


+(UIImage*)detectLED:(UIImage*)image
{
    Mat dstImage;
    vector<SEColorSpaceRange> areas;
    //int vCount;
    SmartEye se = SmartEye::getInstance();
    
    
    // test 最後で失敗(200loopの場合、200回終わってから落ちる)
    /*
    UIImage* correctImage = image;
    UIGraphicsBeginImageContext(correctImage.size);
    [correctImage drawInRect:CGRectMake(0, 0, correctImage.size.width, correctImage.size.height)];
    correctImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageToMat(correctImage, orgImage);// RGBになっている？（imageがRGBなので？）
     */
    
    
    /* test（未確認）
    // 画像の回転を補正する（内蔵カメラで撮影した画像などでおかしな方向にならないようにする）
    UIImage* correctImage = image;
    UIGraphicsBeginImageContext(correctImage.size);
    [correctImage drawInRect:CGRectMake(0, 0, correctImage.size.width, correctImage.size.height)];
    correctImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
     */
    
    
    
    // OK!!
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat orgImage(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(orgImage.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    orgImage.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    
    
    //UIImage* testImage = [UIImage imageNamed:[[NSBundle mainBundle] pathForResource:@"lenna" ofType:@"png"]];
    //UIImageToMat(testImage, orgImage);//NG
    
    //UIImageToMat(image, orgImage);// RGBになっている？（imageがRGBなので？）
    
    
    // test
    areas.push_back({170, 10});
    areas.push_back({100, 255});
    areas.push_back({70, 255});
    
    se.getLightness(&orgImage, CV_RGB2HSV, areas, &dstImage);
    //vCount = se.getLightness(&orgImage, COLOR_BGR2HSV, areas, &dstImage);
    //vCount = se.getLightness(&orgImage, CV_BGR2HSV, areas, &dstImage);

    return MatToUIImage(dstImage);
}


+(void)setConfig
{
    SmartEye se = SmartEye::getInstance();
    ConfigManager *cm = [ConfigManager sharedInstance];
    SESignalConf conf = {0};
    
    bool debugMode = cm.confSettings.debugMode.flag;
    if (debugMode == true) {
        conf.binImageDrawFlag = cm.confSettings.debugMode.binary;
        conf.pointDrawFlag = cm.confSettings.debugMode.point;
        conf.rectDrawFlag = cm.confSettings.debugMode.rect;
        conf.areaDrawFlag = cm.confSettings.debugMode.area;
        conf.signalDrawFlag = cm.confSettings.debugMode.signal;
        conf.centerDrawFlag = cm.confSettings.debugMode.center;
        conf.frameDrawFlag = cm.confSettings.debugMode.collection;
        conf.debugInfoFlag = cm.confSettings.debugMode.log;
        conf.collectionInfoFlag = cm.confSettings.debugMode.collection;
    } else {
        conf.binImageDrawFlag = false;
        conf.pointDrawFlag = false;
        conf.rectDrawFlag = false;
        conf.areaDrawFlag = false;
        conf.signalDrawFlag = false;
        conf.centerDrawFlag = false;
        conf.frameDrawFlag = false;
        conf.debugInfoFlag = false;
    }
    
    // とりあえずtrue。plistで設定しない。通常は最低シグナル検出矩形を描画
    conf.drawFlag = true;
    conf.reset = true;
    
    conf.frequency = 100;
    // default pedestrian
    //this->signalConf->frameSize = cv::Size(SE_SIGNAL_SIZE_PEDESTRIAN_250, SE_SIGNAL_SIZE_PEDESTRIAN_250);
    //conf.frameSize = cv::sqrt(cv::pow(SE_SIGNAL_SIZE_PEDESTRIAN_250, 2.0) * 2);
    conf.frameSize = SE_SIGNAL_SIZE_PEDESTRIAN_250;
    conf.focalLength = SE_CAMERA_FOCAL_LENGTH_415mm; // 0の場合、距離計算しない
    conf.sensorSize = SE_CAMERA_SENSOR_SIZE_620mm;
    conf.fps = 30;
    conf.imgOri = cm.confSettings.detectParams.imageSetting.orientation;
    conf.combineCountThreshold = cm.confSettings.detectParams.combinePoint.threshold;
    conf.combineOffset = cm.confSettings.detectParams.combinePoint.offset;
    conf.integrateRectProp = cm.confSettings.detectParams.integrateRect.prop;
    conf.integrateRectOffset = cm.confSettings.detectParams.integrateRect.offset;
    conf.validRectMinWidth = cm.confSettings.detectParams.validRectMin.width;
    conf.validRectMaxWidth = cm.confSettings.detectParams.validRectMax.width;
    conf.validRectMinHeight = cm.confSettings.detectParams.validRectMin.height;
    conf.validRectMaxHeight = cm.confSettings.detectParams.validRectMax.height;
    conf.compareRectDist = cm.confSettings.detectParams.compareRect.dist;
    conf.compareRectScale = cm.confSettings.detectParams.compareRect.scale;
    conf.recogSignalLightnessDiff = cm.confSettings.detectParams.recogonizeSignal.lightnessDiff;
    conf.recogSignalCompRectDiffCount = cm.confSettings.detectParams.recogonizeSignal.compareSignal.diffCount;
    conf.recogSignalCompRectInvalidCount = cm.confSettings.detectParams.recogonizeSignal.compareSignal.invalidCount;
    
    conf.detectColors = cm.confSettings.colorSettings.detectColors;
    conf.signalRed.h.lower = cm.confSettings.colorSettings.colorSpaceRed.h.lower;
    conf.signalRed.h.upper = cm.confSettings.colorSettings.colorSpaceRed.h.upper;
    conf.signalRed.s.lower = cm.confSettings.colorSettings.colorSpaceRed.s.lower;
    conf.signalRed.s.upper = cm.confSettings.colorSettings.colorSpaceRed.s.upper;
    conf.signalRed.v.lower = cm.confSettings.colorSettings.colorSpaceRed.v.lower;
    conf.signalRed.v.upper = cm.confSettings.colorSettings.colorSpaceRed.v.upper;
    conf.signalGreen.h.lower = cm.confSettings.colorSettings.colorSpaceGreen.h.lower;
    conf.signalGreen.h.upper = cm.confSettings.colorSettings.colorSpaceGreen.h.upper;
    conf.signalGreen.s.lower = cm.confSettings.colorSettings.colorSpaceGreen.s.lower;
    conf.signalGreen.s.upper = cm.confSettings.colorSettings.colorSpaceGreen.s.upper;
    conf.signalGreen.v.lower = cm.confSettings.colorSettings.colorSpaceGreen.v.lower;
    conf.signalGreen.v.upper = cm.confSettings.colorSettings.colorSpaceGreen.v.upper;
    conf.signalCenter.h.lower = cm.confSettings.colorSettings.colorSpaceCenter.h.lower;
    conf.signalCenter.h.upper = cm.confSettings.colorSettings.colorSpaceCenter.h.upper;
    conf.signalCenter.s.lower = cm.confSettings.colorSettings.colorSpaceCenter.s.lower;
    conf.signalCenter.s.upper = cm.confSettings.colorSettings.colorSpaceCenter.s.upper;
    conf.signalCenter.v.lower = cm.confSettings.colorSettings.colorSpaceCenter.v.lower;
    conf.signalCenter.v.upper = cm.confSettings.colorSettings.colorSpaceCenter.v.upper;
    
    DEBUGLOG_PRINTF(@"DebugInfo:%d BinaryImageDraw:%d PointDraw:%d RectDraw:%d AreaDraw:%d SignalDraw:%d CenterDrawFlag:%d FrameDrawFlag:%d ImageOrientation:%d CombineCountThreshold:%d CombineOffset:%d IntegrateRectProp:%f IntegrateRectOffset:%d IntegrateValidRectMinWidth:%d IntegrateValidRectMaxWidth:%d IntegrateValidRectMinHeight:%d IntegrateValidRectMaxHeight:%d CompareRectDist:%f CompareRectScale:%f RecogSignalLightnessDiff:%f RecogSignalCompRectDiffCount:%d RecogSignalCompRectInvalidCount:%d DetectColors:%d", conf.debugInfoFlag, conf.binImageDrawFlag, conf.pointDrawFlag, conf.rectDrawFlag, conf.areaDrawFlag, conf.signalDrawFlag, conf.centerDrawFlag, conf.frameDrawFlag, conf.imgOri, conf.combineCountThreshold, conf.combineOffset, conf.integrateRectProp, conf.integrateRectOffset, conf.validRectMinWidth, conf.validRectMaxWidth, conf.validRectMinHeight, conf.validRectMaxHeight, conf.compareRectDist, conf.compareRectScale, conf.recogSignalLightnessDiff, conf.recogSignalCompRectDiffCount, conf.recogSignalCompRectInvalidCount, conf.detectColors);
    
    DEBUGLOG_PRINTF(@"Red:[%d, %d], [%d, %d], [%d, %d]", conf.signalRed.h.lower, conf.signalRed.h.upper, conf.signalRed.s.lower, conf.signalRed.s.upper, conf.signalRed.v.lower, conf.signalRed.v.upper);

    DEBUGLOG_PRINTF(@"Green:[%d, %d], [%d, %d], [%d, %d]", conf.signalGreen.h.lower, conf.signalGreen.h.upper, conf.signalGreen.s.lower, conf.signalGreen.s.upper, conf.signalGreen.v.lower, conf.signalGreen.v.upper);
    
    DEBUGLOG_PRINTF(@"Center:[%d, %d], [%d, %d], [%d, %d]", conf.signalCenter.h.lower, conf.signalCenter.h.upper, conf.signalCenter.s.lower, conf.signalCenter.s.upper, conf.signalCenter.v.lower, conf.signalCenter.v.upper);
    
    se.setupLEDSignalConfig(&conf);
}

+(UIImage*)detectSignal:(UIImage*)image inRect:(CGRect)rect signals:(NSMutableArray*)signalList debugInfo:(DebugInfoW*)info
{
//    [Log debug:@"=== detect start ==="];
    
    double startTime = CFAbsoluteTimeGetCurrent();
    Mat dstImage;
    std::vector<SESignal> signals;
    SEDebugInfo debugInfo;
    SEFrameInfo framInfo;
    int count;
    SmartEye se = SmartEye::getInstance();
    framInfo.detectRect = cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    framInfo.debugInfoFlag = YES;
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    //CGFloat cols = image.size.width;// orientationによって、bufferの向きと異なる可能性がある
    //CGFloat rows = image.size.height;
    CGFloat cols = CGImageGetWidth(image.CGImage);
    CGFloat rows = CGImageGetHeight(image.CGImage);
    
    // メモリ確保
    Mat orgImage(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(orgImage.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    orgImage.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    // imageをorgImageへ描画(context/orgImage.data:バッファー先頭アドレスへデータコピー)
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    //CGColorSpaceRelease(colorSpace);// createしていないので、解放しない
    CGContextRelease(contextRef);
    
    
    // オリジナル画像へ描画用
    //orgImage.copyTo(dstImage);
    // 信号検出
    count = se.getLEDSignalPedestrian(&orgImage, &dstImage, signals, &debugInfo, SE_COLOR_SPACE_RGB, CV_RGB2HSV, &framInfo);
    //count = se.getLEDSignalPedestrian(&orgImage, &dstImage, signals, &debugInfo, SE_COLOR_SPACE_BGR, CV_BGR2HSV, &framInfo);
//    cout << "signal count:" << count << endl;
    
    // memo: draw on orgImage
    orgImage.copyTo(dstImage);
    //cvtColor(orgImage, dstImage, CV_HSV2RGB);//NG
    
    NSMutableArray* signalArray = (NSMutableArray*)signalList;
    
    for (int i = 0; i < count; i++) {
        SESignal signal = signals.at(i);
        SignalW *signalW = [[SignalW alloc] init];
        //SignalW signalW;
        
        signalW.rectId = signal.rectId;
        signalW.signalId = signal.signalId;
        signalW.kind = signal.kind;
        signalW.type = signal.type;
        signalW.color = signal.color;
        signalW.state = signal.state;
        signalW.level = signal.level;
        signalW.pixel = signal.pixel;
        signalW.probability = signal.probability;
        signalW.circleLevel = signal.circleLevel;
        signalW.matching = signal.matching;
        signalW.distance = signal.guideInfo.distance;
        signalW.direction = signal.guideInfo.direction;
        signalW.time = signal.guideInfo.time;
        signalW.position = signal.guideInfo.position;
        signalW.rect = CGRectMake(signal.rect.x, signal.rect.y, signal.rect.width, signal.rect.height);
        
        [signalArray addObject:signalW];
    }
    
    
    int rectsCount = (int)debugInfo.currentRectsList.size();
    if (rectsCount > 0) {
        NSString *debugDes = [NSString stringWithFormat:@"<===========[%d]===========>\n", rectsCount];
        NSString *allFlags = @"";
        for (int i = 0; i < rectsCount; i++) {
            SESignalArea signalArea = debugInfo.currentRectsList.at(i);
            int rectCount = (int)signalArea.rects.size();
            unsigned long rectId = 0;
            NSString *rectFlags = @"";
            
            NSString *rectStr = @"";
            for (int j = 0; j < rectCount; j++) {
                SERectArea area = signalArea.rects.at(j);
                rectId = area.rectId;
                CGRect rect = CGRectMake(area.rect.x, area.rect.y, area.rect.width, area.rect.height);
                rectStr = [NSString stringWithFormat:@"%@%d->[%d], rect:[%.2f, %.2f, %.2f, %.2f] rectId:%lu, signalId:%lu, pixels:[%d, %d], area:%f, length:%f, color:%d, state:%d\n", rectStr, !area.nullRect, j+1, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, area.rectId, area.signalId, area.pixels, (int)area.averageLightness, area.area, area.length, area.color, area.state];
                
                rectFlags = [NSString stringWithFormat:@"%@%d", rectFlags, !area.nullRect];
            }
            allFlags = [NSString stringWithFormat:@"%@ID<%lu, %lu>=>[%@]\n", allFlags, rectId, signalArea.signalId, rectFlags];
            
            debugDes = [NSString stringWithFormat:@"%@%d[%d]=>ID:%lu\n[%@]\n%@", debugDes, i+1, rectCount, signalArea.signalId, rectFlags, rectStr];
        }
        info.des = debugDes;
        info.pattern = allFlags;
    }
    
    info.procTime = CFAbsoluteTimeGetCurrent() - startTime;
    
//    [Log debug:@"=== detect end ==="];
    
    return MatToUIImage(dstImage);
}

+(void)detectSignalWithSampleBuffer:(CMSampleBufferRef)sampleBuffer inRect:(CGRect)rect signals:(NSMutableArray*)signalList debugInfo:(DebugInfoW*)info
{
    double startTime = CFAbsoluteTimeGetCurrent();
    Mat dstImage;
    std::vector<SESignal> signals;
    SEDebugInfo debugInfo;
    SEFrameInfo framInfo;
    int count;
    SmartEye se = SmartEye::getInstance();
    framInfo.detectRect = cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // イメージバッファのロック
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    // todo:LandscapeRightでキャプチャーしているので、デバッグなどで結果画像表示時回転が必要。検出矩形も必要であれば回転
    // イメージバッファ情報の取得
    unsigned char* base = (uint8_t*)CVPixelBufferGetBaseAddress(buffer);
    // Get the pixel buffer width and height
    //size_t width = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    size_t extendedWidth = bytesPerRow / sizeof( uint32_t ); // each pixel is 4 bytes/32 bits
    
    // メモリはCVPixelと同じ
    Mat orgImage((int)height, (int)extendedWidth, CV_8UC4, base);// 8 bits per component, 4 channels
    
    // オリジナル画像へ描画用
    //orgImage.copyTo(dstImage);// todo:debugのためなので、直接orgImage使ったほうがパフォーマンスに良いかも
    
    // todo:ここでOK?
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    // 信号検出
    // memo:bufferの場合、色空間がBGRになる(kCVPixelFormatType_32BGRAでキャプチャしているので)
    count = se.getLEDSignalPedestrian(&orgImage, &dstImage, signals, &debugInfo, SE_COLOR_SPACE_BGR, CV_BGR2HSV, &framInfo);
    //    cout << "signal count:" << count << endl;
    double endTime = CFAbsoluteTimeGetCurrent() - startTime;
    
    NSMutableArray* signalArray = (NSMutableArray*)signalList;
    
    for (int i = 0; i < count; i++) {
        SESignal signal = signals.at(i);
        SignalW *signalW = [[SignalW alloc] init];
        //SignalW signalW;
        
        signalW.rectId = signal.rectId;
        signalW.signalId = signal.signalId;
        signalW.kind = signal.kind;
        signalW.type = signal.type;
        signalW.color = signal.color;
        signalW.state = signal.state;
        signalW.level = signal.level;
        signalW.pixel = signal.pixel;
        signalW.probability = signal.probability;
        signalW.circleLevel = signal.circleLevel;
        signalW.matching = signal.matching;
        signalW.distance = signal.guideInfo.distance;
        signalW.direction = signal.guideInfo.direction;
        signalW.time = signal.guideInfo.time;
        signalW.position = signal.guideInfo.position;
        signalW.rect = CGRectMake(signal.rect.x, signal.rect.y, signal.rect.width, signal.rect.height);
        signalW.procTime = endTime;
        
        [signalArray addObject:signalW];
    }
    
    
    int rectsCount = (int)debugInfo.currentRectsList.size();
    if (rectsCount > 0) {
        NSString *debugDes = [NSString stringWithFormat:@"<===========[%d]===========>\n", rectsCount];
        NSString *allFlags = @"";
        for (int i = 0; i < rectsCount; i++) {
            SESignalArea signalArea = debugInfo.currentRectsList.at(i);
            int rectCount = (int)signalArea.rects.size();
            unsigned long rectId = 0;
            NSString *rectFlags = @"";
            
            NSString *rectStr = @"";
            for (int j = 0; j < rectCount; j++) {
                SERectArea area = signalArea.rects.at(j);
                rectId = area.rectId;
                CGRect rect = CGRectMake(area.rect.x, area.rect.y, area.rect.width, area.rect.height);
                rectStr = [NSString stringWithFormat:@"%@%d->[%d], rect:[%.2f, %.2f, %.2f, %.2f] rectId:%lu, signalId:%lu, pixels:[%d, %d], area:%f, length:%f, color:%d, state:%d\n", rectStr, !area.nullRect, j+1, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, area.rectId, area.signalId, area.pixels, (int)area.averageLightness, area.area, area.length, area.color, area.state];
                
                rectFlags = [NSString stringWithFormat:@"%@%d", rectFlags, !area.nullRect];
            }
            allFlags = [NSString stringWithFormat:@"%@ID<%lu, %lu>=>[%@]\n", allFlags, rectId, signalArea.signalId, rectFlags];
            
            debugDes = [NSString stringWithFormat:@"%@%d[%d]=>ID:%lu\n[%@]\n%@", debugDes, i+1, rectCount, signalArea.signalId, rectFlags, rectStr];
        }
        info.des = debugDes;
        info.pattern = allFlags;
    }
    
    info.procTime = CFAbsoluteTimeGetCurrent() - startTime;
    
    //    [Log debug:@"=== detect end ==="];
    
    //return MatToUIImage(dstImage);
}

+(int)getExposureLevelWithSampleBuffer:(CMSampleBufferRef)sampleBuffer inRect:(CGRect)rect biasRangeMin:(int)minBias max:(int)maxBias drawFlag:(BOOL)flag
{
    int level = 0;
    double startTime = CFAbsoluteTimeGetCurrent();
    SmartEye se = SmartEye::getInstance();
    cv::Rect detectRect = cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // イメージバッファのロック
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    // todo:LandscapeRightでキャプチャーしているので、デバッグなどで結果画像表示時回転が必要。検出矩形も必要であれば回転
    // イメージバッファ情報の取得
    unsigned char* base = (uint8_t*)CVPixelBufferGetBaseAddress(buffer);
    // Get the pixel buffer width and height
    //size_t width = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    size_t extendedWidth = bytesPerRow / sizeof( uint32_t ); // each pixel is 4 bytes/32 bits
    
    // メモリはCVPixelと同じ
    Mat orgImage((int)height, (int)extendedWidth, CV_8UC4, base);// 8 bits per component, 4 channels
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    level = se.getExposureLevel(&orgImage, detectRect, minBias, maxBias, flag);
    //double endTime = CFAbsoluteTimeGetCurrent() - startTime;
    DEBUGLOG(@"getExposureLevel time:%f", CFAbsoluteTimeGetCurrent() - startTime);
    
    return level;
}

+(void)getCollectionInfo:(CollectionInfoW*)info
{
    SECollectionInfo collectionInfo;
    SEDebugInfo debugInfo;
    SmartEye se = SmartEye::getInstance();
    
    se.getCollectionInfo(&collectionInfo);
    se.getDebugInfo(&debugInfo);
    
    int contourListSize = (int)collectionInfo.imageContours.size();
    for (int i = 0; i < contourListSize; i++) {
        NSMutableArray *contourPoints = [NSMutableArray array];
        vector<cv::Point> points = collectionInfo.imageContours[i];
        int pointCount = (int)points.size();
        for (int j = 0; j < pointCount; j++) {
            cv::Point point = points[j];
            ContourPoint *contourPoint = [[ContourPoint alloc] initWithX:point.x andY:point.y];
            [contourPoints addObject:[contourPoint jsonDic]];
        }
        [info.imageContours addObject:contourPoints];
    }

    int rectsCount = (int)debugInfo.currentRectsList.size();
    for (int i = 0; i < rectsCount; i++) {
        SESignalArea signalArea = debugInfo.currentRectsList.at(i);
        int rectCount = (int)signalArea.rects.size();
        NSMutableArray *patternFlag = [NSMutableArray array];
        for (int j = 0; j < rectCount; j++) {
            SERectArea area = signalArea.rects.at(j);
            [patternFlag addObject:[NSNumber numberWithBool:!area.nullRect]];
        }
        [info.pattern addObject:patternFlag];
    }
}

+(void)getCollectionInfo_1:(CollectionInfoW*)info
{
    SECollectionInfo collectionInfo;
    SmartEye se = SmartEye::getInstance();
    
    se.getCollectionInfo(&collectionInfo);
    
    NSString *strContours = @"[";
    int contourListSize = (int)collectionInfo.imageContours.size();
    for (int i = 0; i < contourListSize; i++) {
        NSString *strPoints = @"[";
        //NSMutableArray *contourPoints = [NSMutableArray array];
        vector<cv::Point> points = collectionInfo.imageContours[i];
        int pointCount = (int)points.size();
        for (int j = 0; j < pointCount; j++) {
            cv::Point point = points[j];
            //ContourPoint *contourPoint = [[ContourPoint alloc] initWithX:point.x andY:point.y];
            //[contourPoints addObject:contourPoint];
            NSString *strPoint = [NSString stringWithFormat:@"{x:%d, y:%d}", point.x, point.y];
            strPoints = [NSString stringWithFormat:@"%@,%@", strPoints, strPoint];
        }
        strPoints = [NSString stringWithFormat:@"%@]", strPoints];
        strContours = [NSString stringWithFormat:@"%@,[%@]", strContours, strPoints];
        //[info.imageContours addObject:contourPoints];
    }
    strContours = [NSString stringWithFormat:@"%@]", strContours];
    info.des = strContours;
}

+(void)testRecognize
{
    SmartEye se = SmartEye::getInstance();
    se.testRecognize();
}

+(UIImage*)testInRange:(UIImage*)image
{
    SmartEye se = SmartEye::getInstance();

    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    // メモリ確保
    Mat orgImage(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(orgImage.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    orgImage.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    // imageをorgImageへ描画(context/orgImage.data:バッファー先頭アドレスへデータコピー)
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    //CGColorSpaceRelease(colorSpace);// createしていないので、解放しない
    CGContextRelease(contextRef);
    
    se.testInRange(&orgImage, SE_COLOR_SPACE_RGB);
    
    return MatToUIImage(orgImage);
}

+(void)testMatching:(UIImage*)image1 withImage:(UIImage*)image2 color:(int)color
{
    Mat mat1, mat2;
    
    UIImageToMat(image1, mat1);
    UIImageToMat(image2, mat2);
    
    SmartEye se = SmartEye::getInstance();
    se.testMatching(&mat1, &mat2, color);
}

@end
