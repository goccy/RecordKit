//
//  RKScreenRecorder.m
//  Pods
//
//  Created by goccy on 2017/06/16.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/ES2/glext.h>
#import "RKScreenRecorder.h"
#import "RKRecordFile.h"

@interface RKScreenRecorder()

@property(nonatomic) CGSize defaultScreenSize;
@property(nonatomic) CGFloat screenScale;

@property(nonatomic) NSInteger fixedBytesPerRow;
@property(nonatomic) CGSize fixedScreenSize;

@property(nonatomic) CADisplayLink *displayLink;
@property(nonatomic) CVPixelBufferPoolRef capturePixelBufferPool;
@property(nonatomic) CVPixelBufferRef capturePixelBuffer;

@property(nonatomic) AVAssetWriter *screenWriter;
@property(nonatomic) AVAssetWriterInput *screenWriterInput;
@property(nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *screenWriterAdaptor;

@property(nonatomic) CFTimeInterval firstCapturedAt;
@property(nonatomic) double currentTimeElapsed;

@end

@implementation RKScreenRecorder

static const NSInteger RGBA = 4;

- (void)setupScreenSize
{
    self.defaultScreenSize  = [UIScreen mainScreen].bounds.size;
    self.screenScale        = [UIScreen mainScreen].scale;
    
    CGFloat screenWidth  = self.defaultScreenSize.width  * self.screenScale;
    CGFloat screenHeight = self.defaultScreenSize.height * self.screenScale;
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVPixelBufferCreate(kCFAllocatorDefault, screenWidth, screenHeight, kCVPixelFormatType_32BGRA, NULL, &pixelBuffer);
    
    // correctly report the buffer alignment (stride) being used by the particular hardware
    self.fixedBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    self.fixedScreenSize  = CGSizeMake(self.fixedBytesPerRow / RGBA, screenHeight);
    
    if (self.fixedScreenSize.width != screenWidth) {
        NSLog(@"defaultScreenWidth:[%f] != fixedScreenWidth:[%f]", screenWidth, self.fixedScreenSize.width);
    }
    
    CVPixelBufferRelease(pixelBuffer);
}

- (NSDictionary *)captureAttributes
{
    return @{
        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
        (id)kCVPixelBufferWidthKey  : @(self.fixedScreenSize.width),
        (id)kCVPixelBufferHeightKey : @(self.fixedScreenSize.height),
        (id)kCVPixelBufferBytesPerRowAlignmentKey : @(0)
    };
}

- (NSURL *)defaultRecordFileURL
{
    return [RKRecordFile fileURL:@"screen.mp4"];
}

- (BOOL)setupScreenWriter
{
    NSError *error = nil;
    self.screenWriter = [[AVAssetWriter alloc] initWithURL:[self defaultRecordFileURL]
                                                  fileType:AVFileTypeMPEG4
                                                     error:&error];
    if (error != nil) {
        return NO;
    }
    CGSize encodeScreenSize = (self.screenScale > 2) ?
        CGSizeMake(self.defaultScreenSize.width * 2, self.defaultScreenSize.height * 2) : self.fixedScreenSize;

    NSInteger pixelCount           = encodeScreenSize.width * encodeScreenSize.height;
    NSDictionary *videoCompression = @{AVVideoAverageBitRateKey: @(pixelCount * 11.4)};
    NSDictionary *videoSettings    = @{AVVideoCodecKey: AVVideoCodecH264,
                                       AVVideoWidthKey:  @(encodeScreenSize.width),
                                       AVVideoHeightKey: @(encodeScreenSize.height),
                                       AVVideoCompressionPropertiesKey: videoCompression};
    self.screenWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    self.screenWriterInput.expectsMediaDataInRealTime = YES;
    self.screenWriterInput.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(-1, 1), CGAffineTransformMakeRotation(M_PI));
    self.screenWriterAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.screenWriterInput sourcePixelBufferAttributes:nil];
    [self.screenWriter addInput:self.screenWriterInput];
    [self.screenWriter startWriting];
    [self.screenWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
    return YES;
}

- (BOOL)startRecording
{
    [RKRecordFile removeFileIfExistsPath:[self defaultRecordFileURL].path];
    [self setupScreenSize];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(capture)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    self.capturePixelBufferPool = NULL;
    CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)[self captureAttributes], &_capturePixelBufferPool);
    CVPixelBufferPoolCreatePixelBuffer(NULL, self.capturePixelBufferPool, (CVPixelBufferRef *)&_capturePixelBuffer);
    if ([self setupScreenWriter]) {
        return YES;
    }
    return NO;
}

- (void)stopRecording
{
    [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink = nil;

    CVPixelBufferRelease(self.capturePixelBuffer);
    CVPixelBufferPoolRelease(self.capturePixelBufferPool);

    [self.screenWriterInput markAsFinished];
    [self.screenWriter finishWritingWithCompletionHandler:^{
        NSLog(@"write %@", [self defaultRecordFileURL]);
    }];
}

- (void)capture
{
    if (![self.screenWriterInput isReadyForMoreMediaData]) return;
    
    if (!self.firstCapturedAt) {
        self.firstCapturedAt = self.displayLink.timestamp;
    }
    if (!self.displayLink) return;
    
    CFTimeInterval elapsedTime = (self.displayLink.timestamp - self.firstCapturedAt);
    self.currentTimeElapsed    = elapsedTime;
    CMTime time                = CMTimeMakeWithSeconds(elapsedTime, 1000);
    
    CVPixelBufferLockBaseAddress(self.capturePixelBuffer, 0);

    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;

    UIGraphicsBeginImageContextWithOptions(keyWindow.frame.size, NO, 0.0);
    [keyWindow drawViewHierarchyInRect:keyWindow.frame afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    void *pixelData = CVPixelBufferGetBaseAddress(self.capturePixelBuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixelData, _fixedScreenSize.width, _fixedScreenSize.height,
                                                 8, CVPixelBufferGetBytesPerRow(self.capturePixelBuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGBitmapByteOrder32Little |
                                                 kCGImageAlphaPremultipliedFirst);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGAffineTransform flipVertical = CGAffineTransformMake( 1, 0, 0, -1, 0, CGImageGetHeight(image.CGImage));
    CGContextConcatCTM(context, flipVertical);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage)), image.CGImage);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);

    BOOL isWriteSuccess = [self.screenWriterAdaptor appendPixelBuffer:self.capturePixelBuffer withPresentationTime:time];
    if (!isWriteSuccess) {
        NSLog(@"Warning: Unable to write buffer to video");
    }
    CVPixelBufferUnlockBaseAddress(self.capturePixelBuffer, 0);
}


@end
