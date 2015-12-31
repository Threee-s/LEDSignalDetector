//
//  CameraSettingViewController.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/27.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import UIKit

// CameraCaptureと直接やり取りする。configに保存した方が良い？(CaptureViewController経由でCamera設定を更新)
class CameraSettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var formatTable: UITableView?
    
    var cameraCap: CameraCapture? = nil
    var configMan: ConfigManager? = nil
    //var videoFormats: [AnyObject] = []
    var videoFormats: NSMutableArray? = nil
    var selectedFormatIndex: Int = 0
    var selectedIndexPath: NSIndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.cameraCap = CameraCapture.getInstance()
        self.configMan = ConfigManager.sharedInstance()
        self.videoFormats = NSMutableArray()
    }
    
    override func viewWillAppear(animated: Bool) {
        print("viewWillAppear")
        super.viewWillAppear(animated)
        
        //self.selectedFormatIndex = Int(self.cameraCap!.getVideoActiveFormatInFormats(self.videoFormats))
        self.cameraCap!.getVideoActiveFormatInFormats(self.videoFormats)
        self.selectedFormatIndex = Int(self.configMan!.confSettings.cameraSettings.formatIndex)
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        print("numberOfSectionsInTableView")
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberOfRowsInSection")
        var count: Int = 0
        
        switch (section) {
        case 0:
            count = self.videoFormats!.count
        default:
            count = 0
        }
        return count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("cellForRowAtIndexPath")
        let cell = tableView.dequeueReusableCellWithIdentifier("VideoFormat", forIndexPath: indexPath) 
        
        switch (indexPath.section) {
        case 0:
            cell.textLabel?.text = self.videoFormats!.objectAtIndex(indexPath.row) as? String
            if (indexPath.row == self.selectedFormatIndex) {
                cell.accessoryType = .Checkmark
                self.selectedIndexPath = indexPath
                // 次回表示/非表示時設定される
                //cell.selected = true
            } else {
                cell.accessoryType = .None
            }
        default:
            break
        }
        
        return cell
    }
    
    /*
    // Please remove your implementation of this method and set the cell properties accessoryType and/or editingAccessoryType to move to the new cell layout behavior.  This method will no longer be called in a future release.
    func tableView(tableView: UITableView, accessoryTypeForRowWithIndexPath indexPath: NSIndexPath!) -> UITableViewCellAccessoryType {
        println("accessoryTypeForRowWithIndexPath")
        
        var accessoryType: UITableViewCellAccessoryType = .None
        
        switch (indexPath.section) {
        case 0:
            if (indexPath.row == self.selectedFormatIndex) {
                accessoryType = .Checkmark
            }
        default:
            break
        }
        
        return accessoryType
    }
    */
    
    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("didSelectRowAtIndexPath")
        //let selectedIndexPath = tableView.indexPathForSelectedRow()
        if (self.selectedFormatIndex != indexPath.row) {//
            // @todo: 初回選択されたcellが非選択にならないので。他いい方法ある？
            // 初回非表示の場合、nilになる(cell作成されない)ので、チェック。自動scrollした方が良いかも
            if (self.selectedIndexPath != nil) {
                let deselectCell = tableView.cellForRowAtIndexPath(self.selectedIndexPath!)
                if (deselectCell != nil) {
                    deselectCell?.accessoryType = .None
                }
            }
            
            let selectedCell = tableView.cellForRowAtIndexPath(indexPath)
            if (selectedCell != nil) {
                selectedCell!.accessoryType = .Checkmark
                self.selectedFormatIndex = indexPath.row
                self.selectedIndexPath = indexPath
                self.cameraCap!.changeActiveFormatWithIndex(Int32(self.selectedFormatIndex))
                self.configMan!.confSettings.cameraSettings.formatIndex = Int32(self.selectedFormatIndex)
            }
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        print("didDeselectRowAtIndexPath")
        // todo:表示されない場合、cellがnilなる
        // nilではない場合、Noneに設定。nilの場合、表示されないので、何もしたくも良いかも。表示される時再度情報が設定される(cellForRowAtIndexPath)
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if (cell != nil) {
            cell?.accessoryType = .None
        }
        
        // cellは必ずnilにならない。ただ、表示されない場合、新規作成されるので、情報がなくなるかも。
        // 表示されないので、問題ないはず。videoFormatsで情報を持っているので、表示される時再度情報が設定される(cellForRowAtIndexPath)
        // ただ、cellを新規作成するだけなので、実際tableviewのcellになっていない?
        //let cell = tableView.dequeueReusableCellWithIdentifier("VideoFormat", forIndexPath: indexPath) as! UITableViewCell
        //cell.accessoryType = .None
    }
}
