//
//  JPTableViewController.m
//  JPImageresizerView_Example
//
//  Created by 周健平 on 2017/12/25.
//  Copyright © 2017年 ZhouJianPing. All rights reserved.
//

#import "JPTableViewController.h"
#import "JPViewController.h"
#import "JPPhotoViewController.h"
#import "UIAlertController+JPImageresizer.h"

@interface JPConfigureModel : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property (nonatomic, strong) JPImageresizerConfigure *configure;
+ (NSArray<JPConfigureModel *> *)testModels;
@end

@implementation JPConfigureModel
+ (NSArray<JPConfigureModel *> *)testModels {
    JPConfigureModel *model1 = [self new];
    model1.title = @"默认样式";
    model1.statusBarStyle = UIStatusBarStyleLightContent;
    model1.configure = [JPImageresizerConfigure defaultConfigureWithImage:nil make:nil];
    
    JPConfigureModel *model2 = [self new];
    model2.title = @"深色毛玻璃遮罩";
    model2.statusBarStyle = UIStatusBarStyleLightContent;
    model2.configure = [JPImageresizerConfigure darkBlurMaskTypeConfigureWithImage:nil make:nil];
    
    JPConfigureModel *model3 = [self new];
    model3.title = @"浅色毛玻璃遮罩";
    model3.statusBarStyle = UIStatusBarStyleDefault;
    model3.configure = [JPImageresizerConfigure lightBlurMaskTypeConfigureWithImage:nil make:nil];
    
    JPConfigureModel *model4 = [self new];
    model4.title = @"拉伸样式的边框图片";
    model4.statusBarStyle = UIStatusBarStyleDefault;
    model4.configure = [JPImageresizerConfigure lightBlurMaskTypeConfigureWithImage:nil make:^(JPImageresizerConfigure *configure) {
        configure
        .jp_strokeColor([UIColor colorWithRed:(205.0 / 255.0) green:(107.0 / 255.0) blue:(153.0 / 255.0) alpha:1.0])
        .jp_borderImage([JPViewController stretchBorderImage])
        .jp_borderImageRectInset([JPViewController stretchBorderImageRectInset]);
    }];
    
    JPConfigureModel *model5 = [self new];
    model5.title = @"平铺样式的边框图片";
    model5.statusBarStyle = UIStatusBarStyleLightContent;
    model5.configure = [JPImageresizerConfigure darkBlurMaskTypeConfigureWithImage:nil make:^(JPImageresizerConfigure *configure) {
        configure
        .jp_frameType(JPClassicFrameType)
        .jp_borderImage([JPViewController tileBorderImage])
        .jp_borderImageRectInset([JPViewController tileBorderImageRectInset]);
    }];
    
    JPConfigureModel *model6 = [self new];
    model6.title = @"圆切样式";
    model6.statusBarStyle = UIStatusBarStyleDefault;
    model6.configure = [JPImageresizerConfigure darkBlurMaskTypeConfigureWithImage:nil make:^(JPImageresizerConfigure *configure) {
        configure
        .jp_strokeColor(JPRGBColor(250, 250, 250))
        .jp_frameType(JPClassicFrameType)
        .jp_isClockwiseRotation(YES)
        .jp_animationCurve(JPAnimationCurveEaseOut)
        .jp_isRoundResize(YES)
        .jp_isArbitrarily(NO);
    }];
    
    JPConfigureModel *model7 = [self new];
    model7.title = @"蒙版样式";
    model7.statusBarStyle = UIStatusBarStyleLightContent;
    model7.configure = [JPImageresizerConfigure darkBlurMaskTypeConfigureWithImage:nil make:^(JPImageresizerConfigure *configure) {
        configure
        .jp_frameType(JPClassicFrameType)
        .jp_maskImage([UIImage imageNamed:@"love.png"])
        .jp_isArbitrarily(NO);
    }];
    
    return @[model1, model2, model3, model4, model5, model6, model7];
}
@end

@interface JPTableViewController ()
@property (nonatomic, copy) NSArray<JPConfigureModel *> *models;
@property (nonatomic, strong) NSURL *tmpURL;
@property (nonatomic, weak) AVAssetExportSession *exporterSession;
@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, copy) JPExportVideoProgressBlock progressBlock;
@property (nonatomic, assign) BOOL isExporting;
@end

