//
//  DBCameraViewController.m
//  DBCamera
//
//  Created by iBo on 31/01/14.
//  Copyright (c) 2014 PSSD - Daniele Bogo. All rights reserved.
//

#import "DBCameraViewController.h"
#import "DBCameraManager.h"
#import "DBCameraView.h"
#import "DBCameraDelegate.h"
#import "DBCameraSegueViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface DBCameraViewController () <DBCameraManagerDelegate, DBCameraViewDelegate> {
    BOOL _processingPhoto;
    UIDeviceOrientation _deviceOrientation;
}

@property (nonatomic, strong) DBCameraView *cameraView;
@property (nonatomic, strong) NSString *pic;
@property (nonatomic, strong) id customCamera;
@property (nonatomic, strong) DBCameraManager *cameraManager;

@end

@implementation DBCameraViewController

+ (DBCameraViewController *) initWithDelegate:(id<DBCameraViewControllerDelegate>)delegate withPic:(NSString *)pic
{
    return [[self alloc] initWithDelegate:delegate cameraView:nil withPic:(NSString *)pic];
}

+ (DBCameraViewController *) init
{
    return [[self alloc] initWithDelegate:nil cameraView:nil withPic:@"contour"];
}

- (id) initWithDelegate:(id<DBCameraViewControllerDelegate>)delegate cameraView:(id)camera withPic:(NSString *)pic
{
    _pic = pic;
    self = [super init];
    
    if ( self ) {
        _processingPhoto = NO;
        _deviceOrientation = UIDeviceOrientationPortrait;
        if ( delegate )
            _delegate = delegate;
        
//        if ( camera )
//            [self setCustomCamera:camera];

//        [self setUseCameraSegue:YES];
    }
    
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
#endif
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    NSError *error;
    if ( [self.cameraManager setupSessionWithPreset:AVCaptureSessionPresetPhoto error:&error] ) {
        if ( self.customCamera ) {
            if ( [self.customCamera respondsToSelector:@selector(previewLayer)] ) {
                [(AVCaptureVideoPreviewLayer *)[self.customCamera valueForKey:@"previewLayer"] setSession:self.cameraManager.captureSession];
                
                if ( [self.customCamera respondsToSelector:@selector(delegate)] )
                    [self.customCamera setValue:self forKey:@"delegate"];
            }
            
            [self.view addSubview:self.customCamera];
        } else
            [self.view addSubview:self.cameraView];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.cameraManager performSelector:@selector(startRunning) withObject:nil afterDelay:0.0];
//    [self.cameraManager setFlashMode:AVCaptureFlashModeOn];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rotationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.cameraManager performSelector:@selector(stopRunning) withObject:nil afterDelay:0.0];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setCameraManager:nil];
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

- (DBCameraView *) cameraView
{
    if ( !_cameraView ) {
        _cameraView = [DBCameraView initWithCaptureSession:self.cameraManager.captureSession];
        _cameraView.pic = _pic;
        [_cameraView defaultInterface];
        [_cameraView setDelegate:self];
    }
    
    return _cameraView;
}

- (DBCameraManager *) cameraManager
{
    if ( !_cameraManager ) {
        _cameraManager = [[DBCameraManager alloc] init];
        [_cameraManager setDelegate:self];
    }
    
    return _cameraManager;
}

- (void) rotationChanged:(NSNotification *)notification
{
    if ( [[UIDevice currentDevice] orientation] != UIDeviceOrientationUnknown ||
         [[UIDevice currentDevice] orientation] != UIDeviceOrientationFaceUp ||
         [[UIDevice currentDevice] orientation] != UIDeviceOrientationFaceDown ) {
        _deviceOrientation = [[UIDevice currentDevice] orientation];
    }
}

#pragma mark - CameraManagerDelagate

- (void) closeCamera
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) switchCamera
{
    if ( [self.cameraManager hasMultipleCameras] )
        [self.cameraManager cameraToggle];
}

- (void) triggerFlashForMode:(AVCaptureFlashMode)flashMode
{
    if ( [self.cameraManager hasFlash] )
        [self.cameraManager setFlashMode:flashMode];
}

- (void) captureImageDidFinish:(UIImage *)image
{
    _processingPhoto = NO;
    
    if ( !self.useCameraSegue ) {
        if ( [_delegate respondsToSelector:@selector(captureImageDidFinish:)] )
            [_delegate captureImageDidFinish:image];
    } else {
        DBCameraSegueViewController *cameraSegueUseViewController = [[DBCameraSegueViewController alloc] init];
        [cameraSegueUseViewController setDelegate:self.delegate];
        [cameraSegueUseViewController setCapturedImage:image];
        [self.navigationController pushViewController:cameraSegueUseViewController animated:YES];
    }
}

- (void) captureImageFailedWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
    });
}

- (void) captureSessionDidStartRunning
{
    id camera = self.customCamera ? self.customCamera : _cameraView;
    CGRect bounds = [(UIView *)camera bounds];
    AVCaptureVideoPreviewLayer *previewLayer = self.customCamera ? (AVCaptureVideoPreviewLayer *)[self.customCamera valueForKey:@"previewLayer"] : _cameraView.previewLayer;
    CGPoint screenCenter = (CGPoint){ (bounds.size.width * .5f), (bounds.size.height * .5f) - CGRectGetMinY(previewLayer.frame) };
    if ([camera respondsToSelector:@selector(drawFocusBoxAtPointOfInterest:andRemove:)] )
        [camera drawFocusBoxAtPointOfInterest:screenCenter andRemove:NO];
    if ( [camera respondsToSelector:@selector(drawExposeBoxAtPointOfInterest:andRemove:)] )
        [camera drawExposeBoxAtPointOfInterest:screenCenter andRemove:NO];
}

#pragma mark - CameraViewDelegate

- (void) cameraViewStartRecording
{
    if ( _processingPhoto )
        return;
    
    _processingPhoto = YES;
    
    [self.cameraManager captureImageForDeviceOrientation:_deviceOrientation];
}

- (void) cameraView:(UIView *)camera focusAtPoint:(CGPoint)point
{
    if ( self.cameraManager.videoInput.device.isFocusPointOfInterestSupported ) {
        [self.cameraManager focusAtPoint:[self.cameraManager convertToPointOfInterestFrom:[[(DBCameraView *)camera previewLayer] frame]
                                                                              coordinates:point
                                                                                    layer:[(DBCameraView *)camera previewLayer]]];
        [(DBCameraView *)camera drawFocusBoxAtPointOfInterest:point andRemove:YES];
    }
}

- (void) cameraView:(UIView *)camera exposeAtPoint:(CGPoint)point
{
    if ( self.cameraManager.videoInput.device.isExposurePointOfInterestSupported ) {
        [self.cameraManager exposureAtPoint:[self.cameraManager convertToPointOfInterestFrom:[[(DBCameraView *)camera previewLayer] frame]
                                                                                 coordinates:point
                                                                                       layer:[(DBCameraView *)camera previewLayer]]];
        [(DBCameraView *)camera drawExposeBoxAtPointOfInterest:point andRemove:YES];
    }
}

#pragma mark - UIApplicationDidEnterBackgroundNotification

- (void) applicationDidEnterBackground:(NSNotification *)notification
{
    id modalViewController = self.presentingViewController;
    if ( modalViewController )
        [self dismissViewControllerAnimated:YES completion:nil];
}

@end