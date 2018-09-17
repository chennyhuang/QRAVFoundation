//
//  QRViewController.m
//  QRWeiXinDemo
//
//  Created by huangzhenyu on 15/4/25.
//  Copyright (c) 2015年 huangzhenyu. All rights reserved.
//

#import "QRViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "QRView.h"
#define kappHeight [UIScreen mainScreen].bounds.size.height
#define kappWidth [UIScreen mainScreen].bounds.size.width
@interface QRViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) AVCaptureDevice * device;
@property (strong, nonatomic) AVCaptureDeviceInput * input;
@property (strong, nonatomic) AVCaptureMetadataOutput * output;
@property (strong, nonatomic) AVCaptureSession * session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer * preview;
@property (strong, nonatomic) QRView *qrRectView;

@property (nonatomic ,strong) UIButton *backButton;
@property (nonatomic ,strong) UILabel *topMsgLabel;
@property (nonatomic ,strong) UILabel *bottomLabel;
@property (nonatomic ,assign) BOOL isAllowReceiveScanResult;
@property (nonatomic ,strong) UILabel *waitLabel;
@property (nonatomic ,strong) UIActivityIndicatorView *indicator;
@end

@implementation QRViewController

- (UIButton *)backButton{
    if (!_backButton) {
        _backButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 26, 30, 30)];
        [_backButton addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
        [_backButton setImage:[UIImage imageNamed:@"back_arrow.png"] forState:UIControlStateNormal];
    }
    return _backButton;
}

- (UILabel *)topMsgLabel{
    if (!_topMsgLabel) {
        _topMsgLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, [UIScreen mainScreen].bounds.size.width, 64)];
        _topMsgLabel.backgroundColor = [UIColor clearColor];
        _topMsgLabel.textAlignment = NSTextAlignmentCenter;
        _topMsgLabel.font = [UIFont systemFontOfSize:20];
        _topMsgLabel.textColor = [UIColor whiteColor];
        _topMsgLabel.text = @"扫描期刊图书内二维码";
    }
    return _topMsgLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.backButton];
    [self.view addSubview:self.topMsgLabel];
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.indicator = indicator;
    indicator.center = self.view.center;
    [indicator startAnimating];
    [self.view addSubview:indicator];
    UILabel *waitLabel = [[UILabel alloc] initWithFrame:CGRectMake((kappWidth - 100)*0.5, CGRectGetMaxY(indicator.frame) + 5, 100, 40)];
    self.waitLabel = waitLabel;
    waitLabel.text = @"正在加载...";
    waitLabel.textColor = [UIColor whiteColor];
    waitLabel.textAlignment = NSTextAlignmentCenter;
    waitLabel.font = [UIFont systemFontOfSize:20.0f];
    [self.view addSubview:waitLabel];
    
    [self performSelector:@selector(setUpAVFoundation) withObject:nil afterDelay:0.6f];
}

- (void)setUpAVFoundation{
    [self.waitLabel removeFromSuperview];
    [self.indicator removeFromSuperview];
    
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:self.input])
    {
        [_session addInput:self.input];
    }
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput:self.output];
    }
    
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preview.videoGravity =AVLayerVideoGravityResize;
    _preview.frame =self.view.layer.bounds;
    [self.view.layer insertSublayer:_preview atIndex:0];
    
    
    //添加自定义界面
    _qrRectView = [[QRView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_qrRectView];
    
    //限制扫描感应区域
    CGFloat screenHeight = self.view.frame.size.height;
    CGFloat screenWidth = self.view.frame.size.width;
    CGRect limitRect = CGRectMake((screenWidth - _qrRectView.transparentArea.width) / 2,
                                  (screenHeight - _qrRectView.transparentArea.height) / 2,
                                  _qrRectView.transparentArea.width,
                                  _qrRectView.transparentArea.height);
    
    [_output setRectOfInterest:CGRectMake(limitRect.origin.y / screenHeight,
                                          limitRect.origin.x / screenWidth,
                                          limitRect.size.height / screenHeight,
                                          limitRect.size.width / screenWidth)];
    [self.view addSubview:self.topMsgLabel];
    [self.view addSubview:self.backButton];
    
    self.bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (screenHeight + _qrRectView.transparentArea.height) / 2 + 30, [UIScreen mainScreen].bounds.size.width, 30)];
    self.bottomLabel.text = @"将二维码对焦到取景框内，即可自动扫描";
    self.bottomLabel.textAlignment = NSTextAlignmentCenter;
    self.bottomLabel.font = [UIFont systemFontOfSize:12];
    self.bottomLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.bottomLabel];
    
    NSString *mediaType = AVMediaTypeVideo;// Or AVMediaTypeAudio
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authStatus ==AVAuthorizationStatusAuthorized) {
    }else if(authStatus == AVAuthorizationStatusDenied){
        [self showAlert];
        return;
    }else {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if(granted){
            }
            else {
                [self showAlert];
                return;
            }
        }];
    }
    //增加 条码类型
    if ([[UIDevice currentDevice] systemVersion ].floatValue >= 8.0) {
        _output.metadataObjectTypes = @[AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode93Code,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeQRCode,AVMetadataObjectTypeAztecCode,   AVMetadataObjectTypeInterleaved2of5Code,AVMetadataObjectTypeITF14Code,AVMetadataObjectTypeDataMatrixCode];
    } else {
        _output.metadataObjectTypes = @[AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode93Code,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeQRCode,AVMetadataObjectTypeAztecCode];
    }
    [_session startRunning];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fireScanTimer" object:nil];
}

- (void)showAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"请在设备的\"设置-隐私-相机\"中允许访问相机。" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertController addAction:sureAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

//消失
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.isAllowReceiveScanResult = NO;
    if (_session) {
        [_session stopRunning];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"invalidateScanTimer" object:nil];
    } else {
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(setUpAVFoundation) object:nil];
    }
}

//
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isAllowReceiveScanResult = YES;
    //     [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
}

//出现
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (_session) {
        [_session startRunning];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fireScanTimer" object:nil];
    }
    
}



#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"获得扫描结果");
    if (!self.isAllowReceiveScanResult) {
        return;
    }
    NSLog(@"处理扫描结果");
    if (_session) {
        [_session stopRunning];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"invalidateScanTimer" object:nil];
    }
    
    self.isAllowReceiveScanResult = NO;
    //    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    NSString *stringValue;
    if ([metadataObjects count] >0)
    {
        //停止扫描
        [_session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
    }
    if (self.qrUrlBlock) {
        self.qrUrlBlock(stringValue);
    }
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)allowReceiveRQ{
    self.isAllowReceiveScanResult = YES;
}

- (void)backClick{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc{
    NSLog(@"QR dealloc");
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

@end