@implementation JPTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Example";
    self.models = [JPConfigureModel testModels];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.tmpURL) {
        NSURL *tmpURL = self.tmpURL;
        self.tmpURL = nil;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSFileManager defaultManager] removeItemAtURL:tmpURL error:nil];
        });
    }
}

- (void)dealloc {
    [self __removeProgressTimer];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.models.count;
    } else if (section == 1 || section == 2) {
        return 2;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if (indexPath.section == 0) {
        JPConfigureModel *model = self.models[indexPath.row];
        cell.textLabel.text = model.title;
    } else if (indexPath.section == 1) {
        if (indexPath.item == 0) {
            cell.textLabel.text = @"裁剪本地GIF";
        } else {
            cell.textLabel.text = @"裁剪本地视频";
        }
    } else if (indexPath.section == 2) {
        if (indexPath.item == 0) {
            cell.textLabel.text = @"成为吴彦祖";
        } else {
            cell.textLabel.text = @"暂停选老婆";
        }
    } else {
        cell.textLabel.text = @"从系统相册选择";
    }
    return cell;
}

#pragma mark - Table view delegate

static JPImageresizerConfigure *gifConfigure_;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        JPConfigureModel *model = self.models[indexPath.row];
        model.configure.image = [self __randomImage];
        [self __startImageresizer:model.configure statusBarStyle:model.statusBarStyle];
    } else if (indexPath.section == 1) {
        JPConfigureModel *model = [JPConfigureModel new];
        if (indexPath.item == 0) {
            NSString *gifPath =(arc4random() % 2) ? JPMainBundleResourcePath(@"Gem.gif", nil) : JPMainBundleResourcePath(@"Dilraba.gif", nil);
            BOOL isLoopPlaybackGIF = arc4random() % 2;
            model.title = @"裁剪本地GIF";
            model.statusBarStyle = UIStatusBarStyleLightContent;
            model.configure = [JPImageresizerConfigure defaultConfigureWithImageData:[NSData dataWithContentsOfFile:gifPath] make:^(JPImageresizerConfigure *configure) {
                configure.jp_frameType(JPClassicFrameType);
                configure.jp_isLoopPlaybackGIF(isLoopPlaybackGIF);
            }];
        } else {
            NSString *videoPath = JPMainBundleResourcePath(@"yaorenmao.mov", nil);
            model.title = @"裁剪本地视频";
            model.statusBarStyle = UIStatusBarStyleDefault;
            model.configure = [JPImageresizerConfigure lightBlurMaskTypeConfigureWithVideoURL:[NSURL fileURLWithPath:videoPath] make:^(JPImageresizerConfigure *configure) {
                configure
                .jp_borderImage([JPViewController stretchBorderImage])
                .jp_borderImageRectInset([JPViewController stretchBorderImageRectInset]);
            } fixErrorBlock:nil fixStartBlock:nil fixProgressBlock:nil fixCompleteBlock:nil];
        }
        [self __startImageresizer:model.configure statusBarStyle:model.statusBarStyle];
    } else if (indexPath.section == 2) {
        if (indexPath.item == 0) {
            [self __openAlbum:YES];
        } else {
            if (!gifConfigure_) {
                [JPProgressHUD show];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    gifConfigure_ = [JPImageresizerConfigure defaultConfigureWithImage:[self __createGIFImage] make:^(JPImageresizerConfigure *configure) {
                        configure.jp_isLoopPlaybackGIF(YES);
                    }];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [JPProgressHUD dismiss];
                        [self __startImageresizer:gifConfigure_ statusBarStyle:UIStatusBarStyleLightContent];
                    });
                });
                return;
            }
            [self __startImageresizer:gifConfigure_ statusBarStyle:UIStatusBarStyleLightContent];
        }
    } else {
        [self __openAlbum:NO];
    }
}

#pragma mark - 随机图片
- (UIImage *)__randomImage {
    NSString *imageName;
    NSInteger index = 1 + arc4random() % (GirlCount + 2);
    if (index > GirlCount) {
        if (index == GirlCount + 1) {
            imageName = @"Kobe.jpg";
        } else {
            imageName = @"Flowers.jpg";
        }
    } else {
        imageName = [NSString stringWithFormat:@"Girl%zd.jpg", index];
    }
    return [UIImage imageWithContentsOfFile:JPMainBundleResourcePath(imageName, nil)];
}

