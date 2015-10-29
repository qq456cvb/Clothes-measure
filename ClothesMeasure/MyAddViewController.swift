//
//  MyAddViewController.swift
//  HelloWorld
//
//  Created by Neil on 15/4/21.
//  Copyright (c) 2015年 Neil. All rights reserved.
//

import UIKit

class MyAddViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var toDoItem = AddToItem(name: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if sender as? UIBarButtonItem != self.doneButton {
            return
        }
        if count(textField.text) > 0 {
            toDoItem.itemName = textField.text
            toDoItem.completed = false
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    

}
