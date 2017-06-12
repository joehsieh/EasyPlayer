//
//  NJAudioEngine.m
//  EasyPlayer
//
//  Created by joe on 14/12/17.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJAudioEngine.h"
#import "AudioUtilities.h"
#import "NJPacketArray.h"
@import AudioUnit;
@import AVFoundation;

#import "NJAudiDataProvider.h"

static NSUInteger const kSampleRate = 44100;

void NJRunningStateChangedCallback(void *inRefCon, AudioUnit ci, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement)
{

}

@interface NJAudioEngine ()
{
    AUGraph graph;
    AudioUnit mixerUnit;
    AudioUnit outputUnit;
    ExtAudioFileRef peopleAudioFileRef;
	ExtAudioFileRef synthesizedAudioFileRef;
}
@end

@implementation NJAudioEngine

- (void)dealloc
{
	[self stop];
	AUGraphUninitialize(graph);
	AUGraphClose(graph);
}

- (id)initWithDelegate:(id <NJAudioEngineDelegate>)inDelegate audioDataProviderList:(NSArray *)inAudioDataProviderList
{
	self = [super init];
	if (self) {
        NSError *audioSessionError = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&audioSessionError];
        [[AVAudioSession sharedInstance] setActive:YES error:&audioSessionError];

		self.delegate = inDelegate;
        self.audioDataProviderList = inAudioDataProviderList;
        [self _createAudioGraph];
		[self _createAudioFile:@"peopleAudio" file:&peopleAudioFileRef];
		[self _createAudioFile:@"synthesizedAudio" file:&synthesizedAudioFileRef];
	}
	return self;
}

- (void)start
{
    Boolean isRunning;
    CheckError(AUGraphIsRunning(graph, &isRunning), "AUGraphIsRunning failed");
    if (!isRunning) {
        CheckError(AUGraphStart(graph), "AUGraphStart failed");
    }
}

- (void)pause
{
	CheckError(AUGraphStop(graph), "AUGraphStop failed");
}

- (void)stop
{
	CheckError(AUGraphStop(graph), "AUGraphStop failed");
    CheckError(ExtAudioFileDispose(peopleAudioFileRef), "ExtAudioFileDispose failed");
	CheckError(ExtAudioFileDispose(synthesizedAudioFileRef), "ExtAudioFileDispose failed");
}

- (void)_createAudioGraph
{
    // new AUGraph
    CheckError(NewAUGraph(&graph), "NewAUGraph failed");
    
    // new output node
    AudioComponentDescription outputdc;
    outputdc.componentType = kAudioUnitType_Output;
    outputdc.componentSubType = kAudioUnitSubType_RemoteIO;
    outputdc.componentManufacturer = kAudioUnitManufacturer_Apple;
    AUNode outputNode;
    CheckError(AUGraphAddNode(graph, &outputdc, &outputNode), "AUGraphAddNode failed");
    
    // mixer node
    AudioComponentDescription mixerdc;
    bzero(&mixerdc, sizeof(AudioComponentDescription));
    mixerdc.componentType = kAudioUnitType_Mixer;
    mixerdc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerdc.componentManufacturer = kAudioUnitManufacturer_Apple;
    AUNode mixerNode;
    CheckError(AUGraphAddNode(graph, &mixerdc, &mixerNode), "AUGraphAddNode failed");
    
    // open graph
    CheckError(AUGraphOpen(graph), "AUGraphOpen failed");
    
    // connect nodes
    AUGraphConnectNodeInput(graph, mixerNode, 0, outputNode, 0);
	AUGraphConnectNodeInput(graph, outputNode, 1, mixerNode, 3);

    // set properties of outputNode
    CheckError(AUGraphNodeInfo(graph, outputNode, NULL, &outputUnit), "AUGraphNodeInfo failed");
    
    UInt32 flag = 1;
    // Enable IO for playing
    CheckError(AudioUnitSetProperty(outputUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    0,
                                    &flag,
                                    sizeof(flag)), "AudioUnitSetProperty failed");
    // set stream format for playing
    AudioStreamBasicDescription destFormat = LPCMStreamDescription();
    CheckError(AudioUnitSetProperty(outputUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &destFormat,
                                    sizeof(destFormat)), "AudioUnitSetProperty failed");
    
    
    // Enable IO for recording
    CheckError(AudioUnitSetProperty(outputUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    1,
                                    &flag,
                                    sizeof(flag)), "");

    // set stream format for recording
    AudioStreamBasicDescription recordFormat = RecordLPCMStreamDescription();
    CheckError(AudioUnitSetProperty(outputUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    1,
                                    &recordFormat,
                                    sizeof(recordFormat)), "AudioUnitSetProperty failed");
    
    // init graph
    CheckError(AUGraphInitialize(graph), "AUGraphInitialize failed");

    // set stream format for all buses
    CheckError(AUGraphNodeInfo(graph, mixerNode, NULL, &mixerUnit), "AUGraphNodeInfo failed");
    
    UInt32 busCount = (UInt32)[self.audioDataProviderList count];
    CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof(busCount)), "AudioUnitSetProperty failed");

    for (UInt32 busIndex = 0 ; busIndex < busCount; busIndex ++) {
        AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, busIndex, &destFormat, sizeof(destFormat));
        
        NJAudiDataProvider *audioDataProvider = self.audioDataProviderList[busIndex];
        AURenderCallbackStruct renderCallbackStruct = audioDataProvider.renderCallbackStruct;
        CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, busIndex, &renderCallbackStruct, sizeof(renderCallbackStruct)), "AudioUnitSetProperty failed");
        // set volume
        CheckError(AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, busIndex, 1.0, 0), "AudioUnitSetParameter failed");
    }
	AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &destFormat, sizeof(destFormat));
    
    // Set input callback of output node
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = NJAURecordCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    CheckError(AudioUnitSetProperty(outputUnit,
                                    kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Global,
                                    1,
                                    &callbackStruct,
                                    sizeof(callbackStruct)), "AudioUnitSetProperty failed");


