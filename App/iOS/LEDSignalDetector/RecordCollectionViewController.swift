//
//  RecordCollectionViewController.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2015/02/15.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import Foundation
import UIKit
import Photos

enum DispMode: Int {
    case List
    case Same
    case Diff
}

enum ImageDatabase: Int {
    case Folder
    case Photos
    case SQLite
}

/* @memo  UICollectionViewDelegateFlowLayoutはcontrollerで適用(layoutの動作を委譲)。
必要であれば、UICollectionViewFlowLayoutのサブクラスを作ってカスタマイズ(storyboardのlayoutにサブクラスを設定)*/
class RecordCollectionViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UploadObserver, QBImagePickerControllerDelegate {
    @IBOutlet weak var progressView: UIProgressView?
    @IBOutlet weak var organizeBarItem: UIBarButtonItem?
    @IBOutlet weak var actionBarItem: UIBarButtonItem?
    //@IBOutlet weak var signalInfoLabel: UILabel?
    
    var photoAssets = [PHAsset]()
    //var images = [UIImage]()
    var records: [RecordInfo] = []
    var imgDb: ImageDatabase = .Folder
    var dispMode: DispMode = .List
    var configMan: ConfigManager? = nil
    var ledFrequency: Int = 10 // 100hz / 30fps
    var fps: Int = 30//30
    var time: Int = 1
    var numOfSections: Int = 1//3 // 100hz / 30fps -> 3periods
    var numOfItems: Int = 0//10 // 100hz / 30fps / 1s -> 10frames
    
    var maxNumOfItems: Int = 4
    
    var logger:SignalLogger? = SignalLogger.sharedInstance
    
    override func viewDidLoad() {// memo:初回画面(instance作成)表示時１回のみ呼ばれる
        super.viewDidLoad()
        print("RecordCollectionViewController viewDidLoad")
        
        self.configMan = ConfigManager.sharedInstance()
        self.progressView?.progressViewStyle = UIProgressViewStyle.Bar
        
        // test
        /*
        let imagePath = NSBundle.mainBundle().pathForResource(String(format: "red2"), ofType:"jpg")
        let image = UIImage(contentsOfFile: imagePath!)
        if (image != nil) {
            var record: RecordInfo = RecordInfo()
            record.detectImage = image
            self.records.append(record)
        }
        
        */
        
        numOfItems = self.records.count
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        print("viewWillAppear")
        
        self.ledFrequency = Int(self.configMan!.confSettings.signalInfo.ledFreq)
        
        self.fps = Int(self.configMan!.confSettings.cameraSettings.fps)
        print("fps:\(self.fps)")
        
        self.time = Int(self.configMan!.confSettings.recordMode.time)
        print("time:\(self.time)")
        
        // todo:imageが変わったときロードした方が良いかも
        //self.updateDispView()
        //self.loadImages(self.imgDb)
        print("records.count:\(self.records.count)")
    }
    
    // MARK: - Collection view data source
    
