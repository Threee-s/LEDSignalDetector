//
//  DebugModeViewController.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2015/03/04.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import UIKit
import AVFoundation

struct DebugModeColorSpaceHSV {
    var hue: Float
    var satureation: Float
    var value: Float
}

enum DebugMode: Int {
    case Camera = 0x01
    case Record = 0x02
    case Graph  = 0x04
    case Color  = 0x08
    case All    = 0x0f
}

// @memo: swiftでoptionalできないので、@objcをつける。構造体を引数にできない？
// optionalでできるはず
@objc protocol DebugModeObserver {
    optional func settingState(state: Bool)// 各種設定開始(ジェスチャー)
    optional func settingChangeStart()
    optional func settingChangeEnd()
    optional func detectStart()
    optional func detectEnd()
    optional func selectRectStart(startPoint: CGPoint)
    optional func selectRectChanged(nextPoint: CGPoint)
    optional func selectRectEnd()
    //optional func selectRectEnd(size: CGSize)
    optional func deleteSelectedRect()
    
    optional func cameraSettingChanged(exposureBias bias: Float)
    optional func cameraSettingChanged(exposureISO iso: Float)
    optional func cameraSettingChanged(exposureDuration ss: Float) -> Float
    optional func cameraSettingChanged(videoFPS fps: Float)
    optional func cameraSettingChanged(zoomFactor zoom: Float)
    
    optional func smartEyeConfigChanged(reset: Bool)// reset:
    //optional func colorSpaceChanged(hue h: Float)
    //optional func colorSpaceChanged(saturation s: Float)
    //optional func colorSpaceChanged(value v: Float)
    
    optional func getVideoActiveFormatInfo() -> CameraFormat
    optional func getCameraCurrentSettings() -> CameraSetting
    
    optional func detectSignalColor(color: Int)
    optional func detectBatch(flag: Bool)
    
    optional func sensorStart()
    optional func setSensorType(type: AirSensorType)
    optional func sensorEnd()
}

// for debug
class DebugModeViewController: UIViewController {
    let QUEUE_SERIAL_IMAGE_SAVE = "com.threees.tre.led.image-save"
    let QUEUE_SERIAL_SIGNAL_LOG = "com.threees.tre.led.signal-log"
    let DEBUG_GESTURE_AVAILABLE_AREA_OFFSET: CGFloat = 50.0
    
    @IBOutlet weak var rangeISOLabel: UILabel!
    @IBOutlet weak var rangeSSLabel: UILabel!
    @IBOutlet weak var rangeFPSLabel: UILabel!
    @IBOutlet weak var valueISOLabel: UILabel!
    @IBOutlet weak var valueSSLabel: UILabel!
    @IBOutlet weak var valueFPSLabel: UILabel!
    
    // for HSV color space
    @IBOutlet weak var hueNameLabel: UILabel!
    @IBOutlet weak var hueLowSlider: UISlider!
    @IBOutlet weak var hueHighSlider: UISlider!
    @IBOutlet weak var hueValueLabel: UILabel!
    @IBOutlet weak var saturationNameLabel: UILabel!
    @IBOutlet weak var saturationLowSlider: UISlider!
    @IBOutlet weak var saturationHighSlider: UISlider!
    @IBOutlet weak var saturationValueLabel: UILabel!
    @IBOutlet weak var valueNameLabel: UILabel!
    @IBOutlet weak var valueLowSlider: UISlider!
    @IBOutlet weak var valueHighSlider: UISlider!
    @IBOutlet weak var valueValueLabel: UILabel!
    @IBOutlet weak var colorTypeSegment: UISegmentedControl!
    
    // for camera setting of exposure
    @IBOutlet weak var exposureOffsetNameLabel: UILabel!
    @IBOutlet weak var exposureOffsetSlider: UISlider!
    @IBOutlet weak var exposureOffsetValueLabel: UILabel!
    @IBOutlet weak var exposureBiasNameLabel: UILabel!
    @IBOutlet weak var exposureBiasSlider: UISlider!
    @IBOutlet weak var exposureBiasValueLabel: UILabel!
    @IBOutlet weak var exposureISONameLabel: UILabel!
    @IBOutlet weak var exposureISOSlider: UISlider!
    @IBOutlet weak var exposureISOValueLabel: UILabel!
    @IBOutlet weak var exposureDurationNameLabel: UILabel!
    @IBOutlet weak var exposureDurationSlider: UISlider!
    @IBOutlet weak var exposureDurationValueLabel: UILabel!
    @IBOutlet weak var fpsNameLabel: UILabel!
    @IBOutlet weak var fpsSlider: UISlider!
    @IBOutlet weak var fpsValueLabel: UILabel!
    @IBOutlet weak var videoFPSSegmentControl: UISegmentedControl!
    @IBOutlet weak var zoomNameLabel: UILabel!
    @IBOutlet weak var zoomSlider: UISlider!
    @IBOutlet weak var zoomValueLabel: UILabel!
    
    // for record
    @IBOutlet weak var imageRecordNameLabel: UILabel!
    @IBOutlet weak var imageRecordTimeSlider: UISlider!
    @IBOutlet weak var imageRecordSwitch: UISwitch!
    @IBOutlet weak var imageRecordValueLabel: UILabel!
    
    @IBOutlet weak var logRecordSwitch: UISwitch!
    @IBOutlet weak var batchDetectSwitch: UISwitch!
    
    // for disp mode(binary/point/rect/signal/selected) todo:->Tool Bar??
    @IBOutlet weak var dispSegment: UISegmentedControl!
    
    @IBOutlet weak var sensorGraphView: AirGraphView!
    @IBOutlet weak var sensorSegControl: UISegmentedControl!
    var sensorStart: Bool = false // センサー起動フラグ
    var sensorType: AirSensorType = AirSensorTypeNone
    
