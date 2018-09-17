//
//  QRView.m
//  QRWeiXinDemo
//
//  Created by huangzhenyu on 15/4/25.
//  Copyright (c) 2015年 lovelydd. All rights reserved.
//

#import "QRView.h"
#define kQrLineanimateDuration 0.008
#define kAppWidth [UIScreen mainScreen].bounds.size.width
#define kAppHeight [UIScreen mainScreen].bounds.size.height
#define ktransparentAreaWidth (kAppWidth * 0.6)
#define ktransparentAreaHeight (kAppWidth * 0.6)

@interface QRView()
@property (nonatomic,strong) UIImageView *qrLine;
@property (nonatomic, weak) NSTimer *timer;
@end

@implementation QRView {
    CGFloat _qrLineY;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.qrLine];
        self.transparentArea = CGSizeMake(ktransparentAreaWidth, ktransparentAreaHeight);
        self.backgroundColor = [UIColor clearColor];
        [self addnotifications];
    }
    return self;
}

- (void)addnotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateTimer) name:@"invalidateScanTimer" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fireTimer) name:@"fireScanTimer" object:nil];
}

#pragma mark 停止定时器
- (void)invalidateTimer{
    NSLog(@"停止定时器");
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark 启动定时器
- (void)fireTimer{
    NSLog(@"启动定时器");
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _timer = [NSTimer scheduledTimerWithTimeInterval:kQrLineanimateDuration target:self selector:@selector(show) userInfo:nil repeats:YES];
    [_timer fire];//立即触发该定时器
}

- (UIImageView *)qrLine
{
    if (!_qrLine) {
        _qrLine  = [[UIImageView alloc] initWithFrame:CGRectMake((kAppWidth - ktransparentAreaWidth) * 0.5, (kAppHeight - ktransparentAreaHeight) * 0.5, ktransparentAreaWidth, 12)];
        _qrLine.image = [UIImage imageNamed:@"QRCodeScanLine"];
        _qrLine.contentMode = UIViewContentModeScaleToFill;
        _qrLineY = _qrLine.frame.origin.y;
        
    }
    return _qrLine;
}

#pragma mark 循环显示横线
- (void)show {
    [UIView animateWithDuration:kQrLineanimateDuration animations:^{
        CGRect rect = self.qrLine.frame;
        rect.origin.y = self->_qrLineY;
        self.qrLine.frame = rect;
        
    } completion:^(BOOL finished) {
        
        CGFloat maxBorder = (kAppHeight  + ktransparentAreaHeight) *0.5 - 12;
        if (self->_qrLineY > maxBorder) {
            self->_qrLineY = (kAppHeight  - ktransparentAreaHeight) * 0.5;
        }
        self->_qrLineY++;
    }];
}

- (void)drawRect:(CGRect)rect {
    //中间小矩形的frame
    CGRect transparentAreaRect = CGRectMake((kAppWidth - ktransparentAreaWidth) * 0.5, (kAppHeight - ktransparentAreaHeight) * 0.5, ktransparentAreaWidth,ktransparentAreaHeight);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self addScreenFillRect:ctx rect:CGRectMake(0, 0, kAppWidth,kAppHeight)];
    [self addCenterClearRect:ctx rect:transparentAreaRect];
    [self addWhiteRect:ctx rect:transparentAreaRect];
    [self addCornerLineWithContext:ctx rect:transparentAreaRect];
}

#pragma mark 绘制整个界面,半透明图层
- (void)addScreenFillRect:(CGContextRef)ctx rect:(CGRect)rect {
    CGContextSetRGBFillColor(ctx, 40 / 255.0,40 / 255.0,40 / 255.0,0.7);
    CGContextFillRect(ctx, rect);
}

#pragma mark 绘制中间小矩形
- (void)addCenterClearRect :(CGContextRef)ctx rect:(CGRect)rect {
    CGContextClearRect(ctx, rect);
}

#pragma mark 绘制白色边框
- (void)addWhiteRect:(CGContextRef)ctx rect:(CGRect)rect {
    CGContextStrokeRect(ctx, rect);
    CGContextSetRGBStrokeColor(ctx, 1, 1, 1, 1);
    CGContextSetLineWidth(ctx, 0.8);
    CGContextAddRect(ctx, rect);
    CGContextStrokePath(ctx);
}

#pragma mark 绘制四个角
- (void)addCornerLineWithContext:(CGContextRef)ctx rect:(CGRect)rect{
    //画四个边角
    CGContextSetLineWidth(ctx, 2);
    CGContextSetRGBStrokeColor(ctx, 83 /255.0, 239/255.0, 111/255.0, 1);//绿色
    
    //左上角
    CGPoint poinsTopLeftA[] = {
        CGPointMake(rect.origin.x+0.7, rect.origin.y),
        CGPointMake(rect.origin.x+0.7 , rect.origin.y + 15)
    };
    
    CGPoint poinsTopLeftB[] = {CGPointMake(rect.origin.x, rect.origin.y +0.7),CGPointMake(rect.origin.x + 15, rect.origin.y+0.7)};
    [self addLine:poinsTopLeftA pointB:poinsTopLeftB ctx:ctx];
    
    //左下角
    CGPoint poinsBottomLeftA[] = {CGPointMake(rect.origin.x+ 0.7, rect.origin.y + rect.size.height - 15),CGPointMake(rect.origin.x +0.7,rect.origin.y + rect.size.height)};
    CGPoint poinsBottomLeftB[] = {CGPointMake(rect.origin.x , rect.origin.y + rect.size.height - 0.7) ,CGPointMake(rect.origin.x+0.7 +15, rect.origin.y + rect.size.height - 0.7)};
    [self addLine:poinsBottomLeftA pointB:poinsBottomLeftB ctx:ctx];
    
    //右上角
    CGPoint poinsTopRightA[] = {CGPointMake(rect.origin.x+ rect.size.width - 15, rect.origin.y+0.7),CGPointMake(rect.origin.x + rect.size.width,rect.origin.y +0.7 )};
    CGPoint poinsTopRightB[] = {CGPointMake(rect.origin.x+ rect.size.width-0.7, rect.origin.y),CGPointMake(rect.origin.x + rect.size.width-0.7,rect.origin.y + 15 +0.7 )};
    [self addLine:poinsTopRightA pointB:poinsTopRightB ctx:ctx];
    
    CGPoint poinsBottomRightA[] = {CGPointMake(rect.origin.x+ rect.size.width -0.7 , rect.origin.y+rect.size.height+ -15),CGPointMake(rect.origin.x-0.7 + rect.size.width,rect.origin.y +rect.size.height )};
    CGPoint poinsBottomRightB[] = {CGPointMake(rect.origin.x+ rect.size.width - 15 , rect.origin.y + rect.size.height-0.7),CGPointMake(rect.origin.x + rect.size.width,rect.origin.y + rect.size.height - 0.7 )};
    [self addLine:poinsBottomRightA pointB:poinsBottomRightB ctx:ctx];
    CGContextStrokePath(ctx);
}

- (void)addLine:(CGPoint[])pointA pointB:(CGPoint[])pointB ctx:(CGContextRef)ctx {
    CGContextAddLines(ctx, pointA, 2);
    CGContextAddLines(ctx, pointB, 2);
}

- (void)dealloc
{
    NSLog(@"qrView dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
