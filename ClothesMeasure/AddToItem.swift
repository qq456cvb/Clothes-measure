//
//  AddToItem.swift
//  HelloWorld
//
//  Created by Neil on 15/4/21.
//  Copyright (c) 2015年 Neil. All rights reserved.
//

import UIKit

class AddToItem: NSObject {
    init(name: String) {
        super.init()
        self.itemName = name
    }
    var itemName: String = ""
    var test: Bool
    {
        get {
            return completed
        }
        set {
            completed = newValue
        }
    }
    var completed: Bool = false
    var creationDate: NSDate = NSDate.init()
}
