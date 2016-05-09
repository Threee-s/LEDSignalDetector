//
//  SettingViewController.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2014/10/13.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

import Foundation

class SettingViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var combineThreshold: UITextField!
    @IBOutlet weak var combineOffset: UITextField!
    @IBOutlet weak var integrateProp: UITextField!
    @IBOutlet weak var integrateOffset: UITextField!
    @IBOutlet weak var integrateValidRectMinWidth: UITextField!
    @IBOutlet weak var integrateValidRectMinHeight: UITextField!
    @IBOutlet weak var integrateValidRectMaxWidth: UITextField!
    @IBOutlet weak var integrateValidRectMaxHeight: UITextField!
    @IBOutlet weak var compareDist: UITextField!
    @IBOutlet weak var compareScale: UITextField!
    @IBOutlet weak var signalLightnessDiff: UITextField!
    @IBOutlet weak var signalDiffCount: UITextField!
    @IBOutlet weak var signalInvalidCount: UITextField!
    
    var configMan: ConfigManager? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.configMan = ConfigManager.sharedInstance()
        self.loadSetting()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //self.presentViewController(imagePicker!, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.saveSetting()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func loadSetting() {
        self.combineThreshold.text = String(format: "%d", self.configMan!.confSettings.detectParams.combinePoint.threshold)
        self.combineOffset.text = String(format: "%d", self.configMan!.confSettings.detectParams.combinePoint.offset)
        self.integrateProp.text = String(format: "%d", self.configMan!.confSettings.detectParams.integrateRect.prop)
        self.integrateOffset.text = String(format: "%d", self.configMan!.confSettings.detectParams.integrateRect.offset)
        self.integrateValidRectMinWidth.text = String(format: "%d", self.configMan!.confSettings.detectParams.validRectMin.width)
        self.integrateValidRectMinHeight.text = String(format: "%d", self.configMan!.confSettings.detectParams.validRectMin.height)
        self.integrateValidRectMaxWidth.text = String(format: "%d", self.configMan!.confSettings.detectParams.validRectMax.width)
        self.integrateValidRectMaxHeight.text = String(format: "%d", self.configMan!.confSettings.detectParams.validRectMax.height)
        self.compareDist.text = String(format: "%d", self.configMan!.confSettings.detectParams.compareRect.dist)
        self.compareScale.text = String(format: "%.1f", self.configMan!.confSettings.detectParams.compareRect.scale)
        self.signalLightnessDiff.text = String(format: "%.1f", self.configMan!.confSettings.detectParams.recogonizeSignal.lightnessDiff)
        self.signalDiffCount.text = String(format: "%d", self.configMan!.confSettings.detectParams.recogonizeSignal.compareSignal.diffCount)
        self.signalInvalidCount.text = String(format: "%d", self.configMan!.confSettings.detectParams.recogonizeSignal.compareSignal.invalidCount)
    }
    
    private func saveSetting() {
        //var confDic: NSMutableDictionary = FileManager.loadConfigFromPlist("SmartEyeConfig.plist")
        self.configMan!.confSettings.detectParams.combinePoint.threshold = Int32(Int(self.combineThreshold.text!)!)
        self.configMan!.confSettings.detectParams.combinePoint.offset = Int32(Int(self.combineOffset.text!)!)
        self.configMan!.confSettings.detectParams.integrateRect.prop = Int32(Int(self.integrateProp.text!)!)
        self.configMan!.confSettings.detectParams.integrateRect.offset = Int32(Int(self.integrateOffset.text!)!)
        self.configMan!.confSettings.detectParams.validRectMin.width = Int32(Int(self.integrateValidRectMinWidth.text!)!)
        self.configMan!.confSettings.detectParams.validRectMin.height = Int32(Int(self.integrateValidRectMinHeight.text!)!)
        self.configMan!.confSettings.detectParams.validRectMax.width = Int32(Int(self.integrateValidRectMaxWidth.text!)!)
        self.configMan!.confSettings.detectParams.validRectMax.height = Int32(Int(self.integrateValidRectMaxHeight.text!)!)
        self.configMan!.confSettings.detectParams.compareRect.dist = Int32(Int(self.compareDist.text!)!)
        self.configMan!.confSettings.detectParams.compareRect.scale = NSString(string: self.compareScale.text!).floatValue
        self.configMan!.confSettings.detectParams.recogonizeSignal.lightnessDiff = NSString(string: self.signalLightnessDiff.text!).floatValue
        self.configMan!.confSettings.detectParams.recogonizeSignal.compareSignal.diffCount = Int32(Int(self.signalDiffCount.text!)!)
        self.configMan!.confSettings.detectParams.recogonizeSignal.compareSignal.invalidCount = Int32(Int(self.signalInvalidCount.text!)!)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true;
    }
    
    @IBAction func closeSettingModal(sender: AnyObject) {
        self.saveSetting()
        
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
}