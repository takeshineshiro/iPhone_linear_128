//
//  ALAssetsLibrary+CustomPhotoAlbum.h
//  wireless_scan_B_mode
//
//  Created by wong on 15/11/20.
//  Copyright © 2015年 lepumedical. All rights reserved.
//




#import <Foundation/Foundation.h>

#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>


typedef void(^SaveImageCompletion)(NSError* error);

@interface ALAssetsLibrary(CustomPhotoAlbum)
-(void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;

-(void)addAssetURL:(NSURL*)assetURL toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;
@end
