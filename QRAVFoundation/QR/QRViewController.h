//
//  QRViewController.h
//  QRWeiXinDemo
//
//  Created by huangzhenyu on 15/4/25.
//  Copyright (c) 2015年 huangzhenyu. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface QRViewController : UIViewController
@property (nonatomic, copy) void(^qrUrlBlock)(NSString *url);
@end
