//
//  OpenCV.m
//  HelloWorld
//
//  Created by Neil on 15/5/1.
//  Copyright (c) 2015年 Neil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenCV.h"
#import <opencv2_contrib/xfeatures2d/nonfree.hpp>

using namespace cv;
using namespace std;

#define RIGHTTOLEFT 3
#define LEFTTORIGHT 2
#define UPTODOWN 1
#define DOWNTOUP 0
static Mat mask;
static Mat mask2;

@implementation MyOpenCV {
@protected
    UIImage * frontEdge;
    UIImage * flankEdge;
    
    float bust_len_flank;
    float bust_len_front;
    
    float waist_len_flank;
    float waist_len_front;
    
    float arm_len;
    float neck_front;
    float neck_flank;
    
    float hip_front;
    float hip_flank;
    
    float crotch_front;
    float crotch_flank;
    
    float sleeveLen;
    float bodyLen;
    float shoulderLen;
    float trouserLen;
    float innerTrouserLen;
    
    float hip_to_top;
    float crotch_to_top;
    float upper_leg_to_top;
    float lower_leg_to_top;
    float ankle_to_top;
    float bust_to_top;
    float neck_to_top;
    float shoulder_low_to_top;
    float wrist_to_margin;
    
    float sleeve_front;
    float sleeve_flank;
    
    float sleeve_mid_front;
    float sleeve_mid_flank;
    
    float ankle_front;
    float ankle_flank;
    
    float frontRatio;
    
    UIImage * frontImage;
    UIImage * flankImage;
    
    UIImage *frontBackImage;
    UIImage *flankBackImage;
    
    UIImage *frontGrayImage;
    UIImage *flankGrayImage;
    std::vector<std::vector<cv::Point>> frontEdgeContour;
    std::vector<std::vector<cv::Point>> flankEdgeContour;
}

UIImageOrientation orientation;


bool SortByY( const cv::Point &p1, const cv::Point &p2)//注意：本函数的参数的类型一定要与vector中元素的类型一致
{
    return p1.y > p2.y;//升序排列
}
double getDistance(cv::Point a, cv::Point b)
{
    double distance;
    distance = powf((a.x - b.x),2) + powf((a.y - b.y),2);
    distance = sqrtf(distance);
    
    return distance;
}

void UIImageToMat(const UIImage* image, cv::Mat& m,
                  bool alphaExist)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.
                                                      CGImage);
    CGFloat cols = image.size.width, rows = image.size.height;
    orientation = image.imageOrientation;
    if  (orientation == UIImageOrientationRight) {
        cols = image.size.height;
        rows = image.size.width;
    }
    CGContextRef contextRef;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    if (CGColorSpaceGetModel(colorSpace) == 0)
    {
        m.create(rows, cols, CV_8UC1);
        //8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone;
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNone;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows,
                                           8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    else
    {
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
            kCGBitmapByteOrderDefault;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows,
                                           8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows),
                       image.CGImage);
    CGContextRelease(contextRef);
}


UIImage* MatToUIImage(const cv::Mat& image)
{
    NSData *data = [NSData dataWithBytes:image.data length:image.
                    elemSize()*image.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(image.cols,   //width
                                        
                                        image.rows,   //height
                                        8,            //bits percomponent
                                        8*image.elemSize(),//bits
                                        
                                        image.step.p[0],   //
                                        
                                        colorSpace,   //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,//
                                        provider,     //
                                        //CGDataProviderRef
                                        NULL,         //decode
                                        false,        //should
                                        //interpolate
                                        kCGRenderingIntentDefault
                                        //intent
                                        );
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1 orientation:orientation];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}



// resize image, keep the W/H ratio
- (UIImage *) resizeImg:(UIImage *)src withWidth:(double) width {
    Mat srcMat;
    UIImageToMat(src, srcMat, true);
    double ratio = src.size.width / src.size.height;
    cv::Size targetSize;
    if (src.imageOrientation == UIImageOrientationRight) {
        targetSize.width = width / ratio;
        targetSize.height = width;
    } else {
        targetSize.width = width;
        targetSize.height = width / ratio;
    }
    Mat dstMat = Mat(targetSize.height, targetSize.width, CV_8UC4);
    cv::resize(srcMat, dstMat, targetSize);
    
    return MatToUIImage(dstMat);
}

- (UIImage *) resizeImg:(UIImage *)src withWidth:(double) width withHeight:(double)height {
    Mat srcMat;
    UIImageToMat(src, srcMat, true);
    cv::Size targetSize;
    if (src.imageOrientation == UIImageOrientationRight) {
        targetSize.width = height;
        targetSize.height = width;
    } else {
        targetSize.width = width;
        targetSize.height = height;
    }
    Mat dstMat = Mat(targetSize.height, targetSize.width, CV_8UC4);
    cv::resize(srcMat, dstMat, targetSize);
    
    return MatToUIImage(dstMat);
}

// check if the pixel diffs a lot

bool pixelDiff(Vec3b p)
{
    int thresh = 30;
    if (p.val[0] > thresh || p.val[1] > thresh || p.val[2] > thresh) {
        return true;
    }
    if (sqrt(pow((double)p.val[0], 2) + pow((double)p.val[1], 2) + pow((double)p.val[2], 2)) > 200) {
        return true;
    }
    return false;
}
// surf