    var confManager: ConfigManager = ConfigManager.sharedInstance()
    
    var imageSaveQueue: dispatch_queue_t?
    var signalLogQueue: dispatch_queue_t?
    
    var observer: DebugModeObserver?
    var graphViewController: LEDSignalGraphViewController?
    var graphView: SignalGraphView?
    
    var videoFPS: Int = 0
    //var realFPS: Float = 0
    
    // todo:有効モードを設定(captureとrecordでは必要なモードが違うので)
    var validMode: DebugMode = .All
    
    // Debug専用viewなので、基本true.今後制御が必要な場合、switchなどで制御.
    var debugMode: Bool = true
    var recordMode: Bool = false
    var cameraMode: Bool = false
    var graphMode: Bool = false
    var colorMode: Bool = false
    
    //var graphSetup: Bool = false
    
    var dispMode: Int = 0
    var dispModeBin: Bool = false
    var dispModePoint: Bool = false
    var dispModeRect: Bool = false
    var dispModeArea: Bool = false
    var dispModeSignal: Bool = false
    var dispModeSelect: Bool = false
    
    //var selectMode: Bool = false
    var rectSelected: Bool = false
    
    var colorType: Int = 0
    
    var saveCapture: Bool = false
    var recordTime: Int = 0
    var captureTime: CMTimeValue = 0
    var captureImageCount: Int = 0
    var saveImageCount: Int = 0
    var saveLogCount: Int = 0
    var saveCountMax: Int = 0
    //var saveCountMax: Int {// 毎回計算される
    //    get {
    //        return Int(self.videoFPS) * self.recordTime
    //    }
    //}
    
    var saveLog: Bool = false
    var batchDetect: Bool = false
    
    var exposureOffset: Float = 0
    var exposureBias: Float = 0
    var exposureISO: Float = 0
    var exposureDuration: Float = 0
    var exposureValue: Float = 0
    var zoomValue: Float = 0
    
    var hue: (low: Int, high: Int) = (0, 0)
    var saturation: (low: Int, high: Int) = (0, 0)
    var value: (low: Int, high: Int) = (0, 0)
    
    // 取りあえず１個
    var signalData: Array<SignalW> = []
    //var signalsData: Dictionary<Int, SignalW> = [:]
    
    var logger: SignalLogger?

    override func viewDidLoad() {
        //Log.debug("DebugModeView viewDidLoad")
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.graphViewController = LEDSignalGraphViewController(nibName: "LEDSignalGraphViewController", bundle: nil)
        // todo:add graphViewController.view?
        //self.graphView = self.graphViewController?.signalGraphView
        //self.graphView?.hidden = true
        self.graphViewController?.signalGraphView?.hidden = true
        
        //self.view.addSubview(self.graphView!)// @memo:まだ初期化されていないので、落ちる
        self.view.addSubview(self.graphViewController!.view!)
        
        self.imageSaveQueue = dispatch_queue_create(QUEUE_SERIAL_IMAGE_SAVE, DISPATCH_QUEUE_SERIAL)
        self.signalLogQueue = dispatch_queue_create(QUEUE_SERIAL_SIGNAL_LOG, DISPATCH_QUEUE_SERIAL)
        
        //initCameraSetting()
        
        self.logger = SignalLogger.sharedInstance
        self.logger?.clearLogs()
        
        if (self.debugMode) {
            self.observer?.settingState!(self.cameraMode || self.recordMode || self.colorMode || self.graphMode)
        }
        
        //self.setupDebugModeView(self.debugMode)
    }
    
    override func viewWillAppear(animated: Bool) {
        //Log.debug("DebugModeView viewWillAppear")
        
        // not to be called because view is always hidden
        super.viewWillAppear(animated)
        
        //initCameraSetting()
    }
    
