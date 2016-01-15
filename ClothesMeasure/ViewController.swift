//
//  ViewController.swift
//  HelloWorld
//
//  Created by Neil on 15/4/21.
//  Copyright (c) 2015年 Neil. All rights reserved.
//

import UIKit
import AVFoundation

@available(iOS 8.0, *)
class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate, DBCameraViewControllerDelegate, processDelegate {


    var analyzer: MyOpenCV = MyOpenCV()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var imageNow = 0
    var backImg = UIImage()
    var progressImages = [UIImage]()
    var reviewIndex = 0
    
    @IBOutlet weak var threshold: UISlider!
    @IBOutlet weak var iv: UIImageView!
    @IBOutlet weak var selectButtion: UIButton!
    @IBOutlet weak var showBtn: UIButton!
    @IBOutlet weak var threshLabel: UILabel!
    @IBOutlet weak var waiting: UIActivityIndicatorView!
    @IBOutlet weak var reviewBtn: UIButton!
    
    
    func getCurrentTime() -> String {
        let date = NSDate()
        let timeFormatter = NSDateFormatter()
        timeFormatter.dateFormat = "时间:yyy-MM-dd HH:mm:ss\n"
        let strNowTime = timeFormatter.stringFromDate(date) as String
        return strNowTime
    }
    
    @IBAction func reviewImage(sender: AnyObject) {
        if (reviewIndex < progressImages.count) {
            self.iv.image = progressImages[reviewIndex++]
        } else {
            reviewIndex = 0
            self.iv.image = progressImages[0]
        }
    }
    
