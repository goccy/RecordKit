//
//  RKAudioUnitProxy.m
//  Pods
//
//  Created by goccy on 2017/06/16.
//
//

#import "RKAudioUnitProxy.h"
#import "RKAudioRecorder.h"

RKAudioUnitProxy::RKAudioUnitProxy(AudioComponentInstance instance)
{
    this->audioUnit = instance;
    AudioComponent component = AudioComponentInstanceGetComponent(this->audioUnit);
    AudioComponentDescription outDesc;
    AudioComponentGetDescription(component, &outDesc);
    AudioComponent originalComponent = AudioComponentFindNext(component, &outDesc);
    assert(AudioComponentInstanceNew(originalComponent, &this->originalAudioUnit) == noErr);
    setAudioComponentDescription(outDesc);
}

void RKAudioUnitProxy::setAudioComponentDescription(AudioComponentDescription from)
{
    this->audioComponentDescription.componentType         = from.componentType;
    this->audioComponentDescription.componentSubType      = from.componentSubType;
    this->audioComponentDescription.componentFlags        = from.componentFlags;
    this->audioComponentDescription.componentManufacturer = from.componentManufacturer;
    this->audioComponentDescription.componentFlagsMask    = from.componentFlagsMask;
}

RKAudioUnitProxy::~RKAudioUnitProxy(void)
{
    
}

RKAudioUnitProxyPlugin::RKAudioUnitProxyPlugin(void) : audioUnitProxy(NULL)
{
    
}

RKAudioUnitProxyPlugin::~RKAudioUnitProxyPlugin(void)
{
    if (audioUnitProxy) {
        delete audioUnitProxy;
        audioUnitProxy = NULL;
    }
}

#define THIS ((RKAudioUnitProxyPlugin *)plugin->reserved)

AudioComponentPlugInInterface *RKAudioUnitProxyPlugin::factory(const AudioComponentDescription *inDesc)
{
    AudioComponentPlugInInterface *interface = (AudioComponentPlugInInterface *)malloc(sizeof(AudioComponentPlugInInterface));
    interface->Open   = (OSStatus (*)(void *, AudioComponentInstance))RKAudioUnitProxyPlugin::open;
    interface->Close  = (OSStatus (*)(void *))RKAudioUnitProxyPlugin::close;
    interface->Lookup = RKAudioUnitProxyPlugin::lookup;
    interface->reserved = new RKAudioUnitProxyPlugin();
    return interface;
}

OSStatus RKAudioUnitProxyPlugin::open(AudioComponentPlugInInterface * _Nonnull plugin, AudioComponentInstance instance)
{
    THIS->audioUnitProxy = new RKAudioUnitProxy(instance);
    return noErr;
}

OSStatus RKAudioUnitProxyPlugin::close(AudioComponentPlugInInterface * _Nonnull plugin)
{
    RKAudioUnitProxyPlugin *proxyPlugin = (RKAudioUnitProxyPlugin *)plugin->reserved;
    delete proxyPlugin;
    plugin->reserved = NULL;
    return noErr;
}

