//
//  LEDSignalGraphViewController.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2015/03/06.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import UIKit

// 信号(複数frame画像のデータが必要)とヒストグラム(1つの画像)、datasourceを更新することで切り替え
// todo:coreplotはswift非対応?なので、直接SignalGraphViewにデータを設定。ObjectiveCのViewControllerで対応するとか
class LEDSignalGraphViewController: UIViewController {
    
    // todo:storyboardでインスタンス化される.実際必要な時作成したほうが良いかも。今後検討
    // 直接親viewにしたほうが良い？
    @IBOutlet weak var signalGraphView: SignalGraphView?

    override func viewDidLoad() {
        //Log.debug("LEDSignalGraphViewController viewDidLoad")
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    
    func setSignalData(data: [AnyObject]!) {
        self.signalGraphView?.setSignalData(data)
    }

}
