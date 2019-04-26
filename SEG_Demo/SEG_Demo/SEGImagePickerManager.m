//
//  SEGImagePickerManager.m
//
//
//  Created by Joeyoung on 2019/4/22.
//  Copyright © 2019 SEGI. All rights reserved.
//

#import "SEGImagePickerManager.h"
#import "TZImagePickerController.h"

// 默认主题色
#define kTheme_Color [UIColor colorWithRed:255 / 255.0f green:196 / 255.0f blue:13 / 255.0f alpha:1]
#define kSEGPicker_screenW [UIScreen mainScreen].bounds.size.width
#define kSEGPicker_screenH [UIScreen mainScreen].bounds.size.height

@interface SEGImagePickerManager ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate ,TZImagePickerControllerDelegate, UIAlertViewDelegate>

/** 选择相册图片 */
@property (nonatomic, strong) TZImagePickerController *phImagePicker;
/** 相机 */
@property (nonatomic, strong) UIImagePickerController *cameraPicker;

@end

@implementation SEGImagePickerManager

- (instancetype)init {
    if (self = [super init]) {
        // 初始化 默认值
        self.sourceType = SEGImagePickerManagerSourceTypePhotoLibrary; // 相册
        self.themeColor = kTheme_Color; // SEGI主题色
        self.allowsEditing = NO; // 不允许裁剪
        self.cropLeftMargin = 15.f; // 裁剪区域左右边距 15px
        self.minImagesCount = 0; // 最小必选张数
        self.maxImagesCount = 1; // 最大必选张数
        self.sortAscendingByModificationDate = YES; // 时间升序
        self.allowTakePicture = NO; // 选照片时不可拍照
        self.allowPickingOriginalPhoto = NO; // 隐藏底部原图按钮
        self.allowPreview = YES;  // 允许预览
        self.showSelectedIndex = NO; // 不展示索引
        self.showPhotoCannotSelectLayer = YES; // 显示不可选择遮罩图层
    }
    return self;
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (!self.delegate || !image) return;
    if (self.allowsEditing == YES) { // 裁剪图片
        [picker dismissViewControllerAnimated:NO completion:nil];
        [[TZImageManager manager] savePhotoWithImage:image location:nil completion:^(PHAsset *asset, NSError *error) {
            TZAssetModel *assetModel = [[TZImageManager manager] createModelWithAsset:asset];
            TZImagePickerController *cropVC = [[TZImagePickerController alloc] initCropTypeWithAsset:assetModel.asset photo:image completion:^(UIImage *cropImage, id asset) {
                if ([self.delegate respondsToSelector:@selector(seg_imagePickerManager:didFinishPickingPhotos:isSelectOriginalPhoto:)]) {
                    [self.delegate seg_imagePickerManager:self
                                   didFinishPickingPhotos:@[cropImage]
                                    isSelectOriginalPhoto:YES];
                }
            }];
            cropVC.isSelectOriginalPhoto = YES;
            cropVC.iconThemeColor = self.themeColor;
            cropVC.oKButtonTitleColorNormal = self.themeColor;
            cropVC.cropRect = self.phImagePicker.cropRect;
            [(UIViewController *)self.delegate presentViewController:cropVC animated:YES completion:nil];
        }];
    } else { // 系统拍照
        [self private_viewController:picker
                 dismissWithAnimated:YES
                              photos:@[image]
               isSelectOriginalPhoto:YES];
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self private_viewController:picker
             dismissWithAnimated:YES
                          photos:nil
           isSelectOriginalPhoto:nil];
}

#pragma mark - TZImagePickerControllerDelegate
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    [self private_viewController:picker
             dismissWithAnimated:YES
                          photos:photos
           isSelectOriginalPhoto:isSelectOriginalPhoto];
}
- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker {
    [self private_viewController:picker
             dismissWithAnimated:YES
                          photos:nil
           isSelectOriginalPhoto:nil];
}

#pragma mark - Event
- (void)presentImagePickerControllerWithAnimated:(BOOL)animated completion:(void (^)(void))completion {
    if (!self.delegate) return;
    if (self.sourceType == SEGImagePickerManagerSourceTypeCamera) { // 相机
        [self seg_authorizationStatusForCameraWithAnimated:animated completion:completion];
    } else { // 相册
        [(UIViewController *)self.delegate presentViewController:self.phImagePicker
                                                        animated:animated
                                                      completion:completion];
    }
}
// 验证用户是否授权
- (void)seg_authorizationStatusForCameraWithAnimated:(BOOL)animated completion:(void (^)(void))completion {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)) {
        NSDictionary *infoDict = [TZCommonTools tz_getInfoDictionary];
        NSString *appName = [infoDict valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [infoDict valueForKey:@"CFBundleName"];
        NSString *message = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Please allow %@ to access your camera in \"Settings -> Privacy -> Camera\""],appName];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSBundle tz_localizedStringForKey:@"Can not use camera"] message:message delegate:self cancelButtonTitle:[NSBundle tz_localizedStringForKey:@"Cancel"] otherButtonTitles:[NSBundle tz_localizedStringForKey:@"Setting"], nil];
        [alert show];
#pragma clang diagnostic pop
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // 防止用户首次拍照拒绝授权时相机页黑屏
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                        [(UIViewController *)self.delegate presentViewController:self.cameraPicker
                                                                        animated:animated
                                                                      completion:completion];
                    } else {
                        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
                    }
                });
            }
        }];
    } else {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [(UIViewController *)self.delegate presentViewController:self.cameraPicker
                                                            animated:animated
                                                          completion:completion];
        } else {
            NSLog(@"模拟器中无法打开照相机,请在真机中使用");
        }
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                           options:@{}
                                 completionHandler:nil];
    }
}

