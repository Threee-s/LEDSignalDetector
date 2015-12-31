//
//  ConfigManager.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2015/02/11.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import Foundation

// todo:.plist上の設定値は基本Stringとして処理している。数値は数値タイプにしたほうが良い？パフォーマンス？
class SEConfigManager {
    var confFile: String?
    //var conf: Dictionary<String, AnyObject> = [:]
    var confDic: NSMutableDictionary = NSMutableDictionary()
    
    class var sharedInstance: SEConfigManager {
        struct Wrapper {// @memo:Can't define static var in class
            static let instance: SEConfigManager = SEConfigManager()
        }
        
        return Wrapper.instance
    }
    
    convenience init() {
        self.init(confFile: "SmartEyeConfig.plist")
    }
    
    init(confFile: String) {
        confDic = FileManager.loadConfigFromPlist(confFile)
        self.confFile = confFile
    }
    
    func saveConf() {
        FileManager.saveToPlist(self.confFile, withDictionary: confDic as [NSObject : AnyObject])
    }
}