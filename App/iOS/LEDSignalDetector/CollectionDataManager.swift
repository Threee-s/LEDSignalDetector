//
//  CollectionDataManager.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2016/04/14.
//  Copyright © 2016年 TrE. All rights reserved.
//

import Foundation




@objc protocol CollectionDataManagerDelegate {
    optional func collectionDataManager(dataManager: CollectionDataManager, didReceiveCollectionBlock dataBlock: CollectionBlock)
    optional func collectionDataManager(dataManager: CollectionDataManager, didReceiveCollectionFrame dataFrame: CollectionFrame, ofDataBlock dataBlock: CollectionBlock)
    optional func collectionDataManager(dataManager: CollectionDataManager, didSendProgress progress: Float)
    optional func collectionDataManager(dataManager: CollectionDataManager, didReceiveProgress progress: Float)
}

// Cloud上のデータを管理
// Local(View表示) <-> Cloud(Jsonなど) データ変換
// CollectionDataViewConttroler(CollectionView)表示用データを管理
// データをLocalファイルに保存
// memo:CollectionDataをここに定義した方が良いかも?->専用クライアントLEDMqttClientがあるので、同じところにした用が良い。
// 1frameのデータをそのまま上げるのではなく、まとまった(検出成功or失敗した)複数のframeを上げる
//   ->シンプルに1frameずつ上げる。
//   ->取得して、再現する場合、IDをもとに複数のframeをまとめる
// view: DetectID一覧
//         ->パターン/frame(画像or輪郭)一覧
//                    ->frame(画像or輪郭)/Detectデータ(CollectionData)
class CollectionDataManager: NSObject, AirServiceDelegate {
    private var delegate: CollectionDataManagerDelegate!
    private var service: AirService!
    // upload or donwloaded ids
    private var dataIds: [String] = []
    private var collectionDataList: [CollectionData] = []
    private var sendCount = 0
    
    class var sharedInstance: CollectionDataManager {
        struct Wrapper {// @memo:Can't define static var in class
            static let instance: CollectionDataManager = CollectionDataManager()
        }
        
        return Wrapper.instance
    }
    
    /*
    class func getInstance(type: CloudType) -> CollectionDataManager {
        struct Wrapper {// @memo:Can't define static var in class
            static let instance: CollectionDataManager = CollectionDataManager(type: type)
        }
        
        return Wrapper.instance
    }*/
    
    override init() {
        super.init()
        self.service = AirServiceManager.getServiceWithType(.MilkCocoa, path: "led/collection")
        self.service.setDelegate(self)
    }
    
    func setDelegate(delegate: CollectionDataManagerDelegate) {
        self.delegate = delegate
    }
    
    func connect() {
        self.service.connect()
    }
    
    func addData(data: CollectionData) {
        self.collectionDataList.append(data)
    }
    
    // save to local(tmp/collection/upload
    func saveData(data: CollectionData) {
        
    }
    
    // select for uploading or downloading
    func selectData(id: String) {
        
    }
    
    //
    func sendDataSelected() {
        self.sendCount = 0
    }
    
    func sendData(data: CollectionData) {
        self.sendCount = 0
        self.service.send(data)
    }
    
    func sendDataOfIds(ids: [String]) {
        self.sendCount = 0
    }
    
    func sendAllData() {
        // todo:mqttで非同期送信になるので、progress計算方法検討
        self.sendCount = 0
        for collectionData in self.collectionDataList {
            self.service.send(collectionData)
        }
    }
    
    func sendBlockData() {
        self.sendCount = 0
        self.service.sendBlockData(self.collectionDataList)
    }
    
    func getAllDataAsync() {
        // MilkcocoaのHistory関数を使うかStreamを実装(APIベース:javascript版APIのパケット調査)
        // 既存Herokuを使った方が楽かも
    }
    
    func getAllData() -> [CollectionBlock] {
        let dataList: [CollectionBlock] = []
        
        return dataList
    }
    
    // todo: for dropbox
    func getDataById(id: String) -> CollectionBlock {
        let info: CollectionBlock! = nil
        
        return info
    }
    
    // milkcocoaから全てのデータを取得して、解析、集計しないとわからないので、あまり意味がないかも
    // todo: for dropbox
    func getDataIds() -> [String] {
        let ids: [String] = []
        
        return ids
    }
    
    func clearAllData() {
        self.collectionDataList.removeAll()
    }
    
    func disconnect() {
        self.service.disconnect()
    }
    
    func serviceDidSend(service: AirService) {
        self.sendCount += 1
        
        let progress = self.sendCount * 100 / self.collectionDataList.count
        // todo: add id for progress
        if (self.delegate != nil) {
            self.delegate.collectionDataManager!(self, didSendProgress: Float(progress))
        }
    }
    
    func service(service: AirService, didReceiveData data: AnyObject) {
        
    }
}