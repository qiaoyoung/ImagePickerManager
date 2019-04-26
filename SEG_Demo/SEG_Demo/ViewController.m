//
//  ViewController.m
//  SEG_Demo
//
//  Created by Joeyoung on 2019/4/22.
//  Copyright © 2019 Joeyoung. All rights reserved.
//

#import "ViewController.h"
#import "SEGImagePickerManager.h"

@interface ViewController ()<SEGImagePickerManagerDelegate>

/** 图片 */
@property (nonatomic, strong) UIImageView *imageView;
/** 必须强引用 */
@property (nonatomic, strong) SEGImagePickerManager *imagePicker;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.imageView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tapGesture)];
    [self.imageView addGestureRecognizer:tap];
    
}
#pragma mark - Event
-(void)tapGesture {
    UIActionSheet *actionSheetView = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"取消"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"拍照", @"相册", nil];
    [actionSheetView showInView:self.view];
}
#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    {
        if (buttonIndex == 0) {
            self.imagePicker = [[SEGImagePickerManager alloc] init];
            self.imagePicker.delegate = self;
            self.imagePicker.sourceType = SEGImagePickerManagerSourceTypeCamera;
            self.imagePicker.allowsEditing = YES;
            [self.imagePicker presentImagePickerControllerWithAnimated:YES completion:nil];
        }
        else if (buttonIndex == 1) {
            self.imagePicker = [[SEGImagePickerManager alloc] init];
            self.imagePicker.delegate = self;
            self.imagePicker.maxImagesCount = 9;
            self.imagePicker.showSelectedIndex = YES;
            [self.imagePicker presentImagePickerControllerWithAnimated:YES completion:nil];
        }
    }
}
#pragma mark - SEGImagePickerManagerDelegate
- (void)seg_imagePickerManager:(SEGImagePickerManager *)manager didFinishPickingPhotos:(NSArray<UIImage *> *)photos isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    self.imageView.image = [photos lastObject];
}


#pragma mark - Getter
- (UIImageView *)imageView {
    if (!_imageView) {
        CGRect rect = CGRectMake(80, 200, 200, 200);
        _imageView = [[UIImageView alloc] initWithFrame:rect];
        _imageView.backgroundColor = [UIColor redColor];
        _imageView.userInteractionEnabled = YES;
    }
    return _imageView;
}

@end