- (UIImage *)surf:(UIImage *)img1 withImg:(UIImage *)img2 withType:(int)type withThresh:(double)thresh {
    Mat result;
    Mat element(10, 10, CV_8U, Scalar::all(255));
    if ((type == 1 && !frontGrayImage) || (type == 2 && !flankGrayImage)) {
        if (type == 1) {
            if (mask.data == NULL) {
                UIImageToMat([self resizeImg:[UIImage imageNamed:@"contour"] withWidth:800 withHeight:img1.size.height], mask, true);
                std::vector<std::vector<cv::Point>> maskContour;
                cvtColor(mask, mask, COLOR_BGRA2GRAY);
                findContours(mask, maskContour, RETR_EXTERNAL,CHAIN_APPROX_NONE);
                drawContours(mask, maskContour, -1, Scalar(255), CV_FILLED);
                //            return MatToUIImage(mask);
            }
        } else {
            if (mask2.data == NULL) {
                UIImageToMat([self resizeImg:[UIImage imageNamed:@"contour2inv"] withWidth:800 withHeight:img1.size.height], mask2, true);
                std::vector<std::vector<cv::Point>> maskContour;
                cvtColor(mask2, mask2, COLOR_BGRA2GRAY);
                findContours(mask2, maskContour, RETR_EXTERNAL,CHAIN_APPROX_NONE);
                drawContours(mask2, maskContour, -1, Scalar(255), CV_FILLED);
                //            return MatToUIImage(mask);
            }
        }
        
        orientation = img1.imageOrientation;
//        img1 = [self resizeImg:img1 withWidth:800];
//        img2 = [self resizeImg:img2 withWidth:800];
        Mat trainImage;
        UIImageToMat(img1, trainImage, true);
        cvtColor(trainImage, trainImage, COLOR_BGRA2BGR);
        
        vector<KeyPoint> train_keypoint;
        Mat trainDescriptor;
        Ptr<cv::Feature2D> surf = cv::xfeatures2d::SurfFeatureDetector::create();
        surf->detect(trainImage, train_keypoint);
        Ptr<cv::xfeatures2d::SurfDescriptorExtractor> extractor = cv::xfeatures2d::SurfDescriptorExtractor::create();
        extractor->compute(trainImage, train_keypoint, trainDescriptor);
        [_delegate onUpdate:MatToUIImage(trainImage) withProgress:1];
        
        
        FlannBasedMatcher matcher;
        vector<Mat> train_desc_collection(1, trainDescriptor);
        matcher.add(train_desc_collection);
        matcher.train();
        
        Mat testImage;
        UIImageToMat(img2, testImage, true);
        cvtColor(testImage, testImage, COLOR_BGRA2BGR);
        
        vector<KeyPoint> test_keypoint;
        Mat testDescriptor;
        surf->detect(testImage, test_keypoint);
        extractor->compute(testImage, test_keypoint, testDescriptor);
        [_delegate onUpdate:MatToUIImage(testImage) withProgress:2];
        
        vector<vector<DMatch>> matches;
        matcher.knnMatch(testDescriptor, matches, 2);
        
        vector<DMatch> goodMatches;
        for (unsigned i = 0; i < matches.size(); i ++) {
            if (matches[i][0].distance < 0.6 * matches[i][1].distance) {
                goodMatches.push_back(matches[i][0]);
            }
        }
        
        Mat dstImage;
        drawMatches(testImage, test_keypoint, trainImage, train_keypoint, goodMatches, dstImage, Scalar(0, 255, 0));
        [_delegate onUpdate:MatToUIImage(dstImage) withProgress:3];
        
        surf.release();
        extractor.release();
        std::vector<Point2f> scene1;
        std::vector<Point2f> scene2;
        for (unsigned i = 0; i < goodMatches.size(); i++) {
            scene1.push_back(train_keypoint[goodMatches[i].trainIdx].pt);
            scene2.push_back(test_keypoint[goodMatches[i].queryIdx].pt);
        }
        
        Mat H = findHomography(scene2, scene1, RANSAC);
        
        
        Mat transformed;
        testImage.copyTo(transformed);
        UIImage *image = MatToUIImage(transformed);
        if (orientation == UIImageOrientationRight) {
            cv::warpPerspective(testImage, transformed, H, cv::Size(image.size.height, image.size.width));
            for (int i = 0; i < transformed.rows; i++) {
                for (int j = 0; j < transformed.cols; j++) {
                    if (transformed.at<Vec4i>(i, j).val[3] == 0) {
                        transformed.at<Vec4i>(i, j).val[0] = testImage.at<Vec4i>(i, j).val[0];
                        transformed.at<Vec4i>(i, j).val[1] = testImage.at<Vec4i>(i, j).val[1];
                        transformed.at<Vec4i>(i, j).val[2] = testImage.at<Vec4i>(i, j).val[2];
                        transformed.at<Vec4i>(i, j).val[3] = testImage.at<Vec4i>(i, j).val[3];
                    }
                }
            }
        } else {
            cv::warpPerspective(testImage, transformed, H, cv::Size(image.size.width, image.size.height));
            for (int i = 0; i < transformed.cols; i++) {
                for (int j = 0; j < transformed.rows; j++) {
                    if (transformed.at<Vec4i>(i, j).val[3] == 0) {
                        transformed.at<Vec4i>(i, j).val[0] = testImage.at<Vec4i>(i, j).val[0];
                        transformed.at<Vec4i>(i, j).val[1] = testImage.at<Vec4i>(i, j).val[1];
                        transformed.at<Vec4i>(i, j).val[2] = testImage.at<Vec4i>(i, j).val[2];
                        transformed.at<Vec4i>(i, j).val[3] = testImage.at<Vec4i>(i, j).val[3];
                    }
                }
            }
        }
        
        [_delegate onUpdate:MatToUIImage(transformed) withProgress:4];
        
        cvtColor(trainImage, trainImage, COLOR_BGR2HSV);
        cvtColor(transformed, transformed, COLOR_BGR2HSV);
        result = transformed;
        absdiff(trainImage, transformed, result);
        [_delegate onUpdate:MatToUIImage(result) withProgress:5];
        
        cvtColor(result, result, COLOR_BGR2GRAY);
        morphologyEx(result, result, MORPH_OPEN, element);
        //    morphologyEx(result, result, MORPH_CLOSE, element);
        // 绘制轮廓
        if (type == 1) {
            for (int i = 0; i < mask.rows; i++) {
                for (int j = 0; j < mask.cols; j++) {
                    if (mask.at<UInt8>(i, j) < 128) {
                        if (img1.imageOrientation != UIImageOrientationRight) {
                            result.at<UInt8>(i, j) = 0;
                        } else {
                            result.at<UInt8>(j, i) = 0;
                        }
                    }
                }
            }
            frontGrayImage = MatToUIImage(result);
        } else {
            for (int i = 0; i < mask2.rows; i++) {
                for (int j = 0; j < mask2.cols; j++) {
                    if (mask2.at<UInt8>(i, j) < 128) {
                        if (img1.imageOrientation != UIImageOrientationRight) {
                            result.at<UInt8>(i, j) = 0;
                        } else {
                            result.at<UInt8>(j, i) = 0;
                        }
                    }
                }
            }
            flankGrayImage = MatToUIImage(result);
            if (type == 2) {
                [_delegate onProcessed:flankGrayImage];
//                return flankGrayImage;
            }
        }
    } else {
        if (type == 1) {
            UIImageToMat(frontGrayImage, result, true);
        } else {
            UIImageToMat(flankGrayImage, result, true);
        }
    }
    [_delegate onUpdate:MatToUIImage(result) withProgress:6];
//    [_delegate onProcessed:MatToUIImage(result)];
//    return MatToUIImage(result);
//    equalizeHist(result, result);
    for (int i = 0; i < result.rows; i++) {
        for (int j = 0; j < result.cols; j++) {
            result.at<UInt8>(i, j) *= 1.5;
        }
    }
    threshold(result, result, thresh, 255, THRESH_BINARY);
    morphologyEx(result, result, MORPH_CLOSE, element);
//    Canny(result, result, 50, 2 * 40, 3, true);
//    adaptiveThreshold(result, result, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY_INV, 11, 8);
    
    [_delegate onUpdate:MatToUIImage(result) withProgress:7];
    
    Mat mat_contours(result.size(),CV_8U,Scalar(0));
    Mat edge_contours(result.size(),CV_8U,Scalar(0));
//    Canny(result, result, 50, 3 * 50, 3, true);
    
    std::vector<std::vector<cv::Point>> contours;
    findContours(result, contours, RETR_EXTERNAL,CHAIN_APPROX_NONE);
    
//    std::vector<std::vector<cv::Point>> true_contours;
//    vector<Vec4i> lines;
//    unsigned long edge_i = 0;
//    for (int i = 0; i < contours.size(); ++i) { // find the biggest contour
////        if (contours[i].size() > max) {
////            max = contours[i].size();
////            true_i = i;
////        }
//        true_contours.push_back(contours[i]);
//        drawContours(edge_contours, true_contours, -1, Scalar(255), 1);
//        HoughLinesP(edge_contours, lines, 1, CV_PI / 180, 80, mat_contours.cols / 2 );
//        true_contours.clear();
//        if (lines.size() > 0) {
//            edge_i = i;
//        }
//    }
//
//    for (int i = 0; i < contours.size(); ++i) { //
//        if (i != edge_i) {
//            true_contours.push_back(contours[i]);
//        }
//    }
//    
    drawContours(mat_contours, contours, -1, Scalar(255), 1);
    
    morphologyEx(mat_contours, mat_contours, MORPH_CLOSE, element);

    findContours(mat_contours, contours, RETR_EXTERNAL,CHAIN_APPROX_NONE);
    std::vector<std::vector<cv::Point>> true_contours;
    unsigned long true_i = 0, max = 0;
    for (int i = 0; i < contours.size(); ++i) { // find the biggest contour
        if (contours[i].size() > max) {
            max = contours[i].size();
            true_i = i;
        }
    }
    true_contours.push_back(contours[true_i]);
    drawContours(edge_contours, true_contours, -1, Scalar(255), 1);
    [_delegate onUpdate:MatToUIImage(edge_contours) withProgress:8];
    if (type == 1) {
        frontEdge = MatToUIImage(edge_contours);
    } else {
        flankEdge = MatToUIImage(edge_contours);
    }
    if (type == 1) {
        frontEdgeContour = true_contours;
        [_delegate onProcessed:frontEdge];
        return frontEdge;
    } else {
        flankEdgeContour = true_contours;
        [_delegate onProcessed:flankEdge];
        return flankEdge;
    }
}


