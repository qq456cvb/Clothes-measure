//
//  DetailViewController.swift
//  ClothesMeasure
//
//  Created by Neil on 7/19/15.
//  Copyright (c) 2015 Neil. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    var details = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        return details.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DetailCell", forIndexPath: indexPath) 
        cell.textLabel?.text = details[indexPath.row]
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        return cell
    }
    
}
