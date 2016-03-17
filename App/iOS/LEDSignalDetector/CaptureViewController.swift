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
import AudioToolbox


enum DisplayMode {
    case Normal // 画面表示(設定無効)
    case Blindness // 画面非表示(設定無効)
    case Setting // 画面表示(設定有効)
}

enum GesturePosition {
    case None
    case LeftTop
    case RightTop
    case LeftBottom
    case RightBottom
    case Middle
}

enum PanMoveDirection {
    case None
    case LeftToRight
    case RightToLeft
    case TopToBottom
    case BottomToTop
}

enum CaptureType {
    case Camera, Image, Video
}

enum CaptureMode {
    case Normal, Eyesight, Navi
}

enum SignalColor {
    case None, Green, Red
}

struct SignalDetectResult {
    var vibrateCount: Int
    var systemSoundId: SystemSoundID
    var speechContent: String
}

// todo:(01/06)　すべての音声(シンプル、必要最小限)。シナリオ検討.

class SignalSpeaker: NSObject, AVSpeechSynthesizerDelegate {
    
    let SPEECH_SIGNAL_GREEN = "青"
    let SPEECH_SIGNAL_RED = "赤"
    // todo:
    
    var speaker: AVSpeechSynthesizer?
    
    override init() {
        super.init()
        
        self.speaker = AVSpeechSynthesizer()
        self.speaker?.delegate = self
    }
    
