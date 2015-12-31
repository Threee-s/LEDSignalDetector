//
//  Util.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2015/02/22.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import Foundation


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
    
}