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

#pragma render callback

OSStatus NJFillUnCompressedData(AudioConverterRef               inAudioConverter,
								UInt32*                         ioNumberDataPackets,
								AudioBufferList*                ioData,
								AudioStreamPacketDescription**  outDataPacketDescription,
								void*                           inUserData)
{
	NJAudioEngine *audioEngine = (__bridge NJAudioEngine *)inUserData;
	NJAudioPacketInfo *packetInfo = [audioEngine.packetArray readNextPacket];
	ioData->mNumberBuffers = 1;
	ioData->mBuffers[0].mDataByteSize = packetInfo->packetDescription.mDataByteSize;
	ioData->mBuffers[0].mData = packetInfo->data;
#warning we should not use aspd from retrieved packet directly.
//	*outDataPacketDescription = &packetInfo.packetDescription;
    UInt32 length = packetInfo->packetDescription.mDataByteSize;
    static AudioStreamPacketDescription aspdesc;
    *outDataPacketDescription = &aspdesc;
    aspdesc.mDataByteSize = length;
    aspdesc.mStartOffset = 0;
    aspdesc.mVariableFramesInPacket = 1;
	return noErr;
}

OSStatus NJAURenderCallback(void *							inRefCon,
						  AudioUnitRenderActionFlags *	ioActionFlags,
						  const AudioTimeStamp *			inTimeStamp,
						  UInt32							inBusNumber,
						  UInt32							inNumberFrames,
						  AudioBufferList *				ioData)
{
	NJAudioEngine *audioEngine = (__bridge NJAudioEngine *)(inRefCon);
    OSStatus status = AudioConverterFillComplexBuffer(audioEngine.player->converter, NJFillUnCompressedData, (__bridge void *)(audioEngine), &inNumberFrames, audioEngine.player->renderAudioBufferList, NULL);
	if (noErr == status && inNumberFrames) {
		ioData->mNumberBuffers = 1;
		ioData->mBuffers[0].mNumberChannels = 2;
		ioData->mBuffers[0].mDataByteSize = audioEngine.player->renderAudioBufferList->mBuffers[0].mDataByteSize;
		ioData->mBuffers[0].mData = audioEngine.player->renderAudioBufferList->mBuffers[0].mData;
#warning why?
//		player->renderAudioBufferList->mBuffers[0].mDataByteSize = player->renderBufferSize;
		status = noErr;
	}
	return status;
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

void createAudioGraph(NJAudioEngine *audioEngine)
{
    NJAUGraphPlayer *player = audioEngine.player;
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
	callbackStruct.inputProcRefCon = (__bridge void *)(audioEngine);
	CheckError(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(callbackStruct)), "AudioUnitSetProperty failed");

	// set isRunning callback
	CheckError(AudioUnitAddPropertyListener(outputUnit, kAudioOutputUnitProperty_IsRunning, NJRunningStateChangedCallback, player), "AudioUnitAddPropertyListener failed");

	// set volume
	CheckError(AudioUnitSetParameter(outputUnit, kHALOutputParam_Volume, kAudioUnitScope_Global, 0, 1.0, 0), "AudioUnitSetParameter failed");

	CAShow(player->graph);
}

@implementation NJAudioEngine

- (void)dealloc
{
	[self stop];

	AudioConverterReset(self.player->converter);
	self.player->renderAudioBufferList->mNumberBuffers = 1;
	self.player->renderAudioBufferList->mBuffers[0].mNumberChannels = 2;
	self.player->renderAudioBufferList->mBuffers[0].mDataByteSize = self.player->renderBufferSize;
	bzero(self.player->renderAudioBufferList->mBuffers[0].mData, self.player->renderBufferSize);
	AudioConverterDispose(self.player->converter);
	free(self.player->renderAudioBufferList->mBuffers[0].mData);
	free(self.player->renderAudioBufferList);

	AUGraphUninitialize(self.player->graph);
	AUGraphClose(self.player->graph);
}

- (id)initWithDelegate:(id <NJAudioEngineDelegate>)inDelegate
{
	self = [super init];
	if (self) {
		self.delegate = inDelegate;
		NJAUGraphPlayer *newPlayer = calloc(1,sizeof(NJAUGraphPlayer));
		self.player = newPlayer;
		createAudioGraph(self);
        self.packetArray = [[NJPacketArray alloc] init];
	}
	return self;
}

- (void)start
{
	CheckError(AUGraphStart(self.player->graph), "AUGraphStart failed");
}

- (void)pause
{
#warning pause
	CheckError(AUGraphStop(self.player->graph), "AUGraphStop failed");
}

- (void)stop
{
	CheckError(AUGraphStop(self.player->graph), "AUGraphStop failed");
}

- (void)setASBD:(AudioStreamBasicDescription)inASBD
{
	// create converter by ASBD
	AudioStreamBasicDescription LPCMASBD = LPCMStreamDescription();
	AudioConverterNew(&inASBD, &LPCMASBD, &self.player->converter);

	UInt32 second = 1;
	UInt32 packetSize = 44100 * second * 8;
	self.player->renderBufferSize = packetSize;
	self.player->renderAudioBufferList = (AudioBufferList *)calloc(1, sizeof(AudioBufferList));
	self.player->renderAudioBufferList->mNumberBuffers = 1;
	self.player->renderAudioBufferList->mBuffers[0].mNumberChannels = 2;
	self.player->renderAudioBufferList->mBuffers[0].mDataByteSize = packetSize;
	self.player->renderAudioBufferList->mBuffers[0].mData = calloc(1, packetSize);
}

- (void)storePacket:(const void *)inData pakcageCount:(UInt32)inPacketCount packetDescription:(AudioStreamPacketDescription *)inPacketDescription
{
	@synchronized(self) {
		for (NSUInteger i = 0 ; i < inPacketCount; i++) {
			AudioStreamPacketDescription *packetDescription = &inPacketDescription[i];
			NJAudioPacketInfo *packetInfo = calloc(1, sizeof(NJAudioPacketInfo));
            packetInfo->data = malloc(packetDescription->mDataByteSize);
			memcpy(packetInfo->data, inData + packetDescription->mStartOffset, packetDescription->mDataByteSize);
			memcpy(&packetInfo->packetDescription, packetDescription, sizeof(AudioStreamPacketDescription));
            [self.packetArray storePacket:packetInfo];
            
		}
	}
}

@end