//
//  RawImag.h
//  wireless_scan_B_mode
//
//  Created by wong on 15/11/19.
//  Copyright © 2015年 lepumedical. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface RawImag : NSObject

@property (nonatomic) NSInteger probeType;

@property(nonatomic) int gain;

@property(nonatomic) int zoom;

@property(nonatomic) NSString* time;

@property(nonatomic)NSData* rawData;

@end