    override func viewDidAppear(animated: Bool) {
        //Log.debug("DebugModeView viewDidAppear")
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        //Log.debug("DebugModeView viewWillDisappear")
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        //Log.debug("DebugModeView viewDidDisappear")
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func convert2fraction(value: Float) -> String {
        var str: String = ""
        if (value >= 1) {
            str = String(format: "%.2f", value)
        } else if (value > 0) {
            let digits = max(0, 2 + floor(log10(value)))
            //println("digits:\(digits)")
            str = String(format: "1/%.*f", digits, 1.0 / value)
        }
        
        return str
    }
    
    private func initCameraSetting() {
        updateCameraActiveFormat(self.observer!.getVideoActiveFormatInfo!())
        updateCameraCurrentSetting(self.observer!.getCameraCurrentSettings!())
        setCameraSetting()
    }
    
    private func initUI() {
        
    }
    
    private func updateCameraSettingSlider() {
        self.exposureDurationSlider.value = self.exposureValue
        self.exposureISOSlider.value = self.exposureISO
        self.exposureBiasSlider.value = self.exposureBias
        self.exposureOffsetSlider.value = self.exposureOffset
        self.fpsSlider.value = Float(self.videoFPS)
        self.zoomSlider.value = self.zoomValue
    }
    
    private func setupDebugModeView(debugMode: Bool) {
        self.setupDispModeView(debugMode)
        self.setupRecordModeView(debugMode, recordMode: self.recordMode)
        self.setupCameraModeView(debugMode, cameraMode: self.cameraMode)
        self.setupGraphModeView(debugMode, graphMode: self.graphMode)
        self.setupColorModeView(debugMode, colorMode: self.colorMode)
    }
    
    private func setupDispModeView(debugMode: Bool) {
        //self.dispSegment.hidden = !debugMode
    }
    
    private func setupRecordModeView(debugMode: Bool, recordMode: Bool) {
        let modeFlag = (debugMode && recordMode)
        self.imageRecordNameLabel.hidden = !modeFlag
        self.imageRecordTimeSlider.hidden = !modeFlag
        self.imageRecordSwitch.hidden = !modeFlag
        self.imageRecordValueLabel.hidden = !modeFlag
    }
    
    private func setupCameraModeView(debugMode: Bool, cameraMode: Bool) {
        let modeFlag = (debugMode && cameraMode)
        if (modeFlag) {
            initCameraSetting()
        } else {
            //setCameraSetting()// 変更時保存すれば良い。無効時保存しなくて良い。
        }
        
        self.rangeISOLabel.hidden = !modeFlag
        self.rangeSSLabel.hidden = !modeFlag
        self.rangeFPSLabel.hidden = !modeFlag
        self.valueISOLabel.hidden = !modeFlag
        self.valueSSLabel.hidden = !modeFlag
        self.valueFPSLabel.hidden = !modeFlag
        
        self.exposureOffsetNameLabel.hidden = !modeFlag
        self.exposureOffsetSlider.hidden = !modeFlag
        self.exposureOffsetValueLabel.hidden = !modeFlag
        self.exposureBiasNameLabel.hidden = !modeFlag
        self.exposureBiasSlider.hidden = !modeFlag
        self.exposureBiasValueLabel.hidden = !modeFlag
        self.exposureISONameLabel.hidden = !modeFlag
        self.exposureISOSlider.hidden = !modeFlag
        self.exposureISOValueLabel.hidden = !modeFlag
        self.exposureDurationNameLabel.hidden = !modeFlag
        self.exposureDurationSlider.hidden = !modeFlag
        self.exposureDurationValueLabel.hidden = !modeFlag
        self.fpsNameLabel.hidden = !modeFlag
        self.fpsSlider.hidden = !modeFlag
        self.fpsValueLabel.hidden = !modeFlag
        self.videoFPSSegmentControl.hidden = !modeFlag
        self.zoomNameLabel.hidden = !modeFlag
        self.zoomSlider.hidden = !modeFlag
        self.zoomValueLabel.hidden = !modeFlag
        
        self.logRecordSwitch.hidden = !modeFlag
        self.batchDetectSwitch.hidden = !modeFlag
    }
    
    private func setupGraphModeView(debugMode: Bool, graphMode: Bool) {
        let modeFlag = (debugMode && graphMode)
        //self.graphView?.hidden = !(debugMode && graphMode)
        //self.graphViewController?.signalGraphView?.hidden = !(debugMode && graphMode)
        self.sensorGraphView.hidden = !modeFlag
        self.sensorSegControl.hidden = !modeFlag
        if (modeFlag) {
            self.startSensor()
        } else {
            self.stopSensor()
        }
    }
    
    private func setupColorModeView(debugMode: Bool, colorMode: Bool) {
        let modeFlag = (debugMode && colorMode )
        if (modeFlag) {
            self.colorType = Int(confManager.confSettings.colorSettings.detectColors)
            if (self.colorType == 1) {
                self.colorTypeSegment.tag = 0
                self.colorTypeSegment.selectedSegmentIndex = 0
            } else if (self.colorType == 4) {
                self.colorTypeSegment.tag = 1
                self.colorTypeSegment.selectedSegmentIndex = 1
            } else if (self.colorType == 5) {
                self.colorTypeSegment.tag = 2
                self.colorTypeSegment.selectedSegmentIndex = 2
            }
            getColor(self.colorType)
            updateColorValue()
        } else {
            //setColor(self.colorType)// 変更時保存すれば良い。無効時保存しなくて良い。
        }
        
        self.hueNameLabel.hidden = !modeFlag
        self.hueLowSlider.hidden = !modeFlag
        self.hueHighSlider.hidden = !modeFlag
        self.hueValueLabel.hidden = !modeFlag
        self.saturationNameLabel.hidden = !modeFlag
        self.saturationLowSlider.hidden = !modeFlag
        self.saturationHighSlider.hidden = !modeFlag
        self.saturationValueLabel.hidden = !modeFlag
        self.valueNameLabel.hidden = !modeFlag
        self.valueLowSlider.hidden = !modeFlag
        self.valueHighSlider.hidden = !modeFlag
        self.valueValueLabel.hidden = !modeFlag
        self.colorTypeSegment.hidden = !modeFlag
    }
    
    private func startSensor() {
        if (self.sensorStart == false) {
            self.observer?.sensorStart!()
            self.sensorStart = true
        }
    }
    
    private func stopSensor() {
        if (self.sensorStart == true) {
            self.observer?.sensorEnd!()
            self.sensorStart = false
        }
    }
    
    private func getColor(type: Int) {
        // todo:allの場合は?
        if (type & 1 == 1) {
            self.hue.low = Int(confManager.confSettings.colorSettings.colorSpaceGreen.h.lower)
            self.hue.high = Int(confManager.confSettings.colorSettings.colorSpaceGreen.h.upper)
            self.saturation.low = Int(confManager.confSettings.colorSettings.colorSpaceGreen.s.lower)
            self.saturation.high = Int(confManager.confSettings.colorSettings.colorSpaceGreen.s.upper)
            self.value.low = Int(confManager.confSettings.colorSettings.colorSpaceGreen.v.lower)
            self.value.high = Int(confManager.confSettings.colorSettings.colorSpaceGreen.v.upper)
        } else if (type & 4 == 4) {
            self.hue.low = Int(confManager.confSettings.colorSettings.colorSpaceRed.h.lower)
            self.hue.high = Int(confManager.confSettings.colorSettings.colorSpaceRed.h.upper)
            self.saturation.low = Int(confManager.confSettings.colorSettings.colorSpaceRed.s.lower)
            self.saturation.high = Int(confManager.confSettings.colorSettings.colorSpaceRed.s.upper)
            self.value.low = Int(confManager.confSettings.colorSettings.colorSpaceRed.v.lower)
            self.value.high = Int(confManager.confSettings.colorSettings.colorSpaceRed.v.upper)
        }
    }
    
    private func setColor(type: Int) {
        if (type & 1 == 1) {
            confManager.confSettings.colorSettings.colorSpaceGreen.h.lower = Int32(self.hue.low)
            confManager.confSettings.colorSettings.colorSpaceGreen.h.upper = Int32(self.hue.high)
            confManager.confSettings.colorSettings.colorSpaceGreen.s.lower = Int32(self.saturation.low)
            confManager.confSettings.colorSettings.colorSpaceGreen.s.upper = Int32(self.saturation.high)
            confManager.confSettings.colorSettings.colorSpaceGreen.v.lower = Int32(self.value.low)
            confManager.confSettings.colorSettings.colorSpaceGreen.v.upper = Int32(self.value.high)
        } else if (type & 4 == 4) {
            confManager.confSettings.colorSettings.colorSpaceRed.h.lower = Int32(self.hue.low)
            confManager.confSettings.colorSettings.colorSpaceRed.h.upper = Int32(self.hue.high)
            confManager.confSettings.colorSettings.colorSpaceRed.s.lower = Int32(self.saturation.low)
            confManager.confSettings.colorSettings.colorSpaceRed.s.upper = Int32(self.saturation.high)
            confManager.confSettings.colorSettings.colorSpaceRed.v.lower = Int32(self.value.low)
            confManager.confSettings.colorSettings.colorSpaceRed.v.upper = Int32(self.value.high)
        }
    }
    
    private func updateColorValue() {
        self.hueLowSlider.value = Float(self.hue.low)
        self.hueHighSlider.value = Float(self.hue.high)
        self.saturationLowSlider.value = Float(self.saturation.low)
        self.saturationHighSlider.value = Float(self.saturation.high)
        self.valueLowSlider.value = Float(self.value.low)
        self.valueHighSlider.value = Float(self.value.high)
        self.hueValueLabel.text = String(format:"%d-%d", self.hue.low, self.hue.high)
        self.saturationValueLabel.text = String(format:"%d-%d", self.saturation.low, self.saturation.high)
        self.valueValueLabel.text = String(format:"%d-%d", self.value.low, self.value.high)
        
        print("hue:\(self.hueValueLabel.text) saturation:\(self.saturationValueLabel.text) value:\(self.valueValueLabel.text)")
    }
    
    private func getCameraSetting() {
        self.exposureValue = confManager.confSettings.cameraSettings.exposureValue
        self.exposureISO = confManager.confSettings.cameraSettings.iso
        self.exposureBias = confManager.confSettings.cameraSettings.bias
        self.videoFPS = Int(confManager.confSettings.cameraSettings.fps)
    }
    
    private func setCameraSetting() {
        confManager.confSettings.cameraSettings.exposureValue = self.exposureValue
        confManager.confSettings.cameraSettings.iso = self.exposureISO
        confManager.confSettings.cameraSettings.bias = self.exposureBias
        confManager.confSettings.cameraSettings.fps = Int32(self.videoFPS)
    }
    
    private func updateCameraSettingValue() {
        self.exposureDurationValueLabel.text = self.convert2fraction(self.exposureDuration)
        self.exposureISOValueLabel.text = String(format: "%.1f", self.exposureISO)
        self.exposureBiasValueLabel.text = String(format: "%.1f", self.exposureBias);
        self.exposureOffsetValueLabel.text = String(format: "%.1f", self.exposureOffset);
        self.fpsValueLabel.text = String(format: "%d", self.videoFPS)
        self.zoomValueLabel.text = String(format: "%.2f", self.zoomValue)
    }
    
    private func setDebugMode() {
        confManager.confSettings.debugMode.flag = self.debugMode
        confManager.confSettings.debugMode.binary = self.dispModeBin
        confManager.confSettings.debugMode.point = self.dispModePoint
        confManager.confSettings.debugMode.rect = self.dispModeRect
        confManager.confSettings.debugMode.area = self.dispModeArea
        confManager.confSettings.debugMode.signal = self.dispModeSignal
    }
    
    // for UISegmentControl
    private func setupConfig(confList: Array<(key: String, value: AnyObject)>) {
        let confDic: NSMutableDictionary = FileManager.loadConfigFromPlist("SmartEyeConfig.plist")
        
        for conf: (key: String, value: AnyObject)  in confList {
            confDic.setValue(conf.value, forKey: conf.key)
        }
        
        FileManager.saveToPlist("SmartEyeConfig.plist", withDictionary: confDic as [NSObject : AnyObject])
        SmartEyeW.setConfig()
    }
    
    private func updateDispMode(mode: Int) {
        
    }
    
    private func setLog(flag: Bool) {
        if (flag) {
            self.confManager.confSettings.debugMode.log = true
            self.logger?.clearLogs()
            self.logger?.addLog(self.confManager.description())
            self.saveLogCount = 0
            
            var logTime = self.recordTime
            if (logTime <= 0) {
                logTime = 1
                //logTime = 2
            } else {// recordTimeが設定された場合、同時に画像も保存する.todo:保存によってパフォーマンスが落ちるので、多少ずれるかも
                FileManager.deleteSubFolder("image")
                FileManager.createSubFolder("image")
                self.saveImageCount = 0
                self.saveCountMax = self.videoFPS * self.recordTime + 1
                self.imageRecordValueLabel.text = String(format: "%ds", self.recordTime)
                self.saveCapture = true
            }
            // memo:captureとlog設定/リセットは違うキュー(スレッド)なので、途中(1,2番目後)でログがリセットされる可能性があるので、+数個を取る
            self.saveCountMax = self.videoFPS * logTime + Int(1) + 5
            print("saveCountMax:\(self.saveCountMax)")
        } else {
            self.confManager.confSettings.debugMode.log = false
        }
        self.observer?.smartEyeConfigChanged!(true)
        self.saveLog = flag
    }
    
    func setValidMode(validMode: DebugMode) {
        self.validMode = validMode
    }
    
    func updateCameraActiveFormat(format: CameraFormat) {
        //print("exposureValue:[0 - 1]")
        //print("exposureDuration:[\(format.minExposureDuration) - \(format.maxExposureDuration)]")
        //print("iso:[\(format.minISO) - \(format.maxISO)]")
        //print("bias:[\(format.minExposureBias) - \(format.maxExposureBias)]")
        //print("fps:[\(format.minFPS) - \(format.maxFPS)]")

        self.exposureOffsetSlider.minimumValue = format.minExposureOffset
        self.exposureOffsetSlider.maximumValue = format.maxExposureOffset
        self.exposureBiasSlider.minimumValue = format.minExposureBias
        self.exposureBiasSlider.maximumValue = format.maxExposureBias
        self.exposureISOSlider.minimumValue = format.minISO
        self.exposureISOSlider.maximumValue = format.maxISO
        // from AVCamManual
        // Use 0-1 as the slider range and do a non-linear mapping from the slider value to the actual device exposure duration
        self.exposureDurationSlider.minimumValue = format.minExposureValue
        self.exposureDurationSlider.maximumValue = format.maxExposureValue
        //self.exposureDurationSlider.minimumValue = format.minExposureDuration
        //self.exposureDurationSlider.maximumValue = format.maxExposureDuration
        
        self.fpsSlider.minimumValue = format.minFPS
        self.fpsSlider.maximumValue = format.maxFPS
        // todo:UISegmentControlの表示範囲制限
        /*
        let fpsList: [Float] = self.videoFPSSegmentControl.
        for fps in fpsList {
            var valid = false
            if (fps >= self.fpsSlider.minimumValue && fps <= self.fpsSlider.maximumValue) {
                valid = true
            }
        
            self.videoFPSSegmentControl.setEnabled(valid, forSegmentControl:fpsList.indexOfObject(fps))
        }*/
        
        self.zoomSlider.minimumValue = format.minZoom
        self.zoomSlider.maximumValue = format.maxZoom
        
        // set by CameraSettingController
        //confManager.confSettings.cameraSettings.formatIndex = index
        
        self.rangeSSLabel.text = String(format: "%@-%@", self.convert2fraction(format.maxExposureDuration), self.convert2fraction(format.minExposureDuration))
        self.rangeISOLabel.text = String(format: "%.1f-%.1f", format.minISO, format.maxISO)
        self.rangeFPSLabel.text = String(format: "%.1f-%.1f", format.minFPS, format.maxFPS)
    }
    
    func updateCameraCurrentSetting(currentSettings: CameraSetting) {
        //print("exposureDuration:\(currentSettings.exposureDuration)")
        //print("exposureValue:\(currentSettings.exposureValue)")
        //print("iso:\(currentSettings.iso)")
        //print("bias:\(currentSettings.bias)")
        //print("offset:\(currentSettings.offset)")
        //print("fps:\(currentSettings.fps)")
        // from current setting of camera. because settings have been changed by formats selection.
        self.exposureDuration = currentSettings.exposureDuration
        self.exposureValue = currentSettings.exposureValue
        self.exposureISO = currentSettings.iso
        self.exposureBias = currentSettings.bias
        self.exposureOffset = currentSettings.offset
        self.videoFPS = Int(currentSettings.fps)
        self.zoomValue = currentSettings.zoom
        
        updateCameraSettingValue()
        updateCameraSettingSlider()
    }
    
    // todo:graph更新。RecordTimerSlider移動対応
    func updateDetectedImageData(detectedImage dImage: UIImage!, data: [AnyObject]!, captureImageInfo cInfo: CaptureImageInfo! = nil, debugInfo dInfo: DebugInfoW!, selectedImage sImage: UIImage, selectecRect rect: CGRect = CGRectZero) {
        
        if (self.debugMode && self.graphMode) {
            self.graphViewController!.setSignalData(data)
        }
        
        // 画像保存. todo: create queue for saving
        //println("debugMode:\(self.debugMode) recordMode:\(self.recordMode) saveCapture:\(self.saveCapture)")
        if (self.debugMode /*&& self.recordMode*/ && self.saveCapture) {
            // 最大画像数分処理(queueに入れる最大画像数)
            if (self.captureImageCount >= self.saveCountMax) {
                return
            } else {
                self.captureImageCount++
            }
            dispatch_async(self.imageSaveQueue!, { () -> Void in // @memo:非同期なので、最大画像数まで制限しないと、キューで待機されるとき、メモリが増え続ける。警告発生して落ちる!?
            //dispatch_sync(self.imageSaveQueue!, { () -> Void in
                print("saveImageCount:\(self.saveImageCount) saveCountMax:\(self.saveCountMax)")
                //var saveImage = cInfo.image
                var saveImage = dImage
                if (self.dispModeSelect) {
                    saveImage = sImage
                }
                // memo:jpegの場合、圧縮されるので、sampleBufferのデータと結果が違うかも
                let data = UIImageJPEGRepresentation(saveImage, 0.5)
                // todo:キャプチャ時と結果が異なる場合、圧縮率を減らす
                //let data = UIImageJPEGRepresentation(saveImage, 1)
                // memo:orientaionが保存されない
                //let data = UIImagePNGRepresentation(saveImage)// not dImage
                if (data == nil) {
                    print("data is nil")
                }
                //let now = NSDate()
                // @memo double->string
                //let fileName = String(format:"%.3f", now.timeIntervalSince1970)
                //let fileNameExt = String(format:"image_%d.jpg", self.saveImageCount + 1)
                let imageNameExt = String(format:"image_%d.png", self.saveImageCount + 1)
                if (FileManager.saveData(data, toFile: imageNameExt, inFolder: "/image")) {
                    /*
                    let dataNameExt = String(format:"data_%d.dat", self.saveImageCount + 1)
                    var str = String(format: "%lld", cInfo.timeStamp.value)
                    if (FileManager.saveString(str, toFile: dataNameExt, inFolder: "/image")) {
                    self.saveImageCount++
                    if (self.saveImageCount == 1) {
                    self.captureTime = cInfo.timeStamp.value
                    }
                    } else {
                    println("data save error")
                    }
                    */
                    self.saveImageCount++
                    if (self.saveImageCount == 1) {
                        self.captureTime = cInfo.timeStamp.value
                    }
                    
                    if (self.saveImageCount == self.saveCountMax) {
                        self.saveCapture = false
                        self.captureImageCount = 0
                        self.captureTime = cInfo.timeStamp.value - self.captureTime
                        
                        // set in UI thread. 保存処理完了後UI更新。更新完了後次の保存処理を行う。countがずれる可能性があるので。
                        //dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        // todo:ファイル保存は非同期なので、実際全てのファイル保存後も数回呼ばれる(溜まっている) ok
                        dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                            print("saveCapture:\(self.saveCapture) saveImageCount:\(self.saveImageCount)")
                            self.imageRecordValueLabel.text = String(format: "%d/%ds", self.saveImageCount, self.recordTime)
                            
                            if (self.saveCapture == false) {
                                print("captureTime:\(self.captureTime)")
                                self.imageRecordValueLabel.text = String(format: "%d/%2d", self.saveImageCount, self.captureTime)
                                //self.imageRecordTimeSlider.value = 0// changeValueが呼ばれる？
                                self.imageRecordSwitch.on = false
                            }
                        })
                        //self.imageRecordValueLabel.text = String(format: "%d/%ds", self.saveImageCount, self.recordTime)//すぐ反映されない？
                    }
                } else {
                    print("image save error")
                }
            })
        }
        