    func speech(type: SignalColor) {
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
    
    func speechWord(word: String) {
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

class SignalAudio: NSObject {
    func vibrate(count: Int) {
        var i = 0
        while(i < count) {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            i++
        }
    }
}

class SignalDetectResultManager: NSObject {
    var detectCount: Int = 0
    var missCount: Int = 0
    var direction: Double = 0
    var trackStart: Bool = false
    // 前回trackingチェック時の検出回数
    var lastCheckCount: Int = 0
    // 音声ナビ回数。初回、途中、最後に案内音声を変更
    var naviCount: Int = 0
    
    var trackingTimer: NSTimer?
    var trackingInterval: NSTimeInterval = 3
    
    var result: SignalDetectResult!
    
    private func startTracking() {
        if (self.trackStart == false) {
            self.trackStart = true
            self.trackingTimer = NSTimer.scheduledTimerWithTimeInterval(self.trackingInterval, target: self, selector: Selector("checkTracking:"), userInfo: nil, repeats: true)
        }
    }
    
    private func stopTracking() {
        if (self.trackStart) {
            if (self.trackingTimer?.valid != nil) {
                self.trackingTimer?.invalidate()
            }
            self.trackStart = false
        }
        
        self.detectCount = 0
        self.direction = 0
        self.lastCheckCount = 0
    }
    
    private func getSpeechContent(color: SignalColor, distance: Float) -> String {
        var content: String = ""
        
        return content
    }
    
    func analyzeSignal(signal: SignalW, direction: Double) -> SignalDetectResult {
        if (self.detectCount == 0) {
            self.detectCount++
            self.direction = direction
            
            self.startTracking()
            
            result = SignalDetectResult(vibrateCount: 1, systemSoundId: 0, speechContent: "")
            
        } else {
            if (fabs(self.direction - direction) < 5) {
                self.detectCount++
                self.direction = direction
            }
            
            if (self.detectCount == 2) {
                // vibratのみ
                result = SignalDetectResult(vibrateCount: 1, systemSoundId: 0, speechContent: "")
            } else if (self.detectCount % 3 == 0) {// TBD:3s毎?
                var signalColor = SignalColor.None
                var signalDistance: Float = 0
                if (signal.color == 1) {
                    signalColor = .Green
                } else if (signal.color == 4) {
                    signalColor = .Red
                }
                signalDistance = signal.distance
                
                let content = self.getSpeechContent(signalColor, distance: signalDistance)
                result = SignalDetectResult(vibrateCount: 1, systemSoundId: 0, speechContent: content)
            }
        }
        
        
        return result
    }
    
    func checkTracking(timer: NSTimer) {
        // TBD:3s内に1以下検出の場合、もう信号がないと判断
        if (self.detectCount - self.lastCheckCount < 2) {
            self.stopTracking()
        }
        
        self.lastCheckCount = self.detectCount
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
    @IBOutlet weak var dummySignalDistance: UILabel!
    
    var selectedImageView: UIImageView?
    //var drawPath: UIBezierPath?
    
    var capturedImages: [AnyObject] = []
    var detectFps: Int = 30
    
    var speaker: SignalSpeaker?
    var audio: SignalAudio?
    
    var dispMode: DisplayMode = .Setting
    var gesturePosition: GesturePosition = .None
    var panMoveDirection: PanMoveDirection = .None
    
    var cameraCap: CameraCapture? = nil
    var captureType: CaptureType = .Camera
    var captureMode: CaptureMode = .Normal
    var captureSetup: Bool = false
    var captureRunning: Bool = false
    
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
    var saveCapturedImage: Bool = false
    var dispImage: Bool = true // TBD
    
    var mapManager: LEDMapManager?
    var mapRegionSet: Bool = false
    
    var sensorMan: AirSensorManager? = nil
    var lastMotionTime: NSTimeInterval = 0.0
    var velocityDeltaX: Double = 0.0
    var velocityDeltaY: Double = 0.0
    var motionClock: CMClockRef?
    
    var selectedMode: Bool = false
    var selectedRect: CGRect = CGRectZero
    
    //var signalDetected: Bool = false
    
    var signalDetectQueue: dispatch_queue_t?
    var signalNoticeTimer: NSTimer?
    var noticeInterval: NSTimeInterval = 3//TBD
    
    var detectRstMan: SignalDetectResultManager?
    
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
        
        // 起動時:Motion+接近+GPS+バイブ+効果音+音声
        //self.startSensor(AirSensorTypeMotion | AirSensorTypeProximity)
       // self.startSensor(AirSensorTypeMotion)
        //self.startSensor(AirSensorTypeProximity)
        //self.startLocation(LEDMapTypeLocation)
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
        self.stopCapture()
        self.stopLocation(LEDMapTypeLocation)
        //self.stopSensor(AirSensorTypeMotion | AirSensorTypeProximity)
        self.stopSensor(AirSensorTypeMotion)
        self.stopSensor(AirSensorTypeProximity)
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
        
        self.signalDetectQueue = dispatch_queue_create(QUEUE_SERIAL_SIGNAL_DETECT, DISPATCH_QUEUE_SERIAL)
        
        self.detectRstMan = SignalDetectResultManager()
        
        self.setupSelectMode()
        // cameraより先にsetup(カメラからのformat通知をdebugに設定するので)
        self.setupDebugMode()
        self.setupLocation()
        self.setupSensor()
        self.setupSpeaker()
        self.setupAudio()
        
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
            
            //let imagePath = NSBundle.mainBundle().pathForResource(String(format: "pedestrian_green"), ofType:"png")
            //let imagePath = NSBundle.mainBundle().pathForResource(String(format: "pedestrian_red"), ofType:"png")
            let imagePath = NSBundle.mainBundle().pathForResource(String(format: "image_1"), ofType:"png")
            let orgImage = UIImage(contentsOfFile: imagePath!)
            //self.captureImageView.image = SmartEyeW.testInRange(orgImage)
            
            //let imagePath1 = NSBundle.mainBundle().pathForResource(String(format: "blue_2"), ofType:"jpg")
            //match1:0.272056 match2:0.612901 match3:0.12402
            //let imagePath1 = NSBundle.mainBundle().pathForResource(String(format: "pedestrian_red"), ofType:"png")
            //match1:0.77847 match2:2.7725 match3:0.630563
            let imagePath1 = NSBundle.mainBundle().pathForResource(String(format: "image_5"), ofType:"png")
            let orgImage1 = UIImage(contentsOfFile: imagePath1!)
            SmartEyeW.testMatching(orgImage, withImage: orgImage1, color: 4)
        }
    }
    
    private func setupLocation() {
        self.mapManager = LEDMapManager.getInstance()
        self.mapManager!.delegate = self
//        self.mapView.mapType = MKMapType.Standard
//        self.mapView.rotateEnabled = false
//        self.mapView.showsUserLocation = true
        
        // todo: for debug
//        self.view.bringSubviewToFront(self.mapView)
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
        //self.sensorMan?.addSensorType(AirSensorTypeAcceleration)
        //self.sensorMan?.addSensorType(AirSensorTypeGyro)
        //self.sensorMan?.addSensorType(AirSensorTypeMotion)
        
        self.motionClock = CMClockGetHostTimeClock()
    }
    
    // 音声案内
    private func setupSpeaker() {
        self.speaker = SignalSpeaker()
    }
    
    // バイブレーション、効果音
    private func setupAudio() {
        self.audio = SignalAudio()
    }
    
    private func startCapture() {
        if (self.captureType == .Camera) {
            SmartEyeW.setConfig()
            self.cameraCap?.startCapture()
            self.captureRunning = true
        }
    }
    
    private func stopCapture() {
        if (self.captureType == .Camera) {
            if (self.captureRunning) {
                self.cameraCap?.stopCapture()
            }
        }
    }
    
    private func startLocation(type: LEDMapType) {
        self.mapManager!.startWithType(type)
    }
    
    private func stopLocation(type: LEDMapType) {
        self.mapManager!.stopWithType(type)
    }
    
    private func startSensor(type: AirSensorType) {
        self.sensorMan?.startWithType(type)
    }
    
    private func stopSensor(type: AirSensorType) {
        self.sensorMan?.stopWithType(type)
    }
    
    private func convertSampleBufferTimeToMotionClock(sampleBuffer: CMSampleBufferRef) {
        
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
        rectPath.lineWidth = 3
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
                self.speaker?.speech(.Green)
            } else if (signalData.type == 4) {
                self.speaker?.speech(.Red)
            }
        }
    }
    