#pragma mark - Dismiss
/**
 统一 dismiss 的方法

 @param picker 导航
 @param animated 动画效果
 @param photos 照片数组 (photos=nil 代表是cancel)
 @param isSelectOriginalPhoto 是否是原图
 */
- (void)private_viewController:(UINavigationController *)picker
           dismissWithAnimated:(BOOL)animated
                        photos:(NSArray<UIImage *> *)photos
         isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    if (!self.delegate) return;
    __weak typeof(self) wSelf = self;
    if (!photos) { // cancel
        [picker dismissViewControllerAnimated:animated completion:^{
            __strong typeof(wSelf) strongSelf = wSelf;
            if (!strongSelf) return;
            if ([strongSelf.delegate respondsToSelector:@selector(seg_imagePickerManagerDidCancel:)]) {
                [strongSelf.delegate seg_imagePickerManagerDidCancel:wSelf];
            }
        }];
    } else { // didFinish
        [picker dismissViewControllerAnimated:animated completion:^{
            __strong typeof(wSelf) strongSelf = wSelf;
            if (!strongSelf) return;
            if ([strongSelf.delegate respondsToSelector:@selector(seg_imagePickerManager:didFinishPickingPhotos:isSelectOriginalPhoto:)]) {
                [strongSelf.delegate seg_imagePickerManager:strongSelf
                                     didFinishPickingPhotos:photos
                                      isSelectOriginalPhoto:isSelectOriginalPhoto];
            }
        }];
    }
}

#pragma mark - Setter
#pragma mark - 相册/相机 通用属性
- (void)setDelegate:(id<SEGImagePickerManagerDelegate>)delegate {
    _delegate = delegate;
}
- (void)setSourceType:(SEGImagePickerManagerSourceType)sourceType {
    _sourceType = sourceType;
}
- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    self.phImagePicker.iconThemeColor = _themeColor;
    self.phImagePicker.oKButtonTitleColorNormal = _themeColor;
    self.phImagePicker.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
}
- (void)setAllowsEditing:(BOOL)allowsEditing {
    _allowsEditing = allowsEditing;
    if (_allowsEditing == YES) self.maxImagesCount = 1;
    self.phImagePicker.allowCrop = _allowsEditing;
    self.phImagePicker.showSelectBtn = !_allowsEditing;
}
- (void)setCropLeftMargin:(CGFloat)cropLeftMargin {
    _cropLeftMargin = cropLeftMargin;
    NSInteger widthHeight = kSEGPicker_screenW - 2*_cropLeftMargin;
    NSInteger top = (kSEGPicker_screenH - widthHeight) / 2;
    self.phImagePicker.cropRect = CGRectMake(_cropLeftMargin, top, widthHeight, widthHeight);
}
#pragma mark - sourceType为相册时 设置才有效
- (void)setMaxImagesCount:(NSInteger)maxImagesCount {
    _maxImagesCount = maxImagesCount;
    self.phImagePicker.maxImagesCount = _maxImagesCount;
}
- (void)setMinImagesCount:(NSInteger)minImagesCount {
    _minImagesCount = minImagesCount;
    self.phImagePicker.minImagesCount = _minImagesCount;
}
- (void)setSortAscendingByModificationDate:(BOOL)sortAscendingByModificationDate {
    _sortAscendingByModificationDate = sortAscendingByModificationDate;
    self.phImagePicker.sortAscendingByModificationDate = _sortAscendingByModificationDate;
}
- (void)setAllowTakePicture:(BOOL)allowTakePicture {
    _allowTakePicture = allowTakePicture;
    self.phImagePicker.allowTakePicture = _allowTakePicture;
}
- (void)setAllowPickingOriginalPhoto:(BOOL)allowPickingOriginalPhoto {
    _allowPickingOriginalPhoto = allowPickingOriginalPhoto;
    self.phImagePicker.allowPickingOriginalPhoto = _allowPickingOriginalPhoto;
}
- (void)setAllowPickingGif:(BOOL)allowPickingGif {
    _allowPickingGif = allowPickingGif;
    self.phImagePicker.allowPickingGif = _allowPickingGif;
}
- (void)setAllowPreview:(BOOL)allowPreview {
    _allowPreview = allowPreview;
    self.phImagePicker.allowPreview = _allowPreview;
}
- (void)setShowSelectedIndex:(BOOL)showSelectedIndex {
    _showSelectedIndex = showSelectedIndex;
    self.phImagePicker.showSelectedIndex = _showSelectedIndex;
}
- (void)setShowPhotoCannotSelectLayer:(BOOL)showPhotoCannotSelectLayer {
    _showPhotoCannotSelectLayer = showPhotoCannotSelectLayer;
    self.phImagePicker.showPhotoCannotSelectLayer = _showPhotoCannotSelectLayer;
}


#pragma mark - Getter
// 选取图片
- (TZImagePickerController *)phImagePicker {
    if (!_phImagePicker) {
        _phImagePicker = [[TZImagePickerController alloc] initWithMaxImagesCount:1 columnNumber:4 delegate:self];
        _phImagePicker.allowPickingVideo = NO;  // 不可选择视频
        _phImagePicker.allowTakeVideo = NO;  // 选照片时不可拍视频
        _phImagePicker.allowPickingGif = NO;  // 不可选择gif
        _phImagePicker.autoDismiss = NO; // 不自动dismiss
    }
    return _phImagePicker;
}
// 拍照
- (UIImagePickerController *)cameraPicker {
    if (!_cameraPicker) {
        _cameraPicker = [[UIImagePickerController alloc] init];
        _cameraPicker.delegate = self;
        _cameraPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        _cameraPicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    }
    return _cameraPicker;
}

@end