// 基于提取的轮廓返回比例尺
// args[0]: 人体轮廓图, args[1]: 实际身高
// return: 实际/图片 比例尺
double  getRatio(UIImage * image, double length) //actual cm / virtual pixel
{
    Mat image_mat;
    UIImageToMat(image, image_mat, false);
    cv::Rect r;//矩形包围轮廓
    r = boundingRect(image_mat);//用矩形包围轮廓
    
    float pixel_width = r.br().y - r.tl().y;
    return length / pixel_width;
}

std::vector<cv::Point> crossPointsY(int y, Mat contour)
{
    std::vector<cv::Point> results;
    for (int i = 0; i < contour.cols; ++i) {
        if (contour.at<UInt8>(y, i) != 0) {
            results.push_back(cv::Point(i, y));
        }
    }
    return results;
}

std::vector<cv::Point> crossPointsX(int x, Mat contour)
{
    std::vector<cv::Point> results;
    for (int i = 0; i < contour.rows; ++i) {
        if (contour.at<UInt8>(i, x) != 0) {
            results.push_back(cv::Point(x, i));
        }
    }
    return results;
}

int getLinePixels(Mat contour, const int& x, const int& y)
{
    // y方向
    if (y == -1) {
        int i = 0, j = 0;
        for (i = 0; i < contour.rows; ++i) {
            if (contour.at<UInt8>(i, x) != 0) {
                break;
            }
        }
        if (i == contour.rows) {
            return -1;
        }
        for (j = contour.rows - 1; j >= 0; j --) {
            if (contour.at<UInt8>(j, x)) {
                break;
            }
        }
        return j - i;
    } else {
        int i = 0, j = 0;
        for (i = 0; i < contour.cols; ++i) {
            if (contour.at<UInt8>(y, i) != 0) {
                break;
            }
        }
        if (i == contour.cols) {
            return -1;
        }
        for (j = contour.cols - 1; j >= 0; j --) {
            if (contour.at<UInt8>(y, j)) {
                break;
            }
        }
        return j - i;
    }
}

int findMin(Mat contour_filled, const int& start_y, const int& end_y)
{
    int min = INT_MAX;
    int min_pos_y = 0;
    for (int j = start_y; j < end_y; ++j) {
        int cnt = 0;
        for (int i = 0; i < contour_filled.cols; i++)
        {
            if (contour_filled.at<UInt8>(j, i) != 0) {
                cnt++;
            }
        }
//        int cnt = getLinePixels(contour_filled, -1, j);
        if (cnt < min) {
            min_pos_y = j;
            min = cnt;
        }
    }
    return  min_pos_y;
}

int findMinX(Mat contour_filled, const int& start_x, const int& end_x)
{
    int min = INT_MAX;
    int min_pos_x = 0;
    for (int j = start_x; j < end_x; ++j) {
        int cnt = 0;
        for (int i = 0; i < contour_filled.rows; i++)
        {
            if (contour_filled.at<UInt8>(i, j) != 0) {
                cnt++;
            }
        }
//        int cnt = getLinePixels(contour_filled, j, -1);
        if (cnt < min) {
            min_pos_x = j;
            min = cnt;
        }
    }
    return  min_pos_x;
}

int findMax(Mat contour_filled, const int& start_y, const int& end_y)
{
    int max = 0;
    int max_pos_y = 0;
    for (int j = start_y; j < end_y; ++j) {
        int cnt = 0;
        for (int i = 0; i < contour_filled.cols; i++)
        {
            if (contour_filled.at<UInt8>(j, i) != 0) {
                cnt++;
            }
        }
//        int cnt = getLinePixels(contour_filled, -1, j);
        if (cnt > max) {
            max_pos_y = j;
            max = cnt;
        }
    }
    return  max_pos_y;
}

int findMaxX(Mat contour_filled, const int& start_x, const int& end_x)
{
    int max = 0;
    int max_pos_x = 0;
    for (int j = start_x; j < end_x; ++j) {
        int cnt = 0;
        for (int i = 0; i < contour_filled.rows; i++)
        {
            if (contour_filled.at<UInt8>(i, j) != 0) {
                cnt++;
            }
        }
//        int cnt = getLinePixels(contour_filled, j, -1);
        if (cnt > max) {
            max_pos_x = j;
            max = cnt;
        }
    }
    return  max_pos_x;
}

