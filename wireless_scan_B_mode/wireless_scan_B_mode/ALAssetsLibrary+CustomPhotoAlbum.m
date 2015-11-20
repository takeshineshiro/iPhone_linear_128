//
//  ALAssetsLibrary+CustomPhotoAlbum.m
//  wireless_scan_B_mode
//
//  Created by wong on 15/11/20.
//  Copyright © 2015年 lepumedical. All rights reserved.
//


#import "ALAssetsLibrary+CustomPhotoAlbum.h"



@implementation ALAssetsLibrary(CustomPhotoAlbum)

-(void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock

{
    [self writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation
     
                       completionBlock:^(NSURL* assetURL, NSError* error) {
                           if (error!=nil) {
                               completionBlock(error);
                               return;
                               
                           }
                           [self addAssetURL: assetURL
                                     toAlbum:albumName
                         withCompletionBlock:completionBlock];
                       }];
}
-(void)addAssetURL:(NSURL*)assetURL toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock{
    
    __block BOOL albumWasFound = NO;
    [self enumerateGroupsWithTypes:ALAssetsGroupAlbum
     
                        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                            if ([albumName compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame) {
                                albumWasFound = YES;
                                [self assetForURL: assetURL
                                      resultBlock:^(ALAsset *asset) {
                                          [group addAsset: asset];
                                          completionBlock(nil);
                                      } failureBlock: completionBlock];
                                return;
                            }
                            if (group==nil && albumWasFound==NO) {
                                __weak ALAssetsLibrary* weakSelf = self;
                                [self addAssetsGroupAlbumWithName:albumName
                                                      resultBlock:^(ALAssetsGroup *group) {
                                                          [weakSelf assetForURL: assetURL
                                                                    resultBlock:^(ALAsset *asset) {
                                                                        [group addAsset: asset];
                                                                        completionBlock(nil);
                                                                    } failureBlock: completionBlock];
                                                      } failureBlock: completionBlock];
                                return;
                            }
                        } failureBlock: completionBlock];
}


@end