#pragma mark - 生成GIF图片
- (UIImage *)__createGIFImage {
    NSMutableArray *images = [NSMutableArray array];
    CGSize size = CGSizeMake(500, 500);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, bitmapInfo);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    for (NSInteger i = 1; i <= GirlCount; i++) {
        NSString *imageName = [NSString stringWithFormat:@"Girl%zd.jpg", i];
        UIImage *image = [UIImage imageWithContentsOfFile:JPMainBundleResourcePath(imageName, nil)];
        
        CGContextSaveGState(context);
        
        CGImageRef cgImage = image.CGImage;
        CGFloat width;
        CGFloat height;
        if (image.size.width >= image.size.height) {
            width = size.width;
            height = width * (image.size.height / image.size.width);
        } else {
            height = size.height;
            width = height * (image.size.width / image.size.height);
        }
        CGFloat x = (size.width - width) * 0.5;
        CGFloat y = (size.height - height) * 0.5;
        
        CGContextDrawImage(context, CGRectMake(x, y, width, height), cgImage);
        CGImageRef resizedCGImage = CGBitmapContextCreateImage(context);
        [images addObject:[UIImage imageWithCGImage:resizedCGImage]];
        CGImageRelease(resizedCGImage);
        
        CGContextClearRect(context, (CGRect){CGPointZero, size});
        CGContextRestoreGState(context);
    }
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    return [UIImage animatedImageWithImages:images duration:JPGIFDuration];
}

#pragma mark - 打开相册
- (void)__openAlbum:(BOOL)isBecomeDanielWu {
    if (isBecomeDanielWu) {
        @jp_weakify(self);
        [JPPhotoToolSI albumAccessAuthorityWithAllowAccessAuthorityHandler:^{
            @jp_strongify(self);
            if (!self) return;
            JPPhotoViewController *vc = [[JPPhotoViewController alloc] init];
            vc.isBecomeDanielWu = isBecomeDanielWu;
            [self.navigationController pushViewController:vc animated:YES];
        } refuseAccessAuthorityHandler:nil alreadyRefuseAccessAuthorityHandler:nil canNotAccessAuthorityHandler:nil isRegisterChange:NO];
        return;
    }
    
    [UIAlertController openAlbum:^(UIImage *image, NSData *imageData, NSURL *videoURL) {
        if (image) {
            JPImageresizerConfigure *configure = [JPImageresizerConfigure defaultConfigureWithImage:image make:nil];
            [self __startImageresizer:configure statusBarStyle:UIStatusBarStyleLightContent];
        } else if (imageData) {
            JPImageresizerConfigure *configure = [JPImageresizerConfigure defaultConfigureWithImageData:imageData make:nil];
            [self __startImageresizer:configure statusBarStyle:UIStatusBarStyleLightContent];
        } else if (videoURL) {
            [self __confirmVideo:videoURL];
        }
    } fromVC:self];
}

