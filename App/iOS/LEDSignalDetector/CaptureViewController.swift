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

enum UserMode: Int {
    case Product = 0
    case Test = 1 // 主にβ版までのテスト
}

enum DisplayMode: Int { // for debug
    case Blindness = 0 // 画面非表示(設定無効)
    case Normal = 1 // 画面表示(設定無効)
    case Setting = 2 // 画面表示(設定有効)
    case Collection = 3 // 画面表示(情報収集)
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
    case None, Green, Red, Yellow
}

struct SignalDetectResult {
    var vibrateCount: Int
    var systemSoundId: SystemSoundID
    var speechContent: String
}

// todo:(01/06)　すべての音声(シンプル、必要最小限)。シナリオ検討.
// RECAIUSの音声合成を使用。あるいは取得した音声ファイルを再生
class SignalSpeaker: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    
    let SPEECH_SIGNAL_GREEN = "青"
    let SPEECH_SIGNAL_RED = "赤"
    // todo:
    
    var speaker: AVSpeechSynthesizer?
    var audioPlayer: AVAudioPlayer?
    
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
    
    func speakWithFile(voiceFile: String) {
        let voiceUrl = NSURL(string: voiceFile)
        speakWithUrl(voiceUrl!)
    }
    
    func speakWithUrl(voiceUrl: NSURL) {
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOfURL: voiceUrl)
            //self.audioPlayer.prepareToPlay()
            self.audioPlayer!.play()
        } catch {
            
        }
    }
    
    func speakWithData(data: NSData) {
        do {
            self.audioPlayer = try AVAudioPlayer(data: data)
            self.audioPlayer!.play()
        } catch {
            
        }
    }
    
    func pauseSpeak() {
        if (self.audioPlayer!.playing) {
            self.audioPlayer!.stop()
        }
    }
    
    func stopSpeak() {
        if (self.audioPlayer!.playing) {
            self.audioPlayer!.stop()
            self.audioPlayer!.prepareToPlay()
        }
    }
    
    // MARK: - AVAudioPlayerDelegate protocol
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        print("audio finished.")
    }
    
    func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        print("audio stopping...")
    }
    
    func audioPlayerEndInterruption(player: AVAudioPlayer) {
        print("audio stopped.")
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
            self.trackingTimer = NSTimer.scheduledTimerWithTimeInterval(self.trackingInterval, target: self, selector: #selector(SignalDetectResultManager.checkTracking(_:)), userInfo: nil, repeats: true)
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
            self.detectCount += 1
            self.direction = direction
            
            self.startTracking()
            
            self.result = SignalDetectResult(vibrateCount: 1, systemSoundId: 0, speechContent: "")
            
        } else {
            if (fabs(self.direction - direction) < 5) {
                self.detectCount += 1
                self.direction = direction
            }
            
            if (self.detectCount == 2) {
                // vibratのみ
                self.result = SignalDetectResult(vibrateCount: 1, systemSoundId: 0, speechContent: "")
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
                self.result = SignalDetectResult(vibrateCount: 1, systemSoundId: 0, speechContent: content)
            }
        }
        
        
        return self.result
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
class CaptureViewController: UIViewController, CameraCaptureObserver, LEDMapManagerDelegate, DebugModeObserver, AirSensorObserver, UploadObserver, CollectionDataManagerDelegate {

    let QUEUE_SERIAL_SIGNAL_DETECT = "com.threees.tre.led.signal-detect"
    let QUEUE_SERIAL_SIGNAL_COLLECT = "com.threees.tre.led.signal-collect"
    
    let identifierProgressViewController = "ProgressViewController"
    
    @IBOutlet weak var mapView: MKMapView! = nil
    @IBOutlet weak var captureImageView: UIImageView! = nil
    @IBOutlet weak var debugButton: UIBarButtonItem! = nil
    @IBOutlet weak var startButton: UIBarButtonItem! = nil
    @IBOutlet weak var camFormatLabel: UILabel! = nil
    @IBOutlet weak var collectSwitch: UISwitch!
    @IBOutlet weak var collectButton: UIButton!
    @IBOutlet weak var exposureImageView: UIImageView!
    @IBOutlet weak var exposureBiasDecButton: UIButton!
    @IBOutlet weak var exposureBiasIncButton: UIButton!
    
    @IBOutlet weak var dummySignalRed: UIImageView! = nil
    @IBOutlet weak var dummySignalGreen: UIImageView! = nil
    @IBOutlet weak var dummySignalRedCount: UILabel! = nil
    @IBOutlet weak var dummySignalGreenCount: UILabel! = nil
    @IBOutlet weak var dummySignalDistance: UILabel!
    
    var progressViewController: ProgressViewController!
    
    var validDetectionView: ValidDetectionView!
    var selectedImageView: UIImageView!
    //var drawPath: UIBezierPath?
    
    var capturedImages: [AnyObject] = []
    var detectFps: Int = 30
    
    var speaker: SignalSpeaker?
    var audio: SignalAudio?
    
    var userMode: UserMode = .Test
    
    var dispMode: DisplayMode = .Normal
    var gesturePosition: GesturePosition = .None
    var panMoveDirection: PanMoveDirection = .None
    
    var cameraCap: CameraCapture? = nil
    var captureType: CaptureType = .Camera
    var captureMode: CaptureMode = .Normal
    var captureSetup: Bool = false
    var captureRunning: Bool = false
    var captureCount: Int = 0;
    
    var procDetect: Bool = false
    // 一度検出後の検出保時回数(検出後のframe数:fps)
    var detectedRetainCount: Int = 0
    
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
    
    // todo:selectedはdebug用 validはcollection用 分ける
    //      debug画面でselectedを選択した場合、現出バッファー矩形(描画矩形)をselecteに合わせる。
    //      selectedRect/validDetectionRect/バッファー描画矩形について再検討。合わせる。
    var selectedMode: Bool = false
    var selectedRect: CGRect = CGRectZero
    var validDetectionRect: CGRect = CGRectZero
    
    //var signalDetected: Bool = false
    
    var signalDetectQueue: dispatch_queue_t!
    var signalNoticeTimer: NSTimer?
    var noticeInterval: NSTimeInterval = 3//TBD
    
    var detectRstMan: SignalDetectResultManager?
    
    var collectionDataMan: CollectionDataManager!
    var signalCollectQueue: dispatch_queue_t!
    var collectionCount: Int = 0
    var collecting: Bool = false
    var collectionCountMax = 0
    var collectionTime = 5
    var currentRectColor: SignalColor = .None
    
    var progressView:UIProgressView!
    
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
        self.signalCollectQueue = dispatch_queue_create(QUEUE_SERIAL_SIGNAL_COLLECT, DISPATCH_QUEUE_SERIAL)
        
        self.detectRstMan = SignalDetectResultManager()
        
        
        self.loadConfig()
        self.setupUI()
        // cameraより先にsetup(カメラからのformat通知をdebugに設定するので)
        self.setupDebugMode()
        self.setupLocation()
        self.setupSensor()
        self.setupSpeaker()
        self.setupAudio()
        self.setupConnection()
        
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
    
    private func loadConfig() {
        self.loadMode()
        
        if (self.userMode == .Test) {
            self.setupCollectionCount()
        }
    }
    
    private func loadMode() {
        self.userMode = UserMode(rawValue: Int(self.confManager.confSettings.settings.userMode))!
        self.dispMode = DisplayMode(rawValue: Int(self.confManager.confSettings.settings.dispMode))!
    }
    
    private func setupCollectionCount() {
        self.collectionCountMax = Int(self.confManager.confSettings.cameraSettings.fps) * self.collectionTime
    }
    
    private func setupUI() {
        // viewの生成と追加
        self.setupSelectView()
        self.setupValidDetectionView()
        
        self.updateUserMode()
        self.updateDispMode()
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
    
    private func setupSelectView() {
        self.selectedRect = self.createSelectedRect()
        //let rect = self.createValidDispRect()
        self.selectedImageView = UIImageView(frame: self.selectedRect)// smarteyeで描画時、selectedRectと一致しない
        self.selectedImageView.hidden = true
        //self.selectedImageView.contentMode = UIViewContentMode.ScaleToFill
        self.selectedImageView.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.addSubview(self.selectedImageView)
    }
    
    private func setupValidDetectionView() {
        self.validDetectionView = ValidDetectionView(frame: self.selectedRect)
        self.validDetectionView.hidden = true
        self.validDetectionView.opaque = false
        self.validDetectionView.contentMode = UIViewContentMode.ScaleToFill
        self.view.addSubview(self.validDetectionView)
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
    
    private func resetDebugMode() {
        
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
    
    //
    private func setupConnection() {
    }
    
    private func enableCollectionUI(flag: Bool) {
        self.validDetectionView?.hidden = !flag
        self.collectSwitch.hidden = !flag
        //self.collectButton.hidden = !flag
        self.exposureImageView.hidden = !flag
        self.exposureBiasDecButton.hidden = !flag
        self.exposureBiasIncButton.hidden = !flag
    }
    
    private func startCapture() {
        if (self.captureType == .Camera) {
            SmartEyeW.setConfig()
            //let currentSettings = self.cameraCap?.getCameraCurrentSettings()
            //let bias = Float((currentSettings?.bias)!)
            self.cameraCap?.startCapture()
            //self.cameraCap?.changeExposureBias(bias)
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
        if ((self.dispMode == .Normal || self.dispMode == .Setting || self.dispMode == .Collection) && !self.saveCapturedImage) {
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
    
    private func needToCollect() -> Bool {
        if (self.userMode == .Test) {
        //if (self.dispMode == .Collection) {
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
    
    private func updateSelectArea(rect: CGRect, valid: Bool) {
        self.selectedRect = rect
        self.selecting = false
        self.setting = false
        
        if (valid) {
            // todo:self.selectedImageViewにもimageを設定(modeはfit?)
            self.selectedMode = valid
            //self.captureImageView.alpha = 0.8
            self.view.bringSubviewToFront(self.selectedImageView!)
        }
    }
    
    private func updateUserMode() {
        if (self.userMode == .Product) {
            self.updateDetectArea(CGRectZero, valid: false)
            self.confManager.confSettings.debugMode.collection = false
        } else if (self.userMode == .Test) {
            // default
            self.dispMode = .Normal

            //let detectRect: CGRect = self.createValidDispRect()
            self.updateDetectArea(self.selectedRect, valid: true)
            self.confManager.confSettings.debugMode.collection = true
        }
        
        self.confManager.confSettings.settings.userMode = Int32(self.userMode.rawValue)
        
        SmartEyeW.setConfig()
    }
    
    private func updateDetectViewFrame(rect: CGRect) {
        self.validDetectionView.changeFrame(rect)
    }
    
    private func updateDetectArea(rect: CGRect, valid: Bool) {
        self.selectedRect = rect// TBD
        // 1回しか描画されないので、意味がないかな
        //self.drawRectangle(self.selectedRect, mode: 1)
        //self.validDetectionView?.frame = self.selectedRect
        //self.validDetectionView.changeFrame(rect)
        self.selecting = false
        self.setting = false
        self.selectedMode = valid
        //self.validDetectionView?.hidden = !self.selectedMode
        //self.captureImageView.alpha = 0.8
        
        self.updateDetectViewFrame(self.validDetectionRect)
        self.enableCollectionUI(valid)
        
        if (valid) {
            // todo:self.selectedImageViewにもimageを設定(modeはfit?)
            //self.validDetectionView?.backgroundColor = UIColor.redColor()
            //self.validDetectionView?.alpha = 0
            //self.view.bringSubviewToFront(self.selectedImageView!)
            self.view.bringSubviewToFront(self.validDetectionView!)
        } else {
            //self.captureImageView.alpha = 1.0
            self.view.layer.contents = nil
        }
    }
    
    // createValidDispRect使用
    private func createSelectedRect() -> CGRect {
        let maxValidSizeWidh = CGFloat(confManager.confSettings.detectParams.validRectMax.width) * 2
        let maxValidSizeHeight = CGFloat(confManager.confSettings.detectParams.validRectMax.height) * 2
        let startPosX = (self.view.bounds.size.width - maxValidSizeWidh) / 2
        let startPosY = (self.view.bounds.size.height - maxValidSizeHeight) / 2
        //let startPosX = (self.view.bounds.size.width - maxValidSizeWidh) / 2
        //let startPosY = (self.view.bounds.size.height - maxValidSizeHeight) / 2
        /*
         let startPosX = (self.view.bounds.size.width - maxValidSizeWidh) / 2
         let startPosY = (self.view.bounds.size.height - maxValidSizeHeight) / 2
         let startPos: CGPoint = CGPointMake(startPosX, startPosY)
         let endPos: CGPoint = CGPointMake(startPosX + maxValidSizeWidh, startPosY + maxValidSizeHeight)
         self.observer?.selectRectStart!(startPos)
         self.observer?.selectRectChanged!(endPos)
         self.observer?.selectRectEnd!()
         */
        return CGRectMake(startPosX, startPosY, maxValidSizeWidh, maxValidSizeHeight)
    }
    
    private func createValidDispRect() -> CGRect {
        // todo:ValidDetectionView.frameはiPhone画面サイズを基準にしているが、smarteyeは実際の画像のバッファーを基準にしている。
        // なので、同じselectedRectでもviewとimageview(camera sensorによる)でのサイズが異なる。
        // cameraからformatのsize(frameバッファーサイズ)を取得して、selectedRectを変換後viewに描画
        // ->selectedRectのwidthとheightは同じなので、それぞれバッファーサイズをベースに変換すると、長方形になってしまう。
        //   maxWidthとmaxHeightの小さい方をベースに変換
        let cameraFormat = self.cameraCap!.getVideoActiveFormatInfo()
        var retioWidth = cameraFormat.maxHeight
        if (cameraFormat.maxWidth < cameraFormat.maxHeight) {
            retioWidth = cameraFormat.maxWidth
        }
        let retio = self.view.bounds.size.width / CGFloat(retioWidth)
        let validWith = self.selectedRect.size.width * retio
        let validHeight = self.selectedRect.size.height * retio
        let startPosX = (self.view.bounds.size.width - validWith) / 2
        let startPosY = (self.view.bounds.size.height - validHeight) / 2
        //let startPosX = (self.view.bounds.size.width - maxValidSizeWidh) / 2
        //let startPosY = (self.view.bounds.size.height - maxValidSizeHeight) / 2
        /*
         let startPosX = (self.view.bounds.size.width - maxValidSizeWidh) / 2
         let startPosY = (self.view.bounds.size.height - maxValidSizeHeight) / 2
         let startPos: CGPoint = CGPointMake(startPosX, startPosY)
         let endPos: CGPoint = CGPointMake(startPosX + maxValidSizeWidh, startPosY + maxValidSizeHeight)
         self.observer?.selectRectStart!(startPos)
         self.observer?.selectRectChanged!(endPos)
         self.observer?.selectRectEnd!()
         */
        return CGRectMake(startPosX, startPosY, validWith, validHeight)
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
    
    private func updateValidDetectionRectLine(color: SignalColor) {
        if (color == .Green) {
            self.validDetectionView.changeLineColor(UIColor.greenColor(), lineWidth: 5.0)
        } else if (color == .Red) {
            self.validDetectionView.changeLineColor(UIColor.redColor(), lineWidth: 5.0)
        } else if (color == .Yellow) {
            self.validDetectionView.changeLineColor(UIColor.yellowColor())
        } else {
            self.validDetectionView.changeLineColor(UIColor.whiteColor())
        }
    }
    
    private func updateSignalImage(color: SignalColor) {
        if (color == .Green) {
            self.dummyGreenCount += 1
            self.dummySignalGreen.backgroundColor = UIColor.greenColor()
            self.dummySignalGreenCount.text = String(format: "%d", self.dummyGreenCount)
        } else if (color == .Red) {
            self.dummyRedCount += 1
            self.dummySignalRed.backgroundColor = UIColor.redColor()
            self.dummySignalRedCount.text = String(format: "%d", self.dummyRedCount)
        } else {
            self.dummySignalGreen.backgroundColor = UIColor.yellowColor()
            self.dummySignalRed.backgroundColor = UIColor.yellowColor()
        }
    }
    
    private func collectSignalData(capInfo: CaptureImageInfo, signals: NSMutableArray, collectionInfo: CollectionInfoW) {
        //let location: LEDMapLocation! = self.mapManager?.getCurrentLocation()
        //let heading: LEDMapHeading! = self.mapManager?.getCurrentHeading()
        let mapInfo: LEDMapInfo! = self.mapManager?.getCurrentMapInfo()
        //let cameraFormat: CameraFormat! = self.cameraCap?.getVideoActiveFormatInfo()
        let cameraSetting: CameraSetting = (self.cameraCap?.getCameraCurrentSettings())!
        let deviceData: DeviceData = DeviceData("", mapInfo.location.coor.latitude, mapInfo.location.coor.longitude, mapInfo.heading.magneticHeading, mapInfo.heading.trueHeading, mapInfo.timestamp)
        let cameraData: CameraData = CameraData(Int(cameraSetting.format), cameraSetting.exposureDuration, cameraSetting.exposureValue, cameraSetting.iso, cameraSetting.bias, cameraSetting.offset, Int(cameraSetting.fps))
        let frameData: FrameData = FrameData(CMTimeGetSeconds(capInfo.timeStamp), capInfo.orientation)
        let detectData: DetectData = DetectData(collectionInfo.imageContours, collectionInfo.pattern)
        var results: [DetectResult] = []
        for signal in signals {
            let signalData: SignalW = signal as! SignalW
            let result: DetectResult = DetectResult(true, Int(signalData.kind), Int(signalData.color), signalData.rect, signalData.distance, signalData.matching, signalData.circleLevel, signalData.procTime)
            results.append(result)
        }
        
        //dispatch_async(self.signalCollectQueue) { () -> Void in
        //if (self.collectionCount < self.collectionCountMax) {
            let collectionData: CollectionData = CollectionData(self.collectionCount, deviceData, cameraData, frameData, detectData, results)
            self.collectionCount = self.collectionCount + 1
            
            self.collectionDataMan.addData(collectionData)
            
            // TBD: output log
            if (self.needToSetting()) {
                do {
                    if (NSJSONSerialization.isValidJSONObject(collectionData.json())) {
                        let data:NSData? = try NSJSONSerialization.dataWithJSONObject(collectionData.json(), options: NSJSONWritingOptions.PrettyPrinted)
                        let payload:NSString = NSString(data:data!, encoding:NSUTF8StringEncoding)!
                        // todo:MQTT
                        let logger = SignalLogger.sharedInstance
                        logger.addLog(payload as String)
                    }
                } catch let error as NSError {
                    // Handle any errors
                    print(error)
                }
            }
        //}
        //}
    }
    
    private func uploadCollection() {
        let alertMsg = ""
        let actionSheet = UIAlertController(title: "Upload", message: alertMsg, preferredStyle: UIAlertControllerStyle.Alert)
        
        let viewButtonAction = UIAlertAction(title: "View", style: UIAlertActionStyle.Default) { (action) in
            
        }
        let uploadButtonAction = UIAlertAction(title: "Upload", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Upload")
            
#if false
            self.progressViewController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierProgressViewController) as! ProgressViewController
            // todo:custom segue
            self.presentViewController(self.progressViewController!, animated: true) { () -> Void in
                print("ProgressViewController")
#if false
                let localPath = FileManager.getSubDirectoryPath("/collection")
                let now = NSDate()
                let dateFormatter = NSDateFormatter()
                dateFormatter.locale = NSLocale(localeIdentifier: "en_US") // ロケールの設定
                dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss" // 日付フォーマットの設定
                let remotePath = "/SmartEye/collection/" + dateFormatter.stringFromDate(now) + "/"
                Uploader.getInstance().observer = self;
                Uploader.getInstance().save(localPath, toDropBox: remotePath, returnViewController: self)
    
#else
                // 30 * 5 = 150大きすぎる?()
                //self.collectionDataMan.sendBlockData(published後mqttDidDisconnectが呼ばれる。実際pushされていない)
                self.collectionDataMan.sendAllData()
#endif
            }
            
#else
            self.progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
            self.progressView.layer.position = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/2 + self.validDetectionRect.size.height)
            self.progressView.progress = 0.0
            self.view.addSubview(self.progressView)
    
            self.collectionDataMan.sendAllData()
#endif
        }
        
        let cancelButtonAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            print("Cancel")
            
            // todo: save to local file
            self.collectionDataMan.clearAllData()
            self.collectionDataMan.disconnect()
        }
        
        if (self.needToSetting()) {
            actionSheet.addAction(viewButtonAction)
        }
        actionSheet.addAction(uploadButtonAction)
        actionSheet.addAction(cancelButtonAction)
        
        self.presentViewController(actionSheet, animated: true) { () -> Void in
            print("Action Sheet")
        }
    }
    
    private func getFocusPoint(point: CGPoint) -> CGPoint {
        var focusPoint: CGPoint = point
        let cameraSetting = self.cameraCap?.getCameraCurrentSettings()
        
        if (cameraSetting?.orientaion == .Landscape) {
            focusPoint = CGPointMake(point.y / self.view.bounds.size.height, 1.0 - point.x / self.view.bounds.size.width)
        }
        
        return focusPoint
    }
    
    
    // MARK: - CameraCaptureObserver protocol
    
    func captureImageInfo(info: CaptureImageInfo!) {
        var detectedImage: UIImage?// = info.image
        var signalDetected = false
        var signalColor = SignalColor.Yellow
        var signalDistance: Float = 0
        var signalCircleLevel: Float = 0
        var signalMatching: Float = -1
        //var detectTime: Double = 0
        var signalData: SignalW!
        
        self.captureCount += 1
        
        // 1frameずつ減らす
        if (self.detectedRetainCount > 0) {
            self.detectedRetainCount -= 1
        }
        
        // todo:非同期で処理する場合、専用キューに入れる(むやみに別キューに入れると、その分コストがかかるので)
        //dispatch_sync(self.signalDetectQueue!, { () -> Void in // @memo:非同期の場合、キューで待機されるとき、メモリが増え続ける。警告発生して落ちる!?
        //if (!self.signalDetected) {// todo: 実際はキューをクリアしたい
        let debugInfo: DebugInfoW = DebugInfoW()
        let signals: NSMutableArray = NSMutableArray()
        //var detectedImage: UIImage? = nil
        
        var detectRect = CGRectZero
        if (self.selectedMode) {
            // todo:直接selectedRectを渡して、smarteyeで計算したほうがパフォーマンスが良いかも
            detectRect = SEUtil.detectRectOfSelecting(info.sampleBuffer, imageOrientation: info.orientation, selectedRect: self.selectedRect)
        } else {
            // memo:現状映像サイズによって実際detectする映像サイズが変わる。範囲は変わらない(解像度による画角が変わらないので)
            //      解像度が高ければdetectのサイズが大きくなるので、その分負荷がかかる
            //      640x480 x zoomFactor/2で上半分でdetectしている。表示しなければこのサイズで良いかも
            //        ただ、輪郭検出に多少影響が出るかも(点の情報が少なくなる->matching時情報が落ちる)。todo:必要ならサイズ調整
            //        todo:AR対応の場合、高解像度低範囲(rect)で行う
            detectRect = SEUtil.detectRectOfSampleBuffer(info.sampleBuffer, imageOrientation: info.orientation)
        }
        
        if (self.needToDetect()) {
            //let detectStartTime = CFAbsoluteTimeGetCurrent()
            
            SmartEyeW.detectSignalWithSampleBuffer(info.sampleBuffer, inRect: detectRect, signals: signals, debugInfo: debugInfo)
            
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
            //let detectEndTime = CFAbsoluteTimeGetCurrent()
            //detectTime = detectEndTime - detectStartTime
            
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
                signalData = signals[0] as! SignalW
                signalCircleLevel = signalData.circleLevel
                signalMatching = signalData.matching
                signalDistance = signalData.distance
                if (signalData.color == 1) {
                    signalColor = .Green
                } else if (signalData.color == 4) {
                    signalColor = .Red
                }
                // test
                if (signalData.kind == 1) {

                    // 回数リセット
                    self.detectedRetainCount = self.detectFps
                    
                    if (self.userMode == .Product) {
                        let detectResult = self.detectRstMan?.analyzeSignal(signalData, direction: self.mapManager!.getCurrentHeading().magneticHeading)
                        self.audio?.vibrate((detectResult?.vibrateCount)!)
                        self.voiceNavigation((detectResult?.speechContent)!)
                    }
                    
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
            
            if (self.needToCollect()) {
                if (self.collectionCount < self.collectionCountMax) {
                    let collW: CollectionInfoW = CollectionInfoW()
                    SmartEyeW.getCollectionInfo(collW)
                    self.collectSignalData(info, signals: signals, collectionInfo: collW)
                }
                
                // 変わっ時且つ　検出時/検出保時回数が0の(一定期間検出されない)場合、設定
                if (self.currentRectColor != signalColor) {
                    if ((signalDetected == true && self.detectedRetainCount == self.detectFps) || (signalDetected == false && self.detectedRetainCount == 0)) {
                        self.currentRectColor = signalColor
                        // @memo: queue in UI thread
                        dispatch_async(dispatch_get_main_queue()) { () -> Void in
                            self.updateValidDetectionRectLine(self.currentRectColor)
                        }
                    }
                }
            }
        } else { // detect時は行わない
            var adjustExpLevel: Int32 = 0
            
            // 表示モード(Normal/Setting)の場合、リアルタイムで描画
            if (self.needToDisplayView()) {
                adjustExpLevel = SmartEyeW.getExposureLevelWithSampleBuffer(info.sampleBuffer, inRect: detectRect, biasRangeMin: -6, max: 6, drawFlag: true)
            } else {// 非表示の場合、3秒毎にチェック。描画しない
                if (self.captureCount % (self.detectFps * 3) == 0) {
                    adjustExpLevel = SmartEyeW.getExposureLevelWithSampleBuffer(info.sampleBuffer, inRect: detectRect, biasRangeMin: -6, max: 6, drawFlag: false)
                }
            }
            
            if (self.captureCount % (self.detectFps * 3) == 0) {
                // todo:
                if (adjustExpLevel != 0) {
                    
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
                    self.dummySignalDistance.text = String(format: "%.2f/%.2f/%.2f", signalDistance, signalCircleLevel, signalMatching)
                }
                //self.updateSignalImage(signalColor)
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
                self.debugViewController?.updateDetectedImageData(signals as [AnyObject], captureImageInfo: info, debugInfo: debugInfo, detectTime: debugInfo.procTime)
            }
        }
    }
    
    func activeFormatChanged(format: CameraFormat) {
        // memo:集計(test)モードの場合、矩形表示を更新
        if (self.dispMode == .Setting || self.userMode == .Test) {
            self.validDetectionRect = self.createValidDispRect()
            // @memo: queue in UI thread
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.updateDetectViewFrame(self.validDetectionRect)
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
    
    // MARK: - UploadObserver
    func uploadFile(file: String!, currentProgress progress: Float) {
        
    }
    
    func uploader(uploder: Uploader!, progress: Float) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.progressViewController?.updateProgress(progress)
        }
        if (progress == 100) {
            dispatch_async(dispatch_get_main_queue()) {
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    print("dismissProgressViewController")
                    // todo:progress画面が表示されるのが原因？で追加されたShowが表示されない。
                    // 実際見えないが、LocalCameraが表示されるな(viewWillAppearなど).unwindでshow一覧画面に戻るので、途中で自動的にImage一覧画面が消え、LocalCamera画面が表示されたかも。ただすぐLocalCamera画面も破棄されshow一覧が表示される(新規showはすでに追加されている)
                    
                    }
                )
            }
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
    
    // MARK: - CollectionDataManagerDelegate protocol
    
    func collectionDataManager(dataManager: CollectionDataManager, didSendProgress progress: Float) {
        print("didSendProgress:\(progress)")
        
        dispatch_async(dispatch_get_main_queue()) {
            //self.progressViewController.updateProgress(progress)
            self.progressView.setProgress(progress / 100, animated: true)
            if (progress >= 100) {
                self.progressView.removeFromSuperview()
            }
        }
        
        if (progress >= 100) {
            self.collectionDataMan.disconnect()
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
        self.updateSelectArea(self.selectedRect, valid: true)
    }
    
    func selectRectCancel() {
        self.updateSelectArea(CGRectZero, valid: false)
    }
    
    func detectRect(rect: CGRect) {
        self.updateDetectArea(rect, valid: true)
    }
    
    func deleteDetectRect() {
        self.updateDetectArea(CGRectZero, valid: false)
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
        //self.validDetectionView?.hidden = !dMode
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
            self.resetDebugMode()
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
            self.collectionCount = 0
        }
    }
    
    @IBAction func collectAction(sender: AnyObject) {
        let colSwitch = sender as! UISwitch
        
        self.collecting = colSwitch.on
        self.procDetect = colSwitch.on
        
        if (colSwitch.on) {
            self.collectionCount = 0
            self.currentRectColor = .Yellow
            //self.validDetectionView.changeLineColor(UIColor.yellowColor())
            self.collectionDataMan = CollectionDataManager.sharedInstance
            self.collectionDataMan.setDelegate(self)
            self.collectionDataMan.connect()
        } else {
            self.currentRectColor = .None
            //self.validDetectionView.changeLineColor(UIColor.whiteColor())
            self.uploadCollection()
        }
        
        self.updateValidDetectionRectLine(self.currentRectColor)
    }
    
    @IBAction func collectionDetectAction(sender: AnyObject) {
        self.collecting = !self.collecting
        self.procDetect = !self.procDetect
        
        if (self.collecting) {
            self.collectButton.setBackgroundImage(UIImage(named: "detect_start.png"), forState: UIControlState.Normal)
            self.collectionCount = 0
            self.currentRectColor = .Yellow
            //self.validDetectionView.changeLineColor(UIColor.yellowColor())
            self.collectionDataMan = CollectionDataManager.sharedInstance
            self.collectionDataMan.setDelegate(self)
            self.collectionDataMan.connect()
        } else {
            self.collectButton.setBackgroundImage(UIImage(named: "detect_stop.png"), forState: UIControlState.Normal)
            self.currentRectColor = .None
            //self.validDetectionView.changeLineColor(UIColor.whiteColor())
            self.uploadCollection()
        }
        
        self.updateValidDetectionRectLine(self.currentRectColor)
    }
    
    @IBAction func exposureBiasDecAction(sender: AnyObject) {
        let currentSettings = self.cameraCap?.getCameraCurrentSettings()
        var bias = Float((currentSettings?.bias)!)
        bias -= 0.5
        self.cameraCap?.changeExposureBias(bias)
    }
    
    @IBAction func exposureBiasIncAction(sender: AnyObject) {
        let currentSettings = self.cameraCap?.getCameraCurrentSettings()
        var bias = Float((currentSettings?.bias)!)
        bias += 0.5
        self.cameraCap?.changeExposureBias(bias)
    }
    
    @IBAction func tapGestureForFocus(sender: AnyObject) {
        let gesRec: UITapGestureRecognizer = sender as! UITapGestureRecognizer
        let pos: CGPoint = gesRec.locationInView(self.view)
        
        if ((pos.x > self.validDetectionRect.origin.x && pos.x < self.validDetectionRect.origin.x + self.validDetectionRect.size.width) && (pos.y > self.validDetectionRect.origin.y && pos.y < self.validDetectionRect.origin.y + self.validDetectionRect.size.height)) {
            let point = CGPointMake((self.validDetectionRect.origin.x + self.validDetectionRect.size.width / 2), self.validDetectionRect.origin.y + self.validDetectionRect.size.height / 2)
            let focusPoint = self.getFocusPoint(point)
            self.cameraCap?.setFocusPoint(focusPoint)
        }
    }
    
    @IBAction func longGestureForDebug(sender: AnyObject) {
        //print("longGestureForDebug")
        
        let gesRec: UILongPressGestureRecognizer = sender as! UILongPressGestureRecognizer
        let pos: CGPoint = gesRec.locationInView(self.view)
        //print("long x:\(pos.x) y:\(pos.y)")
        
        let left: CGFloat = 50
        let right: CGFloat = self.view.bounds.size.width - 50
        
        // for userMode
        let top: CGFloat = self.view.bounds.size.height - 50 - 49 // TabBar:49?
        // for dispMode
        let bottom: CGFloat = 50 + 44 // NavigationBar:44
        
        // 有効検出矩形ないの場合、表示モード変更
        // ->余計だな(debugモードでやればいい)
        if ((pos.x > self.validDetectionRect.origin.x && pos.x < self.validDetectionRect.origin.x + self.validDetectionRect.size.width) && (pos.y > self.validDetectionRect.origin.y && pos.y < self.validDetectionRect.origin.y + self.validDetectionRect.size.height)) {
            if (gesRec.state == UIGestureRecognizerState.Ended) {
                
            }
        } else {
            //print("pan x:\(pos.x) y:\(pos.y)")
            if (gesRec.state == UIGestureRecognizerState.Began) {// 設定秒数間押し続くとBeganになる。Endで処理する場合、手を離さないとdebugmodeが変わらない
                //print("long began(\(gesRec.state))")
                if (pos.y < bottom) {
                    if (pos.x < left) {
                        self.gesturePosition = .LeftTop
                    } else if (pos.x > right) {
                        self.gesturePosition = .RightTop
                    }
                } else if (pos.y > top) {
                    if (pos.x < left) {
                        self.gesturePosition = .LeftBottom
                    } else if (pos.x > right) {
                        self.gesturePosition = .RightBottom
                    }
                }
            } else if (gesRec.state == UIGestureRecognizerState.Changed) {
                //print("long changed(\(gesRec.state))")
                if (((pos.x > left) && (pos.x <= right)) && ((pos.y < bottom) || (pos.y > top))) {
                    if (self.gesturePosition != .Middle) {
                        if (self.gesturePosition == .LeftTop || self.gesturePosition == .LeftBottom) {
                            self.panMoveDirection = .LeftToRight
                        } else if (self.gesturePosition == .RightTop || self.gesturePosition == .RightBottom) {
                            self.panMoveDirection = .RightToLeft
                        }
                        self.gesturePosition = .Middle
                    }
                }
                
            } else if (gesRec.state == UIGestureRecognizerState.Ended) {
                //print("long ended(\(gesRec.state))")
                if (pos.y < bottom) {
                    if (pos.x > right) {
                        if (self.panMoveDirection == .LeftToRight) {
                            if (self.dispMode == .Blindness) {
                                self.dispMode = .Normal
                            } else if (self.dispMode == .Normal) {
                                self.dispMode = .Setting
                            }
                        }
                    } else if (pos.x < left) {
                        if (self.panMoveDirection == .RightToLeft) {
                            if (self.dispMode == .Setting) {
                                self.dispMode = .Normal
                            } else if (self.dispMode == .Normal) {
                                self.dispMode = .Blindness
                            }
                        }
                    }
                    
                    self.updateDispMode()
                } else if (pos.y > top) {
                    if (pos.x > right) {
                        if (self.panMoveDirection == .LeftToRight) {
                            if (self.userMode == .Product) {
                                self.userMode = .Test
                            }
                        }
                    } else if (pos.x < left) {
                        if (self.panMoveDirection == .RightToLeft) {
                            if (self.userMode == .Test) {
                                self.userMode = .Product
                            }
                        }
                    }
                    
                    self.updateUserMode()
                }
                
                self.gesturePosition = .None
                self.panMoveDirection = .None
            } else {// cancelなど
                //print("pan others(\(gesRec.state))")
                self.gesturePosition = .None
                self.panMoveDirection = .None
            }
        }
    }
    
    // memo:long gestureに入った場合、pan gestureには入らない
    @IBAction func panGestureForDebug(sender: AnyObject) {
        let gesRec: UIPanGestureRecognizer = sender as! UIPanGestureRecognizer
        let pos: CGPoint = gesRec.locationInView(self.view)
        
        //if (self.gesturePosition != .None) {
        let left: CGFloat = 50
        let right: CGFloat = self.view.bounds.size.width - 50
        
        // for userMode
        let top: CGFloat = self.view.bounds.size.height - 50 - 49 // TabBar:49?
        // for dispMode
        let bottom: CGFloat = 50 + 44 // NavigationBar:44
        
            //print("pan x:\(pos.x) y:\(pos.y)")
            if (gesRec.state == UIGestureRecognizerState.Began) {
                //print("pan began(\(gesRec.state))")
                if (pos.y < bottom) {
                    if (pos.x < left) {
                        self.gesturePosition = .LeftTop
                    } else if (pos.x > right) {
                        self.gesturePosition = .RightTop
                    }
                } else if (pos.y > top) {
                    if (pos.x < left) {
                        self.gesturePosition = .LeftBottom
                    } else if (pos.x > right) {
                        self.gesturePosition = .RightBottom
                    }
                }
            } else if (gesRec.state == UIGestureRecognizerState.Changed) {
                //print("pan changed(\(gesRec.state))")
                if (((pos.x > left) && (pos.x <= right)) && ((pos.y < bottom) || (pos.y > top))) {
                    if (self.gesturePosition != .Middle) {
                        if (self.gesturePosition == .LeftTop || self.gesturePosition == .LeftBottom) {
                            self.panMoveDirection = .LeftToRight
                        } else if (self.gesturePosition == .RightTop || self.gesturePosition == .RightBottom) {
                            self.panMoveDirection = .RightToLeft
                        }
                        self.gesturePosition = .Middle
                    }
                }

            } else if (gesRec.state == UIGestureRecognizerState.Ended) {
                //print("pan ended(\(gesRec.state))")
                if (pos.y < bottom) {
                    if (pos.x > right) {
                        if (self.panMoveDirection == .LeftToRight) {
                            if (self.dispMode == .Blindness) {
                                self.dispMode = .Normal
                            } else if (self.dispMode == .Normal) {
                                self.dispMode = .Setting
                            }
                        }
                    } else if (pos.x < left) {
                        if (self.panMoveDirection == .RightToLeft) {
                            if (self.dispMode == .Setting) {
                                self.dispMode = .Normal
                            } else if (self.dispMode == .Normal) {
                                self.dispMode = .Blindness
                            }
                        }
                    }
                    
                    self.updateDispMode()
                } else if (pos.y > top) {
                    if (pos.x > right) {
                        if (self.panMoveDirection == .LeftToRight) {
                            if (self.userMode == .Product) {
                                self.userMode = .Test
                            }
                        }
                    } else if (pos.x < left) {
                        if (self.panMoveDirection == .RightToLeft) {
                            if (self.userMode == .Test) {
                                self.userMode = .Product
                            }
                        }
                    }
                    
                    self.updateUserMode()
                }
                
                self.gesturePosition = .None
                self.panMoveDirection = .None
            } else {// cancelなど
                //print("pan others(\(gesRec.state))")
                self.gesturePosition = .None
                self.panMoveDirection = .None
            }
       // }
    }
    
}