// return pos
int pushToMin(Mat contour_filled, const int& start, int group_size, int dir)
{
    int min_pos = start;
    while (1) {
        std::vector<int> cnt1, cnt2;
        if (dir == LEFTTORIGHT || dir == RIGHTTOLEFT) {
            for (int j = -group_size/2; j <= group_size/2; ++j) {
                int cnt_1 = 0;
                for (int i = 0; i < contour_filled.rows; i++)
                {
                    if (contour_filled.at<UInt8>(i, min_pos+j) != 0) {
                        cnt_1++;
                    }
                }
//                int cnt_1 = getLinePixels(contour_filled, min_pos+j, -1);
                cnt1.push_back(cnt_1);
            }
            for (int j = -group_size/2; j <= group_size/2; ++j) {
                int cnt_2 = 0;
                for (int i = 0; i < contour_filled.rows; i++)
                {
                    if (contour_filled.at<UInt8>(i, min_pos+(dir == LEFTTORIGHT ? group_size:(-group_size))+j) != 0) {
                        cnt_2++;
                    }
                }
//                int cnt_2 = getLinePixels(contour_filled, min_pos+(dir == LEFTTORIGHT ? group_size:(-group_size))+j, -1);
                cnt2.push_back(cnt_2);
            }

        } else {
            for (int j = -group_size/2; j <= group_size/2; ++j) {
                int cnt_1 = 0;
                for (int i = 0; i < contour_filled.cols; i++)
                {
                    if (contour_filled.at<UInt8>(min_pos+j, i) != 0) {
                        cnt_1++;
                    }
                }
//                int cnt_1 = getLinePixels(contour_filled, -1, min_pos+j);
                cnt1.push_back(cnt_1);
            }
            for (int j = -group_size/2; j <= group_size/2; ++j) {
                int cnt_2 = 0;
                for (int i = 0; i < contour_filled.cols; i++)
                {
                    if (contour_filled.at<UInt8>(min_pos+(dir == UPTODOWN ? group_size:(-group_size))+j, i) != 0) {
                        cnt_2++;
                    }
                }
//                int cnt_2 = getLinePixels(contour_filled, min_pos+(dir == UPTODOWN ? group_size:(-group_size))+j, -1);
                cnt2.push_back(cnt_2);
            }

        }
        
        std::sort(cnt1.begin(), cnt1.end());
        std::sort(cnt2.begin(), cnt2.end());
        if (cnt1[cnt1.size() / 2] < cnt2[cnt2.size() / 2]) {
            break;
        }
        if (dir == UPTODOWN || dir == LEFTTORIGHT) {
            min_pos += group_size;
        } else {
            min_pos -= group_size;
        }
    }
    return min_pos;
}

// return pos
int pushToMax(Mat contour_filled, const int& start, int group_size, int dir)
{
    int max_pos = start;
    while (1) {
        std::vector<int> cnt1, cnt2;
        if (dir == LEFTTORIGHT || dir == RIGHTTOLEFT) {
            for (int j = -group_size/2; j <= group_size/2; ++j) {
                int cnt_1 = 0;
                for (int i = 0; i < contour_filled.rows; i++)
                {
                    if (contour_filled.at<UInt8>(i, max_pos+j) != 0) {
                        cnt_1++;
                    }
                }
                cnt1.push_back(cnt_1);
            }
            
            
            for (int j = -group_size/2; j <= group_size/2; ++j) {
                int cnt_2 = 0;
                for (int i = 0; i < contour_filled.rows; i++)
                {
                    if (contour_filled.at<UInt8>(i, max_pos + (dir == LEFTTORIGHT ? group_size:(-group_size))+j) != 0) {
                        cnt_2++;
                    }
                }
                cnt2.push_back(cnt_2);
            }
        } else {
            for (int j = -group_size/2; j <= group_size/2; ++j) {
                int cnt_1 = 0;
                for (int i = 0; i < contour_filled.cols; i++)
                {
                    if (contour_filled.at<UInt8>(max_pos+j, i) != 0) {
                        cnt_1++;
                    }
                }
                cnt1.push_back(cnt_1);
            }
            
            
            for (int j = -group_size/2; j <= group_size/2; ++j) {
                int cnt_2 = 0;
                for (int i = 0; i < contour_filled.cols; i++)
                {
                    if (contour_filled.at<UInt8>(max_pos + (dir == UPTODOWN ? group_size:(-group_size))+j, i) != 0) {
                        cnt_2++;
                    }
                }
                cnt2.push_back(cnt_2);
            }
        }
        
        std::sort(cnt1.begin(), cnt1.end());
        std::sort(cnt2.begin(), cnt2.end());
        if (cnt1[cnt1.size() / 2] > cnt2[cnt2.size() / 2]) {
            break;
        }
        
        if (dir == UPTODOWN || dir == LEFTTORIGHT) {
            max_pos += group_size;
        } else {
            max_pos -= group_size;
        }
        
    }
    return max_pos;
}


float calcR(float a, float b)
{
    if (a < b) {
        return calcR(b, a);
    }
    float pi = 3.1415926;
    float q = a + b, h = pow((a - b) / (a + b), 2), m = 22.0f / 7.0f * pi - 1, n = pow((a - b) / a, 33.697);
    return pi * q * (1 + 3 * h / (10 + pow(4 - 3 * h, 0.5))) * (1 + m * n);
}

- (NSString *) getResultString {
    NSString* string;
    string = [[NSString alloc]  initWithFormat:@"肩宽:%f\n胸围:%f\n腰围:%f\n袖长:%f\n身长:%f\n臀围:%f\n袖肥:%f\n袖中肥:%f\n裤长:%f\n内裤长:%f\n裤脚肥:%f\n", [self shoulderLen],[self getBustRound], [self getWaistRound],[self sleeveLen],[self bodyLen],[self getHipRound],[self getSleeveRound],[self getSleeveMidRound],[self trouserLen],[self innerTrouserLen],[self getAnkleRound]];
    return string;
}

- (id) init
{
    return  self;
}

- (id) reset {
    frontEdge = nil;
    flankEdge = nil;
    
    bust_len_flank = 0;
    bust_len_front = 0;
    
    waist_len_flank = 0;
    waist_len_front = 0;
    
    arm_len = 0;
    neck_front = 0;
    neck_flank = 0;
    
    hip_front = 0;
    hip_flank = 0;
    
    crotch_front = 0;
    crotch_flank = 0;
    
    sleeveLen = 0;
    bodyLen = 0;
    shoulderLen = 0;
    trouserLen = 0;
    innerTrouserLen = 0;
    
    hip_to_top = 0;
    crotch_to_top = 0;
    upper_leg_to_top = 0;
    lower_leg_to_top = 0;
    ankle_to_top = 0;
    wrist_to_margin = 0;
    
    sleeve_front = 0;
    sleeve_flank = 0;
    
    sleeve_mid_front = 0;
    sleeve_mid_flank = 0;
    
    ankle_front = 0;
    ankle_flank = 0;
    
    frontImage = nil;
    flankImage = nil;
    
    frontBackImage = nil;
    flankBackImage = nil;
    
    return  self;
}

- (UIImage *) frontImage
{
    return frontImage;
}

-(void) setFrontImage: (UIImage *) img
{
    frontImage = [self resizeImg:img withWidth:800];
}

- (UIImage *) frontBackImage
{
    return frontBackImage;
}

- (void) setFrontBackImage:(UIImage *)img
{
    frontBackImage = [self resizeImg:img withWidth:800];
}

- (UIImage *) flankImage
{
    return flankImage;
}

-(void) setFlankImage: (UIImage *) img
{
    flankImage = [self resizeImg:img withWidth:800];
}

- (UIImage *) flankBackImage
{
    return flankBackImage;
}

- (void) setFlankBackImage:(UIImage *)img
{
    flankBackImage = [self resizeImg:img withWidth:800];
}

- (UIImage *) frontEdge
{
    return frontEdge;
}

- (UIImage *) flankEdge
{
    return flankEdge;
}

