//
//  RKAudioRecorder.h
//  Pods
//
//  Created by goccy on 2017/06/16.
//
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface RKAudioRecorder : NSObject

@property(nonatomic, readonly) BOOL isRecording;
@property(nonatomic, readonly) ExtAudioFileRef audioFile;
@property(nonatomic, readonly) NSURL *audioFileURL;

+ (instancetype)sharedInstance;

- (BOOL)startRecording;

- (void)stopRecording;

@end
