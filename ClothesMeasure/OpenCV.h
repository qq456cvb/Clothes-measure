//
//  OpenCV.h
//  HelloWorld
//
//  Created by Neil on 15/5/1.
//  Copyright (c) 2015年 Neil. All rights reserved.
//

#ifndef HelloWorld_OpenCV_h
#define HelloWorld_OpenCV_h


#endif

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol processDelegate <NSObject>

- (void) onProcessed:(UIImage *) img;
- (void) onUpdate:(UIImage *) img withProgress:(NSInteger) progress;
- (void) onReference:(UIImage *) img;

@end

@interface MyOpenCV : NSObject 
@property float height;
@property float weight;
@property (strong, nonatomic) id<processDelegate> delegate;

- (UIImage *) frontImage;
- (void) setFrontImage: (UIImage *) img;

- (UIImage *) frontBackImage;
- (void) setFrontBackImage: (UIImage *) img;

- (UIImage *) flankImage;
- (void) setFlankImage: (UIImage *) img;

- (UIImage *) flankBackImage;
- (void) setFlankBackImage: (UIImage *) img;

- (UIImage *) frontEdge;
- (UIImage *) flankEdge;

- (float) getBustRound;
- (float) getWaistRound;
- (float) getHipRound;
- (float) getCrotchRound;
- (float) getSleeveRound;
- (float) getSleeveMidRound;
- (float) getAnkleRound;
- (float) shoulderLen;
- (float) bodyLen;
- (float) neckToHipHalfLen;
- (float) sleeveLen;
- (float) trouserLen;
- (float) innerTrouserLen;
- (NSString *) getResultString;

- (id) init;
- (id) reset;
- (UIImage *) frontAnalyze;
- (UIImage *) flankAnalyze;
- (UIImage *)surf:(UIImage *)img1 withImg:(UIImage *)img2 withType:(int)type withThresh:(double)thresh;
- (UIImage *) resizeImg:(UIImage *)src withWidth:(double) width;
@end