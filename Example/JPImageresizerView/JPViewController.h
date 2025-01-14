//
//  JPViewController.h
//  JPImageresizerView
//
//  Created by ZhouJianPing on 12/21/2017.
//  Copyright (c) 2017 ZhouJianPing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JPImageresizerView.h"

@interface JPViewController : UIViewController
+ (UIImage *)stretchBorderImage;
+ (CGPoint)stretchBorderImageRectInset;
+ (UIImage *)tileBorderImage;
+ (CGPoint)tileBorderImageRectInset;

@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property (nonatomic, strong) JPImageresizerConfigure *configure;
@property (nonatomic, assign) BOOL isBecomeDanielWu;

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (nonatomic, weak) JPImageresizerView *imageresizerView;
@property (nonatomic, copy) void (^backBlock)(JPViewController *vc);

+ (void)showErrorMsg:(JPImageresizerErrorReason)reason pathExtension:(NSString *)pathExtension;
@end
