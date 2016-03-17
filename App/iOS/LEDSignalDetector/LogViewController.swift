//
//  LogViewController.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/09/07.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import UIKit

class LogViewController: UIViewController {
    
    @IBOutlet weak var logView: UITextView!
    
    var logger: SignalLogger?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.logger = SignalLogger.sharedInstance
        self.logView.text = ""
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let logStr = self.logger?.getAllLogs()
        let patternLogStr = self.logger?.getPatternLogs()
        //print(logStr)
        self.logView.text = patternLogStr! + logStr!
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

}
