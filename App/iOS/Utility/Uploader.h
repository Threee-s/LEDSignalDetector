//
//  Uploader.h
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/21.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol UploadObserver <NSObject>

@optional

-(void)uploadFile:(NSString*)file currentProgress:(float)progress;

@end

@interface Uploader : NSObject

@property (nonatomic, weak) id<UploadObserver> observer;

+(Uploader*)getInstance;
-(id)initWithViewController:(UIViewController*)srcViewController;
-(void)save:(NSString*)localPath toDropBox:(NSString*)remotePath returnViewController:(UIViewController*)srcViewController;
-(void)save;

@end