    @IBAction func changeThresh(sender: UIStepper) {
        threshLabel.text = "\(sender.value)"
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
//            if self.imageNow == 2 {
//                self.iv.image = self.analyzer.surf(self.analyzer.frontImage(), withImg: self.analyzer.frontBackImage(), withType: 1, withThresh:(self.threshLabel.text as NSString!).doubleValue)
//            } else if self.imageNow == 3 {
//                self.iv.image = self.analyzer.surf(self.analyzer.flankImage(), withImg: self.analyzer.flankBackImage(), withType: 2, withThresh:(self.threshLabel.text as NSString!).doubleValue)
//            }
//        })
    }
    @IBAction func showResult(sender: UIButton) {
//        appDelegate.fileMgr.writeFile("")
//        return
        let alertController = UIAlertController(title: "显示结果", message: analyzer.getResultString(), preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "好的", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func reset(sender: UIButton) {
        selectButtion.setTitle("请选择正面图", forState: UIControlState.Normal)
        selectButtion.enabled = true
        imageNow = 0
        analyzer.reset()
        self.reviewBtn.enabled = false
    }
    
    @IBAction func showPhotos(sender: AnyObject) {
//        var c=UIImagePickerController()
//        c.sourceType=UIImagePickerControllerSourceType.PhotoLibrary
//        c.delegate=self
//        
//        self.presentViewController(c, animated: true, completion: nil)
        if (imageNow == 3) {
            saveImg(self.iv.image!);
        } else {
        var sheet:UIActionSheet
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera))
        {
            sheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: nil, otherButtonTitles: "从相册选择","拍照")
        }   else    {
            sheet = UIActionSheet(title:nil, delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: nil, otherButtonTitles: "从相册选择")
        }
        dispatch_async(dispatch_get_main_queue(),{
            sheet.showInView(self.view)
        })
        }
    }
    
    func showProgress()
    {
        KVNProgress.showProgress(0.0, status: "好啊")
        
        //	[self updateProgress];
        //
        dispatch_main_after(2.7, block: {
            KVNProgress.updateStatus("You can change to a multiline status text dynamically!");
            KVNProgress.updateProgress(0.2, animated: true)
        });
//        dispatch_main_after(5.5, block: {
//            KVNProgress.showSuccess()
//        });
    }

    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int)
    {
        var sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        if  (buttonIndex != 0)
        {
            if(buttonIndex==1){                //相册                
                sourceType = UIImagePickerControllerSourceType.PhotoLibrary
                let imagePickerController:UIImagePickerController = UIImagePickerController()
                imagePickerController.delegate = self
                imagePickerController.allowsEditing = false//true为拍照、选择完进入图片编辑模式
                imagePickerController.sourceType = sourceType
                self.presentViewController(imagePickerController, animated: true, completion: nil)
            }else{
                if imageNow < 2 {
                let db:DBCameraViewController = DBCameraViewController.initWithDelegate(self, withPic:"contour");
                presentViewController(db, animated: true, completion: nil)
                } else {
                    let db:DBCameraViewController = DBCameraViewController.initWithDelegate(self, withPic:"contour2");
                    presentViewController(db, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    func saveImg(image: UIImage) {
        self.dismissViewControllerAnimated(true, completion: nil)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        imageNow++
        if imageNow == 1{
            self.analyzer.setFrontImage(image)
//            KVNProgress.showProgress(0.0, status: "配准中")
            iv.image = image
            selectButtion.setTitle("请选择侧面图", forState: UIControlState.Normal)
        }
        if imageNow == 2 {
//            backImg = image.copy() as! UIImage
            self.analyzer.setFlankImage(image)
            iv.image = image
            //            self.analyzer.setFlankImage(imageToSave)
//            KVNProgress.showProgress(0.0, status: "配准中")
            //            dispatch_main_after(1, block: {KVNProgress.updateProgress(0.5, animated: false)})
            
            selectButtion.setTitle("请选择背景图", forState: UIControlState.Normal)
        }
        if imageNow == 3 {
            self.analyzer.setFrontBackImage(image)
            self.analyzer.setFlankBackImage(self.analyzer.frontBackImage())
            iv.image = image
            selectButtion.setTitle("确认", forState: UIControlState.Normal)
            KVNProgress.showProgress(0.0, status: "请稍后")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                self.analyzer.surf(self.analyzer.frontImage(), withImg: self.analyzer.frontBackImage(), withType: 1, withThresh:(self.threshLabel.text as NSString!).doubleValue)
            })
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                self.analyzer.surf(self.analyzer.flankImage(), withImg: self.analyzer.flankBackImage(), withType: 2, withThresh:(self.threshLabel.text as NSString!).doubleValue)
            });
        }
        if imageNow == 4 {
            selectButtion.enabled = false
            let alertController = UIAlertController(title: "请输入身高和姓名（便于区分）", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
            let okAction = UIAlertAction(title: "好的", style: UIAlertActionStyle.Default) {
                (action: UIAlertAction) -> Void in
                let textField = alertController.textFields?.first as UITextField!
                let name = (alertController.textFields?[1] as UITextField!).text
                self.analyzer.height = (textField.text as NSString!).floatValue
                
                let img1 = self.analyzer.frontAnalyze()
                if img1 == nil
                {
                    let alertView = UIAlertView(title: "错误", message: "图片不符合要求", delegate: self, cancelButtonTitle: "好的")
                    alertView.show()
                } else {
                    let img2 = self.analyzer.flankAnalyze()
                    if img2 == nil
                    {
                        let alertView = UIAlertView(title: "错误", message: "图片不符合要求", delegate: self, cancelButtonTitle: "好的")
                        alertView.show()
                    } else {
                        UIImageWriteToSavedPhotosAlbum(img1, nil, nil, nil);
                        UIImageWriteToSavedPhotosAlbum(img2, nil, nil, nil);
                        self.appDelegate.fileMgr.writeFileAppend(String.init(format: "姓名:%@\n%@%@&", name!, self.getCurrentTime(), self.analyzer.getResultString()))
                        self.reviewBtn.enabled = true
                    }
                }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            alertController.addTextFieldWithConfigurationHandler {
                (textField: UITextField!) -> Void in
                textField.placeholder = "身高（厘米）"
            }
            alertController.addTextFieldWithConfigurationHandler {
                (textField: UITextField!) -> Void in
                textField.placeholder = "姓名（代号）"
            }
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        var imageToSave:UIImage
        imageToSave = info[UIImagePickerControllerOriginalImage] as! UIImage
        saveImg(imageToSave)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        analyzer.delegate = self
        
//        var singleTap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "imageViewTouch")
//        iv .addGestureRecognizer(singleTap)
       // cam.cvMatFromUIImage(UIImage)
        // Do any additional setup after loading the view, typically from a nib.
    }

    func onProcessed(img: UIImage!) {
//        dispatch_sync(dispatch_get_main_queue(), {
//            self.iv.image = img
//        });
        KVNProgress.dismiss()
        if img == nil {
            dispatch_sync(dispatch_get_main_queue(), {
                self.imageNow = 0
                self.selectButtion.setTitle("请选择正面图", forState: UIControlState.Normal)
                let alertView = UIAlertView(title: "错误", message: "图片不符合要求", delegate: self, cancelButtonTitle: "好的")
                alertView.show()
            })
        }
    }
    
    func onReference(img: UIImage!) {
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
    }
    
    func onUpdate(img: UIImage!, withProgress progress: Int) {
//        if progress > 3 {
//            dispatch_sync(dispatch_get_main_queue(), {
//                self.iv.image = img
//                KVNProgress.updateStatus("提取轮廓中");
//            });
//            dispatch_main_after(0, block: {KVNProgress.updateProgress(0.125 * CGFloat(progress), animated: true)})
//        }
        self.progressImages.append(img)
    }
    
    func imageViewTouch(){
    }
    
    func captureImageDidFinish(image: UIImage) {
        saveImg(image)
    }
    
    func dispatch_main_after(delay:NSTimeInterval, block:dispatch_block_t)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(UInt64(delay) * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
    }

    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
    }
    
}

