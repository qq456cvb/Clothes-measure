//
//  MyFileManager.swift
//  ClothesMeasure
//
//  Created by Neil on 7/18/15.
//  Copyright (c) 2015 Neil. All rights reserved.
//

import Foundation

class MyFileManager: NSObject {
    func dirHome() -> String{
        let dirHomePath = NSHomeDirectory()
        print(dirHomePath)
        return dirHomePath
    }
    
    func dirDoc() -> String{
        let documentPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
//        println(documentPath)
        return documentPath
    }
    
    func createFile() {
        let fileManager = NSFileManager.defaultManager()
        let documentPath = NSURL.init(fileURLWithPath: self.dirDoc())
        let testPath = documentPath.URLByAppendingPathComponent("test.txt")
        let res = fileManager.createFileAtPath(testPath.absoluteString, contents: nil, attributes: nil)
        if  (res) {
            print("创建文件成功");
        } else {
            print("创建文件失败");
        }
    }
    
    func writeFile(content: String) {
        let documentPath = NSURL.init(fileURLWithPath: self.dirDoc())
        let testPath = documentPath.URLByAppendingPathComponent("test.txt")
        var res: Bool
        do {
            try content.writeToFile(testPath.absoluteString, atomically: true, encoding: NSUTF8StringEncoding)
            res = true
        } catch _ {
            res = false
        }
        if res {
            print("文件写入成功");
        } else {
            print("文件写入失败");
        }
    }
    
    func writeFileAppend(content: String) {
        let documentPath = NSURL.init(fileURLWithPath: self.dirDoc())
        let testPath = documentPath.URLByAppendingPathComponent("test.txt")
        let str = readFile()
        if str == [] {
            writeFile(content)
            return
        }
        if let fileHandle = NSFileHandle(forWritingAtPath: testPath.absoluteString) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    fileHandle.seekToEndOfFile()
                    fileHandle.writeData(content.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
                    fileHandle.closeFile()
                });
            
        } else {
            print("Unable to open file")
        }
        return
    }
    
    func readFile() -> [String]{
        let documentPath = NSURL.init(fileURLWithPath: self.dirDoc())
        let testPath = documentPath.URLByAppendingPathComponent("test.txt")
        if let content = try? String(contentsOfFile:testPath.absoluteString, encoding: NSUTF8StringEncoding) {
            let array = content.componentsSeparatedByString("&")
            return array
        }
        return []
    }
}