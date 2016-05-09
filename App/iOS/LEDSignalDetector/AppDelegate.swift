//
//  AppDelegate.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2014/10/05.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private func loadConfig() {
        
    }
    
    private func loadCapability() {
        
    }

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        return true
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // 初回起動時
        //Log.debug("application")
        let defaults = NSUserDefaults.standardUserDefaults()
        let dic = ["firstLaunch": true]
        defaults.registerDefaults(dic)
        
        // windowはインスタンス化されている.ViewControllerもrootViewControllerになっている
        //println("window : \(self.window)")
        
        //self.window = UIWindow(frame: UIScreen.mainScreen().bounds)// 不要
        //self.window!.rootViewController = ViewController(nibName: "LEDMainController", bundle: nil)//NG不要
        //println("window : \(self.window)")
        //println("rootViewController : \(self.window!.rootViewController)")
        //self.window!.makeKeyAndVisible()// Key関連なので不要
        
        // 一時フォルダ作成. @memo tmpではないとNG
        FileManager.createRootFolder("tmp")
        FileManager.createSubFolder("image")
        FileManager.createSubFolder("collection")
        
        // configデータをロード
        
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        // 電話、SMS、home/power、バックグランド。一時中断
        // home/powerボタン　一時停止：キャプチャ停止（画像処理停止）
        //Log.debug("applicationWillResignActive")
        
        /*
        let captureViewController = self.window?.rootViewController as CaptureViewController
        if (captureViewController.captureMode == CaptureMode.Eyesight) {
            captureViewController.stopCapture()
        }
        */
        // todo viewを無効/隠して、viewDidDisappearでstopするのが良いかも?
        //self.window.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        // バックグランドで処理する場合、applicationWillTerminateは呼ばれない
        // home/powerボタン　データ、現状態保存：特にない？
        //Log.debug("applicationDidEnterBackground")
        
        ConfigManager.sharedInstance().save()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        // バックグランドに入った時の処理を戻す
        // データ、状態復帰：特にない？設定情報くらい？
        //Log.debug("applicationWillEnterForeground")
        
        // todo:cloudからconfig取得->通信準備する(関連オブジェクト作成など)->backgroundからではない場合、呼ばれないかも
        //      applicationDidBecomeActiveを使用
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // 再開：キャプチャ再開
        //Log.debug("applicationDidBecomeActive")
        
        // todo:非同期通信リクエストを投げる->splash画面でresponseが返ってくるまで数秒待つ
        
        /*
        let captureViewController = self.window?.rootViewController as CaptureViewController
        if (captureViewController.captureMode == CaptureMode.Eyesight) {
            captureViewController.startCapture()
        }*/
        
        // todo viewを有効/表示し、viewWillAppearかviewDidAppearでstartするのが良いかも?
    }
    
    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        // データ保存
        //Log.debug("applicationWillTerminate")
        
        ConfigManager.sharedInstance().save()
        
        // 一時フォルダ削除->残す
        //FileManager.deleteSubFolder("image")
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let dic = ["firstLaunch": false]
        defaults.registerDefaults(dic)
    }

    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        if (DBSession.sharedSession().handleOpenURL(url)) {
            if (DBSession.sharedSession().isLinked()) {
                Uploader.getInstance().save()
            }
            
            return true
        }
        
        return false
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return true
    }

}

