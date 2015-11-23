//
//  main.m
//  wireless_scan_B_mode
//
//  Created by wong on 15/11/19.
//  Copyright © 2015年 lepumedical. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    
    @try {
        
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
    }
    @catch ( NSException* e)  {
        
        NSLog(@"Exception=%@\nStack Trace:%@", e, [e  callStackSymbols]);
    
    
    }
}
