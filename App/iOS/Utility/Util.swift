//
//  Util.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2015/02/22.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


class SEUtil {
    class func gcd(var x: Int, var y: Int) -> Int {
        if (x == 0 || y == 0) {// 引数チェック
            return 0
        }
    
        // ユーグリッドの互除法
        var r: Int = x % y
        while (r != 0) {// yで割り切れるまでループ
            x = y
            y = r
            r = x % y
        }
    
        return y
    }
    
    class func lcm(x: Int, y: Int) -> Int {
        if (x == 0 || y == 0) {// 引数チェック
            return 0
        }
    
        return (x * y / SEUtil.gcd(x, y: y))
    }
    
    // shallow copy
    class func copySampleBuffer(sampleBuffer: CMSampleBufferRef) -> CMSampleBufferRef? {
        let allocator: Unmanaged<CFAllocatorRef>! = CFAllocatorGetDefault()
        //var bufferCopy: UnsafeMutablePointer<CMSampleBuffer?>?
        var bufferCopy : CMSampleBuffer?
        let err = CMSampleBufferCreateCopy(allocator.takeRetainedValue(), sampleBuffer, &bufferCopy)
        if err == noErr {
            return bufferCopy
        } else {
            return nil
        }
    }
    
    // deep copy
    func cloneImageBuffer(sampleBuffer: CMSampleBuffer!) -> CMSampleBuffer? {
        var newSampleBuffer: CMSampleBuffer?
        
        if let oldImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            if let newImageBuffer = cloneImageBuffer(oldImageBuffer) {
                // NG?
                /*
                I was able to fix the problem by creating a format description off the newly created image buffer and using it instead of the format description off the original sample buffer. Unfortunately while that fixes the problem here, the format descriptions don't match and causes problem further down.
                */
                if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                    let dataIsReady = CMSampleBufferDataIsReady(sampleBuffer)
                    let refCon = NSMutableData()
                    var timingInfo: CMSampleTimingInfo = kCMTimingInfoInvalid
                    let timingInfoSuccess = CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timingInfo)
                    if timingInfoSuccess == noErr {
                        let allocator: Unmanaged<CFAllocatorRef>! = CFAllocatorGetDefault()
                        let success = CMSampleBufferCreateForImageBuffer(allocator.takeRetainedValue(), newImageBuffer, dataIsReady, nil, refCon.mutableBytes, formatDescription, &timingInfo, &newSampleBuffer)
                        if success == noErr {
                            //bufferArray.append(newSampleBuffer!)
                        } else {
                            NSLog("Failed to create new image buffer. Error: \(success)")
                        }
                    } else {
                        NSLog("Failed to get timing info. Error: \(timingInfoSuccess)")
                    }
                }
            }
        }
        
        return newSampleBuffer
    }
    
    func cloneImageBuffer(imageBuffer: CVImageBuffer!) -> CVImageBuffer? {
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        let bytesPerRow: size_t = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: size_t = CVPixelBufferGetWidth(imageBuffer)
        let height: size_t = CVPixelBufferGetHeight(imageBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let pixelFormatType = CVPixelBufferGetPixelFormatType(imageBuffer)
        
        let data = NSMutableData(bytes: baseAddress, length: bytesPerRow * height)
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        
        var clonedImageBuffer: CVPixelBuffer?
        let allocator: Unmanaged<CFAllocatorRef>! = CFAllocatorGetDefault()
        let refCon = NSMutableData()
        
        if CVPixelBufferCreateWithBytes(allocator.takeRetainedValue(), width, height, pixelFormatType, data.mutableBytes, bytesPerRow, nil, refCon.mutableBytes, nil, &clonedImageBuffer) == noErr {
            return clonedImageBuffer
        } else {
            return nil
        }
    }
    
    class func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef, imageOrientation: UIImageOrientation) -> UIImage {
        //let imageBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)
        let pixelBuffer: CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        let base = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let cgImage = CGBitmapContextCreateImage(cgContext)
        // todo:Deviceのorientation情報が入っていないのでNG.transformで判断
        let image = UIImage(CGImage: cgImage!, scale: UIScreen.mainScreen().scale, orientation: imageOrientation)
        //CGColorSpaceRelease(colorSpace)// todo:error!不要。下同
        //CGContextRelease(cgContext)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
        
        return image
    }
    
    class func detectRectOfSampleBuffer(sampleBuffer: CMSampleBufferRef, imageOrientation: UIImageOrientation) -> CGRect {
        var rect = CGRectZero
        let pixelBuffer: CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
        
        if (imageOrientation == UIImageOrientation.Up) {
            let x = width / 10
            let y = 44
            let detectWidth = width - x * 2
            let detectHeight = (height - y) / 2
            rect = CGRect(x: x, y: y, width: detectWidth, height: detectHeight)
        } else if (imageOrientation == UIImageOrientation.Right) {
            let x = 44
            let y = height / 10
            let detectWidth = (width - x) / 2
            let detectHeight = height - y * 2
            rect = CGRect(x: x, y: y, width: detectWidth, height: detectHeight)
        }
        
        return rect
    }
    
    class func detectRectOfSelecting(sampleBuffer: CMSampleBufferRef, imageOrientation: UIImageOrientation, selectedRect: CGRect) -> CGRect {
        var rect = CGRectZero
        let pixelBuffer: CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
        
        if (imageOrientation == UIImageOrientation.Up) {
            let x = (CGFloat(width) - selectedRect.size.width) / 2
            let y = (CGFloat(height) - selectedRect.size.height) / 2
            let detectWidth = selectedRect.size.width
            let detectHeight = selectedRect.size.height
            rect = CGRect(x: x, y: y, width: detectWidth, height: detectHeight)
        } else if (imageOrientation == UIImageOrientation.Right) {
            // memo: width/heightはorientaionによって変わる(x/y座標と常に一致)
            let x = (CGFloat(width) - selectedRect.size.height) / 2
            let y = (CGFloat(height) - selectedRect.size.width) / 2
            let detectWidth = selectedRect.size.height
            let detectHeight = selectedRect.size.width
            rect = CGRect(x: x, y: y, width: detectWidth, height: detectHeight)
        }
        
        return rect
    }
    
    /*
     * 返り値が実行時間
     */
    class func timeElapsedInSecondsWhenRunningCode <T> (@autoclosure operation: () -> T)  -> Double {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return Double(timeElapsed)
    }
    
    /*
     * 実行時間のメッセージ
     */
    class func printTimeElapsedWhenRunningCode <T> (title: String, @autoclosure operation: () -> T) {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("Time elapsed for \(title): \(timeElapsed) seconds")
    }
    
    /*
     * 関数の返り値と実行時間のメッセージ
     */
    class func time <T> (@autoclosure f: () -> T) -> (result: T, duration: String) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = f()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, "Elapsed time is \(timeElapsed) seconds.")
    }
    
    /*
     * 関数の返り値と実行時間
     */
    class func time <T> (@autoclosure f: () -> T) -> (result: T, duration: Double) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = f()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, Double(timeElapsed))
    }
}