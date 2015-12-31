//
//  FileManager.m
//  LEDSignalDetector
//
//  Created by 文 光石 on 2014/10/16.
//  Copyright (c) 2014年 TrE. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FileManager.h"
#import "Log.h"

@interface Log : NSObject

+(void)debug:(NSString*)log;

@end

@implementation Log

+(void)debug:(NSString*)log
{
    // macroで制御
#define DEBUG_LOG
#ifdef DEBUG_LOG
    NSLog(@"%@", log);
#endif
}

@end



@interface FileManager()

+(BOOL)createFolder:(NSString*)folderDir;
+(void)deleteFolder:(NSString*)folderDir;
+(NSMutableDictionary*)loadDictionaryFromPlist:(NSString*)fileName;

@end

@implementation FileManager

static NSString *dirPath_ = nil;

+(BOOL)createFolder:(NSString*)folderDir
{
    BOOL ret = YES;
    
    // ファイルマネージャを作成
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    
    // 存在したら一旦削除
    //if ([fileManager fileExistsAtPath:folderDir]) {
    //    [fileManager removeItemAtPath:folderDir error:&error];
    //}
    
    if ([fileManager fileExistsAtPath:folderDir] == NO) {
        // ディレクトリを作成
        ret = [fileManager createDirectoryAtPath:folderDir
                     withIntermediateDirectories:YES
                                      attributes:nil
                                           error:&error];
        
        if (error != nil) {
            ret = NO;
        }
    }
    
    return ret;
}

+(void)deleteFolder:(NSString*)folderDir
{
    if (folderDir != nil) {
        // ファイルマネージャを作成
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSError *error;
        
        // 存在したら削除
        if ([fileManager fileExistsAtPath:folderDir]) {
            if ([fileManager removeItemAtPath:folderDir error:&error] == YES) {
                [Log debug:[NSString stringWithFormat:@"[%@] deleted.", folderDir]];
            }
        }
    }
}

+(void)createRootFolder:(NSString*)rootDir
{
    // ホームディレクトリを取得
    NSString *homeDir = NSHomeDirectory();
    
    // 作成するディレクトリのパスを作成
    NSString *dirPath = [homeDir stringByAppendingPathComponent:rootDir];
    
    if ([FileManager createFolder:dirPath] == YES) {
        dirPath_ = [dirPath copy];
        [Log debug:dirPath_];
    }
}

+(void)createSubFolder:(NSString*)subDir
{
    if (dirPath_ != nil) {
        NSString *dirPath = [NSString stringWithFormat:@"%@/%@", dirPath_, subDir];
        if ([FileManager createFolder:dirPath] == YES) {
            [Log debug:dirPath];
        }
    }
}

+(void)deleteRootFolder
{
    [FileManager deleteFolder:dirPath_];
}

+(void)deleteSubFolder:(NSString*)subDir
{
    if (dirPath_ != nil) {
        NSString *dirPath = [NSString stringWithFormat:@"%@/%@", dirPath_, subDir];
        [FileManager deleteFolder:dirPath];
    }
}

+(NSData*)readDataFromFile:(NSString*)fileName inFolder:(NSString*)folderDir
{
    NSData *data = nil;
    if (dirPath_ != nil && folderDir != nil && fileName != nil) {
        NSString *filePath = [NSString stringWithFormat:@"%@%@/%@", dirPath_, folderDir, fileName];
        data = [[NSData alloc] initWithContentsOfFile:filePath];
    }
    
    return data;
}

+(NSString*)readStringFromFile:(NSString*)fileName inFolder:(NSString*)folderDir
{
    NSString *str = nil;
    NSData *data = [FileManager readDataFromFile:fileName inFolder:folderDir];
    if (data != nil) {
        str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    }
    
    return str;
}

+(BOOL)saveData:(NSData*)data toFile:(NSString*)fileName
{
    BOOL ret = NO;
    
    if (dirPath_ != nil && fileName != nil && data != nil) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", dirPath_, fileName];
        if ([data writeToFile:filePath atomically:YES]) {
            ret = YES;
            [Log debug:[NSString stringWithFormat:@"[%@] saved.", filePath]];
        } else {
            [Log debug:[NSString stringWithFormat:@"[%@] could not save.", filePath]];
        }
    }
    
    return ret;
}

