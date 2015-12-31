//
//  Uploader.m
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/21.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#import "Uploader.h"
#import <AFNetworking/AFNetworking.h>
#import <DropboxSDK/DropboxSDK.h>
#import "FileManager.h"

@interface Uploader() <DBSessionDelegate, DBNetworkRequestDelegate, DBRestClientDelegate>

@property (nonatomic) UIViewController *srcViewController;
@property (nonatomic, copy) NSString *localPath;
@property (nonatomic, copy) NSString *remotePath;
@property (nonatomic, copy) NSString *relinkUserId;

@property (nonatomic, strong) DBRestClient *restClient;

@property (nonatomic) int uploadedFileCount;
@property (nonatomic) int uploadAllFileCount;

-(void)upload;

@end

@implementation Uploader


+(Uploader*)getInstance
{
    static Uploader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once( &onceToken, ^{
        sharedInstance = [Uploader new];
    });
    return sharedInstance;
}

-(id)init
{
    NSLog(@"Uploader init");
    if (self = [super init]) {
        
    }
    
    return self;
}

-(id)initWithViewController:(UIViewController*)srcViewController
{
    NSLog(@"initWithViewController");
    if (self = [super init]) {
        self.srcViewController = srcViewController;
    }
    
    return self;
}

-(void)save
{
    [self upload];
}

-(void)save:(NSString*)localPath toDropBox:(NSString*)remotePath returnViewController:(UIViewController*)srcViewController
{
    NSLog(@"save");
    self.localPath = localPath;
    self.remotePath = remotePath;
    self.srcViewController = srcViewController;
    
    // Set these variables before launching the app
    NSString* appKey = @"1kred45b0ac0p7k";
    NSString* appSecret = @"syllt20dnikjqn5";
    NSString *root = kDBRootDropbox; // Should be set to either kDBRootAppFolder or kDBRootDropbox
    // You can determine if you have App folder access or Full Dropbox along with your consumer key/secret
    // from https://dropbox.com/developers/apps
    
    // Look below where the DBSession is created to understand how to use DBSession in your app
    
    NSString* errorMsg = nil;
    if ([appKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        errorMsg = @"Make sure you set the app key correctly in DBRouletteAppDelegate.m";
    } else if ([appSecret rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        errorMsg = @"Make sure you set the app secret correctly in DBRouletteAppDelegate.m";
    } else if ([root length] == 0) {
        errorMsg = @"Set your root to use either App Folder of full Dropbox";
    }
    
    DBSession* session =
    [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
    session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
    [DBSession setSharedSession:session];
    
    [DBRequest setNetworkRequestDelegate:self];
    
    if (errorMsg != nil) {
        [[[UIAlertView alloc]
           initWithTitle:@"Error Configuring Session" message:errorMsg
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
         show];
    }
    
    if (self.restClient == nil) {
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
    }
    
    if (![[DBSession sharedSession] isLinked]) {
        // show auth view of dropbox
        [[DBSession sharedSession] linkFromController:self.srcViewController];
    } else {
        [self upload];
    }
}

-(void)upload
{
    NSLog(@"upload");
    
    NSArray *fileNames = [FileManager getFileNamesAtPath:self.localPath];
    
    if (fileNames != nil) {
        self.uploadAllFileCount = (int)[fileNames count];
        self.uploadedFileCount = 0;
        [self.restClient createFolder:self.remotePath];
        for (NSString *fileName in fileNames) {
            NSLog(@"fileName:%@", fileName);
            NSString *filePath = [self.localPath stringByAppendingString:fileName];
            NSLog(@"filePath:%@", filePath);
            
            [self.restClient uploadFile:fileName toPath:self.remotePath withParentRev:nil fromPath:filePath];
        }
    }
    
}

#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
    self.relinkUserId = userId;
    [[[UIAlertView alloc]
       initWithTitle:@"Dropbox Session Ended" message:@"Do you want to relink?" delegate:self
       cancelButtonTitle:@"Cancel" otherButtonTitles:@"Relink", nil]
     show];
}


#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
    if (index != alertView.cancelButtonIndex) {
        [[DBSession sharedSession] linkUserId:self.relinkUserId fromController:self.srcViewController];
    }
    self.relinkUserId = nil;
}


#pragma mark -
#pragma mark DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted {
    outstandingRequests++;
    if (outstandingRequests == 1) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)networkRequestStopped {
    outstandingRequests--;
    if (outstandingRequests == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}


#pragma mark -
#pragma mark DBRestClientDelegate methods

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
          metadata:(DBMetadata*)metadata {
    self.uploadedFileCount++;
    float progress = (float)self.uploadedFileCount / self.uploadAllFileCount;
    [self.observer uploadFile:destPath currentProgress:progress];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath {
    
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    
}

@end
