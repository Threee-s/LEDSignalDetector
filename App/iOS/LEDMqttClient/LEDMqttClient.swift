/*
//
//  LEDMqttClient.swift
//  LEDMqttClient
//
//  Created by 文光石 on 2016/04/03.
//  Copyright © 2016年 TrE. All rights reserved.
//
The MIT License (MIT)

Copyright (c) 2016 Threees

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Foundation


let DEFAULTHOST = "woodimkhlkbm.mlkcca.com"
let DEFAULTAPPID = "woodimkhlkbm"
let DEFAULTDATAPATH = "led"

public protocol LEDMQTTClientDelegate: NSObjectProtocol {
    func ledMqttClientDidConnect(client: LEDMQTTClient)
    //func ledMqttClient(client: LEDMQTTClient, didSendCollectionData data: CollectionData)
    func ledMqttClientDidSend(client: LEDMQTTClient)
    func ledMqttClient(client: LEDMQTTClient, didReceiveCollectionData data: CollectionData)
    func ledMqttClientDidDisconnect(client: LEDMQTTClient, withError err: NSError?)
}

/**
 Inupathyデータ取得クラス
 */
public class LEDMQTTClient {
    
    private var milkcocoa: MilkCocoa!
    //private var datastore: DataStore!
    private var host: String!
    private var appId: String!
    //private var dataPath: String!
    private var connected: Bool = false
    
    public weak var delegate: LEDMQTTClientDelegate!
    
    public init() {
        self.appId = DEFAULTAPPID
        self.host = DEFAULTHOST
        //self.dataPath = DEFAULTDATAPATH
    }
    
    //public convenience init(dataPath: String) {
    //    self.init(appId: DEFAULTAPPID, dataPath: dataPath)
    //}
    
    public init(appId: String/*, dataPath: String*/) {
        self.appId = appId
        self.host = appId + ".mlkcca.com"
        //self.dataPath = dataPath
    }
    
    /*public convenience init(appId: String) {
        //self.appId = appId
        //self.host = appId + ".mlkcca.com"
        //self.dataPath = DEFAULTDATAPATH
        self.init(appId: appId, dataPath: DEFAULTDATAPATH)
    }*/
    
    public init(host: String) {
        self.host = host
        self.appId = DEFAULTAPPID
        //self.dataPath = DEFAULTDATAPATH
    }
    
    // MARK: Method

    public func connect() {
        self.milkcocoa = MilkCocoa(app_id: self.appId, host: self.host, onConnect: { (mc) in
            print("connected!")
            if ((self.delegate) != nil) {
                self.connected = true
                self.delegate.ledMqttClientDidConnect(self)
            }
        }, onPublish: { (mc, topic) in
            print("published!")
            if ((self.delegate) != nil) {
                self.delegate.ledMqttClientDidSend(self)
            }
        })
        
        /*self.milkcocoa = MilkCocoa(app_id: self.appId, host: self.host, onConnect: { (mc) -> Void in
            print("connected!")
            if ((self.delegate) != nil) {
                self.connected = true
                self.delegate.ledMqttClientDidConnect(self)
            }
        })*/
    }
    
    public func addPushEvent(path: String) {
        let ds: DataStore = self.milkcocoa.dataStore(path)
        ds.on("push") { (de) in
            //let id: String = de.getValue("id") as! String
            // nil
            //let ts: UInt16 = de.getValue("timestamp") as! UInt16
            //let ts: UInt16 = 0
            //let value = de.getValue("value")
            //print("value:\(value)")
            //let dic: NSDictionary? = value as? NSDictionary
            //let data: CollectionData = CollectionData()
            //if ((self.delegate) != nil) {
            //    self.delegate.ledMqttClient(self, didReceiveCollectionData: data)
            //}
        }
    }
    
    public func push(path: String, data: CollectionData) {
        let ds: DataStore = self.milkcocoa.dataStore(path)
        let jsonData = data.json()
        
        //print("jsonData:\(jsonData)")
        
        ds.push(["collectionData": jsonData])
    }
    
    public func push(path: String, blockData block: [CollectionData]) {
        let ds: DataStore = self.milkcocoa.dataStore(path)
        var params: [[String: AnyObject]] = []
        var index = 0
        
        for data in block {
            //params.append(data.json() as! [String : AnyObject])
            params.append([index.description: data.json()])
            index += 1
        }
        
        //print("params:\(params)")
        
        ds.push(["collectionData": params])
    }
    
    // http api: heroku?milkcocoa?
    public func get() {
        
    }
    
    public func post(data: CollectionData, save: Bool = false) {
        
    }
    
    public func disconnect() {
        self.connected = false
        self.milkcocoa.disconnect()
        if ((self.delegate) != nil) {
            self.delegate.ledMqttClientDidDisconnect(self, withError: nil)
        }
    }
}