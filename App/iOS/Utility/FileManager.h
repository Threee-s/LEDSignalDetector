//
//  FileManager.h
//  LEDSignalDetector
//
//  Created by 文光石 on 2015/06/23.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

#ifndef LEDSignalDetector_FileManager_h
#define LEDSignalDetector_FileManager_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface FileManager : NSObject

+(NSString*)createRootFolder:(NSString*)rootDir;
+(NSString*)createSubFolder:(NSString*)subDir;
+(void)deleteRootFolder;
+(void)deleteSubFolder:(NSString*)subDir;
// todo:change to sub dir
+(void)deleteFolderWithAbsolutePath:(NSString*)path;
+(NSData*)readDataFromFile:(NSString*)fileName inFolder:(NSString*)folderDir;
+(NSString*)readStringFromFile:(NSString*)fileName inFolder:(NSString*)folderDir;
+(BOOL)saveData:(NSData*)data toFile:(NSString*)fileName;
+(BOOL)saveData:(NSData*)data toFile:(NSString*)fileName inFolder:(NSString*)folderDir;
+(BOOL)saveString:(NSString*)str toFile:(NSString*)fileName inFolder:(NSString*)folderDir;
+(BOOL)saveImage:(UIImage*)image toFolder:(NSString*)folderDir;
+(BOOL)fileExists:(NSString*)filePath;
+(NSString*)getSubDirectoryPath:(NSString*)subDir;
+(NSString*)getPathWithFileName:(NSString*)fileName;
+(NSString*)getPathWithFileName:(NSString*)fileName fromFolder:(NSString*)folderDir;
+(NSURL*)getURLWithFileName:(NSString*)fileName;
+(NSArray*)getFileNamesAtPath:(NSString*)path;
+(NSArray*)getFilePathsInSubDir:(NSString*)subDir;
+(int)getFileCountInSubDir:(NSString*)subDir;
+(int)getFileCountInFolder:(NSString*)folderDir;
+(NSString*)getFileNameFromPath:(NSString*)path;

+(void)saveToPlist:(NSString*)fileName WithDictionary:(NSDictionary*)dic;
//+(NSMutableDictionary*)loadDictionaryFromPlist:(NSString*)fileName;
+(NSMutableDictionary*)loadConfigFromPlist:(NSString*)fileName;
+(BOOL)copyFromPath:(NSString*)srcPath toPath:(NSString*)dstPath;

@end

#endif
