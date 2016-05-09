//
//  AirService.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/12/17.
//  Copyright © 2015年 Threees. All rights reserved.
//

import Foundation

protocol AirServiceDelegate {
    func serviceDidSend(service: AirService)
    func service(service: AirService, didReceiveData data: AnyObject)
}

protocol AirService {
    func connect()
    func setDelegate(delegate: AirServiceDelegate)
    func send(data: CollectionData)
    func sendBlockData(blockData: [CollectionData])
    func disconnect()
}

class AirServiceHeroku: AirService {
    //static let servUrls = "https://led.herokuapp.com/api/v1/capabilities"
    static let servUrl = "http://led.herokuapp.com/api/v1/capabilities"
    
    class func uploadMovie(path: String) {
        AirNetworkManager.uploadMovieWithUrl(servUrl, path: path) { (result) -> Void in
            print(result)
        }
    }
    
    func connect() {
        
    }
    
    func setDelegate(delegate: AirServiceDelegate) {
        
    }
    
    func send(data: CollectionData) {
        
    }
    
    func sendBlockData(blockData: [CollectionData]) {
        
    }
    
    func disconnect() {
        
    }
}

class AirServiceDropbox: AirService {
    func connect() {
        
    }
    
    func setDelegate(delegate: AirServiceDelegate) {
        
    }
    
    func send(data: CollectionData) {
        
    }
    
    func sendBlockData(blockData: [CollectionData]) {
        
    }
    
    func disconnect() {
        
    }
}

class AirServiceMilkcocoa: NSObject, AirService, LEDMQTTClientDelegate {
    private var client: LEDMQTTClient!
    private var path: String = ""
    private var connected: Bool = false
    private var delegate: AirServiceDelegate!
    
    var isConnected: Bool {
        return self.connected
    }
    
    convenience override init() {
        //super.init()
        //self.client = LEDMQTTClient()
        //self.client?.delegate = self
        self.init(path: "")
    }
    
    init(path: String) {
        super.init()
        self.path = path
        self.client = LEDMQTTClient()
        self.client.delegate = self
        //self.client.connect()
    }
    
    deinit {
        print("deinit")
        self.client.disconnect()
    }
    
    // MARK: - AirServiceDelegate protocol
    
    func connect() {
        if !self.connected {
            self.client.connect()
        }
    }
    
    func setDelegate(delegate: AirServiceDelegate) {
        self.delegate = delegate
    }
    
    func send(data: CollectionData) {
        if self.connected {
            self.client.push(self.path, data: data)
        }
    }
    
    func sendBlockData(blockData: [CollectionData]) {
        if self.connected {
            self.client.push(self.path, blockData: blockData)
        }
    }
    
    func disconnect() {
        if self.connected {
            self.client.disconnect()
        }
    }
    
    // MARK: - LEDMQTTClientDelegate protocol
    func ledMqttClientDidConnect(client: LEDMQTTClient) {
        print("ledMqttClientDidConnect")
        self.connected = true
    }
    
    func ledMqttClientDidSend(client: LEDMQTTClient) {
        if (self.delegate != nil) {
            self.delegate.serviceDidSend(self)
        }
    }
    
    func ledMqttClient(client: LEDMQTTClient, didReceiveCollectionData data: CollectionData) {
        
    }
    
    func ledMqttClientDidDisconnect(client: LEDMQTTClient, withError err: NSError?) {
        print("ledMqttClientDidDisconnect")
        self.connected = false
    }
}