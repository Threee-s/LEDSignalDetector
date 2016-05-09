//
//  CapabilityManager.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2016/04/17.
//  Copyright © 2016年 TrE. All rights reserved.
//

import Foundation

struct Capability {
    var gps: Bool = false
    var voice: Bool = false
    var motion: Bool = false
}

class CapabilityManager: AirServiceDelegate {
    private var service: AirService!
    private var capability: Capability = Capability()
    
    class var sharedInstance: CapabilityManager {
        struct Wrapper {
            static let instance: CapabilityManager = CapabilityManager()
        }
        
        return Wrapper.instance
    }
    
    init() {
        self.service = AirServiceManager.getServiceWithType(.MilkCocoa, path: "led/capability")
        self.service.setDelegate(self)
    }
    
    private func saveCapability() {
        
    }
    
    func getCapability() -> Capability {
        return self.capability
    }
    
    func service(service: AirService, didReceiveData data: AnyObject) {
        self.saveCapability()
    }
    
    func serviceDidSend(service: AirService) {
        
    }
}