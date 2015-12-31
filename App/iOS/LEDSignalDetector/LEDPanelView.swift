//
//  LEDPanelView.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2014/11/02.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

import Foundation
import UIKit

struct DotColor {
    var c1: CGFloat = 0
    var c2: CGFloat = 0
    var c3: CGFloat = 0
    var c4: CGFloat = 0
}

struct LEDDot {
    var x: CGFloat
    var y: CGFloat
    // var diameter: Float
    var width: CGFloat
    var height: CGFloat
    var color: DotColor
    var enable: Bool
    var scale: CGFloat = 1.0
}

class LEDPanelView : UIView {
    
    // storyboardで設定済なので、取りあえず不要
    //var panelWidth = 0
    //var panelHeight = 0
    //var pixels = 1
    var diameter: Float = 1.0
    var interval: Float = 1.5
    var countWidh: Int = 0
    var countHeight: Int = 0
    var dotPanel: Array<LEDDot> = []
    /*
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override init() {
        super.init()
    }
    
    init(panelWiddth w : Int, panelHeight h : Int) {
        self.panelWidth = w
        self.panelHeight = h
        
        super.init()
    }
    
    init(diameter r : Float, Interval i : Float) {
        super.init()
    
        self.diameter = r
        self.interval = i
    
        self.initDotPanel()
    }
    
    */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initDotPanel()
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        for dot in dotPanel {
            if (dot.enable == true) {
                //CGContextSetFillColorWithColor(context, UIColor(red: dot.dot1, green: dot.dot2, blue: dot.dot3, alpha: dot.dot4).CGColor)
                CGContextSetRGBFillColor(context, dot.color.c1, dot.color.c2, dot.color.c3, dot.color.c4)
                CGContextSetRGBStrokeColor(context, dot.color.c1, dot.color.c2, dot.color.c3, dot.color.c4)
                CGContextFillEllipseInRect(context, CGRectMake(dot.x, dot.y, dot.width, dot.height))
                CGContextFillPath(context)
            }
        }
    }
    
    private func initDotPanel() {
        let w = self.frame.width
        let h = self.frame.height
        countWidh = Int(w / (CGFloat((self.diameter) + self.interval)))
        countHeight = Int(h / (CGFloat((self.diameter) + self.interval)))
        let validW = (self.diameter + self.interval) * Float(self.countWidh) - self.interval//最後のself.interval不要(countwが0になることはないはず)
        let validH = (self.diameter + self.interval) * Float(self.countHeight) - self.interval
        let offsetX = (self.frame.width - CGFloat(validW)) / CGFloat(2)
        let offsetY = (self.frame.height - CGFloat(validH)) / CGFloat(2)
        
        /*
        println("self.frame.origin.x:\(self.frame.origin.x) self.frame.origin.y:\(self.frame.origin.y)")
        println("w:\(w) h:\(h)")
        println("countWidh:\(self.countWidh) countHeight:\(self.countHeight)")
        println("validW:\(validW) validH:\(validH)")
        println("offsetX:\(offsetX) offsetY:\(offsetY)")
        */
        
        for j in 0...self.countHeight - 1 {
            let y = offsetY + CGFloat(j) * CGFloat(self.diameter + self.interval)
            for i in 0...self.countWidh {
                let x = offsetX + CGFloat(i) * CGFloat(self.diameter + self.interval)
                let dotColor = DotColor(c1: 1, c2: 0, c3: 0, c4: 1)//test
                let dot = LEDDot(x: x, y: y, width: CGFloat(self.diameter), height: CGFloat(self.diameter), color: dotColor, enable: false, scale: 1)
                dotPanel.append(dot)
            }
        }
    }
    
    func setAllDotColor(c1: CGFloat, c2: CGFloat, c3: CGFloat, c4: CGFloat) {
        let size = self.countWidh * self.countHeight
        for i in 0...size - 1 {
            dotPanel[i].color = DotColor(c1: c1, c2: c2, c3: c3, c4: c4)
        }
    }
    
    func setAllEnableDotColor(c1: CGFloat, c2: CGFloat, c3: CGFloat, c4: CGFloat) {
        let size = self.countWidh * self.countHeight
        for i in 0...size - 1 {
            var dot = dotPanel[i]
            if (dot.enable == true) {
                dot.color = DotColor(c1: c1, c2: c2, c3: c3, c4: c4)
            }
        }
    }
    
    func setDotColorAtIndex(index: Int, c1: CGFloat, c2: CGFloat, c3: CGFloat, c4: CGFloat) {
        let size = self.countWidh * self.countHeight
        if (index >= 0 && index < size) {
            dotPanel[index].color = DotColor(c1: c1, c2: c2, c3: c3, c4: c4)
        }
    }
}