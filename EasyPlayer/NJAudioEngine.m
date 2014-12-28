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
    Boolean isRunning;
    CheckError(AUGraphIsRunning(graph, &isRunning), "AUGraphIsRunning failed");
    if (!isRunning) {
        CheckError(AUGraphStart(graph), "AUGraphStart failed");
    }
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
    
    // set properties of outputNode
    AudioUnit outputUnit;
    CheckError(AUGraphNodeInfo(graph, outputNode, NULL, &outputUnit), "AUGraphNodeInfo failed");
    // set destination stream format
    AudioStreamBasicDescription destFormat = LPCMStreamDescription();
    CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &destFormat, sizeof(destFormat)), "AudioUnitSetProperty failed");
    
    // init graph
    CheckError(AUGraphInitialize(graph), "AUGraphInitialize failed");

#warning precision
    // set stream format for all buses
    AudioUnit mixerUnit;
    CheckError(AUGraphNodeInfo(graph, mixerNode, NULL, &mixerUnit), "AUGraphNodeInfo failed");
    
    NSUInteger busCount = [self.audioDataProviderList count];
    CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &busCount, sizeof(busCount)), "AudioUnitSetProperty failed");
    
    for (NSUInteger busIndex = 0 ; busIndex < busCount; busIndex ++) {
        AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, busIndex, &destFormat, sizeof(destFormat));
        AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, busIndex, &destFormat, sizeof(destFormat));
        
        NJAudiDataProvider *audioDataProvider = self.audioDataProviderList[busIndex];
        AURenderCallbackStruct renderCallbackStruct = audioDataProvider.renderCallbackStruct;
        CheckError(AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, busIndex, &renderCallbackStruct, sizeof(renderCallbackStruct)), "AudioUnitSetProperty failed");
        // set volume
        CheckError(AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, busIndex, 1.0, 0), "AudioUnitSetParameter failed");
    }
    
    // set isRunning callback
    CheckError(AudioUnitAddPropertyListener(outputUnit, kAudioOutputUnitProperty_IsRunning, NJRunningStateChangedCallback, graph), "AudioUnitAddPropertyListener failed");

    CAShow(graph);
}

@end