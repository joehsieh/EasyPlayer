//
//  NJAudioEngine.m
//  EasyPlayer
//
//  Created by joe on 14/12/17.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJAudioEngine.h"
#import "AudioUtilities.h"
@import AudioUnit;

#pragma render callback

OSStatus NJAURenderCallback(void *							inRefCon,
						  AudioUnitRenderActionFlags *	ioActionFlags,
						  const AudioTimeStamp *			inTimeStamp,
						  UInt32							inBusNumber,
						  UInt32							inNumberFrames,
						  AudioBufferList *				ioData)
{
	return noErr;
}

void NJRunningStateChangedCallback(void *inRefCon, AudioUnit ci, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement)
{

}

AudioStreamBasicDescription LPCMStreamDescription()
{
	AudioStreamBasicDescription destFormat;
	bzero(&destFormat, sizeof(AudioStreamBasicDescription));
	destFormat.mSampleRate = 44100.0;
	destFormat.mFormatID = kAudioFormatLinearPCM;
	destFormat.mReserved = 0;
	destFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat;
	destFormat.mBitsPerChannel = sizeof(Float32) * 8;
	destFormat.mChannelsPerFrame = 1;
	destFormat.mBytesPerFrame = destFormat.mChannelsPerFrame * sizeof(Float32);
	destFormat.mFramesPerPacket = 1;
	destFormat.mBytesPerPacket = destFormat.mFramesPerPacket * destFormat.mBytesPerFrame;
	return destFormat;
}

typedef struct NJAUGraphPlayer
{
	AUGraph graph;
	AudioStreamBasicDescription ASBD;
	AudioConverterRef converter;
	AudioUnit effectUnit;
} NJAUGraphPlayer;

void createAudioGraph(NJAUGraphPlayer *player)
{
	// new AUGraph
	CheckError(NewAUGraph(&player->graph), "NewAUGraph failed");

	// new output node
	AudioComponentDescription outputdc;
	outputdc.componentType = kAudioUnitType_Output;
	outputdc.componentSubType = kAudioUnitSubType_RemoteIO;
	outputdc.componentManufacturer = kAudioUnitManufacturer_Apple;
	AUNode outputNode;
	CheckError(AUGraphAddNode(player->graph, &outputdc, &outputNode), "AUGraphAddNode failed");

	// open graph
	CheckError(AUGraphOpen(player->graph), "AUGraphOpen failed");

	// init graph
	CheckError(AUGraphInitialize(player->graph), "AUGraphInitialize failed");

	// set properties of outputNode
	AudioUnit outputUnit;
	CheckError(AUGraphNodeInfo(player->graph, outputNode, NULL, &outputUnit), "AUGraphNodeInfo failed");

	// set destination stream format
	AudioStreamBasicDescription LPCMASBD = LPCMStreamDescription();
	CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &LPCMASBD, sizeof(LPCMASBD)), "");

	// set render callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = NJAURenderCallback;
	callbackStruct.inputProcRefCon = player;
	CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(callbackStruct)), "AudioUnitSetProperty failed");

	// set isRunning callback
	CheckError(AudioUnitAddPropertyListener(outputUnit, kAudioOutputUnitProperty_IsRunning, NJRunningStateChangedCallback, player), "AudioUnitAddPropertyListener failed");

	CAShow(player->graph);
}

@interface NJAudioEngine ()
{
	NJAUGraphPlayer player;
}
@end

@implementation NJAudioEngine

- (void)dealloc
{
	[self stop];
	AUGraphUninitialize(player.graph);
	AUGraphClose(player.graph);
}

- (id)initWithDelegate:(id <NJAudioEngineDelegate>)inDelegate
{
	self = [super init];
	if (self) {
		self.delegate = inDelegate;
		NJAUGraphPlayer newPlayer = {0};
		player = newPlayer;
		createAudioGraph(&player);
	}
	return self;
}

- (void)start
{
	CheckError(AUGraphStart(player.graph), "AUGraphStart failed");
}

- (void)pause
{
#warning pause
	CheckError(AUGraphStop(player.graph), "AUGraphStop failed");
}

- (void)stop
{
	CheckError(AUGraphStop(player.graph), "AUGraphStop failed");
}

- (void)setASBD:(AudioStreamBasicDescription)inASBD
{
	// create converter by ASBD
	memcpy(&player.ASBD, &inASBD, sizeof(AudioStreamBasicDescription));
	AudioStreamBasicDescription LPCMASBD = LPCMStreamDescription();
	AudioConverterNew(&inASBD, &LPCMASBD, &player.converter);
}


@end