    private func needToDetect() -> Bool {
        if (self.procDetect && self.detect && !self.setting && !self.saveCapturedImage) {
            return true
        }
        
        return false
    }
    
    private func needToDisplayView() -> Bool {
        if ((self.dispMode == .Normal || self.dispMode == .Setting) && !self.saveCapturedImage) {
            return true
        }
        
        return false
    }
    
    private func needToSetting() -> Bool {
        if (self.dispMode == .Setting && self.debugMode) {
            return true
        }
        
        return false
    }
    
    private func needToValidDebug() -> Bool {
        if (self.dispMode == .Setting) {
            return true
        }
        
        return false
    }
    
    private func updateDispMode() {
        if (self.dispMode == .Blindness) {
            self.tabBarController?.tabBar.hidden = true
            self.navigationController?.navigationBarHidden = true
        } else if (self.dispMode == .Normal) {
            self.tabBarController?.tabBar.hidden = true
            self.navigationController?.navigationBarHidden = true
        } else if (self.dispMode == .Setting) {
            self.tabBarController?.tabBar.hidden = false
            self.navigationController?.navigationBarHidden = false
        }
    }
    
    private func voiceNotice(color: SignalColor) {
        if (color == .Green) {
            self.speaker?.speech(.Green)
        } else if (color == .Red) {
            self.speaker?.speech(.Red)
        }
    }
    