AudioComponentMethod RKAudioUnitProxyPlugin::lookup(SInt16 selector)
{
    AudioComponentMethod method = NULL;
    switch (selector) {
        case kAudioUnitRange:
            break;
        case kAudioUnitInitializeSelect:
            method = (AudioComponentMethod)initialize;
            break;
        case kAudioUnitUninitializeSelect:
            method = (AudioComponentMethod)unInitialize;
            break;
        case kAudioUnitGetPropertyInfoSelect:
            method = (AudioComponentMethod)getPropertyInfo;
            break;
        case kAudioUnitGetPropertySelect:
            method = (AudioComponentMethod)getProperty;
            break;
        case kAudioUnitSetPropertySelect:
            method = (AudioComponentMethod)setProperty;
            break;
        case kAudioUnitAddPropertyListenerSelect:
            method = (AudioComponentMethod)addPropertyListener;
            break;
        case kAudioUnitRemovePropertyListenerSelect:
            method = (AudioComponentMethod)removePropertyListenerWithUserData;
            break;
        case kAudioUnitRemovePropertyListenerWithUserDataSelect:
            method = (AudioComponentMethod)removePropertyListenerWithUserData;
            break;
        case kAudioUnitAddRenderNotifySelect:
            method = (AudioComponentMethod)addRenderNotify;
            break;
        case kAudioUnitRemoveRenderNotifySelect:
            method = (AudioComponentMethod)removeRenderNotify;
            break;
        case kAudioUnitGetParameterSelect:
            method = (AudioComponentMethod)getParameter;
            break;
        case kAudioUnitSetParameterSelect:
            method = (AudioComponentMethod)setParameter;
            break;
        case kAudioUnitScheduleParametersSelect:
            method = (AudioComponentMethod)scheduleParameters;
            break;
        case kAudioUnitRenderSelect:
            method = (AudioComponentMethod)render;
            break;
        case kAudioUnitResetSelect:
            method = (AudioComponentMethod)reset;
            break;
        case kAudioUnitComplexRenderSelect:
            method = (AudioComponentMethod)render;
            break;
        case kAudioUnitProcessSelect:
            method = (AudioComponentMethod)process;
            break;
        case kAudioUnitProcessMultipleSelect:
            method = (AudioComponentMethod)processMultiple;
            break;
            // the flowing cases are undocumented.
            // But used by APComponent::CreateDispatchTable
        case kAudioOutputUnitStartSelect:
            method = (AudioComponentMethod)start;
            break;
        case kAudioOutputUnitStopSelect:
            method = (AudioComponentMethod)stop;
            break;
        case 0x008:
            method = (AudioComponentMethod)callback0x008;
            break;
        case 0x00c:
            method = (AudioComponentMethod)callback0x00c;
            break;
        case 0x101:
            method = (AudioComponentMethod)callback0x101;
            break;
        case 0x102:
            method = (AudioComponentMethod)callback0x102;
            break;
        case 0x105:
            method = (AudioComponentMethod)callback0x105;
            break;
        case 0x106:
            method = (AudioComponentMethod)callback0x106;
            break;
        default:
            NSLog(@"RKAudioUnitProxyPlugin::default");
            break;
    }
    return method;
}

OSStatus RKAudioUnitProxyPlugin::unInitialize(AudioComponentPlugInInterface * _Nonnull plugin)
{
    return AudioUnitUninitialize(THIS->audioUnitProxy->originalAudioUnit);
}

OSStatus RKAudioUnitProxyPlugin::initialize(AudioComponentPlugInInterface * _Nonnull plugin)
{
    return AudioUnitInitialize(THIS->audioUnitProxy->originalAudioUnit);
}

OSStatus RKAudioUnitProxyPlugin::getPropertyInfo(AudioComponentPlugInInterface * _Nonnull plugin,
                                                 AudioUnitPropertyID inID,
                                                 AudioUnitScope inScope,
                                                 AudioUnitElement inElement,
                                                 UInt32 * _Nullable outDataSize,
                                                 Boolean * _Nullable outWritable)
{
    return AudioUnitGetPropertyInfo(THIS->audioUnitProxy->originalAudioUnit, inID, inScope, inElement, outDataSize, outWritable);
}

OSStatus RKAudioUnitProxyPlugin::getProperty(AudioComponentPlugInInterface * _Nonnull plugin,
                                             AudioUnitPropertyID inID,
                                             AudioUnitScope inScope,
                                             AudioUnitElement inElement,
                                             void * _Nonnull outData,
                                             UInt32 * _Nonnull ioDataSize)
{
    return AudioUnitGetProperty(THIS->audioUnitProxy->originalAudioUnit, inID, inScope, inElement, outData, ioDataSize);
}

OSStatus RKAudioUnitProxyPlugin::setProperty(AudioComponentPlugInInterface * _Nonnull plugin,
                                             AudioUnitPropertyID inID,
                                             AudioUnitScope inScope,
                                             AudioUnitElement inElement,
                                             const void * _Nullable inData,
                                             UInt32 inDataSize)
{
    OSStatus ret = AudioUnitSetProperty(THIS->audioUnitProxy->originalAudioUnit, inID, inScope, inElement, inData, inDataSize);
    RKAudioUnitProxy *proxy = THIS->audioUnitProxy;
    if (ret != noErr) {
        AudioComponent component = AudioComponentInstanceGetComponent(proxy->originalAudioUnit);
        CFStringRef name;
        AudioComponentCopyName(component, &name);
        NSLog(@"RKAudioUnitProxyPlugin::setProperty componentName = %@", name);
    }
    assert(ret == noErr);
    return ret;
}

OSStatus RKAudioUnitProxyPlugin::addPropertyListener(AudioComponentPlugInInterface * _Nonnull plugin,
                                                     AudioUnitPropertyID inID,
                                                     AudioUnitPropertyListenerProc  _Nonnull inProc,
                                                     void * _Nullable inProcUserData)
{
    return AudioUnitAddPropertyListener(THIS->audioUnitProxy->originalAudioUnit, inID, inProc, inProcUserData);
}

