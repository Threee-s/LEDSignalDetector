//
//  ConfigSetting.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2016/04/14.
//  Copyright © 2016年 TrE. All rights reserved.
//

import Foundation


// Cloudから最新configを取得
// ConfigManagerに設定、.plistに保存
// 管理者用:
//    設定一覧を表示/編集(SettingViewControllerと連携)
//    config設定値をCloudへ送信
// .plist <-> ConfigManager <-> ConfigSetting(<->SettingViewController) <-> LEDMqttClinet <-> Cloud
class ConfigSetting {
    
}