#warning FIXME
	// Set output callback of mixer
//	AURenderCallbackStruct mixerOutputCallbackStruct;
//	mixerOutputCallbackStruct.inputProc = NJMixerOutputCallback;
//	mixerOutputCallbackStruct.inputProcRefCon = (__bridge void *)(self);
//	CheckError(AudioUnitSetProperty(mixerUnit,
//									kAudioUnitProperty_SetRenderCallback,
//									kAudioUnitScope_Output,
//									0,
//									&mixerOutputCallbackStruct,
//									sizeof(mixerOutputCallbackStruct)), "AudioUnitSetProperty failed");

    // set isRunning callback
    CheckError(AudioUnitAddPropertyListener(outputUnit, kAudioOutputUnitProperty_IsRunning, NJRunningStateChangedCallback, graph), "AudioUnitAddPropertyListener failed");

    CAShow(graph);
}

OSStatus NJAURecordCallback(void *							inRefCon,
                            AudioUnitRenderActionFlags *	ioActionFlags,
                            const AudioTimeStamp *			inTimeStamp,
                            UInt32							inBusNumber,
                            UInt32							inNumberFrames,
                            AudioBufferList *				ioData)
{
    NJAudioEngine *engine = (__bridge NJAudioEngine *)inRefCon;
    //double timeInSeconds = inTimeStamp->mSampleTime / kSampleRate;
    //printf("\n%fs inBusNumber: %u inNumberFrames: %u ", timeInSeconds, (unsigned int)inBusNumber, (unsigned int)inNumberFrames);

    AudioBufferList bufferList;
    SInt16 samples[inNumberFrames];
    memset(&samples, 0, sizeof(samples));
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = samples;
    bufferList.mBuffers[0].mNumberChannels = 1;
    bufferList.mBuffers[0].mDataByteSize = inNumberFrames * sizeof(SInt16);
    
    CheckError(AudioUnitRender(engine->outputUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, &bufferList), "AudioUnitRender");
    
    ExtAudioFileWriteAsync(engine->peopleAudioFileRef, inNumberFrames, &bufferList);
    return noErr;
}

OSStatus NJMixerOutputCallback(void *							inRefCon,
							AudioUnitRenderActionFlags *	ioActionFlags,
							const AudioTimeStamp *			inTimeStamp,
							UInt32							inBusNumber,
							UInt32							inNumberFrames,
							AudioBufferList *				ioData)
{
	NJAudioEngine *engine = (__bridge NJAudioEngine *)inRefCon;
	double timeInSeconds = inTimeStamp->mSampleTime / kSampleRate;
	printf("\n%fs inBusNumber: %u inNumberFrames: %u ", timeInSeconds, (unsigned int)inBusNumber, (unsigned int)inNumberFrames);

	AudioBufferList bufferList;
	SInt16 samples[inNumberFrames];
	memset(&samples, 0, sizeof(samples));
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0].mData = samples;
	bufferList.mBuffers[0].mNumberChannels = 1;
	bufferList.mBuffers[0].mDataByteSize = inNumberFrames * sizeof(SInt16);

	CheckError(AudioUnitRender(engine->outputUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, &bufferList), "AudioUnitRender");

	ExtAudioFileWriteAsync(engine->synthesizedAudioFileRef, inNumberFrames, &bufferList);
	return noErr;
}

- (void)setVolume:(CGFloat)inVolume forBusIndex:(UInt32)inBusIndex
{
    if (inBusIndex > [self.audioDataProviderList count]) {
        return;
    }
    CheckError(AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, inBusIndex, inVolume, 0), "AudioUnitSetParameter failed");
}

- (void)_createAudioFile:(NSString *)inFileName file:(ExtAudioFileRef *)inFile
{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *destinationFilePath = [[NSString alloc] initWithFormat: @"%@/%@.caf", documentsDirectory, inFileName];
    NSLog(@">>> %@\n", destinationFilePath);
    
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
    
    AudioStreamBasicDescription asbd = RecordLPCMStreamDescription();
    OSStatus setupErr = ExtAudioFileCreateWithURL(destinationURL, kAudioFileCAFType, &asbd, NULL, kAudioFileFlags_EraseFile, inFile);
    CFRelease(destinationURL);
    NSAssert(setupErr == noErr, @"Couldn't create file for writing");
    
    setupErr = ExtAudioFileSetProperty(*inFile, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &asbd);
    NSAssert(setupErr == noErr, @"Couldn't create file for format");
    
    setupErr =  ExtAudioFileWriteAsync(*inFile, 0, NULL);
    NSAssert(setupErr == noErr, @"Couldn't initialize write buffers for audio file");
}

@end
