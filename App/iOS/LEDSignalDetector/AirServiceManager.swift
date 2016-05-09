//
//  AirServiceManager.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/12/21.
//  Copyright © 2015年 Threees. All rights reserved.
//

import Foundation


enum CloudType {
    case MilkCocoa
    case DropBox
    case Heroku
}

// todo:各種クラウドサービスを管理する。
// 共通API(protocol)を定義し、通信レイヤーを隠し、簡単に操作できるようにする
// Web系全て管理
class AirServiceManager: NSObject {
    
    class func getServiceWithType(type: CloudType, path: String) -> AirService {
        var service: AirService! = nil
        
        if type == .MilkCocoa {
            service = AirServiceMilkcocoa(path: path)
        } else if type == .DropBox {
            service = AirServiceDropbox()
        } else if type == .Heroku {
            service = AirServiceHeroku()
        }
        
        return service
    }
    
    class func getServiceOfMilkcocoaWithPath(path: String) -> AirServiceMilkcocoa {
        return AirServiceMilkcocoa(path: path)
    }
}
