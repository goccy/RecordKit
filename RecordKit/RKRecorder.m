//
//  RKRecorder.m
//  Pods
//
//  Created by goccy on 2017/06/15.
//
//

#import "RKRecorder.h"
#import "RKScreenRecorder.h"
#import "RKAudioRecorder.h"

@interface RKRecorder()

@property(nonatomic, readwrite) BOOL isAvailable;

@property(nonatomic, readwrite) BOOL isRecording;

@property(nonatomic, readwrite) BOOL isMicrophoneEnabled;

@property(nonatomic, readwrite) BOOL isCameraEnabled;

@property(nonatomic) RKScreenRecorder *screenRecorder;

@end

@implementation RKRecorder

static RKRecorder *g_sharedInstance = nil;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_sharedInstance = [RKRecorder new];
    });
    return g_sharedInstance;
}

- (BOOL)isAvailable
{
    return YES;
}

- (BOOL)startRecording
{
    self.screenRecorder = [RKScreenRecorder new];
    [self.screenRecorder startRecording];
    [[RKAudioRecorder sharedInstance] startRecording];
    return YES;
}

- (BOOL)stopRecording
{
    [self.screenRecorder stopRecording];
    [[RKAudioRecorder sharedInstance] stopRecording];
    return YES;
}

- (void)autoRecordForSeconds:(NSUInteger)seconds withDelay:(NSUInteger)delay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startRecording];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopRecording];
        });
    });
}

@end
