//
//  RecordDetailCollectionViewController.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2015/02/23.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import Foundation
import UIKit

class RecordDetailCollectionViewController : UICollectionViewController, DebugModeObserver {
    @IBOutlet weak var debugBarButton: UIBarButtonItem!
    @IBOutlet weak var actionBarButton: UIBarButtonItem!
    
    var configMan: ConfigManager? = nil
    var debugViewController: DebugModeViewController?
    var debugView: UIView?
    var debugMode: Bool = false
    
    var records: [RecordInfo] = []
    var numOfSections: Int = 3
    var numOfItems: Int = 10
    var selectedSection: Int = 0
    var selectedRow: Int = 0
    
    var selectedPath: NSIndexPath?
    
    var logger:SignalLogger? = SignalLogger.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("RecordDetailCollectionViewController viewDidLoad")
        
        self.configMan = ConfigManager.sharedInstance()
        self.setupDebugMode() // 常にdebugMode?
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        print("viewWillAppear")
        print("numOfSections:\(self.numOfSections) numOfItems:\(self.numOfItems) selectedSection:\(self.selectedSection) selectedRow:\(self.selectedRow)")
    }
    
    private func setupDebugMode() {
        // todo:load .xib? -> @memo:need to load xib for creating instance all of views.
        //self.debugViewController = DebugModeViewController()
        // NG?debugView is nil?!
        //self.debugViewController = DebugModeViewController(nibName: "DebugModeViewController", bundle: nil) as? DebugModeViewController
        self.debugViewController = DebugModeViewController(nibName: "DebugModeViewController", bundle: nil)
        self.debugViewController?.observer = self
        self.debugView = self.debugViewController?.view
        self.debugView?.hidden = true
        // todo:adjust size?
        self.view.addSubview(self.debugView!)
    }
    
    // MARK: - Collection view data source
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    // todo:総数/(枚数/周期)
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.numOfItems;
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("RecordDetailCell", forIndexPath: indexPath) as! RecordDetailCell
        
        /*
        let fileNo = (indexPath.row * self.numOfSections + self.selectedSection) + 1
        let fileName = String(format: "image_%d.png", fileNo)
        let filePath = FileManager.getPathWithFileName(fileName, fromFolder: "/image")
        cell.orgImage = UIImage(contentsOfFile: filePath)
        cell.recordDetailImageView.image = cell.orgImage
        */
        
        let fileNo = (indexPath.row * self.numOfSections + indexPath.section)
        if (fileNo < self.records.count) {
            cell.orgImage = self.records[fileNo].detectImage
            cell.recordDetailImageView.image = cell.orgImage
        }
        
        self.navigationItem.title = String(format: "%d", fileNo)
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // @memo:templateになっているので、メンバーは入っていない(nil)可能性がある。いつtemplateになるかは、内部で判断
        // cell数によるかも。左右いくつ移動した時は、メンバーは入っているみたい
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("RecordDetailCell", forIndexPath: indexPath) as! RecordDetailCell
        
        self.selectedPath = indexPath
        /*
        let fileNo = (self.selectedPath!.row * self.numOfSections + self.selectedSection) + 1
        let fileName = String(format: "image_%d.png", fileNo)
        let filePath = FileManager.getPathWithFileName(fileName, fromFolder: "/image")
        cell.orgImage = UIImage(contentsOfFile: filePath)
        */
        
        let fileNo = (indexPath.row * self.numOfSections + indexPath.section)
        if (fileNo < self.records.count) {
            cell.orgImage = self.records[fileNo].detectImage
            cell.recordDetailImageView.image = cell.orgImage
        }
        
        self.logger?.clearLogs()
        
        let signals: NSMutableArray = NSMutableArray()
        let debugInfo: DebugInfoW! = DebugInfoW()
        // memo: same with buffer size/orientation
        let width = CGImageGetWidth(cell.orgImage!.CGImage)
        let height = CGImageGetHeight(cell.orgImage!.CGImage)
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        //let rect = CGRect(x: 0, y: 0, width: cell.orgImage!.size.width, height: cell.orgImage!.size.height)
        let image: UIImage = SmartEyeW.detectSignal(cell.orgImage, inRect: rect, signals: signals, debugInfo:debugInfo)
        //image.imageOrientation = detailCell.orgImage?.imageOrientation
        cell.detectedImage = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: cell.orgImage!.imageOrientation)
        
        //cell.detectedImage = SmartEyeW.detectSignal(cell.orgImage, inRect: rect, signals: signals, debugInfo: debugInfo)
        cell.recordDetailImageView.image = cell.detectedImage
        
        if (debugInfo != nil && debugInfo.des != nil) {
            self.logger?.addLog(debugInfo.des)
            self.logger?.addPatternLog(debugInfo.pattern)
        }
    }
    
    // MARK: - DebugMode protocol
    
    func settingState(state: Bool) {
        
    }
    
    func settingChangeStart() {
    }
    
    func settingChangeEnd() {
    }
    
    func detectStart() {
    }
    
    func detectEnd() {
    }
    
    func selectRectStart(startPoint: CGPoint) {
    }
    
    func selectRectChanged(nextPoint: CGPoint) {
    }
    
    func selectRectEnd() {
    }
    
    func detectRect(rect: CGRect) {
    }
    
    func deleteDetectRect() {
        
    }
    
    func deleteSelectedRect() {
        
    }
    
    func cameraSettingChanged(exposureBias bias: Float) {
    }
    
    func cameraSettingChanged(exposureISO iso: Float) {
    }
    
    func cameraSettingChanged(exposureDuration ss: Float) -> Float {
        return 0
    }
    
    func cameraSettingChanged(videoFPS fps: Float) {
    }
    
    func smartEyeConfigChanged(reset: Bool) {
        SmartEyeW.setConfig()
        
        // todo:UIImageViewを選択する前に、debug処理をすると、self.selectedPath.sectionが1以上の場合、cellがnil
        // Collectionの現在表示中のcell取得できない?selectedPathではなく、sectionとrowを分ける必要があるかも
        // selectedPathはsection:0で作る
        /*let cell = self.collectionView!.dequeueReusableCellWithReuseIdentifier("RecordDetailCell", forIndexPath: self.selectedPath) as! RecordDetailCell
        
        let fileNo = (self.selectedPath!.row * self.numOfSections + self.selectedSection) + 1
        let fileName = String(format: "image_%d.png", fileNo)
        let filePath = FileManager.getPathWithFileName(fileName, fromFolder: "/image")
        cell.orgImage = UIImage(contentsOfFile: filePath)
        
        var signals: NSMutableArray = NSMutableArray()
        cell.detectedImage = SmartEyeW.detectSignal(cell.orgImage, signals: signals)
        cell.recordDetailImageView.image = cell.detectedImage
        */
        
        self.logger?.clearLogs()
        let cells: [AnyObject] = self.collectionView!.visibleCells()
        print("cells.cout:\(cells.count)")
        for cell in cells {
            let detailCell: RecordDetailCell = cell as! RecordDetailCell
            let signals: NSMutableArray = NSMutableArray()
            let debugInfo: DebugInfoW! = DebugInfoW()
            // memo: same with buffer size/orientation
            let width = CGImageGetWidth(detailCell.orgImage!.CGImage)
            let height = CGImageGetHeight(detailCell.orgImage!.CGImage)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let image: UIImage = SmartEyeW.detectSignal(detailCell.orgImage, inRect: rect, signals: signals, debugInfo:debugInfo)
            //image.imageOrientation = detailCell.orgImage?.imageOrientation
            detailCell.detectedImage = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: detailCell.orgImage!.imageOrientation)
            detailCell.recordDetailImageView.image = detailCell.detectedImage
            
            if (debugInfo != nil && debugInfo.des != nil) {
                self.logger?.addLog(debugInfo.des)
            }
        }
    }
    
    func getVideoActiveFormatInfo() -> CameraFormat {
        return CameraFormat()
    }
    
    func getCameraCurrentSettings() -> CameraSetting {
        return CameraSetting()
    }
    
    func detectSignalColor(color: Int) {
        
    }
    
    // MARK: - IBAction
    
    @IBAction func procAction(sender: AnyObject) {
        // added in iOS8
        let actionSheet = UIAlertController()
        
        let debugButtonAction = UIAlertAction(title: "Debug", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Debug")
            
            self.debugMode = !self.debugMode
            print("debugModeView:\(self.debugMode)")
            // todo:animation
            self.tabBarController?.tabBar.hidden = self.debugMode
            self.debugView?.hidden = !self.debugMode
            // todo:CaptureImageViewはTabbarまでではないので、viewの白い背景が表示される。伸ばそう
            // ->ImageViewをMainViewと同じサイズにした
            if (self.debugMode) {
                self.navigationItem.title = "Debug Mode"
                //self.debugBarButton.title = "Done"
            } else {
                self.navigationItem.title = ""
                //self.debugBarButton.title = "Debug"
            }
        }
        
        let detectButtonAction = UIAlertAction(title: "Detect", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Detect")
            
            SmartEyeW.setConfig()
            
            // todo:UIImageViewを選択する前に、debug処理をすると、self.selectedPath.sectionが1以上の場合、cellがnil
            // Collectionの現在表示中のcell取得できない?selectedPathではなく、sectionとrowを分ける必要があるかも
            // selectedPathはsection:0で作る
            /*let cell = self.collectionView!.dequeueReusableCellWithReuseIdentifier("RecordDetailCell", forIndexPath: self.selectedPath) as! RecordDetailCell
            
            let fileNo = (self.selectedPath!.row * self.numOfSections + self.selectedSection) + 1
            let fileName = String(format: "image_%d.png", fileNo)
            let filePath = FileManager.getPathWithFileName(fileName, fromFolder: "/image")
            cell.orgImage = UIImage(contentsOfFile: filePath)
            
            var signals: NSMutableArray = NSMutableArray()
            cell.detectedImage = SmartEyeW.detectSignal(cell.orgImage, signals: signals)
            cell.recordDetailImageView.image = cell.detectedImage
            */
            
            self.logger?.clearLogs()
            let cells: [AnyObject] = self.collectionView!.visibleCells()
            print("cells.cout:\(cells.count)")
            for cell in cells {
                let detailCell: RecordDetailCell = cell as! RecordDetailCell
                let signals: NSMutableArray = NSMutableArray()
                let debugInfo: DebugInfoW! = DebugInfoW()
                // memo: same with buffer size/orientation
                let width = CGImageGetWidth(detailCell.orgImage!.CGImage)
                let height = CGImageGetHeight(detailCell.orgImage!.CGImage)
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                let image: UIImage = SmartEyeW.detectSignal(detailCell.orgImage, inRect: rect, signals: signals, debugInfo:debugInfo)
                //image.imageOrientation = detailCell.orgImage?.imageOrientation
                detailCell.detectedImage = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: detailCell.orgImage!.imageOrientation)
                detailCell.recordDetailImageView.image = detailCell.detectedImage
                
                if (debugInfo != nil && debugInfo.des != nil) {
                    self.logger?.addLog(debugInfo.des)
                }
            }
        }
        
        let cancelButtonAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            print("Cancel")
        }
        
        actionSheet.addAction(debugButtonAction)
        actionSheet.addAction(detectButtonAction)
        actionSheet.addAction(cancelButtonAction)
        
        self.presentViewController(actionSheet, animated: true) { () -> Void in
            print("Action Sheet")
        }
    }
}
