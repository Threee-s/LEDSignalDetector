//
//  ValidDetectionView.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2016/04/14.
//  Copyright © 2016年 TrE. All rights reserved.
//

import UIKit

class ValidDetectionView: UIView {
    
    private var lineWidth: CGFloat = 3.0
    
    private var originLT: CGPoint = CGPointZero
    private var lineLT2R: CGPoint = CGPointZero
    private var lineLT2B: CGPoint = CGPointZero
    
    private var originLB: CGPoint = CGPointZero
    private var lineLB2R: CGPoint = CGPointZero
    private var lineLB2T: CGPoint = CGPointZero
    
    private var originRT: CGPoint = CGPointZero
    private var lineRT2L: CGPoint = CGPointZero
    private var lineRT2B: CGPoint = CGPointZero
    
    private var originRB: CGPoint = CGPointZero
    private var lineRB2L: CGPoint = CGPointZero
    private var lineRB2T: CGPoint = CGPointZero
    
    private var lineLength: CGFloat = 0
    private var lineColor: UIColor = UIColor.whiteColor()
    
    override init(frame: CGRect) {
        //print("init")
        super.init(frame: frame)
        
        self.updatePath(frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        //print("draw")
        // viewの設定.
        /*self.layer.borderColor = UIColor.brownColor().CGColor
        self.layer.borderWidth = 0.5
        self.layer.cornerRadius = 10.0
        self.layer.masksToBounds = true*/
        
        let linePath: UIBezierPath = UIBezierPath()
        linePath.moveToPoint(self.originLT)
        linePath.addLineToPoint(self.lineLT2R)
        linePath.moveToPoint(self.originLT)
        linePath.addLineToPoint(self.lineLT2B)
        
        linePath.moveToPoint(self.originLB)
        linePath.addLineToPoint(self.lineLB2R)
        linePath.moveToPoint(self.originLB)
        linePath.addLineToPoint(self.lineLB2T)
        
        linePath.moveToPoint(self.originRT)
        linePath.addLineToPoint(self.lineRT2L)
        linePath.moveToPoint(self.originRT)
        linePath.addLineToPoint(self.lineRT2B)
        
        linePath.moveToPoint(self.originRB)
        linePath.addLineToPoint(self.lineRB2L)
        linePath.moveToPoint(self.originRB)
        linePath.addLineToPoint(self.lineRB2T)
        
        linePath.lineWidth = self.lineWidth
        
        // 線の色を赤色に設定.
        self.lineColor.setStroke()
        
        // 描画.
        linePath.stroke()
    }
 
    private func updatePath(rect: CGRect) {
        //print("updatePath")
        self.lineLength = (rect.size.width - self.lineWidth * 2) / 3
        self.originLT = CGPoint(x: 0, y: 0)
        self.lineLT2R = CGPoint(x: self.lineLength, y: 0)
        self.lineLT2B = CGPoint(x: 0, y: self.lineLength)
        
        self.originLB = CGPoint(x: 0, y: rect.size.height)
        self.lineLB2R = CGPoint(x: self.lineLength, y: rect.size.height)
        self.lineLB2T = CGPoint(x: 0, y: rect.size.height - self.lineLength)
        
        self.originRT = CGPoint(x: rect.size.width, y: 0)
        self.lineRT2L = CGPoint(x: rect.size.width - self.lineLength, y: 0)
        self.lineRT2B = CGPoint(x: rect.size.width, y: self.lineLength)
        
        self.originRB = CGPoint(x: rect.size.width, y: rect.size.height)
        self.lineRB2L = CGPoint(x: rect.size.width - self.lineLength, y: rect.size.height)
        self.lineRB2T = CGPoint(x: rect.size.width, y: rect.size.height - self.lineLength)
    }

    func changeFrame(rect: CGRect) {
        self.frame = rect;
        self.updatePath(rect)
        self.setNeedsDisplay()
    }
    
    func changeLineColor(color: UIColor, lineWidth: CGFloat = 3.0) {
        self.lineColor = color
        self.lineWidth = lineWidth
        self.setNeedsDisplay()
    }
    
    func changeLineWidth(lineWidth: CGFloat) {
        self.lineWidth = lineWidth
    }
}
