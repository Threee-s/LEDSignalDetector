//
//  AirNetworkManager.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/11/15.
//  Copyright © 2015年 Threees. All rights reserved.
//

import Foundation

class AirNetworkManager: NSObject {
    let QUEUE_SERIAL_CONNECTION_REQUEST = "com.threees.aircomm.connection-request"
    
    class func requestJsonDataWithUrl(url: String, responseJsonHandler: (NSDictionary?) -> Void) {
        requestDataWithUrl(url) { (data) -> Void in
            do {
                let dict = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                responseJsonHandler(dict)
            } catch {
                
            }
        }
    }
    
    class func uploadMovieWithUrl(url: String, path: String, responseResultHandler: String -> Void) {
        postFileWithUrl(url, path: path) { (data) -> Void in
            let result = String(data: data!, encoding: NSUTF8StringEncoding)
            if (result != nil) {
                responseResultHandler(result!)
            }
        }
    }
    
    // todo: add header parameters
    private class func requestDataWithUrl(url: String, responseHandler: (NSData?) -> Void) {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        let reqUrl = NSURL(string: url)
        let request = NSMutableURLRequest(URL: reqUrl!)
        request.HTTPMethod = "GET"
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if (error == nil) {
                responseHandler(data)
            } else {
                print(error)
            }
        }
        task.resume()
    }
    
    // todo: add header parameters
    private class func postFileWithUrl(url: String, path: String, responseHandler: (NSData?) -> Void) {
        let fileName = FileManager.getFileNameFromPath(path)
        let fileData = NSData(contentsOfFile: path)
        //let boundary = "aircamera-service-upload-file"
        let boundary = "aircamera"
        let contentType = String(format: "multipart/form-data; boundary=%@", boundary)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.HTTPAdditionalHeaders = ["Content-Type" : contentType]
        let session = NSURLSession(configuration: config)
        let reqUrl = NSURL(string: url)
        let request = NSMutableURLRequest(URL: reqUrl!)
        let bodyData = NSMutableData()
        
        // todo:関数化
        // テキスト部分の設定
        bodyData.appendData(getBodyData(String(format: "--%@\r\n", boundary)))
        bodyData.appendData(getBodyData(String(format: "Content-Disposition: form-data; name=\"%@\"\r\n\r\n", "title")))
        //bodyData.appendData(getBodyData(String(format: "name=\"%@\"\r\n\r\n", "title")))
        bodyData.appendData(getBodyData(String(format: "%@\r\n", fileName)))
        
        bodyData.appendData(getBodyData(String(format: "--%@\r\n", boundary)))
        bodyData.appendData(getBodyData(String(format: "Content-Disposition: form-data; name=\"%@\"\r\n\r\n", "video")))
        //bodyData.appendData(getBodyData(String(format: "name=\"%@\"\r\n\r\n", "video")))
        bodyData.appendData(getBodyData(String(format: "@%@.mov\r\n", fileName)))
        //bodyData.appendData(getBodyData(String(format: "@%@\r\n", path)))
        
        // 画像の設定
        bodyData.appendData(getBodyData(String(format: "--%@\r\n", boundary)))
        bodyData.appendData(getBodyData(String(format: "Content-Disposition: form-data; name=\"%@\";", "filename")))
        //bodyData.appendData(getBodyData(String(format: "name=\"%@\";", "filename")))
        bodyData.appendData(getBodyData(String(format: "filename=\"%@.mov\"\r\n", fileName)))
        //bodyData.appendData(getBodyData(String(format: "Content-Type: video/quicktime\r\n\r\n")))
        bodyData.appendData(getBodyData(String(format: "Content-Type: application/octet-stream\r\n")))
        bodyData.appendData(getBodyData(String(format: "Content-Transfer-Encoding: binary\r\n\r\n")))
        //bodyData.appendData(getBodyData(String(format: "\r\n")))
        // バイナリデータ
        bodyData.appendData(fileData!)
        bodyData.appendData(getBodyData(String(format: "\r\n")))
        
        // 最後にバウンダリを付ける
        bodyData.appendData(getBodyData(String(format: "--%@--\r\n", boundary)))
        
        request.HTTPMethod = "POST"
        request.HTTPBody = bodyData
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            // todo: wrap error for returnning
            if (error == nil) {
                responseHandler(data)
            } else {
                print(error)
            }
        }
        task.resume()
    }
    
    private class func getBodyData(param: String) -> NSData {
        let bodyData = param.dataUsingEncoding(NSUTF8StringEncoding)
        
        return bodyData!
    }
}
