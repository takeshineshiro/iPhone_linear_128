//
//  ViewController.h
//  wireless_scan_B_mode
//
//  Created by wong on 15/11/20.
//  Copyright © 2015年 lepumedical. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "AsyncSocket.h"
@interface ViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,AsyncSocketDelegate,UIPopoverControllerDelegate,UIPickerViewDataSource,UIPickerViewDelegate>

@property (strong, atomic) ALAssetsLibrary* library;

@property (weak, nonatomic) IBOutlet UIImageView *scanImg;
@property (nonatomic,retain)UIImagePickerController* imagePicker;
@property (nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (weak, nonatomic) IBOutlet UIButton *btnFrozen;
@property (weak, nonatomic) IBOutlet UIButton *btnSave;

@property (weak, nonatomic) IBOutlet UIButton *btnScan;

@property (weak, nonatomic) IBOutlet UIButton *btnPre;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property (weak, nonatomic) IBOutlet UILabel *labelCount;
@property (weak, nonatomic) IBOutlet UIButton *btnWifi;
@property(nonatomic) UIView* settingView;
@property(nonatomic) UIImageView* belowImageView;

@end
