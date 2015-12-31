//
//  CaptureViewController.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2014/10/05.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices//for kUTTypeImage
import MapKit


enum CaptureType {
    case Camera, Image, Video
}

enum CaptureMode {
    case Normal, Eyesight, Navi
}

enum SignalColor {
    case None, Green, Red
}


class SignalSpeaker: NSObject, AVSpeechSynthesizerDelegate {
    
    let SPEECH_SIGNAL_GREEN = "青"
    let SPEECH_SIGNAL_RED = "赤"
    
    var speaker: AVSpeechSynthesizer?
    
    override init() {
        super.init()
        
        self.speaker = AVSpeechSynthesizer()
        self.speaker?.delegate = self
    }
    
    func speach(type: SignalColor) {
        var word = ""
        
        if (type == .Green) {
            word = SPEECH_SIGNAL_GREEN
        } else if (type == .Red) {
            word = SPEECH_SIGNAL_RED
        }
        
        let utterance = AVSpeechUtterance(string: word)
        // same with system language
        //utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        self.speaker?.speakUtterance(utterance)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate protocol
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didStartSpeechUtterance utterance: AVSpeechUtterance) {
        print("speech start")
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
        print("speech end")
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let word = (utterance.speechString as NSString).substringWithRange(characterRange)
        print("Speech: \(word)")
    }
}

// todo
// CameraCaptureをViewControllerにする？カメラ関連操作を行う。カメラviewをmainviewのlayerにする。
// ViewControllerにした場合、別途画面追加が必要かな
// とりあえず、debugモードとしてすべて本Controllerで制御。カメラ設定変更が変わった時の処理をdelegeteで通知
class CaptureViewController: UIViewController, CameraCaptureObserver, LEDMapManagerDelegate, DebugModeObserver, AirSensorObserver {

    let QUEUE_SERIAL_SIGNAL_DETECT = "com.threees.tre.led.signal-detect"
    
    @IBOutlet weak var mapView: MKMapView! = nil
    @IBOutlet weak var captureImageView: UIImageView! = nil
    @IBOutlet weak var debugButton: UIBarButtonItem! = nil
    @IBOutlet weak var startButton: UIBarButtonItem! = nil
    @IBOutlet weak var camFormatLabel: UILabel! = nil
    
    @IBOutlet weak var dummySignalRed: UIImageView! = nil
    @IBOutlet weak var dummySignalGreen: UIImageView! = nil
    @IBOutlet weak var dummySignalRedCount: UILabel! = nil
    @IBOutlet weak var dummySignalGreenCount: UILabel! = nil
    
    var selectedImageView: UIImageView?
    //var drawPath: UIBezierPath?
    
    var detectImages: [AnyObject] = []
    var detectFps: Int = 30
    
    var speaker: SignalSpeaker?
    
    var cameraCap: CameraCapture? = nil
    var captureType: CaptureType = .Camera
    var captureMode: CaptureMode = .Normal
    var captureSetup: Bool = false
    
    var procDetect: Bool = false
    
    var debugViewController: DebugModeViewController?
    var debugView: UIView?
    var debugMode: Bool = false
    
    var confManager: ConfigManager = ConfigManager.sharedInstance()
    var setting: Bool = false
    var detect: Bool = true// default true
    var selecting: Bool = false
    var debugState: Bool = false
    var batchDetect: Bool = false
    var dispImage: Bool = true // TBD
    
    var mapManager: LEDMapManager = LEDMapManager.getInstance()
    var mapRegionSet: Bool = false
    
    var sensorMan: AirSensorManager? = nil
    
    var selectedRect: CGRect = CGRectZero
    
    var signalDetected: Bool = false
    
    var signalDetectQueue: dispatch_queue_t?
    var signalNoticeTimer: NSTimer?
    var noticeInterval: NSTimeInterval = 3//TBD
    
    var dummyGreenCount = 0
    var dummyRedCount = 0

    override func viewDidLoad() {
        //Log.debug("CaputureView viewDidLoad")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        //Log.debug("CaputureView viewWillAppear")
        super.viewWillAppear(animated)
        
        // アプリ内画面切替時（例えば、設定画面から戻った場合）。アプリバック->再開では呼ばれない
        
        // todo:
        self.mapManager.start()
        // self.cameraCap?.startCapture()
        self.startCapture()
    }
    
