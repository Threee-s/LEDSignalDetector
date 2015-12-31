//
//  DebugLog.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/07/10.
//  Copyright (c) 2015年 TrE. All rights reserved.
//
// https://github.com/inamiy/DebugLog/blob/master/DebugLog.all.swift

import Foundation
import CoreGraphics
import QuartzCore


class SignalLogger {
    var allLogs: String = ""
    var latestLogs: String = ""
    
    class var sharedInstance: SignalLogger {
        struct Wrapper {// @memo:Can't define static var in class
            static let instance: SignalLogger = SignalLogger()
        }
        
        return Wrapper.instance
    }
    
    func addLog(log: String!) {
        if (log != nil && log != "") {
            latestLogs += log + "\n"
        }
    }
    
    func getLatestLog() -> String {
        return latestLogs
    }
    
    func getAllLogs() -> String {
        //allLogs += latestLogs
        allLogs = latestLogs
        
        return allLogs
    }
    
    func clearLogs() {
        allLogs = ""
        latestLogs = ""
    }
}

#if false
extension DDFileReader
{
    func readLogLine(index: Int) -> NSString!
    {
        var line: NSString!
        
        self.resetOffset()
        
        var lineNum = 0
        
        self.enumerateLinesUsingBlock { (currentLine, stop) in
            lineNum++
            if lineNum == index {
                line = currentLine
                stop = true
            }
        }
        
        let logFuncString = "LOG_OBJECT\\(.*?\\)" as NSString
        
        var range = line.rangeOfString(logFuncString as String, options: .RegularExpressionSearch)
        range.location += logFuncString.length-6
        range.length -= logFuncString.length-5
        
        line = line.substringWithRange(range).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return line
    }
}


// Swift and Objective-C Class Parsing by @jpsim
// https://gist.github.com/jpsim/1b86d116808cb4e9bc30
extension DebugLog
{
    enum ClassType {
        case Swift, ObjectiveC
        
        func toString() -> String {
            switch self {
            case .Swift:
                return "Swift"
            case .ObjectiveC:
                return "Objective-C"
            }
        }
    }
    
    struct ParsedClass {
        let type: ClassType
        let name: String
        
        let mangledName: String?
        let moduleName: String?
    }
    
    static func _substr(str: String, range: Range<Int>) -> String {
        let startIndex = advance(str.startIndex, range.startIndex)
        let endIndex = advance(startIndex, range.endIndex)
        
        return str[Range(start: startIndex, end: endIndex)]
    }
    
    static func parseClass(aClass: AnyClass) -> ParsedClass {
        // Swift mangling details found here: http://www.eswick.com/2014/06/inside-swift
        
        let originalName = NSStringFromClass(aClass)
        
        if !originalName.hasPrefix("_T") {
            // Not a Swift symbol
            return ParsedClass(type: ClassType.ObjectiveC,
                name: originalName,
                mangledName: nil,
                moduleName: nil)
        }
        
        let originalNameLength = count(originalName.utf16)
        var cursor = 4
        var substring = _substr(originalName, range: cursor ..< originalNameLength-cursor)
        
        // Module
        let moduleLength = (substring as NSString).integerValue
        let moduleLengthLength = count("\(moduleLength)".utf16)
        let moduleName = _substr(substring, range: moduleLengthLength ..< moduleLength)
        
        // Update cursor and substring
        cursor += moduleLengthLength + count(moduleName.utf16)
        substring = _substr(originalName, range: cursor ..< originalNameLength-cursor)
        
        // Class name
        let classLength = (substring as NSString).integerValue
        let classLengthLength = count("\(classLength)".utf16)
        let className = _substr(substring, range: classLengthLength ..< classLength)
        
        return ParsedClass(type: ClassType.Swift,
            name: className,
            mangledName: originalName,
            moduleName: moduleName)
    }
    
}

//
// TODO:
// Some C-structs (e.g. CGAffineTransform, CATransform3D) + Printable don't work well in Xcode6-beta2
//
extension CGAffineTransform : Printable, DebugPrintable
{
    public var description: String
        {
            //        return NSStringFromCGAffineTransform(self) // comment-out: requires UIKit
            return "[\(a), \(b);\n \(c), \(d);\n \(tx), \(ty)]"
    }
    
    public var debugDescription: String
        {
            return self.description
    }
}

extension CATransform3D : Printable, DebugPrintable
{
    public var description: String
        {
            return "[\(m11) \(m12) \(m13) \(m14);\n \(m21) \(m22) \(m23) \(m24);\n \(m31) \(m32) \(m33) \(m34);\n \(m41) \(m42) \(m43) \(m44)]"
    }
    
    public var debugDescription: String
        {
            return self.description
    }
}


struct DebugLog
{
    static let _lock = NSObject()
    
    static var printHandler: (Any!, String, String, Int) -> Void = { body, filename, functionName, line in
        
        if body == nil {
            println("[\(filename).\(functionName):\(line)]")    // print functionName
            return
        }
        
        if let body = body as? String {
            if count(body) == 0 {
                println("") // print break
                return
            }
        }
        
        println("[\(filename):\(line)] \(body)")
    }
    
    static func print(_ body: Any! = nil, var filename: String = __FILE__, var functionName: String = __FUNCTION__, line: Int = __LINE__)
    {
        #if DEBUG
            
            objc_sync_enter(_lock)
            
            filename = filename.lastPathComponent.stringByDeletingPathExtension
            self.printHandler(body, filename, functionName, line)
            
            objc_sync_exit(_lock)
            
        #endif
    }
}