    private func voiceNavigation(content: String) {
        self.speaker?.speechWord(content)
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
        var signalDetected = false
        var signalColor = SignalColor.None
        var signalDistance: Float = 0
        var signalCircleLevel: Float = 0
        var signalMatching: Float = -1
        var detectTime: Double = 0
        
        
        // todo:非同期で処理する場合、専用キューに入れる(むやみに別キューに入れると、その分コストがかかるので)
        //dispatch_sync(self.signalDetectQueue!, { () -> Void in // @memo:非同期の場合、キューで待機されるとき、メモリが増え続ける。警告発生して落ちる!?
        //if (!self.signalDetected) {// todo: 実際はキューをクリアしたい
        let debugInfo: DebugInfoW = DebugInfoW()
        let signals: NSMutableArray = NSMutableArray()
        //var detectedImage: UIImage? = nil
        if (self.needToDetect()) {
            let detectStartTime = CFAbsoluteTimeGetCurrent()
            
            var rect = CGRectZero
            if (self.selectedMode) {
                // todo:直接selectedRectを渡して、smarteyeで計算したほうがパフォーマンスが良いかも
                rect = SEUtil.detectRectOfSelecting(info.sampleBuffer, imageOrientation: info.orientation, selectedRect: self.selectedRect)
            } else {
                // memo:現状映像サイズによって実際detectする映像サイズが変わる。範囲は変わらない(解像度による画角が変わらないので)
                //      解像度が高ければdetectのサイズが大きくなるので、その分負荷がかかる
                //      640x480 x zoomFactor/2で上半分でdetectしている。表示しなければこのサイズで良いかも
                //        ただ、輪郭検出に多少影響が出るかも(点の情報が少なくなる->matching時情報が落ちる)。todo:必要ならサイズ調整
                //        todo:AR対応の場合、高解像度低範囲(rect)で行う
                rect = SEUtil.detectRectOfSampleBuffer(info.sampleBuffer, imageOrientation: info.orientation)
            }
            SmartEyeW.detectSignalWithSampleBuffer(info.sampleBuffer, inRect: rect, signals: signals, debugInfo: debugInfo)
            
            // memo:大体0.01s前後(信号があった時)。背景に障害物がある場合、もっとかかるかも。>0.033sの場合、点滅のパターンが崩れる可能性がある
            // todo:非同期シリアルキューで処理したほうが良い。最大５枚(適度)分のバッファー(array)を用意してframeをコピーし、直ちにcaptureのコンテキストを返す。
            //    ->ここではなく、SmartEyeでやったほうが良いかもー＞callbackか30枚目の呼び出しで結果を返す必要がある
            //    ->C++でのスレットは多少面倒なので、とりあえずここで行う
            //      ->シャッタータイミングを保つ。frameをdropしない ※これが大事!!!
            //      ->5枚くらいなら充分かも。メモリもそれほど上がらない
            //      ->ただ、5枚超えた場合、処理をクリア(detect再開)する必要がある。あるいは、溜まった分まで処理して再開(fpsまであったら良いが、足りない場合、面倒かも)
            //        検出できたら、一旦クリアしたほうが良いかも（同期を取ってリアルタイム性を保つ?）
            //      ->表示の場合、最新のframeを描画。古いframeを描画すると目立つので、多少frameが欠落しても気づかないので、スムーズな映像にしたほうが良い
            //        Beta評価者とAR対応の場合。
            //      ->motion情報を入れると、一度検知できたら、その後motion情報で追跡できるかも。
            //        信号の矩形エリアを追跡できれば、矩形検出部分の処理がなくなるので、パフォーマンスがよくなるかも？点滅パターンさえ正常にできれば
            //        あるいは、検出エリアを絞るので(上下左右1.5倍のエリア)、fullの検知処理を行ってもパフォーマンスは上がるはず
            //      ->VideoSnakeを参照。media/motion配列バッファー、clock同期、sync処理(captureとmotionの同期)
            let detectEndTime = CFAbsoluteTimeGetCurrent()
            detectTime = detectEndTime - detectStartTime
            
            if (signals.count > 0) {// 一番確率が高い信号(基本1個)
                
                /*
                for obj in signals {
                    let signalData: SignalW = obj as! SignalW
                    if (signalData.color == 1) {
                        signalColor = .Green
                    } else if (signalData.color == 4) {
                        signalColor = .Red
                    }
                    signalDistance = signalData.distance
                }*/
                let signalData: SignalW = signals[0] as! SignalW
                signalCircleLevel = signalData.circleLevel
                signalMatching = signalData.matching
                // test
                if (signalData.kind == 1) {

                    signalDistance = signalData.distance
                    let detectResult = self.detectRstMan?.analyzeSignal(signalData, direction: self.mapManager!.getCurrentHeading().magneticHeading)
                    self.audio?.vibrate((detectResult?.vibrateCount)!)
                    self.voiceNavigation((detectResult?.speechContent)!)
                    
                    // todo:音声/振動案内->
                    //self.voiceNotice(signalColor)
                    // 振動
                    //self.audio?.vibrate(signals.count)
                    
                    signalDetected = true
                } else {
                    // test
                    //signalDistance = 1
                    //signalDetected = true
                }
            }
        }
        
        // 表示モード(Normal/Setting)
        if (self.needToDisplayView()) {
            // 表示するので、image取得
            detectedImage = SEUtil.imageFromSampleBuffer(info.sampleBuffer, imageOrientation: info.orientation)
            
            // @memo: queue in UI thread
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.captureImageView.image = detectedImage
                //if (self.selectedMode) {
                    //self.selectedImageView?.image = detectedImage
                //}
                
                if (signalDetected) {
                    self.dummySignalDistance.text = String(format: "%f/%f/%f", signalDistance, signalCircleLevel, signalMatching)
                }
                self.updateSignalImage(signalColor)
            }
        } else {
            self.captureImageView.image = nil
            //self.selectedImageView?.image = nil
        }
        