    override func viewDidAppear(animated: Bool) {
        //Log.debug("CaputureView viewDidAppear")
        super.viewDidAppear(animated)
        
        // アプリ内画面切替時（例えば、設定画面から戻った場合）。アプリ再開では呼ばれない
        
        // キャプチャ再開.一瞬キャプチャが止まるように見えるので、viewWillAppearで開始。
        // self.cameraCap?.startCapture()
        // self.stopCapture()
    }
    
    override func viewWillDisappear(animated: Bool) {
        //Log.debug("CaputureView viewWillDisappear")
        super.viewWillDisappear(animated)
        
        // アプリ内画面切替時（例えば、設定画面に切替えた場合）。アプリがバックグランドへ移動時呼ばれない
    }
    
    override func viewDidDisappear(animated: Bool) {
        //Log.debug("CaputureView viewDidDisappear")
        super.viewDidDisappear(animated)
        
        // アプリ内画面切替時（例えば、設定画面に切替えた場合）。アプリがバックグランドへ移動時呼ばれない
        
        // キャプチャ停止（画像処理停止）。一瞬キャプチャが止まるように見えるので、完全非表示後stop
        //self.cameraCap?.stopCapture()
        self.stopCapture()
        // todo:
        self.mapManager.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        //Log.debug("didReceiveMemoryWarning")
    }
    
    private func setup() {
        // test
        self.captureMode = .Normal
        self.captureType = .Camera
        
        self.speaker = SignalSpeaker()
        
        self.signalDetectQueue = dispatch_queue_create(QUEUE_SERIAL_SIGNAL_DETECT, DISPATCH_QUEUE_SERIAL)
        
        self.setupSelectMode()
        // cameraより先にsetup(カメラからのformat通知をdebugに設定するので)
        self.setupDebugMode()
        self.setupMapview()
        
        if (self.captureType == .Camera) {
            self.setupCamera()
        } else if (self.captureType == .Image) {
            
            //SmartEyeW.testRecognize()
            
            /*
            for var i = 0; i < 60; i++ {
                println("==================\(i) start==================")
                let imagePath = NSBundle.mainBundle().pathForResource(String(format: "image_%d", i + 1), ofType:"png")
                var signals: NSMutableArray = NSMutableArray()
                let orgImage = UIImage(contentsOfFile: imagePath!)
                SmartEyeW.detectSignal(orgImage, signals: signals)
                
                if (signals.count > 0) {
                    
                    for obj in signals {
                        let signal: SignalW = obj as! SignalW
                        println("\(signal.description())")
                    }
                    
                }
                println("==================\(i) end==================")
            }*/
            
            /*
            let imagePath = NSBundle.mainBundle().pathForResource(String(format: "red2"), ofType:"jpg")
            var signals: NSMutableArray = NSMutableArray()
            let orgImage = UIImage(contentsOfFile: imagePath!)
            SmartEyeW.detectSignal(orgImage, signals: signals)
            */
            
            let imagePath = NSBundle.mainBundle().pathForResource(String(format: "red"), ofType:"jpg")
            let orgImage = UIImage(contentsOfFile: imagePath!)
            self.captureImageView.image = SmartEyeW.testInRange(orgImage)
        }
    }
    
    private func setupMapview() {
        self.mapManager.delegate = self
        self.mapView.mapType = MKMapType.Standard
        self.mapView.rotateEnabled = false
        self.mapView.showsUserLocation = true
        
        // todo: for debug
        self.view.bringSubviewToFront(self.mapView)
    }
    
    private func setupSelectMode() {
        self.selectedRect = CGRectMake(self.captureImageView.bounds.size.width / 10, self.captureImageView.bounds.size.height / 8, self.captureImageView.bounds.size.width * 3 / 4, self.captureImageView.bounds.size.height * 2 / 5)
        self.selectedImageView = UIImageView(frame: self.selectedRect)
        self.selectedImageView?.hidden = true
        self.selectedImageView?.contentMode = UIViewContentMode.ScaleToFill
        self.view.addSubview(self.selectedImageView!)
    }
    
