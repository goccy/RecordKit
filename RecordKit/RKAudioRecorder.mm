//
//  RKAudioRecorder.m
//  Pods
//
//  Created by goccy on 2017/06/16.
//
//

#import "RKAudioRecorder.h"
#import "RKAudioUnitProxy.h"
#import "RKRecordFile.h"

@interface RKAudioRecorder()

@property(nonatomic, readwrite) BOOL isRecording;

@property(nonatomic, readwrite) ExtAudioFileRef audioFile;

@property(nonatomic, readwrite) NSURL *audioFileURL;

@end

@implementation RKAudioRecorder

static RKAudioRecorder *g_sharedInstance = nil;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_sharedInstance = [RKAudioRecorder new];
        g_sharedInstance.audioFileURL = [RKRecordFile fileURL:@"audio.aiff"];
    });
    return g_sharedInstance;
}

- (BOOL)startRecording
{
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate       = 44100.0;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFormatFlags      = kAudioFormatFlagIsFloat|kAudioFormatFlagIsPacked|kAudioFormatFlagIsNonInterleaved;
    asbd.mBitsPerChannel   = 32;
    asbd.mChannelsPerFrame = 2;
    asbd.mFramesPerPacket  = 1;
    asbd.mBytesPerFrame    = 4;
    asbd.mBytesPerPacket   = 4;
    asbd.mReserved         = 0;
    
    AudioStreamBasicDescription createASBD;
    memcpy(&createASBD, &asbd, sizeof(AudioStreamBasicDescription));
    createASBD.mFormatFlags      = kLinearPCMFormatFlagIsBigEndian|kLinearPCMFormatFlagIsSignedInteger|kLinearPCMFormatFlagIsPacked;
    createASBD.mBitsPerChannel   = 16;
    
    if (ExtAudioFileCreateWithURL((__bridge CFURLRef)self.audioFileURL,
                                  kAudioFileAIFFType,
                                  &createASBD,
                                  NULL,
                                  kAudioFileFlags_EraseFile,
                                  &_audioFile) != noErr) {
        return NO;
    }
    // Set up the converter
    if (ExtAudioFileSetProperty(self.audioFile,
                                kExtAudioFileProperty_ClientDataFormat,
                                sizeof(AudioStreamBasicDescription),
                                &asbd) != noErr) {
        return NO;
    }
    self.isRecording = YES;
    return YES;
}

- (void)stopRecording
{
    self.isRecording = NO;
    ExtAudioFileDispose(self.audioFile);
    NSLog(@"write file %@", self.audioFileURL.path);
}

+ (void)injectAudioUnitProxy
{
    // (1) Fetch all `AudioComponent` by `AudioComponentFindNext`
    // (2) `AudioComponentRegister` can register customized AudioUnit defined lifecycle.
    // (3) Define newer version of predefined AudioUnit
    // (4) After this section, `AudioComponentFindNext(NULL, desc)` returns `newer` version for AudioUnit ( our customized AudioUnit )
    AudioComponentDescription allDesc = {0};
    AudioComponent component = NULL;
    while ((component = AudioComponentFindNext(component, &allDesc)) != NULL) {
        AudioComponentDescription outDesc;
        AudioComponentGetDescription(component, &outDesc);
        CFStringRef name;
        AudioComponentCopyName(component, &name);
        UInt32 version;
        AudioComponentGetVersion(component, &version);
        
        // ignore not supported componentSubType
        if (outDesc.componentSubType == kAudioUnitSubType_AUiPodTime) continue;
        if (outDesc.componentSubType == kAudioUnitSubType_AUiPodEQ) continue;

        AudioComponentInstance instance;
        assert(AudioComponentInstanceNew(component, &instance) == noErr);
        if (AudioUnitInitialize(instance) == noErr) {
            AudioComponentRegister(&outDesc, name, version + 1, &RKAudioUnitProxyPlugin::factory);
        }
        AudioUnitUninitialize(instance);
        AudioComponentInstanceDispose(instance);
    }
}

+ (void)load
{
    [[self class] injectAudioUnitProxy];
}

@end
