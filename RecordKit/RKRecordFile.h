//
//  RKRecordFile.h
//  Pods
//
//  Created by goccy on 2017/06/16.
//
//

#import <Foundation/Foundation.h>

@interface RKRecordFile : NSObject

+ (NSURL *)fileURL:(NSString *)fileName;

+ (BOOL)removeFileIfExistsPath:(NSString *)path;

@end