    private func setupDebugMode() {
        // todo:load .xib? -> @memo:need to load xib for creating instance all of views.
        //self.debugViewController = DebugModeViewController()
        // NG?debugView is nil?!
        //self.debugViewController = DebugModeViewController(nibName: "DebugModeViewController", bundle: nil) as? DebugModeViewController
        // todo:debugボタンを押した時、loadしたほうが良いかも。とりあえず、loadしておいて、表示・非表示で切り替える
        self.debugViewController = DebugModeViewController(nibName: "DebugModeViewController", bundle: nil)
        self.debugViewController?.observer = self
        self.debugView = self.debugViewController?.view
        self.debugView?.hidden = true
        
        // todo:adjust size?
        self.view.addSubview(self.debugView!)
    }
    
    private func setupCamera() {
        if (self.captureSetup == false) {
            // todo: get setting config from ConfigManager
            var cameraSettings = CameraSetting()
            cameraSettings.mode = CameraMode.ATv
            cameraSettings.orientaion = CameraOrientaion.Landscape
            cameraSettings.isMode = CameraImageStabilizationMode.Off
            cameraSettings.type = CameraDataType.Pixel
            cameraSettings.pixelFormat = CameraPixelFormatType.BGRA
            cameraSettings.format = self.confManager.confSettings.cameraSettings.formatIndex
            cameraSettings.exposureValue = self.confManager.confSettings.cameraSettings.exposureValue
            cameraSettings.iso = self.confManager.confSettings.cameraSettings.iso
            cameraSettings.bias = self.confManager.confSettings.cameraSettings.bias
            cameraSettings.fps = self.confManager.confSettings.cameraSettings.fps
            
            // 画像向き(デバイス:portrait キャプチャー:landscape)
            if (cameraSettings.orientaion == CameraOrientaion.Landscape) {
                self.confManager.confSettings.detectParams.imageSetting.orientation = 1 // landscape
            }
            
            //self.cameraCap = CameraCapture()
            self.cameraCap = CameraCapture.getInstance()
            self.cameraCap!.imageView = self.captureImageView
            self.cameraCap!.validRect = self.captureImageView.bounds
            self.cameraCap!.cameraObserver = self
            // todo: set with setting config from ConfigManager
            //self.cameraCap!.setupCaptureDevice()
            self.cameraCap!.setupCaptureDeviceWithSetting(cameraSettings)
            self.captureSetup = true
        }
    }
    
    private func setupSensor() {
        self.sensorMan = AirSensorManager.getInstance()
        self.sensorMan?.observer = self
        //self.sensorMan?.addSensorType(AirSensorTypeProximity)
        self.sensorMan?.addSensorType(AirSensorTypeLocation)
        self.sensorMan?.addSensorType(AirSensorTypeHeading)
        self.sensorMan?.addSensorType(AirSensorTypeAcceleration)
        self.sensorMan?.addSensorType(AirSensorTypeGyro)
        //self.sensorMan?.addSensorType(AirSensorTypeAttitude)
    }
    
    private func detectSignal(image: UIImage) -> (Bool, UIImage) {
        var detected: Bool = false
        //var signals: [AnyObject] = []// @memo:addObjectできない
        //var signals: Array<SignalW> = []// @memo:addObjectできない
        let signals: NSMutableArray = NSMutableArray()
        let debugInfo: DebugInfoW = DebugInfoW()
        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let detectedImage = SmartEyeW.detectSignal(image, inRect: rect, signals: signals, debugInfo: debugInfo)
        
        if (signals.count > 0) {
            detected = true
        }
        
        return (detected, detectedImage)
    }
    
    // fix ratio
    private func getClipImageRect(rectInView: CGRect, viewSize: CGSize, imageSize: CGSize) -> CGRect {
        let wScale = imageSize.width / viewSize.width
        let hScale = imageSize.height / viewSize.height
        
        let imageRect = CGRectMake(rectInView.origin.x * wScale, rectInView.origin.y * hScale, rectInView.size.width * wScale, rectInView.size.height * hScale)
        
        return imageRect
    }
    
    private func clipImage(image: UIImage, rect: CGRect) -> UIImage? {
        let clipCGImage = CGImageCreateWithImageInRect(image.CGImage, rect)
        let clipImage = UIImage(CGImage: clipCGImage!)
        
        return clipImage
    }
    
