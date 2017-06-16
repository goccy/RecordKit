//
//  RKRecordFile.m
//  Pods
//
//  Created by goccy on 2017/06/16.
//
//

#import "RKRecordFile.h"

@implementation RKRecordFile

+ (NSString *)defaultArchiveDirectory
{
    NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    return [documentsPath stringByAppendingPathComponent:@"RecordKit"];
}

+ (BOOL)makeDefaultArchiveDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *targetDirectory  = [[self class] defaultArchiveDirectory];
    if ([fileManager fileExistsAtPath:targetDirectory]) return NO;
    
    NSError *error;
    if (![fileManager createDirectoryAtPath:targetDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"FAIL CREATE DIRECTORY %@", targetDirectory);
        return NO;
    }
    [[self class] addSkipBackupAttribute:[NSURL fileURLWithPath:targetDirectory]];
    return YES;
}

+ (BOOL)addSkipBackupAttribute:(NSURL *)url
{
    assert([[NSFileManager defaultManager] fileExistsAtPath:[url path]]);
    NSError *error = nil;
    if (![url setResourceValue:[NSNumber numberWithBool: YES]
                        forKey:NSURLIsExcludedFromBackupKey error: &error]) {
        NSLog(@"ERROR: URL:%@ reason:%@", [url lastPathComponent], error);
        return NO;
    }
    return YES;
}

+ (NSURL *)fileURL:(NSString *)fileName
{
    [[self class] makeDefaultArchiveDirectory];
    return [NSURL fileURLWithPath:[[[self class] defaultArchiveDirectory] stringByAppendingPathComponent:fileName]];
}

+ (BOOL)removeFileIfExistsPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        if ([fileManager removeItemAtPath:path error:&error] == NO) {
            NSLog(@"Could not delete old recording:%@", [error localizedDescription]);
            return NO;
        }
    }
    return YES;
}

@end
