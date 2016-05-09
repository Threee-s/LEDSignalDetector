//
//  ProgressViewController.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2016/04/11.
//  Copyright © 2016年 TrE. All rights reserved.
//

import UIKit
import MBCircularProgressBar

class ProgressViewController: UIViewController {
    
    @IBOutlet weak var airProgressView: MBCircularProgressBarView!
    //@IBOutlet weak var progressView: UIProgressView!
    
    
    // test
    var flag: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.airProgressView.value = 0
        
        self.airProgressView.hidden = !self.flag
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

    func updateProgress(progress: Float) {
        print("updateProgress progress:\(progress)")
        self.airProgressView.value = CGFloat(progress)
        
        if (progress >= 1) {
            dispatch_async(dispatch_get_main_queue()) {
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    print("dismissAirProgressViewController")
                    
                    }
                )
            }
        }
    }
}