        if (self.debugMode && self.saveLog) {
            print("saveLogCount:\(self.saveLogCount)")
            if (self.saveLogCount < self.saveCountMax) {
                // オーバーヘッドで逆に遅くなるかも？
                //dispatch_async(self.signalLogQueue!, { () -> Void in
                    if (data != nil && data.count > 0) {
                        for obj in data {
                            let signalData: SignalW = obj as! SignalW
                            let signalStr: String = signalData.description()
                            self.logger?.addLog(signalStr)
                        }
                    } else {
                        //self.logger?.addLog("no signal")
                    }
                    
                    if (dInfo != nil && dInfo.des != nil) {
                        self.logger?.addLog(dInfo.des)
                    } else {
                        //self.logger?.addLog("no info")
                    }
                //})
                self.saveLogCount++
            } else {
                self.saveLog = false
                self.confManager.confSettings.debugMode.log = false
                self.observer?.smartEyeConfigChanged!(false)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.logRecordSwitch.on = false
                })
            }
        }
    }
    
    func setSensorData(info: AirSensorInfo!, ofType type: AirSensorType) {
        print("self.sensorType:\(self.sensorType) type:\(type)")
        if (self.sensorType != AirSensorTypeNone) {
            if (self.sensorType == AirSensorTypeAccelerationHigh) {
                self.sensorGraphView.addAccelerationData(info.rawInfo.acceleration)
            } else if (self.sensorType == AirSensorTypeGyro) {
                self.sensorGraphView.addGyroData(info.rawInfo.rotation)
            } else if (self.sensorType == AirSensorTypeAttitude) {
                self.sensorGraphView.addAttitudeData(info.rawInfo.rotation)
            }
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func longGestureForDebug(sender: AnyObject) {
        print("longGestureForDebug")
        
        let gesRec: UILongPressGestureRecognizer = sender as! UILongPressGestureRecognizer
        let pos: CGPoint = gesRec.locationInView(self.view)
        print("x:\(pos.x) y:\(pos.y)")
        
        if (gesRec.state == UIGestureRecognizerState.Began) {// 設定秒数間押し続くとBeganになる。Endで処理する場合、手を離さないとdebugmodeが変わらない
            let left: CGFloat = DEBUG_GESTURE_AVAILABLE_AREA_OFFSET
            let top: CGFloat = DEBUG_GESTURE_AVAILABLE_AREA_OFFSET + 44 // NavigationBar:44
            let right: CGFloat = self.view.bounds.size.width - DEBUG_GESTURE_AVAILABLE_AREA_OFFSET
            let bottom: CGFloat = self.view.bounds.size.height - DEBUG_GESTURE_AVAILABLE_AREA_OFFSET - 44.0 // ToolBar:44
            let areaBottom: CGFloat = self.view.bounds.size.height - 44.0
            //let right: CGFloat = self.view.bounds.size.width - 40.0
            //let bottom: CGFloat = self.view.bounds.size.height - 40.0
            print("left:\(left) top:\(top) right:\(right) bottom:\(bottom)")
            
            if (pos.x <= left && pos.y <= top) {// record
                /*
                let alert: UIAlertView = UIAlertView(title: "Long", message: "Long Gesture!", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
                */
                
                //self.debugMode = !self.debugMode
                //self.setupDebugModeView(self.debugMode)
                //self.setDebugMode()
                //self.setupConfig([("DebugMode", self.debugMode)])
                if (self.debugMode) {
                    self.recordMode = !self.recordMode
                    self.setupRecordModeView(self.debugMode, recordMode: self.recordMode)
                    /*if (self.recordMode) {
                        self.observer?.detectEnd!()
                    } else {
                        self.observer?.detectStart!()
                    }*/
                }
                print("DebugMode:\(self.debugMode)")
            } else if (pos.x <= left && pos.y >= bottom && pos.y < areaBottom) {// 左下:camera mode
                if (self.debugMode) {
                    self.cameraMode = !self.cameraMode
                    self.setupCameraModeView(self.debugMode, cameraMode: self.cameraMode)
                }
                print("DebugMode:\(self.debugMode) / CameraMode:\(self.cameraMode)")
            } else if (pos.x >= right && pos.y >= bottom && pos.y < areaBottom) {// 右下:graph mode
                if (self.debugMode) {
                    self.graphMode = !self.graphMode
                    self.setupGraphModeView(self.debugMode, graphMode: self.graphMode)
                }
                print("DebugMode:\(self.debugMode) / GraphMode:\(self.graphMode)")
            } else if (pos.x >= right && pos.y <= top) {// 右上:色空間
                if (self.debugMode) {
                    self.colorMode = !self.colorMode
                    self.setupColorModeView(self.debugMode, colorMode: self.colorMode)
                }
                print("DebugMode:\(self.debugMode) / RecordMode:\(self.colorMode)")
            }
        }
        
        if (self.debugMode) {
            self.observer?.settingState!(self.cameraMode || self.recordMode || self.colorMode || self.graphMode)
        }
    }
    
#if true
    // todo:選択されたimageViewに拡大して表示される??
    @IBAction func panGestureForDebug(sender: AnyObject) {
        if (!self.debugMode) {
            return
        }
        
        let gesRec: UIPanGestureRecognizer = sender as! UIPanGestureRecognizer
        let pos: CGPoint = gesRec.locationInView(self.view)
        
        if (self.dispModeSelect) {
            print("x:\(pos.x) y:\(pos.y)")
            if (gesRec.state == UIGestureRecognizerState.Began) {
                self.observer?.selectRectStart!(pos)
            } else if (gesRec.state == UIGestureRecognizerState.Changed) {
                self.observer?.selectRectChanged!(pos)
            } else if (gesRec.state == UIGestureRecognizerState.Ended) {
                self.observer?.selectRectEnd!()
            } else {// cancelなど
                self.observer?.selectRectEnd!()
            }
        }
    }
#endif
    
    @IBAction func changeZoomPinchGestureForDebug(sender: AnyObject) {
    }
    
    // for UISegmentControl(複数のモードを表示できない)/Bar item of tool bar
    @IBAction func dispModeChanged(sender: AnyObject) {
        let dispModeBarItem = sender as! UIBarButtonItem
        //dispModeBarItem.tintColor = UIColor.blueColor()
        //self.dispMode = dispModeBarItem.tag
        let mode: Int = dispModeBarItem.tag
        var selected: Bool = false
        //var config: (key: String, value: AnyObject) = ("", "")
        
        /*
        self.dispModeBin = false
        self.dispModePoint = false
        self.dispModeRect = false
        self.dispModeArea = false
        self.dispModeSignal = false
        self.dispModeSelect = false // reset
        */
        
        switch (mode) {
        case 1:
            self.dispModeBin = !self.dispModeBin
            selected = self.dispModeBin
            break
        case 2:
            self.dispModePoint = !self.dispModePoint
            selected = self.dispModePoint
            break
        case 3:
            self.dispModeRect = !self.dispModeRect
            selected = self.dispModeRect
            break
        case 4:
            self.dispModeArea = !self.dispModeArea
            selected = self.dispModeArea
            break
        case 5:
            self.dispModeSignal = !self.dispModeSignal
            selected = self.dispModeSignal
            break
        case 6:
            self.dispModeSelect = !self.dispModeSelect
            selected = self.dispModeSelect
            break
        default:
            break
        }
        
        dispModeBarItem.tintColor = selected == true ? UIColor.redColor() : UIColor.blueColor()
        
        setDebugMode()
        self.observer?.smartEyeConfigChanged!(false)
    }
    
    
    // カラーなど状態変更表示
    @IBAction func sliderTouchBegan(sender: AnyObject) {
        self.observer?.settingChangeStart!()
    }
    
    // カラーなど状態変更表示
    @IBAction func sliderColorTouchCancel(sender: AnyObject) {
        // 更新された可能性があるので、保存
        setColor(self.colorType)
        self.observer?.smartEyeConfigChanged!(true)
        self.observer?.settingChangeEnd!()
    }
    
    @IBAction func sliderColorTouchEnded(sender: AnyObject) {
        // todo:plistに保存
        // todo:更新したかどうかのフラグがあったほうが良い
        setColor(self.colorType)
        
        // record
        //self.saveCountMax = Int(self.videoFPS) * self.recordTime
        self.observer?.smartEyeConfigChanged!(true)
        self.observer?.settingChangeEnd!()
    }
    
    @IBAction func sliderCameraTouchCancel(sender: AnyObject) {
        // 更新された可能性があるので、保存
        setCameraSetting()
        self.observer?.settingChangeEnd!()
    }
    
    @IBAction func sliderCameraTouchEnded(sender: AnyObject) {
        // todo:plistに保存
        // todo:更新したかどうかのフラグがあったほうが良い
        setCameraSetting()
        
        // record
        //self.saveCountMax = Int(self.videoFPS) * self.recordTime
        
        self.observer?.settingChangeEnd!()
    }
    
    @IBAction func sliderHueLowChanged(sender: UISlider) {
        self.hue.low = Int(sender.value)
        updateColorValue()
    }
    
    @IBAction func sliderHueHighChanged(sender: UISlider) {
        self.hue.high = Int(sender.value)
        updateColorValue()
    }
    
    @IBAction func sliderSaturationLowChanged(sender: UISlider) {
        self.saturation.low = Int(sender.value)
        updateColorValue()
    }
    
    @IBAction func sliderSaturationHighChanged(sender: UISlider) {
        self.saturation.high = Int(sender.value)
        updateColorValue()
    }
    
    @IBAction func sliderValueLowChanged(sender: UISlider) {
        self.value.low = Int(sender.value)
        updateColorValue()
    }
    
    @IBAction func sliderValueHighChanged(sender: UISlider) {
        self.value.high = Int(sender.value)
        updateColorValue()
    }
    
    @IBAction func colorTypeChanged(sender: UISegmentedControl) {
        // 現在信号色保存
        setColor(self.colorType)
        
        switch (sender.selectedSegmentIndex) {
        case 0:
            self.colorType = 1
        case 1:
            self.colorType = 4
        case 2:
            self.colorType = 5;
        default:
            break
        }
        
        getColor(self.colorType)
        updateColorValue()
        confManager.confSettings.colorSettings.detectColors = Int32(self.colorType)
        
        self.observer?.smartEyeConfigChanged!(true)
        // test
        self.observer?.detectSignalColor!(self.colorType)
    }
    
    
    @IBAction func exposureBiasChanged(sender: AnyObject) {
        print("exposureBiasChanged")
        let slider: UISlider = sender as! UISlider
        
        self.observer!.cameraSettingChanged!(exposureBias: slider.value)
        self.exposureBias = slider.value
        updateCameraSettingValue()
    }
    
    @IBAction func exposureIOSChanged(sender: AnyObject) {
        print("exposureIOSChanged")
        let slider: UISlider = sender as! UISlider
        
        self.observer!.cameraSettingChanged!(exposureISO: slider.value)
        self.exposureISO = slider.value
        updateCameraSettingValue()
    }
    
    @IBAction func exposureDurationChanged(sender: AnyObject) {
        print("exposureDurationChanged")
        let slider: UISlider = sender as! UISlider
        
        self.exposureDuration = self.observer!.cameraSettingChanged!(exposureDuration: slider.value)
        self.exposureValue = slider.value
        updateCameraSettingValue()
    }
    
    @IBAction func fpsValueChanged(sender: AnyObject) {
        print("fpsValueChanged")
        var fps: Float = 30
        if (sender is UISlider) {
            let fpsSender = sender as! UISlider
            fps = fpsSender.value
        } else if (sender is UISegmentedControl) {
            let fpsSender = sender as! UISegmentedControl
            switch (fpsSender.selectedSegmentIndex) {
            case 0:
                fps = 30
            case 1:
                fps = 60
            case 2:
                fps = 120
            case 3:
                fps = 240
            default:
                fps = 30
            }
            
            self.videoFPS = Int(fps)

            updateCameraSettingValue()
            setCameraSetting()
        }
    }
    
    @IBAction func zoomChanged(sender: AnyObject) {
        print("zoomChanged")
        let slider: UISlider = sender as! UISlider
        
        self.observer!.cameraSettingChanged!(zoomFactor: slider.value)
        self.zoomValue = slider.value
        updateCameraSettingValue()
    }
    
    @IBAction func sliderRecordTimeChanged(sender: UISlider) {
        self.recordTime = Int(sender.value)
        self.imageRecordValueLabel.text = String(format: "%ds", self.recordTime)
        self.confManager.confSettings.recordMode.time = Int32(self.recordTime)
    }
    
    // for save capture image switch
    @IBAction func saveCaptureSwitchChanged(sender: AnyObject) {
        let saveSwitch = sender as! UISwitch
        
        self.observer?.detectEnd!()
        // onの場合、imageフォルダを新規作成
        if (saveSwitch.on) {
            FileManager.deleteSubFolder("image")
            FileManager.createSubFolder("image")
            self.saveImageCount = 0
            self.saveCountMax = self.videoFPS * self.recordTime + 1
            self.imageRecordValueLabel.text = String(format: "%ds", self.recordTime)
        }
        
        self.saveCapture = saveSwitch.on
        self.observer?.detectStart!()
    }

    @IBAction func saveLogSwitchChanged(sender: AnyObject) {
        let logSwitch = sender as! UISwitch
        
        self.observer?.detectEnd!()
        self.setLog(logSwitch.on)
        self.observer?.detectStart!()
    }
    
    @IBAction func batchDetectSwitchChanged(sender: AnyObject) {
        let batchSwitch = sender as! UISwitch
        
        self.batchDetect = batchSwitch.on
        
        self.observer?.detectEnd!()
        // ログも出力
        self.setLog(true)
        self.observer?.detectBatch!(self.batchDetect)
        self.observer?.detectStart!()
    }
    
    @IBAction func sensorGraphChanged(sender: AnyObject) {
        let segCtrl = sender as! UISegmentedControl
        var type = AirSensorTypeNone
        
        switch (segCtrl.selectedSegmentIndex) {
        case 0:
            type = AirSensorTypeNone
            break;
        case 1:
            // Hight/Low/Allに分ける?
            type = AirSensorTypeAccelerationHigh
            break;
        case 2:
            type = AirSensorTypeGyro
            break;
        case 3:
            type = AirSensorTypeAttitude
            break;
        default:
            type = AirSensorTypeNone
        }
        
        self.sensorType = type
        self.sensorGraphView.setSensorType(self.sensorType)
        self.observer?.setSensorType!(self.sensorType)
    }
}
