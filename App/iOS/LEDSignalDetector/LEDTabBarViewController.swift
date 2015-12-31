//
//  LEDTabBarViewController.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/28.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import UIKit

class LEDTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("prepareForSegue")
        
        if let cameraSettingViewController = segue.destinationViewController as? CameraSettingViewController {
            print("destinationViewController = CameraSettingViewController")
            if let captureViewController = segue.sourceViewController as? CaptureViewController {
                print("sourceViewController = CaptureViewController")
                let videoFormats: NSMutableArray = NSMutableArray()
                let index = captureViewController.cameraCap?.getVideoActiveFormatInFormats(videoFormats)
                cameraSettingViewController.videoFormats = videoFormats
                cameraSettingViewController.selectedFormatIndex = Int(index!)// Int32->Int ok?
            }
        } else if let captureViewController = segue.sourceViewController as? CaptureViewController {
            print("sourceViewController = CaptureViewController")
            if let cameraSettingViewController = segue.destinationViewController as? CameraSettingViewController {
                print("destinationViewController = CameraSettingViewController")
                captureViewController.cameraCap?.changeActiveFormatWithIndex(Int32(cameraSettingViewController.selectedFormatIndex))
            }
        }
    }
    

}