OSStatus RKAudioUnitProxyPlugin::removePropertyListenerWithUserData(AudioComponentPlugInInterface * _Nonnull plugin,
                                                                    AudioUnitPropertyID inID,
                                                                    AudioUnitPropertyListenerProc _Nonnull inProc,
                                                                    void * _Nullable inProcUserData)
{
    return AudioUnitRemovePropertyListenerWithUserData(THIS->audioUnitProxy->originalAudioUnit, inID, inProc, inProcUserData);
}

OSStatus RKAudioUnitProxyPlugin::addRenderNotify(AudioComponentPlugInInterface * _Nonnull plugin,
                                                 AURenderCallback  _Nonnull inProc,
                                                 void * _Nullable inProcUserData)
{
    return AudioUnitAddRenderNotify(THIS->audioUnitProxy->originalAudioUnit, inProc, inProcUserData);
}

OSStatus RKAudioUnitProxyPlugin::removeRenderNotify(AudioComponentPlugInInterface * _Nonnull plugin,
                                                    AURenderCallback  _Nonnull inProc,
                                                    void * _Nullable inProcUserData)
{
    return AudioUnitRemoveRenderNotify(THIS->audioUnitProxy->originalAudioUnit, inProc, inProcUserData);
}

OSStatus RKAudioUnitProxyPlugin::getParameter(AudioComponentPlugInInterface * _Nonnull plugin,
                                              AudioUnitParameterID inID,
                                              AudioUnitScope inScope,
                                              AudioUnitElement inElement,
                                              AudioUnitParameterValue * _Nonnull outValue)
{
    return AudioUnitGetParameter(THIS->audioUnitProxy->originalAudioUnit, inID, inScope, inElement, outValue);
}

OSStatus RKAudioUnitProxyPlugin::setParameter(AudioComponentPlugInInterface * _Nonnull plugin,
                                              AudioUnitParameterID inID,
                                              AudioUnitScope inScope,
                                              AudioUnitElement inElement,
                                              AudioUnitParameterValue inValue,
                                              UInt32 inBufferOffsetInFrames)
{
    return AudioUnitSetParameter(THIS->audioUnitProxy->originalAudioUnit, inID, inScope, inElement, inValue, inBufferOffsetInFrames);
}

OSStatus RKAudioUnitProxyPlugin::scheduleParameters(AudioComponentPlugInInterface * _Nonnull plugin,
                                                    const AudioUnitParameterEvent * _Nonnull inParameterEvent,
                                                    UInt32 inNumParamEvents)
{
    return AudioUnitScheduleParameters(THIS->audioUnitProxy->originalAudioUnit, inParameterEvent, inNumParamEvents);
}

OSStatus RKAudioUnitProxyPlugin::reset(AudioComponentPlugInInterface * _Nonnull plugin,
                                       AudioUnitScope inScope,
                                       AudioUnitElement inElement)
{
    return AudioUnitReset(THIS->audioUnitProxy->originalAudioUnit, inScope, inElement);
}

OSStatus RKAudioUnitProxyPlugin::process(AudioComponentPlugInInterface * _Nonnull plugin,
                                         AudioUnitRenderActionFlags * _Nullable ioActionFlags,
                                         const AudioTimeStamp * _Nonnull inTimeStamp,
                                         UInt32 inNumberFrames,
                                         AudioBufferList * _Nonnull ioData)
{
    return AudioUnitProcess(THIS->audioUnitProxy->originalAudioUnit, ioActionFlags, inTimeStamp, inNumberFrames, ioData);
}

OSStatus RKAudioUnitProxyPlugin::processMultiple(AudioComponentPlugInInterface * _Nonnull plugin,
                                                 AudioUnitRenderActionFlags * _Nullable ioActionFlags,
                                                 const AudioTimeStamp * _Nonnull inTimeStamp,
                                                 UInt32 inNumberFrames,
                                                 UInt32 inNumberInputBufferLists,
                                                 const AudioBufferList * _Nonnull * _Nonnull inInputBufferLists,
                                                 UInt32 inNumberOutputBufferLists,
                                                 AudioBufferList * _Nonnull * _Nonnull ioOutputBufferLists)
{
    return AudioUnitProcessMultiple(THIS->audioUnitProxy->originalAudioUnit,
                                    ioActionFlags,
                                    inTimeStamp,
                                    inNumberFrames,
                                    inNumberInputBufferLists,
                                    inInputBufferLists,
                                    inNumberOutputBufferLists,
                                    ioOutputBufferLists);
}

