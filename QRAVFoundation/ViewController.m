//
//  ViewController.m
//  QRAVFoundation
//
//  Created by 黄振宇 on 15/10/31.
//  Copyright © 2015年 YunMei. All rights reserved.
//

#import "ViewController.h"
#import "QRViewController.h"

@interface ViewController ()
- (IBAction)sanQR:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
}

- (void)showQRViewController {
    QRViewController *qrVc = [[QRViewController alloc] init];
    qrVc.qrUrlBlock = ^(NSString *url){
        _textView.text = url;
    };
    [self.navigationController pushViewController:qrVc animated:YES];
}

#pragma mark 判断摄像头是否可用
- (BOOL)validateCamera {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] &&
    [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (IBAction)sanQR:(UIButton *)sender {
    if ([self validateCamera]) {
        [self showQRViewController];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"没有摄像头或摄像头不可用" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
}
@end
