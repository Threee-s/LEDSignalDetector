//
//  CameraOperator.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2014/10/06.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

import Foundation
import AVFoundation

class CameraOperator {
    var stillImageOutput: AVCaptureStillImageOutput!
    var session: AVCaptureSession!
    
    func setupCameraCapture(frame: CGRect) -> Bool {
        // セッション作成
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSessionPresetHigh
        
#if true
        // ビデオ入力用のデバイスを取得(正面？)
        let captureDevice: AVCaptureDevice? = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    
#else //正面、背面カメラ取得
        var captureDevice: AVCaptureDevice?
        var devices: NSArray = AVCaptureDevice.devices()
        for device: AnyObject in devices {
            if device.position == AVCaptureDevicePosition.Back {
                captureDevice = device as? AVCaptureDevice
            }
        }
#endif
        
        if (captureDevice != nil) {
            // Debug
            print(captureDevice!.localizedName)
            print(captureDevice!.modelID)
        } else {
            print("Missing Camera")// Simulatorではnil
            return false
        }
        
        // Input
        //var error: NSErrorPointer!
        //var deviceInput: AVCaptureDeviceInput
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice) as AVCaptureDeviceInput
            self.session.addInput(deviceInput as AVCaptureInput)
        } catch let error as NSError {
            print(error)
        }
        
        
#if false
        // Output
        var deviceOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        //deviceOutput.setSampleBufferDelegate(sampleBufferDelegate: self, queue: dispatch_get_main_queue())
        //deviceOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: nil]
        self.session.addOutput(deviceOutput as AVCaptureOutput)
    
        // ビデオ入力のAVCaptureConnectionを取得
        var videoConn: AVCaptureConnection? = deviceOutput.connectionWithMediaType(AVMediaTypeVideo)
        //videoConn?.videoOrientation = AVCaptureVideoOrientation.Portrait
        //videoConn?.supportsVideoOrientation
        // キャプチャ頻度??
#else
        self.stillImageOutput = AVCaptureStillImageOutput()
        var videoConn: AVCaptureConnection? = nil
        let connections: NSArray = self.stillImageOutput.connections
        for conn: AnyObject in connections {
            let ports: NSArray = conn.inputPorts
            for port: AnyObject in ports {
                if (port.mediaType == AVMediaTypeVideo) {
                    videoConn = conn as? AVCaptureConnection;
                    break;
                }
            }
            if (videoConn != nil) {
                break;
            }
        }
        self.session.addOutput(self.stillImageOutput)
    
        // セッションから入力のプレビュー表示を作成(ビデオ表示用)
        //var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.layerWithSession(self.session) as AVCaptureVideoPreviewLayer
        //previewLayer.frame = frame
    
        // 直接mainviewのレイヤーでプレビュー表示。必要であれば、プレビュー用サブView作成。
        //self.view.layer.addSublayer(previewLayer)
        // self.priview.addSublayer(previewLayer) // priviewは初期か処理でself.viewに追加。サイズも指定。
#endif
        
        
        self.session.startRunning()
        
        return true
    }
    
    // 1画像取得
    func takePhoneFromVideo() {
        // ビデオ入力のAVCaptureConnectionを取得
        let videoConn: AVCaptureConnection? = self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
        
        if (videoConn == nil) {
            return
        }
        
        // ビデオ入力から画像を非同期で取得
        self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConn, completionHandler: { (imgBuf, error) -> Void in
            if (imgBuf == nil) {
                return
            }
            
            // JPEG画像取得
            let imgData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imgBuf)
            let videoImage: UIImage = UIImage(data: imgData)!
            
            // 画像処理
        })
    }

}