+(BOOL)saveData:(NSData*)data toFile:(NSString*)fileName inFolder:(NSString*)folderDir
{
    BOOL ret = NO;
    
    if (dirPath_ != nil && folderDir != nil && fileName != nil && data != nil) {
        NSString *filePath = [NSString stringWithFormat:@"%@%@/%@", dirPath_, folderDir, fileName];
        [Log debug:[NSString stringWithFormat:@"filePath:[%@]", filePath]];
        if ([data writeToFile:filePath atomically:YES]) {
            ret = YES;
            [Log debug:[NSString stringWithFormat:@"[%@] saved.", filePath]];
        } else {
            [Log debug:[NSString stringWithFormat:@"[%@] could not save.", filePath]];
        }
    } else {
        [Log debug: @"param error"];
    }
    
    return ret;
}

+(BOOL)saveString:(NSString*)str toFile:(NSString*)fileName inFolder:(NSString*)folderDir
{
    BOOL ret = NO;
    
    if (str != nil) {
        NSData *data = [str dataUsingEncoding: NSASCIIStringEncoding];
        ret = [FileManager saveData:data toFile:fileName inFolder:folderDir];
    }
    
    return ret;
}

+(BOOL)fileExists:(NSString*)filePath
{
    if (filePath != nil) {
        // ファイルマネージャを作成
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        return [fileManager fileExistsAtPath:filePath];
    }
    
    return NO;
}

+(NSString*)getSubDirectoryPath:(NSString*)subDir
{
    NSString* subDirPath = nil;
    
    if (dirPath_ != nil && subDir != nil) {
        subDirPath = [NSString stringWithFormat:@"%@%@/", dirPath_, subDir];
        [Log debug:[NSString stringWithFormat:@"subDirPath[%@]", subDirPath]];
    }
    
    return subDirPath;
}

+(NSString*)getPathWithFileName:(NSString*)fileName
{
    NSString* filePath = nil;
    
    if (dirPath_ != nil && fileName != nil) {
        filePath = [NSString stringWithFormat:@"%@/%@", dirPath_, fileName];
        [Log debug:[NSString stringWithFormat:@"filePath[%@] created.", filePath]];
    }
    
    return filePath;
}

+(NSString*)getPathWithFileName:(NSString*)fileName fromFolder:(NSString*)folderDir
{
    NSString* filePath = nil;
    
    if (dirPath_ != nil && folderDir != nil && fileName != nil) {
        filePath = [NSString stringWithFormat:@"%@%@/%@", dirPath_, folderDir, fileName];
        [Log debug:[NSString stringWithFormat:@"filePath[%@] created.", filePath]];
    }
    
    return filePath;
}

+(NSURL*)getURLWithFileName:(NSString*)fileName
{
    NSURL* fileURL = nil;
    
    NSString* filePath = [FileManager getPathWithFileName:fileName];
    if (filePath != nil) {
        fileURL = [NSURL URLWithString:filePath];
    }
    
    return fileURL;
}

+(void)saveToPlist:(NSString*)fileName WithDictionary:(NSDictionary*)dic
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];
    
    [Log debug:filePath];
    
    [dic writeToFile:filePath atomically:NO];
}

+(NSMutableDictionary*)loadDictionaryFromPlist:(NSString*)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];
    
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    
    return dic;
}

+(NSMutableDictionary*)loadConfigFromPlist:(NSString*)fileName
{
    NSMutableDictionary* dic = [FileManager loadDictionaryFromPlist:fileName];
    if (dic == nil) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"SmartEyeConfig_Init" ofType:@"plist"];
        dic = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    }
    
    return dic;
}

+(NSArray*)getFileNamesAtPath:(NSString*)path
{
    NSArray *fileNames = nil;
    // ファイルマネージャを作成
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //NSError *error;
    
    if (path != nil) {
        
        fileNames = [fileManager subpathsAtPath:path];
    }
    
    return fileNames;
}

+(int)getFileCountInFolder:(NSString*)folderDir
{
    int count = 0;
    
    if (dirPath_ != nil && folderDir != nil) {
        NSArray *fileNames = [FileManager getFileNamesAtPath:folderDir];
        if (fileNames != nil) {
            count = (int)[fileNames count];
        }
    }
    
    return count;
}

@end