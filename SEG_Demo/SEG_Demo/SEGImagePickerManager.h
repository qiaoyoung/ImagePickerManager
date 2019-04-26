//
//  SEGImagePickerManager.h
//  
//
//  Created by Joeyoung on 2019/4/22.
//  Copyright © 2019 SEGI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SEGImagePickerManagerSourceType) {
    SEGImagePickerManagerSourceTypePhotoLibrary, // 相册
    SEGImagePickerManagerSourceTypeCamera  // 相机
};

@class SEGImagePickerManager;
@protocol SEGImagePickerManagerDelegate <NSObject>

- (void)seg_imagePickerManager:(SEGImagePickerManager *)manager didFinishPickingPhotos:(NSArray<UIImage *> *)photos isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto;

- (void)seg_imagePickerManagerDidCancel:(SEGImagePickerManager *)picker;

@end

/**
 使用方法:
    在要使用的类中, 必须强引用(因为该Manager只做为中间层配置使用, 不做强引用会被释放)
    @property (nonatomic, strong) SEGImagePickerManager *imagePicker;
 eg:
    self.imagePicker = [[SEGImagePickerManager alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.sourceType = SEGImagePickerManagerSourceTypeCamera;
    self.imagePicker.allowsEditing = YES;
    [self.imagePicker presentImagePickerControllerWithAnimated:YES completion:nil];
 */
@interface SEGImagePickerManager : NSObject

#pragma mark - 相册/相机 通用属性
/** delegate */
@property(nonatomic, weak) id<SEGImagePickerManagerDelegate> delegate; 
/** 相机类型: 默认为相册 */
@property (nonatomic, assign) SEGImagePickerManagerSourceType sourceType;
/** 主题色，默认SEGI */
@property (nonatomic, strong) UIColor *themeColor;
/** 默认NO，不允许裁剪，如果设置为YES，允许裁剪(maxImagesCount = 1 才有效) */
@property (nonatomic, assign) BOOL allowsEditing;
/** 设置裁剪区域左右边距: 默认15px */
@property (nonatomic, assign) CGFloat cropLeftMargin;

#pragma mark - sourceType为相册时 设置才有效
/** 最大可选图片数量，默认1张 */
@property (nonatomic, assign) NSInteger maxImagesCount;
/** 最小照片必选张数，默认0张 */
@property (nonatomic, assign) NSInteger minImagesCount;
/** 默认是YES，对照片排序，按修改时间升序.
 如果设置为NO，最新的照片会显示在最前面，内部的拍照按钮会排在第一个 */
@property (nonatomic, assign) BOOL sortAscendingByModificationDate;
/** 默认为NO，如果设置为YES，用户将可以拍摄照片 */
@property (nonatomic, assign) BOOL allowTakePicture;
/** 默认为NO，如果设置为YES，原图按钮将显示，用户可以选择发送原图 */
@property (nonatomic, assign) BOOL allowPickingOriginalPhoto;
/** 默认为NO，如果设置为YES，用户可以选择gif图片 */
@property (nonatomic, assign) BOOL allowPickingGif;
/** 默认为YES，如果设置为NO，预览按钮将隐藏，用户将不能去预览照片 */
@property (nonatomic, assign) BOOL allowPreview;
/** 默认为NO，不显示照片的选中序号，如果设置为YES，显示 */
@property (nonatomic, assign) BOOL showSelectedIndex;
/** 默认是YES，当照片选择张数达到maxImagesCount时，其它照片会显示颜色为cannotSelectLayerColor的浮层
 如果设置为NO，不显示 */
@property (nonatomic, assign) BOOL showPhotoCannotSelectLayer;
// Default is white color with 0.8 alpha;
@property (nonatomic, strong) UIColor *cannotSelectLayerColor;

/**
 模态出照片选择器

 @param animated 动画效果
 @param completion 回调
 */
- (void)presentImagePickerControllerWithAnimated:(BOOL)animated completion:(void (^)(void))completion;
 
@end


