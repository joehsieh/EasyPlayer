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

#import "NJAudiDataProvider.h"

void NJRunningStateChangedCallback(void *inRefCon, AudioUnit ci, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement)
{

}

@interface NJAudioEngine ()
{
    AUGraph graph;
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
		self.delegate = inDelegate;
        self.audioDataProviderList = inAudioDataProviderList;
        [self _createAudioGraph];
	}
	return self;
}

- (void)start
{
	CheckError(AUGraphStart(graph), "AUGraphStart failed");
}

- (void)pause
{
#warning pause
	CheckError(AUGraphStop(graph), "AUGraphStop failed");
}

- (void)stop
{
	CheckError(AUGraphStop(graph), "AUGraphStop failed");
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
    
    // open graph
    CheckError(AUGraphOpen(graph), "AUGraphOpen failed");
    
    // init graph
    CheckError(AUGraphInitialize(graph), "AUGraphInitialize failed");
    
    // set properties of outputNode
    AudioUnit outputUnit;
    CheckError(AUGraphNodeInfo(graph, outputNode, NULL, &outputUnit), "AUGraphNodeInfo failed");
    
    // set destination stream format
    AudioStreamBasicDescription LPCMASBD = LPCMStreamDescription();
    CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &LPCMASBD, sizeof(LPCMASBD)), "");
    
    
    //    // mixer node
    //    AudioComponentDescription mixerdc;
    //    bzero(&mixerdc, sizeof(AudioComponentDescription));
    //    mixerdc.componentType = kAudioUnitType_Mixer;
    //    mixerdc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    //    mixerdc.componentManufacturer = kAudioUnitManufacturer_Apple;
    //
    //#warning precision
    //    UInt32 busCount = (UInt32)[audioEngine.audioDataProviderList count];
    //    for (NSUInteger busIndex = 0 ; busIndex < busCount; busIndex ++) {
    //        CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof (busCount)), "AudioUnitSetProperty failed");
    //
    //
    //        status = AudioUnitSetProperty(outputNode, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, busIndex, &destFormat, sizeof(destFormat));
    //
    //    }
    //    __unused OSStatus status = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof (busCount));
    //    status = AudioUnitSetParameter(self.audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, 1.0, 0);
    //    NSAssert(noErr == status, @"We need to set bus count. %d", (int)status);
    //    for (UInt32 i = 0; i < busCount; i++) {
    //        status = AudioUnitSetParameter(self.audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, i, 1.0, 0);
    //    }
    
    // set render callback
    //	callbackStruct.inputProc = NJAURenderCallback;
    NJAudiDataProvider *audioDataProvider = self.audioDataProviderList[0];
    //    callbackStruct.inputProc = audioDataProvider.
    //	callbackStruct.inputProcRefCon = (__bridge void *)(audioEngine);
    AURenderCallbackStruct renderCallbackStruct = audioDataProvider.renderCallbackStruct;
    CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(renderCallbackStruct)), "AudioUnitSetProperty failed");
    
    // set isRunning callback
    CheckError(AudioUnitAddPropertyListener(outputUnit, kAudioOutputUnitProperty_IsRunning, NJRunningStateChangedCallback, graph), "AudioUnitAddPropertyListener failed");
    
    // set volume
    CheckError(AudioUnitSetParameter(outputUnit, kHALOutputParam_Volume, kAudioUnitScope_Global, 0, 1.0, 0), "AudioUnitSetParameter failed");
    
    CAShow(graph);
}

@end