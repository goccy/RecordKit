//
//  RKScreenRecorder.h
//  Pods
//
//  Created by goccy on 2017/06/16.
//
//

#import <Foundation/Foundation.h>

@interface RKScreenRecorder : NSObject

@property(nonatomic, readonly) NSURL *screenFileURL;

+ (instancetype)sharedInstance;

- (BOOL)startRecording;

- (void)stopRecording:(void(^)(void))completionHandler;

@end
