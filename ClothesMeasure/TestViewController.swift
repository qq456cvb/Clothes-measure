//
//  TestViewController.swift
//  ClothesMeasure
//
//  Created by Neil on 7/19/15.
//  Copyright (c) 2015 Neil. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var results = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        results = appDelegate.fileMgr.readFile() as [String]!
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func numberOfSectionsInTableView(tableview: UITableView) -> Int{
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return results.count - 1;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TestCell", forIndexPath: indexPath) 
        cell.textLabel?.text = results[indexPath.row]
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        dispatch_async(dispatch_get_main_queue(), {
             self.performSegueWithIdentifier("Details", sender: tableView.cellForRowAtIndexPath(indexPath))
            });
       
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "Details") {
            let dvc: DetailViewController = segue.destinationViewController as! DetailViewController
            let txt = (sender as! UITableViewCell).textLabel?.text as String?
            dvc.details = txt!.componentsSeparatedByString("\n")
        }
    }
    
    @IBAction func unwindToHistory(segue: UIStoryboardSegue) {
    }
}
