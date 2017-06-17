//
//  RKRecorder.h
//  Pods
//
//  Created by goccy on 2017/06/15.
//
//

#import <Foundation/Foundation.h>

@interface RKRecorder : NSObject

/**
 * A Boolean value that indicates whether the recorder is available for recording.
 */
@property(nonatomic, readonly) BOOL isAvailable;

/**
 * A Boolean value that indicates whether the app is currently recording.
 */
@property(nonatomic, readonly) BOOL isRecording;

/**
 * A Boolean value that indicates whether the microphone is currently enabled.
 */
@property(nonatomic, readonly) BOOL isMicrophoneEnabled;

/**
 * A Boolean value that indicates whether the camera is currently enabled.
 */
@property(nonatomic, readonly) BOOL isCameraEnabled;

/**
 * Returns an app’s instance of the shared recorder.
 */
+ (instancetype)sharedInstance;

/**
 * Starts recording the app display and sound.
 */
- (BOOL)startRecording;

/**
 * Stops the current recording.
 */
- (BOOL)stopRecording:(void(^)(NSURL *recordedFileURL, NSError *error))completionBlock;

/**
 * automatically recording the app display and sound ( for testing )
 * @param seconds recording total time
 * @param delay defer recording timing
 */
- (void)autoRecordForSeconds:(NSUInteger)seconds withDelay:(NSUInteger)delay;

@end