#pragma mark - 判断视频是否需要修正方向（内部or外部修正）
- (void)__confirmVideo:(NSURL *)videoURL {
    // 校验视频信息
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoURL];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [videoAsset loadValuesAsynchronouslyForKeys:@[@"duration", @"tracks"] completionHandler:^{
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    // 方向没被修改过，无需修正，直接进入
    AVAssetTrack *videoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    if (CGAffineTransformEqualToTransform(videoTrack.preferredTransform, CGAffineTransformIdentity)) {
        JPImageresizerConfigure *configure = [JPImageresizerConfigure defaultConfigureWithVideoAsset:videoAsset make:nil fixErrorBlock:nil fixStartBlock:nil fixProgressBlock:nil fixCompleteBlock:nil];
        [self __startImageresizer:configure statusBarStyle:UIStatusBarStyleLightContent];
        return;
    }
    
    UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"该视频方向需要先修正" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
#pragma mark 内部修正
    [alertCtr addAction:[UIAlertAction actionWithTitle:@"先进页面再修正" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @jp_weakify(self);
        JPImageresizerConfigure *configure = [JPImageresizerConfigure defaultConfigureWithVideoURL:videoURL make:nil fixErrorBlock:^(NSURL *cacheURL, JPImageresizerErrorReason reason) {
            [JPViewController showErrorMsg:reason pathExtension:[cacheURL pathExtension]];
            @jp_strongify(self);
            if (!self) return;
            [self.navigationController popViewControllerAnimated:YES];
        } fixStartBlock:^{
            [JPProgressHUD show];
        } fixProgressBlock:^(float progress) {
            [JPProgressHUD showProgress:progress status:[NSString stringWithFormat:@"修正方向中...%.0lf%%", progress * 100]];
        } fixCompleteBlock:^(NSURL *cacheURL) {
            [JPProgressHUD dismiss];
        }];
        [self __startImageresizer:configure statusBarStyle:UIStatusBarStyleLightContent];
    }]];
    
#pragma mark 外部修正
    [alertCtr addAction:[UIAlertAction actionWithTitle:@"先修正再进页面" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [JPProgressHUD show];
        @jp_weakify(self);
        [JPImageresizerTool fixOrientationVideoWithAsset:videoAsset fixErrorBlock:^(NSURL *cacheURL, JPImageresizerErrorReason reason) {
            
            [JPViewController showErrorMsg:reason pathExtension:[cacheURL pathExtension]];
            
            @jp_strongify(self);
            if (!self) return;
            self.isExporting = NO;
            
        } fixStartBlock:^(AVAssetExportSession *exportSession) {
            
            @jp_strongify(self);
            if (!self) return;
            self.isExporting = YES;
            
            [self __addProgressTimer:^(float progress) {
                [JPProgressHUD showProgress:progress status:[NSString stringWithFormat:@"修正方向中...%.0lf%%", progress * 100] userInteractionEnabled:YES];
            } exporterSession:exportSession];
            
        } fixCompleteBlock:^(NSURL *cacheURL) {
            [JPProgressHUD dismiss];
            
            @jp_strongify(self);
            if (!self) return;
            self.isExporting = NO;
            self.tmpURL = cacheURL; // 保存该路径，裁剪后删除视频。
            
            JPImageresizerConfigure *configure = [JPImageresizerConfigure defaultConfigureWithVideoAsset:[AVURLAsset assetWithURL:cacheURL] make:nil fixErrorBlock:nil fixStartBlock:nil fixProgressBlock:nil fixCompleteBlock:nil];
            [self __startImageresizer:configure statusBarStyle:UIStatusBarStyleLightContent];
        }];
    }]];
    
    [alertCtr addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertCtr animated:YES completion:nil];
}

- (void)setIsExporting:(BOOL)isExporting {
    if (_isExporting == isExporting) return;
    _isExporting = isExporting;
    if (isExporting) {
        @jp_weakify(self);
        [JPExportCancelView showWithCancelHandler:^{
            @jp_strongify(self);
            if (!self) return;
            [self.exporterSession cancelExport];
        }];
    } else {
        [JPExportCancelView hide];
    }
}

#pragma mark - 开始裁剪
- (void)__startImageresizer:(JPImageresizerConfigure *)configure statusBarStyle:(UIStatusBarStyle)statusBarStyle {
    JPViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"JPViewController"];
    vc.statusBarStyle = statusBarStyle;
    vc.configure = configure;
    
    CATransition *cubeAnim = [CATransition animation];
    cubeAnim.duration = 0.45;
    cubeAnim.type = @"cube";
    cubeAnim.subtype = kCATransitionFromRight;
    cubeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.navigationController.view.layer addAnimation:cubeAnim forKey:@"cube"];
    
    [self.navigationController pushViewController:vc animated:NO];
}

#pragma mark - 监听视频导出进度的定时器

- (void)__addProgressTimer:(JPExportVideoProgressBlock)progressBlock exporterSession:(AVAssetExportSession *)exporterSession {
    [self __removeProgressTimer];
    if (progressBlock == nil || exporterSession == nil) return;
    self.exporterSession = exporterSession;
    self.progressBlock = progressBlock;
    self.progressTimer = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(__progressTimerHandle) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
}

- (void)__removeProgressTimer {
    [self.progressTimer invalidate];
    self.progressTimer = nil;
    self.progressBlock = nil;
    self.exporterSession = nil;
}

- (void)__progressTimerHandle {
    if (self.progressBlock && self.exporterSession) self.progressBlock(self.exporterSession.progress);
}

@end
