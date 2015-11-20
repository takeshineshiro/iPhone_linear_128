//
//  CustomImagePickerViewController.m
//  wireless_scan_B_mode
//
//  Created by wong on 15/11/19.
//  Copyright © 2015年 lepumedical. All rights reserved.
//

#import "CustomImagePickerViewController.h"

@interface CustomImagePickerViewController ()

@end

@implementation CustomImagePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.userInteractionEnabled = true;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:true withAnimation:UIStatusBarAnimationNone];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:true withAnimation:UIStatusBarAnimationNone];
    
}



@end