- (float) getBustRound
{
    if (bust_len_flank == 0 || bust_len_front == 0) {
        return 0;
    }
    return calcR(bust_len_front/2, bust_len_flank/2);
}

- (float) getWaistRound
{
    return (15.458 + 0.481 * waist_len_front + 2.514 * waist_len_flank);
}

- (float) getHipRound
{
    return calcR(hip_front/2, hip_flank/2);
//    return 97.63;
}

- (float) getCrotchRound
{
        return calcR(crotch_front/2, crotch_flank/2);
}

- (float) getSleeveRound
{
    return calcR(sleeve_front / 2, sleeve_front * 0.618 / 2);
}

- (float) getSleeveMidRound
{
    return calcR(sleeve_mid_flank / 2, sleeve_mid_front / 2);
}

- (float) getAnkleRound
{
    return calcR(ankle_front / 2, ankle_flank / 2);
}

- (float) shoulderLen {
    return  shoulderLen;
}

- (float) sleeveLen {
    return sleeveLen;
}

- (float) bodyLen {
    return bodyLen;
}

- (float) trouserLen {
    return  trouserLen;
}

- (float) innerTrouserLen {
    return innerTrouserLen;
}
- (UIImage *) flankAnalyze
{
    @try {
        if (!flankImage || _height == 0) {
            return nil;
        }
        Mat result, contour;
//        double ratio = getRatio(flankEdge, _height);
        UIImageToMat(flankImage, result, false);
        UIImageToMat(flankEdge, contour, false);
        Mat contour_filled(contour.size(),CV_8U,Scalar(0));
        if (flankImage.imageOrientation == UIImageOrientationRight) {
            transpose(result, result);
            flip(result, result, 1);
            transpose(contour, contour);
            flip(contour, contour, 1);
            transpose(contour_filled, contour_filled);
            flip(contour_filled, contour_filled, 1);
        }
            
        std::vector<std::vector<cv::Point>> contours = flankEdgeContour;
        drawContours(contour_filled, contours, -1, Scalar(255), FILLED);
        
        cv::Rect r = boundingRect(contour);
        //TODO 判断朝向
    //    int cnt = 0;
    //    for (int i = 0; i < contour.rows; ++i) {
    //        if (contour_filled.at<UInt8>(i, (r.br().x + r.tl().x) / 2) != 0 ) {
    //            cnt++;
    //        }
    //    }
        
        int min_pos_y = 0, min_pos_x = 0, max_pos_x = 0;
    //    std::vector<cv::Point> poly;
    //    std::vector<cv::Point> candidates;
        
    //    approxPolyDP(contours[0], poly, MAX(flankImage.size.width, flankImage.size.height) / 40,true);
    //    std::vector<cv::Point>::const_iterator itp = poly.begin();
    //
    ////    assert(poly.size() >  MAX(flankImage.size.width, flankImage.size.height) / 40.0); // 确保轮廓有效
    //    while (itp != (poly.end() - 1))
    //    {
    //        float x1 = (itp)->x, x2 = (itp+1)->x;
    //        float y1 = (itp)->y, y2 = (itp+1)->y;
    //        if (x1 != x2 && abs((y2 - y1) / (x2 - x1)) < 0.5 && y1 < flankImage.size.height/2)  { //找到一些候选点
    //            candidates.push_back(y1>y2? cv::Point(x1, y1):cv::Point(x2, y2));
    //        }
    //        ++itp;
    //    }
    //    sort(candidates.begin(), candidates.end(), SortByY);
        
        /* --------------sleeve--------------*/
       
        int lcol;
        for (lcol = r.tl().x + wrist_to_margin * r.width; lcol <  flankImage.size.width; lcol += 5) {
            vector<cv::Point> lrows = crossPointsX(lcol, contour);
            int lrow = lrows[lrows.size() - 1].y;
            vector<cv::Point> lrows_5 = crossPointsX(lcol + 5, contour);
            int lrow_5 = lrows_5[lrows_5.size() - 1].y;
            if(((double)(lrow_5-lrow))/5>1.732)
                break;
        }
        std::vector<cv::Point> shoulder_pts_left = crossPointsX(lcol, contour);

    //    min_pos_x = pushToMin(contour_filled, shoulder_pts_left[0].x, 5, RIGHTTOLEFT);
    //    max_pos_x = r.tl().x + r.width * wrist_to_margin;
    //    max_pos_x = findMaxX(contour_filled, max_pos_x, min_pos_x);
        max_pos_x = (shoulder_pts_left[0].x + r.tl().x) / 2;
        std::vector<cv::Point> sleeve_mid_pts = crossPointsX(max_pos_x, contour);
    //    line(result, sleeve_mid_pts[0], sleeve_mid_pts[1], Scalar(255), 3);
        sleeve_mid_flank = abs(sleeve_mid_pts[0].y - sleeve_mid_pts[1].y) * ratio;
        std::cout << "侧面袖中肥: " << sleeve_mid_flank << std::endl;
        
        min_pos_x = shoulder_pts_left[0].x * 0.8 + max_pos_x * 0.2;
        std::vector<cv::Point> sleeve_pts;
        sleeve_pts = crossPointsX(min_pos_x, contour);
    //    line(result, sleeve_pts[0], sleeve_pts[1], Scalar(255), 3);
        sleeve_flank = abs(sleeve_pts[0].y - sleeve_pts[1].y) * ratio;
        std::cout << "侧面袖肥: " << sleeve_flank << std::endl;
        
//        cv::Point left_point = shoulder_pts_left[1]; // 腋窝点
//        cv::Point wrist_point, right_point;

        //---------手腕点-------------//
    //    for (int unsigned j = 0; j < poly.size(); j++) {
    //        if (poly[j] == left_point) {
    //            cv::Point temp = left_point;
    //            int tempj = j;
    //            while (abs((poly[tempj-1].y- poly[tempj].y) / (poly[tempj-1].x - poly[tempj].x)) < 0.5) {
    //                tempj--;
    //            }
    //            wrist_point = poly[tempj];
    //        }
    //    }
//        int i = 0;
//        for (i = left_point.x + flankImage.size.width/20; i < flankImage.size.width ; i++) {
//            if (contour.at<UInt8>(left_point.y, i) != 0) {
//                break;
//            }
//        }
//        
//        // 后背对应腋窝高度的点
//        right_point.x = i;
//        right_point.y = left_point.y;
    //    line(result, left_point, right_point, Scalar(255), 5);
        
    //    line(result, left_point, wrist_point, Scalar(255), 5);
    //    arm_len = getDistance(left_point, wrist_point);
    //    std::cout << "手臂长：" << arm_len * ratio<< std::endl;
        
        // 通过原轮廓精确测量
//        cv::Point bust_middle = cv::Point((shoulder_pts_left[0].x+right_point.x)/2, left_point.y+5 / ratio);
//        cv::Point bust_right = bust_middle, bust_left = bust_middle;
//        while (contour.at<UInt8>(bust_right.y, bust_right.x++) == 0) {
//        }
//        while (contour.at<UInt8>(bust_left.y, bust_left.x--) == 0) {
//        }
        
        // neck
        std::vector<cv::Point> neck_pts;
        int neck_to_top_pixel = neck_to_top / ratio + r.tl().y;
        neck_pts = crossPointsY(findMin(contour_filled, neck_to_top_pixel - 5 / ratio, neck_to_top_pixel + 5 / ratio), contour);
    //    line(result, neck_pts[1], neck_pts[0], Scalar(255), 3);
        neck_flank = (neck_pts[1].x - neck_pts[0].x) * ratio;
        std::cout << "领口侧宽：" << neck_flank << std::endl;
        
        // bust
        std::vector<cv::Point> bust_pts;
        bust_pts = crossPointsY(shoulder_pts_left[1].y + 3/ratio, contour);
        line(result, bust_pts[0], bust_pts[bust_pts.size()-1], Scalar(255, 0, 0), 3);
        bust_len_flank = (bust_pts[1].x-bust_pts[0].x) * ratio;
        std::cout << "胸侧宽：" << bust_len_flank << std::endl;

//        line(result, shoulder_pts_left[0], shoulder_pts_left[1], Scalar(255, 0, 0), 3);
        // waist
        std::vector<cv::Point> waist_pts;
        min_pos_y = findMin(contour_filled, shoulder_pts_left[1].y + r.height / 6 - 5 / ratio,
                            shoulder_pts_left[1].y + r.height / 6 + 5 / ratio);
        waist_pts = crossPointsY(min_pos_y, contour);
        line(result, waist_pts[0], waist_pts[waist_pts.size()-1], Scalar(0,255,0), 3);
        waist_len_flank = (waist_pts[1].x - waist_pts[0].x) * ratio;
        std::cout<< "腰侧宽：" <<waist_len_flank << std::endl;
        
        //crotch
        std::vector<cv::Point> crotch_pts;
        crotch_pts = crossPointsY(crotch_to_top * r.height + r.tl().y, contour);
//        line(result, crotch_pts[0], crotch_pts[1], Scalar(255), 3);
        crotch_flank = (crotch_pts[crotch_pts.size()-1].x - crotch_pts[0].x) * ratio;
        
        std::vector<cv::Point> hip_pts;
        // hip
        Mat waist_to_down = contour(Range(waist_pts[0].y, waist_pts[0].y + 30/ratio), Range(0, frontImage.size.width - 1));
        int iter = frontImage.size.width - 1;
        vector<cv::Point> hip_right_pt;
        for (; iter > 0; iter--) {
            hip_right_pt = crossPointsX(iter, waist_to_down);
            if (hip_right_pt.size() > 0) {
                break;
            }
            hip_right_pt.clear();
        }
//        if (hip_right_pt.size() == 1) {
//            hip_pts = crossPointsY(hip_right_pt[0].y, contour);
//        } else {
//            hip_pts = hip_right_pt;
//        }

        hip_pts = crossPointsY(hip_right_pt[0].y + waist_pts[0].y, contour);
        line(result, hip_pts[0], hip_pts[hip_pts.size()-1], Scalar(0, 0, 255), 3);
        hip_flank = (hip_pts[hip_pts.size()-1].x - hip_pts[0].x) * ratio;
        std::cout<< "臀侧宽：" <<hip_flank << std::endl;
        
        // front waist
        Mat front_contour;
        UIImageToMat(frontEdge, front_contour, false);
        cv::Rect r_front = boundingRect(front_contour);
        std::vector<cv::Point> waist_front_pts = crossPointsY(hip_to_top * r_front.height + r_front.tl().y - (hip_pts[0].y - waist_pts[0].y), front_contour);
        line(result, waist_front_pts[1], waist_front_pts[0], Scalar::all(arc4random() % 255), 3);
        waist_len_front = (waist_front_pts[waist_front_pts.size()-1].x - waist_front_pts[0].x) * ratio;
        std::cout << "腰正宽：" << waist_len_front << std::endl;
        
        vector<cv::Point> hip_front_pts =
        //knee
//        std::vector<cv::Point>knee_pts;
//        min_pos_y = pushToMin(contour_filled, hip_pts[0].y, 3, UPTODOWN);
//        knee_pts = crossPointsY(min_pos_y, contour);
    //    line(result, knee_pts[0], knee_pts[1], Scalar(255), 3);
        
        //upper_leg
//        std::vector<cv::Point> upper_leg_pts;
//        upper_leg_pts = crossPointsY(knee_pts[0].y - 8 / ratio, contour);
//    //    line(result, upper_leg_pts[0], upper_leg_pts[1], Scalar(255), 3);
//        
//        //lower_leg
//        std::vector<cv::Point> lower_leg_pts;
//        max_pos_y = pushToMax(contour_filled, knee_pts[0].y, 5, UPTODOWN);
//        lower_leg_pts = crossPointsY(max_pos_y, contour);
    //    line(result, lower_leg_pts[0], lower_leg_pts[1], Scalar(255), 3);
        
        //ankle
        std::vector<cv::Point> ankle_pts;
        ankle_pts = crossPointsY(ankle_to_top * r.height + r.tl().y, contour);
    //    line(result, ankle_pts[0], ankle_pts[1], Scalar(255), 3);
        ankle_flank = ankle_front / 0.618;
        if (frontImage.imageOrientation == UIImageOrientationRight) {
            transpose(result, result);
            flip(result, result, 2);
            transpose(contour, contour);
            flip(contour, contour, 2);
        }
        trouserLen = (r.br().y - waist_pts[0].y) * ratio;
        std::cout << "裤长：" << trouserLen << std::endl;
        return MatToUIImage(result);
    }
    @catch (NSException *e) {
        return nil;
    }
}

