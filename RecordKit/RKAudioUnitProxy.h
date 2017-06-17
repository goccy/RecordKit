//
//  RKAudioUnitProxy.h
//  Pods
//
//  Created by goccy on 2017/06/16.
//
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

class RKAudioUnitProxy {
public:
    AudioUnit __nonnull audioUnit;
    AudioUnit __nonnull originalAudioUnit;
    AudioComponentDescription audioComponentDescription;
    
    RKAudioUnitProxy(AudioComponentInstance __nonnull instance);
    ~RKAudioUnitProxy(void);
    void setAudioComponentDescription(AudioComponentDescription from);
};

class RKAudioUnitProxyPlugin {
public:
    RKAudioUnitProxyPlugin(void);
    ~RKAudioUnitProxyPlugin(void);
    static AudioComponentPlugInInterface *__nonnull factory(const AudioComponentDescription *__nonnull inDesc);
    
private:
    RKAudioUnitProxy *__nonnull audioUnitProxy;
    
    static OSStatus open(AudioComponentPlugInInterface *__nonnull plugin, AudioComponentInstance __nonnull instance);
    static OSStatus close(AudioComponentPlugInInterface *__nonnull plugin);
    static AudioComponentMethod __nonnull lookup(SInt16 selector);
    
    static OSStatus unInitialize(AudioComponentPlugInInterface *__nonnull plugin);
    static OSStatus initialize(AudioComponentPlugInInterface *__nonnull plugin);
    static OSStatus getPropertyInfo(AudioComponentPlugInInterface *__nonnull plugin,
                                    AudioUnitPropertyID inID,
                                    AudioUnitScope inScope,
                                    AudioUnitElement inElement,
                                    UInt32 *__nullable outDataSize,
                                    Boolean *__nullable outWritable);
    static OSStatus getProperty(AudioComponentPlugInInterface *__nonnull plugin,
                                AudioUnitPropertyID inID,
                                AudioUnitScope inScope,
                                AudioUnitElement inElement,
                                void *__nonnull outData,
                                UInt32 *__nonnull ioDataSize);
    static OSStatus setProperty(AudioComponentPlugInInterface *__nonnull plugin,
                                AudioUnitPropertyID inID,
                                AudioUnitScope inScope,
                                AudioUnitElement inElement,
                                const void * __nullable inData,
                                UInt32 inDataSize);
    static OSStatus addPropertyListener(AudioComponentPlugInInterface *__nonnull plugin,
                                        AudioUnitPropertyID inID,
                                        AudioUnitPropertyListenerProc __nonnull inProc,
                                        void * __nullable inProcUserData);
    static OSStatus removePropertyListenerWithUserData(AudioComponentPlugInInterface *__nonnull plugin,
                                                       AudioUnitPropertyID inID,
                                                       AudioUnitPropertyListenerProc __nonnull inProc,
                                                       void * __nullable inProcUserData);
    static OSStatus addRenderNotify(AudioComponentPlugInInterface *__nonnull plugin,
                                    AURenderCallback __nonnull inProc,
                                    void *__nullable inProcUserData);
    static OSStatus removeRenderNotify(AudioComponentPlugInInterface *__nonnull plugin,
                                       AURenderCallback __nonnull inProc,
                                       void *__nullable inProcUserData);
    static OSStatus getParameter(AudioComponentPlugInInterface *__nonnull plugin,
                                 AudioUnitParameterID inID,
                                 AudioUnitScope inScope,
                                 AudioUnitElement inElement,
                                 AudioUnitParameterValue *__nonnull outValue);
    static OSStatus setParameter(AudioComponentPlugInInterface *__nonnull plugin,
                                 AudioUnitParameterID inID,
                                 AudioUnitScope inScope,
                                 AudioUnitElement inElement,
                                 AudioUnitParameterValue inValue,
                                 UInt32	inBufferOffsetInFrames);
    static OSStatus scheduleParameters(AudioComponentPlugInInterface *__nonnull plugin,
                                       const AudioUnitParameterEvent *__nonnull inParameterEvent,
                                       UInt32 inNumParamEvents);
    static OSStatus reset(AudioComponentPlugInInterface *__nonnull plugin,
                          AudioUnitScope inScope,
                          AudioUnitElement inElement);
    static OSStatus process(AudioComponentPlugInInterface *__nonnull plugin,
                            AudioUnitRenderActionFlags *__nullable ioActionFlags,
                            const AudioTimeStamp *__nonnull inTimeStamp,
                            UInt32 inNumberFrames,
                            AudioBufferList *__nonnull ioData);
    static OSStatus processMultiple(AudioComponentPlugInInterface *__nonnull plugin,
                                    AudioUnitRenderActionFlags *__nullable ioActionFlags,
                                    const AudioTimeStamp *__nonnull inTimeStamp,
                                    UInt32 inNumberFrames,
                                    UInt32 inNumberInputBufferLists,
                                    const AudioBufferList * __nonnull * __nonnull inInputBufferLists,
                                    UInt32 inNumberOutputBufferLists,
                                    AudioBufferList * __nonnull * __nonnull ioOutputBufferLists);
    static OSStatus render(AudioComponentPlugInInterface *__nonnull plugin,
                           AudioUnitRenderActionFlags *__nonnull ioActionFlags,
                           const AudioTimeStamp *__nonnull inTimeStamp,
                           UInt32 inOutputBusNumber,
                           UInt32 inNumberFrames,
                           AudioBufferList *__nonnull ioData);
    static OSStatus start(AudioComponentPlugInInterface *__nonnull plugin);
    static OSStatus stop(AudioComponentPlugInInterface *__nonnull plugin);
    static OSStatus callback0x101(AudioComponentPlugInInterface *__nonnull plugin);
    static OSStatus callback0x102(AudioComponentPlugInInterface *__nonnull plugin);
    static OSStatus callback0x105(AudioComponentPlugInInterface *__nonnull plugin);
    static OSStatus callback0x106(AudioComponentPlugInInterface *__nonnull plugin);
    static OSStatus callback0x008(AudioComponentPlugInInterface *__nonnull plugin);
    static OSStatus callback0x00c(AudioComponentPlugInInterface *__nonnull plugin);
};
