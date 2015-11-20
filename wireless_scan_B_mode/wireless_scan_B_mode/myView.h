//
//  myView.h
//  wireless_scan_B_mode
//
//  Created by wong on 15/11/19.
//  Copyright © 2015年 lepumedical. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
@interface myView : UIView{
    
    NSInteger lineCount;
    double scale;
}
@property(nonatomic) double scale;
@property(nonatomic) NSInteger lineCount;
@end
