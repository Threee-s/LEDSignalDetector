//
//  LEDPedestrianSignalView.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2014/11/02.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

import Foundation

struct SignalArea {
    var i: Int
    var j: Int
    var row: Int
    var column: Int
}

class LEDPedestrianSignalView : LEDPanelView {
    // 信号位置をdot配列の位置(index)で管理
    var blue: SignalArea
    var red: SignalArea
    var signalInterval: Int = 10
    // LEDPanelの範囲を超えないように、パネルサイズ調整。
    let redSignal: [[Int]] =
    [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1 ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1, 1, 1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1 ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1 ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0,  2,1, 1, 1 ,1, 1, 1, 1, 1, 1,2  ,0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0,   2,2,1, 1, 1 ,1, 1, 1, 1, 1, 1,2,2  , 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0,    2,2,2,1, 1, 1 ,1, 1, 1, 1, 1, 1,2,2,2   , 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0,     2,2,2,2,1, 1, 1 ,1, 1, 1, 1, 1, 1,2,2,2,2    , 0, 0, 0, 0, 0],
        [0, 0, 0, 0,       2,2,2,0,0,0,1, 1 ,1, 1, 1, 1, 1,0,0,0,2,2,2      , 0, 0, 0, 0],
        [0, 0, 0,        2,2,2,0,0,0,0,1, 1 ,1, 1, 1, 1, 1,0,0,0,0,2,2,2       , 0, 0, 0],
        [0, 0,         2,2,2,0,0,0,0,0,1, 1 ,1, 1, 1, 1, 1,0,0,0,0,0,2,2,2        , 0, 0],
        [0,          2,2,2,0,0,0,0,0,0,1, 1 ,1, 1, 1, 1, 1,0,0,0,0,0,0,2,2,2         , 0],
        [0,          2,2,2,0,0,0,0,0,0,1, 1 ,1, 1, 1, 1, 1,0,0,0,0,0,0,2,2,2         , 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1, 1, 1, 1, 1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1, 1, 0, 1, 1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1, 1, 0, 1, 1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1,1,  0,  1,1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1,1,  0,  1,1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1,1,  0,  1,1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1,2,  0,  2,1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1,2,  0,  2,1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1,3,  0,  3,1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  2,1,3,  0,  3,1,2  ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0,  1, 2,1,3,  0,  3,1,2, 1  ,0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]// 27 x 27
    
    required init?(coder aDecoder: NSCoder) {
        // super.init前に初期化が必要
        self.blue = SignalArea(i: 0, j: 0, row: 0, column: 0)
        self.red = SignalArea(i: 0, j: 0, row: 0, column: 0)
        
        super.init(coder: aDecoder)
        
        // 信号エリアの縦開始位置
        let offsetRow = Int((super.countHeight - super.countWidh * 2 - self.signalInterval) / 2)
        
        // 横は0から
        self.blue.i = 0
        self.blue.j = offsetRow
        self.blue.column = super.countWidh
        self.blue.row = super.countWidh
        
        for j in 0...self.blue.row - 1 {
            let dotIndexY = (self.blue.j + j) * self.blue.column
            for i in 0...self.blue.column - 1 {
                let dotIndex = dotIndexY + (self.blue.i + i)
                super.dotPanel[dotIndex].color = DotColor(c1: 0, c2: 0, c3: 1, c4: 1)
                super.dotPanel[dotIndex].enable = true
                //println("dotIndex:\(dotIndex)")
            }
        }
        
        
        self.red.i = 0
        self.red.j = offsetRow + super.countWidh + self.signalInterval
        self.red.column = super.countWidh
        self.red.row = super.countWidh
        
        for j in 0...self.red.row - 1 {
            let dotIndexY = (self.red.j + j) * self.red.column
            for i in 0...self.red.column - 1 {
                let dotIndex = dotIndexY + (self.red.i + i)
                super.dotPanel[dotIndex].color = DotColor(c1: 1, c2: 0, c3: 0, c4: 1)
                super.dotPanel[dotIndex].enable = true
                //println("dotIndex:\(dotIndex)")
            }
        }
        
        
#if false
        let signalRedRow = self.redSignal.count
        let signalRedColumn = self.redSignal[0].count
        // 赤信号配列をLEDPanelの真ん中に調整
        let offsetSignalRedX = Int((self.red.column - signalRedColumn) / 2)
        let offsetSignalRedY = Int((self.red.row - signalRedRow) / 2)
        
        // 赤信号配列の要素位置をLEDPanelの位置に変換
        for y in 0...signalRedRow - 1 {
            for x in 0...signalRedColumn - 1 {
                let signalDot = self.redSignal[y][x]
                if (signalDot > 0) {
                    let dotX = self.red.i + offsetSignalRedX + x
                    let dotY = self.red.j + offsetSignalRedY + y
                    let dotIndex = dotX * dotY
                    super.dotPanel[dotIndex].enable = true
                    println("dotIndex:\(dotIndex)[dotX:\(dotX) dotY\(dotY)]")
                }
            }
        }
#endif
        
    }
}