- (UIImage *) frontAnalyze
{
    @try {
        if (!frontImage || _height == 0) {
            return nil;
        }

        srand((unsigned)time(NULL));
        
        Mat contour, result;
        int up, middle, down;
        
        ratio = getRatio(frontEdge, _height);
        UIImageToMat(frontImage, result, false);
        UIImageToMat(frontEdge, contour, false);
        Mat contour_filled(contour.size(),CV_8U,Scalar(0));
        if (frontImage.imageOrientation == UIImageOrientationRight) {
            transpose(result, result);
            flip(result, result, 1);
            transpose(contour, contour);
            flip(contour, contour, 1);
            transpose(contour_filled, contour_filled);
            flip(contour_filled, contour_filled, 1);
        }
        
        cv::Rect r = boundingRect(contour);
        
        std::vector<cv::Point> poly;
//        std::vector<cv::Point> candidates; //腋下 腋上 四个点
        std::vector<cv::Point> fingerTips; // 指尖
        std::vector<std::vector<cv::Point>> contours = frontEdgeContour;
        // 填充轮廓
        
        drawContours(contour_filled, contours, -1, Scalar(255), FILLED);

        fingerTips.push_back(crossPointsX(r.tl().x + 1, contour)[0]);
        fingerTips.push_back(crossPointsX(r.br().x - 1, contour)[0]);
//        approxPolyDP(contours[0], poly, MAX(frontImage.size.width, frontImage.size.height) / 40,true);
//        std::vector<cv::Point>::const_iterator itp = poly.begin();
//        while (itp != (poly.end() - 1))
//        {
//            float x1 = (itp)->x, x2 = (itp+1)->x;
//            float y1 = (itp)->y, y2 = (itp+1)->y;
//            if (x1 != x2 && abs((y2 - y1) / (x2 - x1)) < 0.5 && y1 < frontImage.size.height/2)  { //找到一些候选点
//                if (x1 > frontImage.size.width/4 && x1 < 3*frontImage.size.width/4 && x2 > frontImage.size.width/4 && x2 < 3*frontImage.size.width/4) {
//                    candidates.push_back(y1>y2? cv::Point(x1, y1):cv::Point(x2, y2));
//                }
//                else {
//                    if (x1 > frontImage.size.width/4 && x1 < 3*frontImage.size.width/4) {
//                        candidates.push_back(cv::Point(x1, y1));
//                    }
//                    if (x2 > frontImage.size.width/4 && x2 < 3*frontImage.size.width/4) {
//                        candidates.push_back(cv::Point(x2, y2));
//                    }
//                }
//            }
//            ++itp;
//        }
//        
//        sort(candidates.begin(), candidates.end(), SortByY);
//    //    line(result, candidates[0], candidates[2], Scalar(255), 3);
//        unsigned long i = candidates.size() - 1;
//        if (candidates.size() >= 4) {
//            while (candidates[i--].y < r.tl().y + 10 / ratio) {
//            }
//    //        line(result, candidates[i], candidates[i+1], Scalar(255), 3);
//        } else {
//            return nil;
//        }

        /* -------------neck------------ */
    //    int x = (candidates[2].x + candidates[3].x)/2;
        int min_pos_y = 0, max_pos_y = 0, max_pos_x = 0;
//        int start_y = (candidates[2].y + candidates[3].y)/2;
//        int end_y = start_y-20/ratio;
        
        std::vector<cv::Point> neck_pts;
        min_pos_y = findMin(contour_filled, r.tl().y + 15 / ratio, r.tl().y + 55 / ratio);
        neck_pts = crossPointsY(min_pos_y, contour);
        neck_to_top = (neck_pts[0].y - r.tl().y) * ratio;
        line(result, neck_pts[0], neck_pts[1], Scalar::all(arc4random() % 255), 3);
        neck_front = (neck_pts[1].x - neck_pts[0].x) * ratio;
        std::cout << "领口正宽: " << neck_front << std::endl;
        up = neck_pts[0].y;
    ////    std::cout<<"start_y："<<start_y<<std::endl;
    ////    std::cout<<"end_y："<<end_y<<std::endl;

    //    int left_final = 0, right_final = 0, min = INT_MAX, max = 0;
    //    for (int i = start_y; i>end_y; i--) {
    //        int right = x, left = x;
    //        while (contour.at<UInt8>(i, right++) == 0) {
    //        }
    //        while (contour.at<UInt8>(i, left--) == 0) {
    //        }
    //        if (right - left < min) {
    //            min = right - left;
    //            right_final = right;
    //            left_final = left;
    //            start_y = i;
    //        }
    //    }
    //    line(result, cv::Point(left_final, start_y), cv::Point(right_final, start_y), Scalar(255), 3);
    //    std::cout<<"T1："<<min*ratio<<std::endl;
    //    
    //    end_y = r.tl().y+5/ratio;
    //    int y =0;
    //    for (int i = start_y; i>end_y; i--) {
    //        int right = x, left = x;
    //        while (contour.at<UInt8>(i, right++) == 0) {
    //        }
    //        while (contour.at<UInt8>(i, left--) == 0) {
    //        }
    //        if (right - left > max) {
    //            max = right - left;
    //            right_final = right;
    //            left_final = left;
    //            y = i;
    //        }
    //    }
    //    line(result, cv::Point(left_final, y), cv::Point(right_final, y), Scalar(255), 3);
    //    std::cout<<"T2："<<max*ratio<<std::endl;
    //    neck_len = (min+max) / 2 *ratio;
    //    std::cout << "领口宽: " << neck_len << std::endl;
    //    shoulderLen = abs(candidates[0].x-candidates[1].x) * ratio;
    //    std::cout << "肩宽: " << abs(candidates[0].x-candidates[1].x) * ratio << std::endl;
       
        /*----------------wrist_to_margin----------------*/
        max_pos_x = r.br().x - 10 / ratio;
        max_pos_x = findMinX(contour_filled, max_pos_x - 20.0 / ratio, max_pos_x);
        std::vector<cv::Point> wrist_pts;
        wrist_pts = crossPointsX(max_pos_x, contour);
        wrist_to_margin = (r.br().x - max_pos_x) * 1.0f / r.width;
        
        
        

         /*----------------shoulder------------*/
        int lcol, rcol;
        for (lcol = r.tl().x + wrist_to_margin * r.width; lcol <  frontImage.size.width; lcol += 5) {
            int lrow = crossPointsX(lcol, contour)[1].y;
            int lrow_5 = crossPointsX(lcol + 5, contour)[1].y;
            if(((double)(lrow_5-lrow))/5>1.732)
                break;
        }
        for(rcol = r.br().x - wrist_to_margin * r.width; rcol > 0; rcol -= 5){
            int rrow = crossPointsX(rcol, contour)[1].y;
            int rrow_5 = crossPointsX(rcol - 5, contour)[1].y;
            if(((double)(rrow_5-rrow))/5>1.732)
                break;
        }
        shoulderLen = (rcol - lcol) * ratio;
        std::vector<cv::Point> shoulder_pts_left = crossPointsX(lcol, contour);
        std::vector<cv::Point> shoulder_pts_right = crossPointsX(rcol, contour);
        line(result, shoulder_pts_left[0], shoulder_pts_right[0], Scalar(0,255,0), 3);
        shoulder_low_to_top = (shoulder_pts_right[1].y - r.tl().y) * ratio;
        std::cout << "肩宽: " << shoulderLen << std::endl;

        
        line(result, shoulder_pts_left[1], shoulder_pts_right[1], Scalar(255,255,0), 3);
        /* -------------bust------------*/
        std::vector<cv::Point> bust_pts;
        bust_pts = crossPointsY(MAX(shoulder_pts_left[1].y, shoulder_pts_right[1].y) + 5/ratio, contour);
        bust_to_top = (bust_pts[0].y - r.tl().y) * ratio;
        line(result, bust_pts[1], bust_pts[0], Scalar(255, 0, 0), 3);
        bust_len_front = (bust_pts[1].x - bust_pts[0].x) * ratio;
        std::cout << "胸正宽: " << bust_len_front<< std::endl;
        
        /*----------------sleeve------------*/
        Mat upper_body = contour(Range(0, frontImage.size.height / 2 - 1), Range(0, frontImage.size.width - 1));
        Mat upper_filled = contour_filled(Range(0, frontImage.size.height / 2 - 1), Range(0, frontImage.size.width - 1));
        
        int arm_down_right = shoulder_pts_right[0].x;
        int arm_down_left = shoulder_pts_left[0].x;
        float sleeve_right = abs(arm_down_right - max_pos_x) * ratio;
//        min_pos_x = pushToMin(contour_filled, arm_left, 5, LEFTTORIGHT);
        max_pos_x = r.tl().x + 10 / ratio;
        max_pos_x = findMinX(contour_filled, max_pos_x + 20.0 / ratio, max_pos_x);
        float sleeve_left = abs(arm_down_left - max_pos_x) * ratio;
        
        sleeveLen = MAX(sleeve_left, sleeve_right);
        
        max_pos_x = (r.br().x + arm_down_right) / 2;
        std::vector<cv::Point> sleeve_mid_pts;
        sleeve_mid_pts = crossPointsX(max_pos_x, upper_body);
        line(result, sleeve_mid_pts[0], sleeve_mid_pts[sleeve_mid_pts.size()-1], Scalar::all(arc4random() % 255), 3);
        sleeve_mid_front = abs(sleeve_mid_pts[0].y - sleeve_mid_pts[1].y) * ratio;
        std::cout << "正面袖中肥: " << sleeve_mid_front << std::endl;
        
        std::vector<cv::Point> sleeve_pts;
        sleeve_pts = crossPointsX(sleeve_mid_pts[0].x * 0.2 + arm_down_right * 0.8, upper_body);
        //    assert(sleeve_pts.size() == 2);
        line(result, sleeve_pts[0], sleeve_pts[sleeve_pts.size()-1], Scalar::all(arc4random() % 255), 3);
        sleeve_front = abs(sleeve_pts[0].y-sleeve_pts[1].y) * ratio;
        std::cout << "正面袖肥: " << sleeve_front << std::endl;
        
        /* -------------waist------------*/
//        min_pos_y = findMin(contour_filled, shoulder_pts_left[1].y + r.height / 6 - 8 / ratio,
//                            shoulder_pts_left[1].y + r.height / 6 + 8 / ratio);
//        std::vector<cv::Point> waist_pts = crossPointsY(min_pos_y, contour);
////        line(result, waist_pts[1], waist_pts[0], Scalar::all(arc4random() % 255), 3);
//        waist_len_front = (waist_pts[1].x - waist_pts[0].x) * ratio;
//        std::cout << "腰宽：" << waist_len_front << std::endl;
        
        /* -------------crotch------------*/
        std::vector<cv::Point> crotch_pts;
        int start_y = r.br().y - 15 / ratio;
        while (1) {
            int cnt = 0;
            for (int i = 0; i < frontImage.size.width; i++)
            {
                if (contour.at<UInt8>(start_y, i) != 0) {
                    crotch_pts.push_back(cv::Point(i, start_y));
                    cnt++;
                }
            }
            if (cnt < 3) {
                break;
            }
            crotch_pts.clear();
            start_y--;
        }
//        int end_y = r.br().y - 5.0f/ratio;

    //    assert(crotch_pts.size() == 3);
        for (int i = 0; i < crotch_pts.size(); i++) {
            crotch_pts[i].y -= 5 / ratio;
        }
        line(result, crotch_pts[0], crotch_pts[crotch_pts.size()-1], Scalar(arc4random() % 255), 3);
        middle = crotch_pts[0].y;
        crotch_to_top = (crotch_pts[0].y - r.tl().y) * 1.0 / r.height ;
        crotch_front = (crotch_pts[crotch_pts.size()-1].x - crotch_pts[0].x) * ratio;
        
        /* -------------hip------------*/
//        std::vector<cv::Point> hip_pts;
//        max_pos_y = findMax(contour_filled, (shoulder_pts_left[1].y + shoulder_pts_left[0].y) / 2 + r.height/6, crotch_pts[0].y);
//    //    std::cout<< max_pos_y<<std::endl;
//        hip_pts = crossPointsY(max_pos_y, contour);
//    //    assert(hip_pts.size() == 2);
//        line(result, hip_pts[0], hip_pts[1], Scalar(0,0,255), 3);
//        hip_to_top = (hip_pts[0].y - r.tl().y) * 1.0 / r.height;
//        hip_front = (hip_pts[1].x - hip_pts[0].x) * ratio;
//        
        /* -------------ankle------------*/
        
        
        std::vector<cv::Point> ankle_pts;
        min_pos_y = findMin(contour_filled, crotch_pts[0].y, r.br().y - 4 / ratio);
//        min_pos_y = r.br().y - 20 / ratio;
        
        ankle_pts = crossPointsY(min_pos_y, contour);
    //    assert(ankle_pts.size() == 4);
        line(result, ankle_pts[0], ankle_pts[1], Scalar::all(arc4random() % 255), 3);
//        line(result, ankle_pts[2], ankle_pts[3], Scalar::all(arc4random() % 255), 3);
        ankle_front = abs(ankle_pts[1].x - ankle_pts[0].x) * ratio;
        down = ankle_pts[0].y;
        ankle_to_top = (ankle_pts[0].y - r.tl().y) * 1.0 / r.height;
        
         /* ---------upper_leg----------- */
        
    //    std::vector<cv::Point> upper_leg_pts;
    //    min_pos_y = pushToMin(contour_filled, start_y, 3, UPTODOWN);
    //    int offset = 8 / ratio;
    //    std::vector<cv::Point> upper_leg_pts;
    //    upper_leg_pts = crossPointsY(crotch_pts[0].y + 30 / ratio, contour);
    //    assert(upper_leg_pts.size() == 4);
    //    line(result, upper_leg_pts[0], upper_leg_pts[1], Scalar(255), 3);
    //    line(result, upper_leg_pts[2], upper_leg_pts[3], Scalar(255), 3);
    //    upper_leg_to_top = (upper_leg_pts[0].y - r.tl().y) * 1.0 / r.height;
        
        /*--------------lower_leg---------------*/
        
        std::vector<cv::Point> lower_leg_pts;
        max_pos_y = pushToMax(contour_filled, ankle_pts[0].y, 3, DOWNTOUP);
        lower_leg_pts = crossPointsY(max_pos_y, contour);
    //    assert(lower_leg_pts.size() == 4);
    //    line(result, lower_leg_pts[0], lower_leg_pts[1], Scalar(255), 3);
    //    line(result, lower_leg_pts[2], lower_leg_pts[3], Scalar(255), 3);
        lower_leg_to_top = (lower_leg_pts[0].y - r.tl().y) * 1.0 / r.height;
        
    //    std::cout<<"总宽："<<(r.br().x - r.tl().x)*ratio<<std::endl;
        
        bodyLen = (middle-up) * ratio;
        innerTrouserLen = (down-middle) * ratio;
        std::cout<<"身长："<< (middle-up) * ratio<<std::endl;
        std::cout<<"内裤长："<< (down-middle) * ratio <<std::endl;
        if (frontImage.imageOrientation == UIImageOrientationRight) {
            transpose(result, result);
            flip(result, result, 2);
            transpose(contour, contour);
            flip(contour, contour, 2);
        }
        return MatToUIImage(result);
    }
    @catch(NSException *e) {
        return nil;
    }
}

@end