/// LOG() = prints __FUNCTION__
func LOG(filename: String = __FILE__, var functionName: String = __FUNCTION__, line: Int = __LINE__)
{
    #if DEBUG
        
        DebugLog.print(nil, filename: filename, functionName: functionName, line: line)
        
    #endif
}

/// LOG(...) = println
func LOG(body: Any, filename: String = __FILE__, var functionName: String = __FUNCTION__, line: Int = __LINE__)
{
    #if DEBUG
        
        DebugLog.print(body, filename: filename, functionName: functionName, line: line)
        
    #endif
}

/// LOG_OBJECT(myObject) = println("myObject = ...")
func LOG_OBJECT(body: Any, filename: String = __FILE__, var functionName: String = __FUNCTION__, line: Int = __LINE__)
{
    #if DEBUG
        
        if let reader = DDFileReader(filePath: filename) {
        let logBody = "\(reader.readLogLine(line)) = \(body)"
        
        LOG(logBody, filename: filename, functionName: functionName, line: line)
        }
        
    #endif
}

func LOG_OBJECT(body: AnyClass, filename: String = __FILE__, var functionName: String = __FUNCTION__, line: Int = __LINE__)
{
    #if DEBUG
        
        let reader = DDFileReader(filePath: filename)
        
        let classInfo: DebugLog.ParsedClass = DebugLog.parseClass(body)
        let classString = classInfo.moduleName != nil ? "\(classInfo.moduleName!).\(classInfo.name)" : "\(classInfo.name)"
        
        LOG_OBJECT(classString, filename: filename, functionName: functionName, line: line)
        
        // comment-out: requires method name demangling
        //    LOG_OBJECT("\(class_getName(body))", filename: filename, functionName: functionName, line: line)
        
    #endif
}


//
// Swift port of DDFileReader by Dave DeLong
//
// objective c - How to read data from NSFileHandle line by line? - Stack Overflow
// http://stackoverflow.com/a/3711079/666371
//
public class DDFileReader
{
    public var lineDelimiter = "\n"
    public var chunkSize = 128
    
    public let filePath: NSString
    
    private let _fileHandle: NSFileHandle!
    private let _totalFileLength: CUnsignedLongLong
    private var _currentOffset: CUnsignedLongLong = 0
    
    public init?(filePath: NSString)
    {
        self.filePath = filePath
        if let fileHandle = NSFileHandle(forReadingAtPath: filePath as String) {
            self._fileHandle = fileHandle
            self._totalFileLength = self._fileHandle.seekToEndOfFile()
        }
        else {
            self._fileHandle = nil
            self._totalFileLength = 0
            
            return nil
        }
    }
    
    deinit
    {
        self._fileHandle.closeFile()
    }
    
    public func readLine() -> NSString?
    {
        if self._currentOffset >= self._totalFileLength {
            return nil
        }
        
        self._fileHandle.seekToFileOffset(self._currentOffset)
        let newLineData = self.lineDelimiter.dataUsingEncoding(NSUTF8StringEncoding)
        let currentData = NSMutableData()
        var shouldReadMore = true
        
        autoreleasepool {
            
            while shouldReadMore {
                
                if self._currentOffset >= self._totalFileLength {
                    break
                }
                
                var chunk = self._fileHandle.readDataOfLength(self.chunkSize)
                
                let newLineRange = chunk.rangeOfData(newLineData!)
                
                if newLineRange.location != NSNotFound {
                    chunk = chunk.subdataWithRange(NSMakeRange(0, newLineRange.location+newLineData!.length))
                    shouldReadMore = false
                }
                currentData.appendData(chunk)
                
                self._currentOffset += CUnsignedLongLong(chunk.length)
                
            }
            
        }
        
        let line = NSString(data: currentData, encoding:NSUTF8StringEncoding)
        
        return line
    }
    
    public func readTrimmedLine() -> NSString?
    {
        let characterSet = NSCharacterSet(charactersInString: self.lineDelimiter)
        return self.readLine()?.stringByTrimmingCharactersInSet(characterSet)
    }
    
    public func enumerateLinesUsingBlock(closure: (line: NSString, stop: inout Bool) -> Void)
    {
        var line: NSString? = nil
        var stop = false
        while stop == false {
            line = self.readLine()
            if line == nil { break }
            
            closure(line: line!, stop: &stop)
        }
    }
    
    public func resetOffset()
    {
        self._currentOffset = 0
    }
}

extension NSData
{
    private func rangeOfData(dataToFind: NSData) -> NSRange
    {
        var searchIndex = 0
        var foundRange = NSRange(location: NSNotFound, length: dataToFind.length)
        
        for index in 0...length-1 {
            
            let bytes_ = UnsafeBufferPointer(start: UnsafePointer<CUnsignedChar>(self.bytes), count: self.length)
            let searchBytes_ = UnsafeBufferPointer(start: UnsafePointer<CUnsignedChar>(dataToFind.bytes), count: self.length)
            
            if bytes_[index] == searchBytes_[searchIndex] {
                if foundRange.location == NSNotFound {
                    foundRange.location = index
                }
                searchIndex++
                if searchIndex >= dataToFind.length {
                    return foundRange
                }
            }
            else {
                searchIndex = 0
                foundRange.location = NSNotFound
            }
            
        }
        return foundRange
    }
}
#endif