OSStatus RKAudioUnitProxyPlugin::render(AudioComponentPlugInInterface * _Nonnull plugin,
                                        AudioUnitRenderActionFlags * _Nonnull ioActionFlags,
                                        const AudioTimeStamp * _Nonnull inTimeStamp,
                                        UInt32 inOutputBusNumber,
                                        UInt32 inNumberFrames,
                                        AudioBufferList * _Nonnull ioData)
{
    OSStatus ret = AudioUnitRender(THIS->audioUnitProxy->originalAudioUnit,
                                   ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, ioData);
    
    if (![RKAudioRecorder sharedInstance].isRecording) return ret;

#if TARGET_IPHONE_SIMULATOR
    if (THIS->audioUnitProxy->audioComponentDescription.componentType == kAudioUnitType_Mixer &&
        THIS->audioUnitProxy->audioComponentDescription.componentSubType == kAudioUnitSubType_SpatialMixer) return ret;
#endif
    if (ExtAudioFileWrite([RKAudioRecorder sharedInstance].audioFile, inNumberFrames, ioData) != noErr) {
        NSLog(@"WARN: Unable to write audio");
    }
    return ret;
}

OSStatus RKAudioUnitProxyPlugin::start(AudioComponentPlugInInterface * _Nonnull plugin)
{
    return AudioOutputUnitStart(THIS->audioUnitProxy->originalAudioUnit);
}

OSStatus RKAudioUnitProxyPlugin::stop(AudioComponentPlugInInterface * _Nonnull plugin)
{
    return AudioOutputUnitStop(THIS->audioUnitProxy->originalAudioUnit);
}

OSStatus RKAudioUnitProxyPlugin::callback0x101(AudioComponentPlugInInterface * _Nonnull plugin)
{
    RKAudioUnitProxy *proxy = THIS->audioUnitProxy;
    AudioComponent component = AudioComponentInstanceGetComponent(proxy->originalAudioUnit);
    CFStringRef name;
    AudioComponentCopyName(component, &name);
    NSLog(@"called unknown callback function by 0x101. componentName = %@", name);
    return noErr;
}

OSStatus RKAudioUnitProxyPlugin::callback0x102(AudioComponentPlugInInterface * _Nonnull plugin)
{
    RKAudioUnitProxy *proxy = THIS->audioUnitProxy;
    AudioComponent component = AudioComponentInstanceGetComponent(proxy->originalAudioUnit);
    CFStringRef name;
    AudioComponentCopyName(component, &name);
    NSLog(@"called unknown callback function by 0x102");
    return noErr;
}

OSStatus RKAudioUnitProxyPlugin::callback0x105(AudioComponentPlugInInterface * _Nonnull plugin)
{
    RKAudioUnitProxy *proxy = THIS->audioUnitProxy;
    AudioComponent component = AudioComponentInstanceGetComponent(proxy->originalAudioUnit);
    CFStringRef name;
    AudioComponentCopyName(component, &name);
    NSLog(@"called unknown callback function by 0x105");
    return noErr;
}

OSStatus RKAudioUnitProxyPlugin::callback0x106(AudioComponentPlugInInterface * _Nonnull plugin)
{
    RKAudioUnitProxy *proxy = THIS->audioUnitProxy;
    AudioComponent component = AudioComponentInstanceGetComponent(proxy->originalAudioUnit);
    CFStringRef name;
    AudioComponentCopyName(component, &name);
    NSLog(@"called unknown callback function by 0x106");
    return noErr;
}

OSStatus RKAudioUnitProxyPlugin::callback0x008(AudioComponentPlugInInterface * _Nonnull plugin)
{
    RKAudioUnitProxy *proxy = THIS->audioUnitProxy;
    AudioComponent component = AudioComponentInstanceGetComponent(proxy->originalAudioUnit);
    CFStringRef name;
    AudioComponentCopyName(component, &name);
    NSLog(@"called unknown callback function by 0x008");
    return noErr;
}

OSStatus RKAudioUnitProxyPlugin::callback0x00c(AudioComponentPlugInInterface * _Nonnull plugin)
{
    RKAudioUnitProxy *proxy = THIS->audioUnitProxy;
    AudioComponent component = AudioComponentInstanceGetComponent(proxy->originalAudioUnit);
    CFStringRef name;
    AudioComponentCopyName(component, &name);
    NSLog(@"called unknown callback function by 0x00c");
    return noErr;
}