    private func drawRectangle(rect: CGRect, mode: Int) {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        
        let rectPath = UIBezierPath(rect: rect)
        //rectPath.moveToPoint(rect.origin)
        rectPath.lineWidth = 1
        if (mode == 0) {
            UIColor.blueColor().setStroke()
        } else if (mode == 1) {
            UIColor.whiteColor().setStroke()
        }
        rectPath.stroke()
        
        self.view.layer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
    }
    
    private func speachSignal(data: [AnyObject]!) {
        for obj in data {
            let signalData: SignalW = obj as! SignalW
            // TBD
            if (signalData.type == 1) {
                self.speaker?.speach(.Green)
            } else if (signalData.type == 4) {
                self.speaker?.speach(.Red)
            }
        }
    }
    
    private func startCapture() {
        if (self.captureType == .Camera) {
            SmartEyeW.setConfig()
            self.cameraCap?.startCapture()
        }
    }
    
    private func stopCapture() {
        if (self.captureType == .Camera) {
            self.cameraCap?.stopCapture()
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef, imageOrientation: UIImageOrientation) -> UIImage {
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
    
    private func detectRectOfSampleBuffer(sampleBuffer: CMSampleBufferRef, imageOrientation: UIImageOrientation) -> CGRect {
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
    
    private func needToDetect() -> Bool {
        if (self.procDetect && self.detect && !self.setting) {
            return true
        }
        
        return false
    }
    
    private func voiceNotice(color: SignalColor) {
        if (color == .Green) {
            self.speaker?.speach(.Green)
        } else if (color == .Red) {
            self.speaker?.speach(.Red)
        }
    }
    
    private func updateSignalImage(color: SignalColor) {
        if (color == .Green) {
            self.dummyGreenCount++
            self.dummySignalGreen.backgroundColor = UIColor.greenColor()
            self.dummySignalGreenCount.text = String(format: "%d", self.dummyGreenCount)
        } else if (color == .Red) {
            self.dummyRedCount++
            self.dummySignalRed.backgroundColor = UIColor.redColor()
            self.dummySignalRedCount.text = String(format: "%d", self.dummyRedCount)
        } else {
            self.dummySignalGreen.backgroundColor = UIColor.yellowColor()
            self.dummySignalRed.backgroundColor = UIColor.yellowColor()
        }
    }
    
    
    // MARK: - CameraCaptureObserver protocol
    
    func captureImageInfo(info: CaptureImageInfo!) {
        var detectedImage: UIImage?// = info.image
        let signals: NSMutableArray = NSMutableArray()
        
        if (self.batchDetect) {
            //let imageRect = self.getClipImageRect(self.selectedRect, viewSize: self.view.bounds.size, imageSize: info.image.size)
            //let selectedImage = self.clipImage(info.image, rect: imageRect)
            //let selectedImage = info.image
            if (self.needToDetect()) {
                self.detectImages.append(info.sampleBuffer)
                if (self.detectImages.count == self.detectFps + 1) {// +1は現在frame情報取得用
                    let debugInfo: DebugInfoW = DebugInfoW()
                    //var detectedImage: UIImage? = nil
                    for obj in self.detectImages {
                        let detectBuffer = obj as! CMSampleBufferRef
                        let rect = self.detectRectOfSampleBuffer(info.sampleBuffer, imageOrientation: info.orientation)
                        SmartEyeW.detectSignalWithSampleBuffer(detectBuffer, inRect: rect, signals: signals, debugInfo: debugInfo)
                    }
                    self.batchDetect = false
                    self.detectImages = [] // clear
                }
            } else {
                self.detectImages = [] // clear
            }
        } else {
            // todo:非同期で処理する場合、専用キューに入れる(むやみに別キューに入れると、その分コストがかかるので)
            //dispatch_sync(self.signalDetectQueue!, { () -> Void in // @memo:非同期の場合、キューで待機されるとき、メモリが増え続ける。警告発生して落ちる!?
            //if (!self.signalDetected) {// todo: 実際はキューをクリアしたい
            let debugInfo: DebugInfoW = DebugInfoW()
            //var detectedImage: UIImage? = nil
            if (self.needToDetect()) {
                let rect = self.detectRectOfSampleBuffer(info.sampleBuffer, imageOrientation: info.orientation)
                SmartEyeW.detectSignalWithSampleBuffer(info.sampleBuffer, inRect: rect, signals: signals, debugInfo: debugInfo)
            }
            
            detectedImage = self.imageFromSampleBuffer(info.sampleBuffer, imageOrientation: info.orientation)
            
            if (self.debugMode) {
                // todo: create queue for saving in DebugModeView -> ok
                // todo: save image in debug view controller      -> ok
                // todo: always update signal graph data
                self.debugViewController?.updateDetectedImageData(detectedImage: detectedImage, data: signals as [AnyObject], captureImageInfo: info, debugInfo: debugInfo, selectedImage: detectedImage!, selectecRect: self.selectedRect)
            }
            //})
        }
        // @memo: queue in UI thread
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if (!self.procDetect || self.debugMode) {//
                self.captureImageView.image = detectedImage
                var signalColor = SignalColor.None
                if (signals.count > 0) {
                    for obj in signals {
                        let signalData: SignalW = obj as! SignalW
                        if (signalData.color == 1) {
                            signalColor = .Green
                        } else if (signalData.color == 4) {
                            signalColor = .Red
                        }
                    }
                }
                self.voiceNotice(signalColor)
                self.updateSignalImage(signalColor)
            } else {
                // todo: speaker only
                self.captureImageView.image = detectedImage
                var signalColor = SignalColor.None
                if (signals.count > 0) {
                    for obj in signals {
                        let signalData: SignalW = obj as! SignalW
                        if (signalData.color == 1) {
                            signalColor = .Green
                        } else if (signalData.color == 4) {
                            signalColor = .Red
                        }
                    }
                }
                self.voiceNotice(signalColor)
                self.updateSignalImage(signalColor)
            }
        }
    }
    
    func activeFormatChanged(format: CameraFormat) {
        if (self.debugMode) {// 既にcamera setting modeが有効の場合、反映できない(既に表示中のため)
            // @memo: queue in UI thread
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.debugViewController?.updateCameraActiveFormat(format)
            }
        }
        print("activeFormatChanged")
        SmartEyeW.setConfig()
    }
    
    func currentSettingChanged(settings: CameraSetting) {
        if (self.debugMode) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.debugViewController?.updateCameraCurrentSetting(settings)
            })
        }
    }
    
    // MARK: - AirSensorObserver protocol
    
    func capture(info: AirSensorInfo!) {
        
    }
    
    func displayCameraView(flag: Bool, info: AirSensorInfo!) {
        self.dispImage = !flag
    }
    
    func sensorInfo(info: AirSensorInfo!, ofType type: AirSensorType) {
    }
    
    // MARK: - LEDMapManagerDelegate protocol
    
    func mapManager(mapManager: LEDMapManager!, currentPostion pos: CLLocationCoordinate2D) {
        //println("latitude:\(pos.latitude) longitude:\(pos.longitude)")
        
        if (self.mapRegionSet == false) {
            // memo: 0.0 ~ 180.0
            let coorSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.0, 0.0)
            let coorRegion: MKCoordinateRegion = MKCoordinateRegionMake(pos, coorSpan)
            
            self.mapView.setRegion(coorRegion, animated: false)
            self.mapRegionSet = true
        }
        
        self.mapView.setCenterCoordinate(pos, animated: true)
    }
    
    func mapManager(mapManager: LEDMapManager!, isValidArea flag: Bool) {
        if (self.captureMode == .Navi) {
            if (flag) {
                self.startCapture()
            } else {
                self.stopCapture()
            }
        }
    }
    
    // MARK: - DebugMode protocol
    
    func settingState(state: Bool) {
        self.debugState = state
        self.mapView.hidden = !self.debugMode || self.debugState
        
        // test
        self.dummySignalGreen.backgroundColor = UIColor.yellowColor()
        self.dummySignalRed.backgroundColor = UIColor.yellowColor()
    }
    
    func settingChangeStart() {
        self.setting = true
        self.cameraCap?.startChanging()
    }
    
    func settingChangeEnd() {
        self.setting = false
        self.cameraCap?.endChanging()
    }
    
    func detectStart() {
        self.detect = true
    }
    
    func detectEnd() {
        self.detect = false
    }
    
    func selectRectStart(startPoint: CGPoint) {
        self.setting = true
        self.selecting = true
        self.selectedImageView?.hidden = self.selecting
        self.selectedRect.origin = startPoint
    }
    
    func selectRectChanged(nextPoint: CGPoint) {
        var width = nextPoint.x - self.selectedRect.origin.x
        var height = nextPoint.y - self.selectedRect.origin.y
        
        if (width < 0) {
            width = -width
        }
        if (height < 0) {
            height = -height
        }
        self.selectedRect.size = CGSizeMake(width, height)
        self.drawRectangle(self.selectedRect, mode: 0)
    }
    
    func selectRectEnd() {
        self.drawRectangle(self.selectedRect, mode: 1)
        self.selectedImageView?.frame = self.selectedRect
        self.selecting = false
        self.setting = false
        self.selectedImageView?.hidden = self.selecting
    }
    
    func cameraSettingChanged(exposureBias bias: Float) {
        self.cameraCap!.changeExposureBias(bias)
    }
    
    func cameraSettingChanged(exposureISO iso: Float) {
        self.cameraCap!.changeISO(iso)
    }
    
    func cameraSettingChanged(exposureDuration ss: Float) -> Float {
        return self.cameraCap!.changeExposureDuration(ss)
    }
    
    func cameraSettingChanged(videoFPS fps: Float) {
        self.cameraCap!.switchFPS(fps)
    }
    
    func cameraSettingChanged(zoomFactor zoom: Float) {
        self.cameraCap?.changeVideoZoom(zoom, withRate: 0)
    }
    
    func smartEyeConfigChanged(reset: Bool) {
        if (reset) {
            // todo:再検知
            //SmartEyeW.setConfig("SmartEyeConfig.plist")
        } else {
            // todo:検知継続
        }
        
        // TBD
        SmartEyeW.setConfig()
    }
    
    func getVideoActiveFormatInfo() -> CameraFormat {
        return self.cameraCap!.getVideoActiveFormatInfo()
    }
    
    func getCameraCurrentSettings() -> CameraSetting {
        return self.cameraCap!.getCameraCurrentSettings()
    }
    
    func detectSignalColor(color: Int) {
        if (color & 1 == 1) {
            self.speaker?.speach(.Green)
            self.dummySignalGreen.backgroundColor = UIColor.greenColor()
            self.dummySignalRed.backgroundColor = UIColor.yellowColor()
        } else if (color & 4 == 4) {
            self.speaker?.speach(.Red)
            self.dummySignalRed.backgroundColor = UIColor.redColor()
            self.dummySignalGreen.backgroundColor = UIColor.yellowColor()
        }
    }
    
    func detectBatch(flag: Bool) {
        self.batchDetect = flag
    }
    
    func sensorStart() {
        self.sensorMan!.start()
    }
    
    func sensorEnd() {
        self.sensorMan!.stop()
    }

    // MARK: - IBAction
    
    @IBAction func debugModeAction(sender: AnyObject) {
        let dMode = !self.debugMode
        print("debugModeView:\(dMode)")
        // todo:animation
        self.tabBarController?.tabBar.hidden = dMode
        self.debugView?.hidden = !dMode
        self.selectedImageView?.hidden = !dMode
        self.mapView.hidden = !dMode || self.debugState
        // todo:CaptureImageViewはTabbarまでではないので、viewの白い背景が表示される。伸ばそう
        // ->ImageViewをMainViewと同じサイズにした
        if (dMode) {
            self.navigationItem.title = "Debug Mode"
            self.debugButton.title = "Done"
            self.captureImageView.alpha = 0.9
        } else {
            self.navigationItem.title = ""
            self.debugButton.title = "Debug"
            self.captureImageView.alpha = 1.0
        }
        
        self.debugMode = dMode
    }
    
    @IBAction func startAction(sender: AnyObject) {
        let detectButton = sender as! UIBarButtonItem
        
        self.procDetect = !self.procDetect
        if (self.procDetect) {
            SmartEyeW.setConfig()
            //self.cameraCap?.changeCameraDataType(CameraDataType.Pixel)
            detectButton.title = "Stop"
        } else {
            detectButton.title = "Start"
            //self.cameraCap?.changeCameraDataType(CameraDataType.Image)
        }
    }
}

