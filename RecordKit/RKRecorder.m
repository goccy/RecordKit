//
//  RKRecorder.m
//  Pods
//
//  Created by goccy on 2017/06/15.
//
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "RKRecorder.h"
#import "RKScreenRecorder.h"
#import "RKAudioRecorder.h"
#import "RKRecordFile.h"

@interface RKRecorder()

@property(nonatomic, readwrite) BOOL isAvailable;

@property(nonatomic, readwrite) BOOL isRecording;

@property(nonatomic, readwrite) BOOL isMicrophoneEnabled;

@property(nonatomic, readwrite) BOOL isCameraEnabled;

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
    [[RKScreenRecorder sharedInstance] startRecording];
    [[RKAudioRecorder sharedInstance] startRecording];
    return YES;
}

- (BOOL)stopRecording:(void(^)(NSURL *recordedFileURL, NSError *error))completionBlock
{
    [[RKScreenRecorder sharedInstance] stopRecording:^{
        [[RKAudioRecorder sharedInstance] stopRecording];
        [self writeVideo:^(NSURL *videoFileURL, AVAssetExportSessionStatus status, NSError *error) {
            switch (status) {
                case AVAssetExportSessionStatusCompleted:
                    if (completionBlock) completionBlock(videoFileURL, error);
                    break;
                default:
                    if (completionBlock) completionBlock(nil, error);
                    break;
            }
        }];
    }];
    return YES;
}

- (void)autoRecordForSeconds:(NSUInteger)seconds withDelay:(NSUInteger)delay
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startRecording];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopRecording:^(NSURL *videoFileURL, NSError *error) {
                if (error) {
                    NSLog(@"cannot save videoFile. reason: %@", error);
                }
                if (videoFileURL) {
                    [self saveVideoToPhotoLibrary:videoFileURL];
                }
            }];
        });
    });
}

- (void)saveVideoToPhotoLibrary:(NSURL *)videoFileURL
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:videoFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"cannot copy to photo library. reason:%@", [error localizedDescription]);
        } else {
            [RKRecordFile removeFileIfExistsPath:videoFileURL.path];
        }
    }];
}

- (void)writeVideo:(void(^)(NSURL *videoFileURL, AVAssetExportSessionStatus status, NSError *error))completionBlock
{
    NSURL *videoFileURL  = [RKRecordFile fileURL:@"video.mp4"];
    NSURL *screenFileURL = [RKScreenRecorder sharedInstance].screenFileURL;
    NSURL *audioFileURL  = [RKAudioRecorder sharedInstance].audioFileURL;
    AVURLAsset *screenAsset = [[AVURLAsset alloc] initWithURL:screenFileURL options:nil];
    AVURLAsset *audioAsset  = [[AVURLAsset alloc] initWithURL:audioFileURL options:nil];
    
    AVAssetTrack *assetScreenTrack = nil;
    AVAssetTrack *assetAudioTrack  = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[screenFileURL path]]) {
        NSArray *assetArray = [screenAsset tracksWithMediaType:AVMediaTypeVideo];
        if ([assetArray count] > 0) {
            assetScreenTrack = assetArray[0];
        }
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[audioFileURL path]]) {
        NSArray *assetArray = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
        if ([assetArray count] > 0) {
            assetAudioTrack = assetArray[0];
        }
    }
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    if (assetScreenTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, screenAsset.duration) ofTrack:assetScreenTrack atTime:kCMTimeZero error:nil];
        [compositionVideoTrack setPreferredTransform:CGAffineTransformConcat(CGAffineTransformMakeScale(-1, 1), CGAffineTransformMakeRotation(M_PI))];
        if (assetAudioTrack != nil) [compositionVideoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, screenAsset.duration) toDuration:audioAsset.duration];
    }
    
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
    }
    
    [RKRecordFile removeFileIfExistsPath:videoFileURL.path];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetPassthrough];
    [exportSession setOutputFileType:AVFileTypeQuickTimeMovie];
    [exportSession setOutputURL:videoFileURL];
    [exportSession setShouldOptimizeForNetworkUse:NO];
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        [RKRecordFile removeFileIfExistsPath:screenFileURL.path];
        [RKRecordFile removeFileIfExistsPath:audioFileURL.path];
        completionBlock(videoFileURL, exportSession.status, exportSession.error);
    }];
}

@end
