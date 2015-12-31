//
//  VideoOperator.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2014/10/07.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class VideoOperator {
    
    private var videoImageGenerator: AVAssetImageGenerator? = nil
    private var times: [NSValue] = [NSValue(CMTime:kCMTimeZero)]
    private var procImageCount: Int = 0
    var videoImageView: UIImageView! = nil
    
    func setImageView(imageView: UIImageView) {
        self.videoImageView = imageView
    }

    func loadVideoFromFile(filePath: String?, fps: Float64) {
        
        if (FileManager.fileExists(filePath) != true) {
            print("file[\(filePath)] not exists")
            return;
        }
        
        // ファイルからassetを生成
        let fileURL = NSURL(fileURLWithPath: filePath!)
        let videoAsset = AVURLAsset(URL: fileURL, options: nil)
        
        // 画像キャプチャ用generator生成
        self.videoImageGenerator = AVAssetImageGenerator(asset: videoAsset)
        //generator.maximumSize = self.videoImageView.frame.size
        
        // test out
        
        
        // 動画期間
        let duration = CMTimeGetSeconds(videoAsset.duration)
        print("duration: \(duration)")
        
        let allFrame = (duration * fps)
        
        // test 途中画像解析でエラーが発生（原因不明、未調査）適当に減らしてみる.SmartEyeWで解決
        //let allFrame = (duration * fps) - 10//NG
        //let allFrame = (1.0 * fps) - 10//OK 取りあえず発生しない
        print("allFrame: \(allFrame)")
        
        for var currentFrame = 0.0; currentFrame < allFrame; ++currentFrame {
            //println("currentFrame: \(currentFrame)")
            let currentTime = (currentFrame / fps)
            //println("currentTime: \(currentTime)")
            
            let requestTime: CMTime = CMTimeMakeWithSeconds(currentTime, 600)// よく使用されるフレームレートの公倍数
            
            // test OK
            /*
            //let requestTime: CMTime = CMTimeMakeWithSeconds(2, 600);// 600
            // 指定した時間での画像を取得(同期で処理するので、固まるかも)
            let capturedImage : CGImageRef! = generator.copyCGImageAtTime(
                requestTime,
                actualTime: nil,
                error: nil)
            
            if (capturedImage != nil) {
                self.videoImageView.image = UIImage(CGImage: capturedImage)
            } else {
                println("capturedImage is nil!")
            }
            */
            
            
            self.times.append(NSValue(CMTime: requestTime))
        }
    }
    
    func playVideo() {
        
        self.videoImageGenerator!.generateCGImagesAsynchronouslyForTimes(self.times,
            //capturedImage is CGImage!
            completionHandler: { (requestedTime, capturedImage, actualTime, result, error) -> Void in
            
                if (result == AVAssetImageGeneratorResult.Succeeded) {
                    //println("Succeeded!")
                    if (capturedImage != nil) {
                        let videoImage: UIImage = UIImage(CGImage: capturedImage!)
                        //println(videoImage.size)

                        
                        // pngファイルへ変換と保存
                        //let ledImage: UIImage = SmartEyeW.detectLED(videoImage)
                        //let pngData: NSData = UIImagePNGRepresentation(videoImage)
                        //let pngData: NSData = UIImagePNGRepresentation(ledImage)
                        //let fileName: String = String(format: "image_%d.png", self.procImageCount)
                        //FileManager.saveData(pngData, toFile: fileName)
                        
                        
                        // 生データ(bitmap)取得。TBD
                        //var dataProvider: CGDataProviderRef = CGImageGetDataProvider(capturedImage)
                        //var data: CFDataRef = CGDataProviderCopyData(dataProvider)
                        
                        //var signals: Array<SignalW> = []
                        let signals: NSMutableArray = NSMutableArray()
                        let debugInfo: DebugInfoW = DebugInfoW()
                        let ledImage: UIImage = SmartEyeW.detectSignal(videoImage, inRect: CGRectZero, signals: signals, debugInfo: debugInfo)
                        
                        
                        // mainスレッドで画面に表示
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            //self.videoImageView.image = videoImage
                            self.videoImageView.image = ledImage
                        })
                        
                        self.procImageCount++
                        //println("image count : \(self.procImageCount)")
                        
                    } else {
                        print("capturedImage is nil!")
                    }
                } else if (result == AVAssetImageGeneratorResult.Failed) {
                    print("Failed!")
                } else if (result == AVAssetImageGeneratorResult.Cancelled) {
                    print("Cancelled!")
                }
        })
    }
    
    func stopVideo() {
        self.videoImageGenerator?.cancelAllCGImageGeneration()
    }
}