        // 設定モード
        if (self.needToSetting()) {
            if (self.batchDetect) {// memo:バッチ処理の場合、通常のdetectは行われない
                //let imageRect = self.getClipImageRect(self.selectedRect, viewSize: self.view.bounds.size, imageSize: info.image.size)
                //let selectedImage = self.clipImage(info.image, rect: imageRect)
                //let selectedImage = info.image
                self.capturedImages.append(info.sampleBuffer)
                if (self.capturedImages.count == self.detectFps + 1) {// +1は現在frame情報取得用
                    let debugInfo: DebugInfoW = DebugInfoW()
                    //var detectedImage: UIImage? = nil
                    for obj in self.capturedImages {
                        let detectBuffer = obj as! CMSampleBufferRef
                        let rect = SEUtil.detectRectOfSampleBuffer(info.sampleBuffer, imageOrientation: info.orientation)
                        SmartEyeW.detectSignalWithSampleBuffer(detectBuffer, inRect: rect, signals: signals, debugInfo: debugInfo)
                    }
                    self.batchDetect = false
                    self.capturedImages = [] // clear
                }
            } else if (self.saveCapturedImage) {
                self.debugViewController?.saveCapturedImageInfo(captureImageInfo: info)
            } else {
                // todo: create queue for saving in DebugModeView -> ok
                // todo: save image in debug view controller      -> ok
                // todo: always update signal graph data
                self.debugViewController?.updateDetectedImageData(signals as [AnyObject], captureImageInfo: info, debugInfo: debugInfo, detectTime: detectTime)
            }
        }
    }
    
    func activeFormatChanged(format: CameraFormat) {
        if (self.dispMode == .Setting) {
            // @memo: queue in UI thread
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.debugViewController?.updateCameraActiveFormat(format)
            }
        }
        //print("activeFormatChanged")
        SmartEyeW.setConfig()
    }
    
    func currentSettingChanged(settings: CameraSetting) {
        if (self.dispMode == .Setting) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.debugViewController?.updateCameraCurrentSetting(settings)
            })
        }
    }
    
    // MARK: - AirSensorObserver protocol
    
    func capture(info: AirSensorInfo!) {
        
    }
    
    // 画面表示非表示。検出有効無効は基本ifNeededToDetectで行う
    func displayCameraView(flag: Bool, info: AirSensorInfo!) {
        self.dispImage = flag
        // 手持ちの場合信号検出するので、方向通知開始/GPS停止。ポケットなどに入れた場合、方向通知停止/GPS開始
        /*
        if (flag) {
            self.mapManager!.startWithType(LEDMapTypeHeading)
            self.mapManager!.stopWithType(LEDMapTypeLocation)
        } else {
            self.mapManager!.stopWithType(LEDMapTypeHeading)
            self.mapManager!.startWithType(LEDMapTypeLocation)
        }*/
        
    }
    
    func ifNeededToDetect(flag: Bool) {
        
        // headingの代わりにrollをみても良いかも->pitch/yaw(上向き/傾き)によって多少影響が出るようだ(上向きではない場合のお互いの関係がよく分からない)->とりあえずheading
        self.procDetect = flag;
        if (flag) {
            self.startCapture()
            self.startLocation(LEDMapTypeHeading)
        } else {
            self.stopCapture()
            self.stopLocation(LEDMapTypeHeading)
        }
    }
    
    func movedDistance(distance: Float, inDirection direction: AirSensorMovementDirection) {
        
    }
    
    func sensorInfo(info: AirSensorInfo!, ofType type: AirSensorType) {
        if (self.lastMotionTime == 0) {
            self.lastMotionTime = info.rawInfo.acceleration.timestamp
        }
        
        if (self.debugMode) {
            // todo:移動方向判断。加速度の+/-だけで良い？
            
            // todo:配列にする。motionのtimestamp/distDeltaとキャプチャのtimestampを比較。一番近いtimestampのdistDeltaを探す？
            // timestampは同期とる必要がある。appleのsample参照
            let timeDelta = info.rawInfo.acceleration.timestamp - self.lastMotionTime
            self.lastMotionTime = info.rawInfo.acceleration.timestamp
            
            // todo:AirSensorManagerで計算してinfoで渡したほうが良いかも
            
            // memo:user accelerationは動いていない場合、x/y/zとも0.
            // distとtransDeltaはあんまり変わらない。
            // todo:歩き時(手ぶれ時)は基本mm/cm単位で位置がずれる(実際の値は0.xxxm単位。Gがg/m2なので)。->inch->pointに変換すればOK?
            //      一旦信号の相対移動距離を計算->センサー内での移動距離->画面上のpoint移動距離計算?->結局上記と同じ?
            // test1
            let initVelX = self.velocityDeltaX
            let initVelY = self.velocityDeltaY
            let distX = (initVelX * timeDelta) + 0.5 * info.rawInfo.acceleration.x * timeDelta * timeDelta
            let distY = (initVelY * timeDelta) + 0.5 * info.rawInfo.acceleration.y * timeDelta * timeDelta
            
            self.velocityDeltaX += info.rawInfo.acceleration.x * timeDelta
            self.velocityDeltaY += info.rawInfo.acceleration.y * timeDelta
            
            // test2
            //let transDeltaX = 0.5 * info.rawInfo.acceleration.x * timeDelta * timeDelta
            //let transDeltaY = 0.5 * info.rawInfo.acceleration.y * timeDelta * timeDelta
            // test3
            let transDeltaX = self.velocityDeltaX * timeDelta
            let transDeltaY = self.velocityDeltaY * timeDelta
            
            
            print("x:\(info.rawInfo.acceleration.x) y:\(info.rawInfo.acceleration.y) z:\(info.rawInfo.acceleration.z)")
            print("vX:\(self.velocityDeltaX) vY:\(self.velocityDeltaX)")
            print("distX:\(distX) distY:\(distY)")
            print("transDeltaX:\(transDeltaX) transDeltaY:\(transDeltaY)")
            
            print("pitch:\(info.rawInfo.rotation.pitch) roll:\(info.rawInfo.rotation.roll) yaw:\(info.rawInfo.rotation.yaw)")
            
            self.debugViewController?.setSensorData(info, ofType: type)
        }
        print("sensorInfo");
    }
    
    // MARK: - LEDMapManagerDelegate protocol
    
    func mapManager(mapManager: LEDMapManager!, currentPostion pos: LEDMapLocation) {
        //println("latitude:\(pos.latitude) longitude:\(pos.longitude)")
        
        if (self.mapRegionSet == false) {
            // memo: 0.0 ~ 180.0
            let coorSpan: MKCoordinateSpan = MKCoordinateSpanMake(0.0, 0.0)
            let coorRegion: MKCoordinateRegion = MKCoordinateRegionMake(pos.coor, coorSpan)
            
//            self.mapView.setRegion(coorRegion, animated: false)
            self.mapRegionSet = true
        }
        
//        self.mapView.setCenterCoordinate(pos.coor, animated: true)
    }
    
    func mapManager(mapManager: LEDMapManager!, currentDirection dir: LEDMapHeading!) {
        // todo:保存し、frameの情報としてsmarteyeに渡す
    }
    
    // todo:情報登録の場合
    func mapManager(mapManager: LEDMapManager!, signalsOfNeighboring signals: [AnyObject]!) {
        
    }
    
    // todo:情報登録の場合
    func mapManager(mapManager: LEDMapManager!, isValidArea flag: Bool) {
        if (self.captureMode == .Navi) {
            if (flag) {
                self.startCapture()
            } else {
                self.stopCapture()
            }
        }
    }
    
    func mapManager(mapManager: LEDMapManager!, isNearToCrossing flag: Bool) {
        if (self.captureMode == .Navi) {
            // todo:GPSをoff、Headingをon。
            if (flag) {
                self.startCapture()
                self.mapManager!.stopWithType(LEDMapTypeLocation)
                self.mapManager!.startWithType(LEDMapTypeHeading)
            } else {
                self.stopCapture()
                self.mapManager!.stopWithType(LEDMapTypeHeading)
                self.mapManager!.startWithType(LEDMapTypeLocation)
            }
        }
    }
    
    // MARK: - DebugModeObserver protocol
    
    func settingState(state: Bool) {
        self.debugState = state
//        self.mapView.hidden = !self.debugMode || self.debugState
        
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
        self.selectedMode = true
        self.selectedImageView?.hidden = !self.selectedMode
        self.captureImageView.alpha = 0.7
    }
    
    func selectRectCancel() {
        self.view.layer.contents = nil
        self.selectedRect = CGRectZero
        self.selectedImageView?.frame = self.selectedRect
        self.selecting = false
        self.setting = false
        self.selectedMode = false
        self.selectedImageView?.hidden = !self.selectedMode
        self.captureImageView.alpha = 1.0
    }
    
    func detectRect(rect: CGRect) {
        self.selectedRect = rect
        // 1回しか描画されないので、意味がないかな
        self.drawRectangle(self.selectedRect, mode: 1)
        self.selectedImageView?.frame = self.selectedRect
        self.selecting = false
        self.setting = false
        self.selectedMode = true
        self.selectedImageView?.hidden = !self.selectedMode
        self.captureImageView.alpha = 0.8
        // todo:self.selectedImageViewにもimageを設定(modeはfit?)
        //self.selectedImageView?.backgroundColor = UIColor.redColor()
        //self.selectedImageView?.alpha = 0
        self.view.bringSubviewToFront(self.selectedImageView!)
    }
    
    func deleteDetectRect() {
        self.view.layer.contents = nil
        self.selectedRect = CGRectZero
        self.selectedImageView?.frame = self.selectedRect
        self.selecting = false
        self.setting = false
        self.selectedMode = false
        self.selectedImageView?.hidden = !self.selectedMode
        self.captureImageView.alpha = 1.0
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
            self.speaker?.speech(.Green)
            self.dummySignalGreen.backgroundColor = UIColor.greenColor()
            self.dummySignalRed.backgroundColor = UIColor.yellowColor()
        } else if (color & 4 == 4) {
            self.speaker?.speech(.Red)
            self.dummySignalRed.backgroundColor = UIColor.redColor()
            self.dummySignalGreen.backgroundColor = UIColor.yellowColor()
        }
        self.audio?.vibrate(1)
    }
    
    func detectBatch(flag: Bool) {
        self.batchDetect = flag
    }
    
    func saveCapturedImage(flag: Bool) {
        self.saveCapturedImage = flag
    }
    
    func sensorStart() {
        self.sensorMan!.start()
    }
    
    func setSensorType(type: AirSensorType) {
        self.sensorMan?.setSensorType(type)
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
//        self.mapView.hidden = !dMode || self.debugState
        // todo:CaptureImageViewはTabbarまでではないので、viewの白い背景が表示される。伸ばそう
        // ->ImageViewをMainViewと同じサイズにした
        if (dMode) {
            self.navigationItem.title = "Debug Mode"
            self.debugButton.title = "Done"
            self.captureImageView.alpha = 0.8
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
    
    @IBAction func longGestureForDebug(sender: AnyObject) {
        //print("longGestureForDebug")
        
        let gesRec: UILongPressGestureRecognizer = sender as! UILongPressGestureRecognizer
        let pos: CGPoint = gesRec.locationInView(self.view)
        //print("long x:\(pos.x) y:\(pos.y)")
        
        let left: CGFloat = 50
        let top: CGFloat = 0
        let right: CGFloat = self.view.bounds.size.width - 50
        let bottom: CGFloat = 50 + 44 // NavigationBar:44
        
        print("pan x:\(pos.x) y:\(pos.y)")
        if (gesRec.state == UIGestureRecognizerState.Began) {// 設定秒数間押し続くとBeganになる。Endで処理する場合、手を離さないとdebugmodeが変わらない
            print("pan began(\(gesRec.state))")
            if ((pos.x < left) && (pos.y < bottom)) {
                self.gesturePosition = .LeftTop
            } else if ((pos.x > right) && (pos.y < bottom)) {
                self.gesturePosition = .RightTop
            }
        } else if (gesRec.state == UIGestureRecognizerState.Changed) {
            print("pan changed(\(gesRec.state))")
            if (((pos.x > left) && (pos.x <= right)) && (pos.y < bottom)) {
                if (self.gesturePosition != .Middle) {
                    if (self.gesturePosition == .LeftTop) {
                        self.panMoveDirection = .LeftToRight
                    } else if (self.gesturePosition == .RightTop) {
                        self.panMoveDirection = .RightToLeft
                    }
                    
                    self.gesturePosition = .Middle
                }
            }
            
        } else if (gesRec.state == UIGestureRecognizerState.Ended) {
            print("pan ended(\(gesRec.state))")
            if ((pos.x > right) && (pos.y < bottom)) {
                if (self.panMoveDirection == .LeftToRight) {
                    if (self.dispMode == .Blindness) {
                        self.dispMode = .Normal
                    } else if (self.dispMode == .Normal) {
                        self.dispMode = .Setting
                    }
                }
            } else if ((pos.x < left) && (pos.y < bottom)) {
                if (self.panMoveDirection == .RightToLeft) {
                    if (self.dispMode == .Setting) {
                        self.dispMode = .Normal
                    } else if (self.dispMode == .Normal) {
                        self.dispMode = .Blindness
                    }
                }
            }
            
            self.updateDispMode()
            
            self.gesturePosition = .None
            self.panMoveDirection = .None
        } else {// cancelなど
            print("pan others(\(gesRec.state))")
            self.gesturePosition = .None
            self.panMoveDirection = .None
        }
    }
    
    // memo:long gestureに入った場合、pan gestureには入らない
    @IBAction func panGestureForDebug(sender: AnyObject) {
        let gesRec: UIPanGestureRecognizer = sender as! UIPanGestureRecognizer
        let pos: CGPoint = gesRec.locationInView(self.view)
        
        //if (self.gesturePosition != .None) {
            let left: CGFloat = 50
            let top: CGFloat = 0
            let right: CGFloat = self.view.bounds.size.width - 50
            let bottom: CGFloat = 50 + 44 // NavigationBar:44
            
            print("pan x:\(pos.x) y:\(pos.y)")
            if (gesRec.state == UIGestureRecognizerState.Began) {
                print("pan began(\(gesRec.state))")
                if ((pos.x < left) && (pos.y < bottom)) {
                    self.gesturePosition = .LeftTop
                } else if ((pos.x > right) && (pos.y < bottom)) {
                    self.gesturePosition = .RightTop
                }
            } else if (gesRec.state == UIGestureRecognizerState.Changed) {
                print("pan changed(\(gesRec.state))")
                if (((pos.x > left) && (pos.x <= right)) && (pos.y < bottom)) {
                    if (self.gesturePosition != .Middle) {
                        if (self.gesturePosition == .LeftTop) {
                            self.panMoveDirection = .LeftToRight
                        } else if (self.gesturePosition == .RightTop) {
                            self.panMoveDirection = .RightToLeft
                        }
                        
                        self.gesturePosition = .Middle
                    }
                }

            } else if (gesRec.state == UIGestureRecognizerState.Ended) {
                print("pan ended(\(gesRec.state))")
                if ((pos.x > right) && (pos.y < bottom)) {
                    if (self.panMoveDirection == .LeftToRight) {
                        if (self.dispMode == .Blindness) {
                            self.dispMode = .Normal
                        } else if (self.dispMode == .Normal) {
                            self.dispMode = .Setting
                        }
                    }
                } else if ((pos.x < left) && (pos.y < bottom)) {
                    if (self.panMoveDirection == .RightToLeft) {
                        if (self.dispMode == .Setting) {
                            self.dispMode = .Normal
                        } else if (self.dispMode == .Normal) {
                            self.dispMode = .Blindness
                        }
                    }
                }
                
                self.updateDispMode()
                
                self.gesturePosition = .None
                self.panMoveDirection = .None
            } else {// cancelなど
                print("pan others(\(gesRec.state))")
                self.gesturePosition = .None
                self.panMoveDirection = .None
            }
       // }
    }
    
}

