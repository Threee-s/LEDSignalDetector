//
//  CollectionData.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2016/03/27.
//  Copyright © 2016年 TrE. All rights reserved.
//

import Foundation
//import CoreLocation
//import SwiftyJSON

class DataConverter {
    // カメラ、センサー、1セット(1s/30frameの情報：主に輪郭point情報)、解析結果
    static func signal2JSON() {
        
    }
    
    // todo:解析しやすい形式に変換
    static func json2Signal(json: NSDictionary) {
        
    }
}

class DeviceData {
    var version: String = "nan"
    var latitude: Double = 0
    var longitude: Double = 0
    var magneticHeading: Double = 0
    var trueHeading: Double = 0
    var timestamp: Double = 0
    
    init() {
        
    }
    
    init(_ v: String, _ lat: Double, _ lon: Double, _ mhead: Double, _ thead: Double, _ t: Double) {
        self.version = v
        self.latitude = lat
        self.longitude = lon
        self.magneticHeading = mhead
        self.trueHeading = thead
        self.timestamp = t
    }
    
    func toJson() -> [String: AnyObject] {
        return ["version": version, "latitude": latitude.description, "longitude": longitude.description, "magneticHeading": magneticHeading.description, "trueHeading": trueHeading.description, "timestamp": timestamp.description];
    }
    
    func json() -> NSDictionary {
        return ["ver": version, "lat": latitude, "lon": longitude, "mh": magneticHeading, "th": trueHeading, "ts": timestamp];
    }
}

class SystemData {
    var cpu: Float = 0
    var memory: Float = 0
}

class CameraData {
    var formatIndex: Int = -1
    var exposureDuration: Float = 0
    var exposureValue: Float = 0
    var iso: Float = 0
    var bias: Float = 0
    var offset: Float = 0
    var fps: Int = 0
    // todo:histogram
    
    init() {
        
    }
    
    init(_ index: Int, _ duration: Float, _ value: Float, _ iso: Float, _ bias: Float, _ offset: Float, _ fps: Int) {
        self.formatIndex = index
        self.exposureDuration = duration
        self.exposureValue = value
        self.iso = iso
        self.bias = bias
        self.offset = offset
        self.fps = fps
    }
    
    func toJson() -> [String: AnyObject?] {
        return ["formatIndex": formatIndex.description, "exposureDuration": exposureDuration.description, "exposureValue": exposureValue.description, "iso": iso.description, "bias": bias.description, "offset": offset.description, "fps": fps.description];
    }
    
    func json() -> NSDictionary {
        return ["index": formatIndex, "duration": exposureDuration, "value": exposureValue, "iso": iso, "bias": bias, "offset": offset, "fps": fps];
    }
}

class FrameData {
    var timestamp: Double = 0
    var orientation: UIImageOrientation = UIImageOrientation.Up
    
    init() {
        
    }
    
    init(_ t: Double, _ ori: UIImageOrientation = UIImageOrientation.Up) {
        self.timestamp = t
        self.orientation = ori
    }
    
    func toJson() -> [String: AnyObject] {
        return ["timestamp": timestamp.description, "orientation": orientation.rawValue.description]
    }
    
    func json() -> NSDictionary {
        return ["ts": timestamp, "ori": orientation.rawValue]
    }
}

class DetectData {
    var des: String = ""
    var conturs: NSArray
    var pattern: NSArray
    
    init() {
        conturs = NSArray()
        pattern = NSArray()
    }
    
    init(_ des: String) {
        self.des = des
        conturs = NSArray()
        pattern = NSArray()
    }
    
    init(_ conturs: NSArray, _ pattern: NSArray) {
        self.conturs = conturs
        self.pattern = pattern
    }
    
    func toJson() -> [String: AnyObject] {
        return ["conturs": des];
    }
    
    func json() -> NSDictionary {
        return ["conturs": conturs, "pattern": pattern]
    }
}

class DetectResult {
    var signal: Bool = false
    var kind: Int = 0
    var color: Int = 0
    var rect: CGRect = CGRectZero
    var distance: Float = 0
    var matching: Float = 0
    var circle: Float = 0
    var procTime: Double = 0
    
    init() {
        
    }
    
    init(_ signal: Bool, _ kind: Int, _ color: Int, _ rect: CGRect, _ distance: Float, _ matching: Float, _ circle: Float, _ procTime: Double) {
        self.signal = signal
        self.kind = kind
        self.color = color
        self.rect = rect
        self.distance = distance
        self.matching = matching
        self.circle = circle
        self.procTime = procTime
    }
    
    func toJson() -> [String: AnyObject?] {
        let rectJson = ["x": rect.origin.x.description, "y": rect.origin.y.description, "w": rect.size.width.description, "h": rect.size.height.description].description
        return ["signal": signal.description, "color": color.description, "rect": rectJson, "distance": distance.description, "matching": matching.description, "circle": circle.description, "time": procTime.description];
    }
    
    func json() -> NSDictionary {
        let rectJson: NSDictionary = ["x": rect.origin.x, "y": rect.origin.y, "w": rect.size.width, "h": rect.size.height]
        return ["signal": signal, "color": color, "rect": rectJson, "distance": distance, "matching": matching, "circle": circle, "time": procTime];
    }
}

public class CollectionData {
    var index: Int
    var device: DeviceData
    var camera: CameraData
    var frame: FrameData
    var detection: DetectData
    var results: [DetectResult]
    
    init() {
        index = 0
        device = DeviceData()
        camera = CameraData()
        frame = FrameData()
        detection = DetectData()
        results = []
    }
    
    init(_ index: Int, _ device: DeviceData, _ camera: CameraData, _ frame: FrameData, _ detection: DetectData, _ results: [DetectResult]) {
        self.index = index
        self.device = device
        self.camera = camera
        self.frame = frame
        self.detection = detection
        self.results = results
    }
    
    func getJson() -> [String: AnyObject] {
        var rets: String = ""
        for ret in results {
            rets += ret.toJson().description
        }
        return ["index": index, "device": device.toJson().description, "camera": camera.toJson().description, "frame": frame.toJson(), "detection": detection.toJson(),  "result": rets]
    }
    
    func json() -> NSDictionary {
        return ["index": index, "device": device.json(), "camera": camera.json(), "frame": frame.json(), "detection": detection.json(),  "result": results]
    }
}