    // 枚数/周期
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.numOfSections;
    }
    
    // todo:総数/(枚数/周期)
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("numOfItems:\(self.numOfItems)")
        return self.numOfItems;
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("cellForItemAtIndexPath:\(indexPath.row)")
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("RecordCell", forIndexPath: indexPath) as! RecordCell
        
        let fileNo = (indexPath.row * self.numOfSections + indexPath.section)
        if (fileNo < self.records.count) {
            cell.recordImageView.image = self.records[fileNo].detectImage
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var nums: Int = self.numOfItems
        if (self.numOfItems > self.maxNumOfItems) {
            nums = self.maxNumOfItems
        }
        let width: CGFloat = (CGRectGetWidth(self.view.frame) - CGFloat(2.0) * CGFloat(nums - 1)) / CGFloat(nums)
        
        // memo:cellのサイズ。中のimageはautolayoutで変更(設定しないとdefaultのcellサイズ。ハマった。。。)
        return CGSizeMake(width, width)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        // set index
        // didSelectよりprepareForSegueの方が先に実行される？ので、ここでもindex取得
        if segue.identifier == "RecordImageDetail" {
            let cell = sender as! RecordCell // cell選択時のsequeなので
            let indexPath = self.collectionView?.indexPathForCell(cell)
            //let row = indexPath?.row
            //println("prepareForSegue:[selectedIndex:\(row)]")
            // push sequeなので、ここで移動先の設定を行う(IBActionいらないので)
            let recordDetailViewController = segue.destinationViewController as! RecordDetailCollectionViewController
            
            recordDetailViewController.records = self.records
            recordDetailViewController.numOfSections = self.numOfSections
            recordDetailViewController.numOfItems = self.numOfItems
            recordDetailViewController.selectedPath = indexPath
            //recordDetailViewController.selectedPath?.section = 0// 1 section //error!
            if let section = indexPath?.section {
                recordDetailViewController.selectedSection = section
                print("section:\(section)")
            }
            if let row = indexPath?.row {
                recordDetailViewController.selectedRow = row
                print("row:\(row)")
            }
        }
    }
    
    /*
    private func updateDispView() {
        if (self.time <= 0) {
            self.organizeBarItem?.title = "Load"
            //self.dispModeButton?.titleLabel?.text = "List"
            self.dispMode = .List
            self.imgDb = .Photos
            self.changeDispData(.List)
        } else {
            self.organizeBarItem?.title = "Save"
            self.loadImages(self.imgDb)
            self.changeDispData(self.dispMode)
        }
        
        self.collectionView?.reloadData()
    }*/
    
    private func loadImages(db: ImageDatabase) {
        print("imgDb:\(db)")
        
        if (db == .Folder) {
            self.getImagesFromFolder()
            self.changeDispData(self.dispMode)
            self.collectionView?.reloadData()// todo:ここで良い?
        } else if (db == .Photos) {
            //self.getImagesFromPhotos()
            //self.changeDispData(.List)
            //self.getImagesFromImagePicker()// no lib :OK
            self.getImagesFromQBImagePicker()// callbackで更新
        }
        
        //self.changeDispData(self.dispMode)
        //self.collectionView?.reloadData()// todo:ここで良い?
    }
    
    private func getImagesFromQBImagePicker() {
        if (!QBImagePickerController.isAccessibilityElement()) {
            // alert
            print("Not accessible")
        }
        
        let imagePickerController = QBImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsMultipleSelection = true
        imagePickerController.minimumNumberOfSelection = 1
        imagePickerController.maximumNumberOfSelection = 240 // TBD
        imagePickerController.showsNumberOfSelectedAssets = true
        imagePickerController.numberOfColumnsInPortrait = 4
        imagePickerController.numberOfColumnsInLandscape = 7
        //var subtypes: [AnyObject] = []
        
        //imagePickerController.assetCollectionSubtypes = subtypes
        
        self.presentViewController(imagePickerController, animated: true, completion: { () -> Void in
            print("presentViewController")
        })
    }
    
    private func getImagesFromFolder() {
        self.records.removeAll(keepCapacity: false)
        
        let localPath = FileManager.getSubDirectoryPath("/image")
        let fileCount: Int = Int(FileManager.getFileCountInFolder(localPath))
        for (var i = 1; i <= fileCount; i++) {
            let fileName = String(format: "image_%d.png", i)
            let filePath = FileManager.getPathWithFileName(fileName, fromFolder: "/image")
            let image = UIImage(contentsOfFile: filePath)
            if (image != nil) {
                let record: RecordInfo = RecordInfo()
                record.detectImage = image
                self.records.append(record)
            }
        }
    }
    
    private func getImagesFromPhotos() {
        self.photoAssets = []
        
        let assets: PHFetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: nil)
        assets.enumerateObjectsUsingBlock { (asset, index, stop) -> Void in
            self.photoAssets.append(asset as! PHAsset)
        }
        
        for asset: PHAsset in self.photoAssets {
            let manager: PHImageManager = PHImageManager()
            manager.requestImageForAsset(asset, targetSize: CGSizeZero, contentMode: PHImageContentMode.AspectFill, options: nil) { (image, info) -> Void in
                let record: RecordInfo = RecordInfo()
                record.detectImage = image
                self.records.append(record)
            }
        }
    }
    
    private func getImagesFromImagePicker() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let imagePicker: UIImagePickerController? = UIImagePickerController()
            imagePicker!.delegate = self
            imagePicker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker!.allowsEditing = false
            //imagePicker!.videoQuality = UIImagePickerControllerQualityType.TypeMedium//default
            // 動画撮影用の設定
            //imagePicker!.mediaTypes = NSArray(object: "public.movie")
            //imagePicker!.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.Video
            // カメラ画面上に独自UI設定
            //imagePicker!.cameraOverlayView =
            self.presentViewController(imagePicker!, animated: true, completion: nil)
        }
    }
    
    private func changeDispData(mode: DispMode) {
        if (self.dispMode == .List) {
            self.numOfSections = 1
            //self.numOfItems = self.fps * self.time
            self.numOfItems = self.records.count
        } else if (self.dispMode == .Same) {
            let detectFreq = SEUtil.gcd(self.ledFrequency, y: self.fps)
            self.numOfSections = self.fps / detectFreq
            print("numOfSections:\(self.numOfSections)")
            
            self.numOfItems = detectFreq * self.time
            print("numOfItems:\(self.numOfItems)")
        } else if (self.dispMode == .Diff) {
            let detectFreq = SEUtil.gcd(self.ledFrequency, y: self.fps)
            self.numOfSections = detectFreq * self.time
            print("numOfSections:\(self.numOfSections)")
            
            self.numOfItems = self.fps / detectFreq
            print("numOfItems:\(self.numOfItems)")
        }
    }
    
    private func updateProgress(progress: Float, info: String) {
        dispatch_sync(dispatch_get_main_queue(), { () -> Void in
            self.progressView?.progress = progress
        })
    }
    
    // MARK: QBImagePickerControllerDelegate
    
    func qb_imagePickerController(imagePickerController: QBImagePickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        print("didFinishPickingAssets")
        print("count of assets : \(assets.count)")
        
        self.records.removeAll(keepCapacity: false)
        
        let requestOption: PHImageRequestOptions = PHImageRequestOptions()
        // memo:同期
        requestOption.synchronous = true
        for var i = 0; i < assets.count; i++ {
            let asset: PHAsset = assets[i] as! PHAsset
            if (asset.mediaType == PHAssetMediaType.Image) {
                print("request image start")
                PHImageManager.defaultManager().requestImageDataForAsset(asset, options: requestOption, resultHandler: { (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) -> Void in
                    print("orientation:\(orientation.rawValue)")
                    let image: UIImage? = UIImage(data: imageData!)
                    if (image != nil) {
                        let record: RecordInfo = RecordInfo()
                        record.detectImage = image
                        self.records.append(record)
                    }
                })
                print("request image end")
            }
        }
        
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            print("dismissImagePickerController")
            self.changeDispData(self.dispMode)
            self.collectionView?.reloadData()// todo:ここで良い?
        })
    }
    
    func qb_imagePickerControllerDidCancel(imagePickerController: QBImagePickerController!) {
        print("qb_imagePickerControllerDidCancel")
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            print("dismissViewController")
        })
    }
    
    func qb_imagePickerController(imagePickerController: QBImagePickerController!, shouldSelectAsset asset: PHAsset!) -> Bool {
        print("shouldSelectAsset")
        return true
    }
    
    func qb_imagePickerController(imagePickerController: QBImagePickerController!, didSelectAsset asset: PHAsset!) {
        print("didSelectAsset")
    }
    
    func qb_imagePickerController(imagePickerController: QBImagePickerController!, didDeselectAsset asset: PHAsset!) {
        print("didDeselectAsset")
    }
    
    // MARK: - UIImagePickerControllerDelegate
    // ビデオ撮影終了後[use]を選択した時呼ばれる。リアルタイム検出できないな
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("imagePickerController")
        
        if (info.indexForKey(UIImagePickerControllerOriginalImage) != nil) {
            let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            let record: RecordInfo = RecordInfo()
            record.detectImage = image
            self.records.append(record)
            // willApearが呼ばれるので、不要
            //self.changeDispData(.List)
            //self.collectionView?.reloadData()
        } else {
            let pickedURL:NSURL = info[UIImagePickerControllerReferenceURL] as! NSURL
            let fetchResult: PHFetchResult = PHAsset.fetchAssetsWithALAssetURLs([pickedURL], options: nil)
            let asset: PHAsset = fetchResult.firstObject as! PHAsset
            PHImageManager.defaultManager().requestImageDataForAsset(asset, options: nil, resultHandler: { (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) -> Void in
                let image: UIImage! = UIImage(data: imageData!)
                
                let record: RecordInfo = RecordInfo()
                record.detectImage = image
                self.records.append(record)
                //self.changeDispData(.List)
                //self.collectionView?.reloadData()
            })
        }
        
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    
    // MARK: - IBAction
    
    @IBAction func organizeAction(sender: AnyObject) {
        // added in iOS8
        let actionSheet = UIAlertController()
        
        let photosButtonAction = UIAlertAction(title: "Photos", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Photos")
            
            self.imgDb = .Photos
            self.loadImages(self.imgDb)
        }
        
        let localButtonAction = UIAlertAction(title: "Local", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Local")
            
            self.imgDb = .Folder
            self.loadImages(self.imgDb)
        }
        
        let cancelButtonAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            print("Cancel")
        }
        
        actionSheet.addAction(photosButtonAction)
        actionSheet.addAction(localButtonAction)
        actionSheet.addAction(cancelButtonAction)
        
        self.presentViewController(actionSheet, animated: true) { () -> Void in
            print("Action Sheet")
        }
    }
    
    @IBAction func procAction(sender: AnyObject) {
        // added in iOS8
        let actionSheet = UIAlertController()
        
        let detectButtonAction = UIAlertAction(title: "Detect", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Detect")
            
            self.logger?.clearLogs()
            SmartEyeW.setConfig()
            var imageCount = 0
            
            for obj in self.records {
                imageCount++
                let recordInfo = obj as RecordInfo
                let info = CaptureImageInfo()
                info.image = recordInfo.detectImage
                let selectedImage = recordInfo.detectImage
                let signals: NSMutableArray = NSMutableArray()
                
                let debugInfo: DebugInfoW! = DebugInfoW()
                let width = CGImageGetWidth(selectedImage!.CGImage)
                let height = CGImageGetHeight(selectedImage!.CGImage)
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                //let rect = CGRect(x: 0, y: 0, width: selectedImage!.size.width, height: selectedImage!.size.height)
                SmartEyeW.detectSignal(selectedImage, inRect: rect, signals: signals, debugInfo: debugInfo)
                //self.debugViewController?.updateDetectedImageData(detectedImage: detectedImage, data: signals as [AnyObject], captureImageInfo: info, debugInfo: debugInfo, selectedImage: selectedImage!)
                
                if (imageCount == 30) {
                    if (signals.count > 0) {
                        for obj in signals {
                            let signalData: SignalW = obj as! SignalW
                            if (signalData.color == 1) {
                                self.navigationItem.title = "Green"
                                //self.signalInfoLabel?.text = "Green"
                                print("Green")
                            } else if (signalData.color == 4) {
                                self.navigationItem.title = "Red"
                                //self.signalInfoLabel?.text = "Red"
                                print("Red")
                            } else {
                                self.navigationItem.title = "No Signal"
                                //self.signalInfoLabel?.text = "No Signal"
                                print("No Signal")
                            }
                        }
                    } else {
                        self.navigationItem.title = "No Signal"
                        //self.signalInfoLabel?.text = "No Signal"
                        print("No Signal")
                    }
                }
                if (debugInfo != nil && debugInfo.des != nil) {
                    self.logger?.addLog(debugInfo.des)
                }
            }
        }
        
        let detectFirstNullButtonAction = UIAlertAction(title: "Detect(Null)", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Detect")
            
            self.logger?.clearLogs()
            SmartEyeW.setConfig()
            var imageCount = 0
            
            for obj in self.records {
                imageCount++
                print("imageCount:\(imageCount)")
                let recordInfo = obj as RecordInfo
                let info = CaptureImageInfo()
                info.image = recordInfo.detectImage
                let selectedImage = recordInfo.detectImage
                let signals: NSMutableArray = NSMutableArray()
                
                let debugInfo: DebugInfoW! = DebugInfoW()
                let width = CGImageGetWidth(selectedImage!.CGImage)
                let height = CGImageGetHeight(selectedImage!.CGImage)
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                //let rect = CGRect(x: 0, y: 0, width: selectedImage!.size.width, height: selectedImage!.size.height)
                SmartEyeW.detectSignal(selectedImage, inRect: rect, signals: signals, debugInfo: debugInfo)
                //self.debugViewController?.updateDetectedImageData(detectedImage: detectedImage, data: signals as [AnyObject], captureImageInfo: info, debugInfo: debugInfo, selectedImage: selectedImage!)
                
                //print("imageCount:\(imageCount)")
                if (imageCount == 31) {
                    if (signals.count > 0) {
                        for obj in signals {
                            let signalData: SignalW = obj as! SignalW
                            if (signalData.color == 1) {
                                self.navigationItem.title = "Green"
                                //self.signalInfoLabel?.text = "Green"
                                print("Green")
                            } else if (signalData.color == 4) {
                                self.navigationItem.title = "Red"
                                //self.signalInfoLabel?.text = "Red"
                                print("Red")
                            } else {
                                self.navigationItem.title = "No Signal"
                                //self.signalInfoLabel?.text = "No Signal"
                                print("No Signal")
                            }
                        }
                    } else {
                        self.navigationItem.title = "No Signal"
                        //self.signalInfoLabel?.text = "No Signal"
                        print("No Signal")
                    }
                }
                if (debugInfo != nil && debugInfo.des != nil) {
                    self.logger?.addLog(debugInfo.des)
                }
            }
        }
        
        let dropboxButtonAction = UIAlertAction(title: "Dropbox", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Dropbox")
            
            let localPath = FileManager.getSubDirectoryPath("/image")
            let now = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US") // ロケールの設定
            dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss" // 日付フォーマットの設定
            let remotePath = "/SmartEye/data/" + dateFormatter.stringFromDate(now) + "/"
            Uploader.getInstance().observer = self;
            Uploader.getInstance().save(localPath, toDropBox: remotePath, returnViewController: self)
        }
        
        /*
        var dispMode: String = ""
        if (self.dispMode == .List) {
            self.dispMode = .Same
            dispMode = "Same"
        } else if (self.dispMode == .Same) {
            self.dispMode = .Diff
            dispMode = "Diff"
        } else {
            self.dispMode = .List
            dispMode = "List"
        }
        
        let dispModeButtonAction = UIAlertAction(title: dispMode, style: UIAlertActionStyle.Default) { (action) -> Void in
            print(dispMode)
            
            self.changeDispData(self.dispMode)
            self.collectionView?.reloadData()
        }*/
        
        let deleteButtonAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Delete")
            
            FileManager.deleteSubFolder("/image")
            self.imgDb = .Folder
            self.loadImages(self.imgDb)
        }
        
        let cancelButtonAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            print("Cancel")
        }
        
        actionSheet.addAction(detectButtonAction)
        actionSheet.addAction(detectFirstNullButtonAction)
        actionSheet.addAction(dropboxButtonAction)
        actionSheet.addAction(deleteButtonAction)
        actionSheet.addAction(cancelButtonAction)
        
        self.presentViewController(actionSheet, animated: true) { () -> Void in
            print("Action Sheet")
        }
    }
    
    @IBAction func selecteImageTapGesture(sender: AnyObject) {
        print("selecteImageTapGesture")
        
        let gesRec: UITapGestureRecognizer = sender as! UITapGestureRecognizer
        
        if (gesRec.state == UIGestureRecognizerState.Ended) {
            // todo:Pageスクロールにする。アニメーション
        }
    }
    
    func uploadFile(file: String!, currentProgress progress: Float) {
        self.updateProgress(progress, info: file)
    }
}