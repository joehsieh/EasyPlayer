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

typedef struct {
	AudioStreamPacketDescription packetDescription;
	void *data;
} NJAudioPacketInfo;

typedef struct NJAUGraphPlayer
{
	AUGraph graph;
	AudioStreamBasicDescription ASBD;
	AudioConverterRef converter;

	NJAudioPacketInfo *packets; // data structure to store packets
	size_t expectedTotalPacketCount; // expected total packet count
	size_t loadedPacketCount; // loaded packet count
	size_t packetWriteIndex;
	size_t packetReadIndex;
	AudioBufferList *renderAudioBufferList;
	UInt32 renderBufferSize;
} NJAUGraphPlayer;

#pragma render callback

OSStatus NJFillUnCompressedData(AudioConverterRef               inAudioConverter,
								UInt32*                         ioNumberDataPackets,
								AudioBufferList*                ioData,
								AudioStreamPacketDescription**  outDataPacketDescription,
								void*                           inUserData)
{
	NJAUGraphPlayer *player = (NJAUGraphPlayer *)inUserData;
	NJAudioPacketInfo packetInfo = player->packets[player->packetReadIndex];
	ioData->mNumberBuffers = 1;
	ioData->mBuffers[0].mDataByteSize = packetInfo.packetDescription.mDataByteSize;
	ioData->mBuffers[0].mData = packetInfo.data;
	*outDataPacketDescription = &packetInfo.packetDescription;
	player->packetReadIndex ++;
	return noErr;
}

OSStatus NJAURenderCallback(void *							inRefCon,
						  AudioUnitRenderActionFlags *	ioActionFlags,
						  const AudioTimeStamp *			inTimeStamp,
						  UInt32							inBusNumber,
						  UInt32							inNumberFrames,
						  AudioBufferList *				ioData)
{
	NJAUGraphPlayer *player = (NJAUGraphPlayer *)inRefCon;
	OSStatus status = AudioConverterFillComplexBuffer(player->converter, NJFillUnCompressedData, player, &inNumberFrames, player->renderAudioBufferList, NULL);
	if (noErr == status && inNumberFrames) {
		ioData->mNumberBuffers = 1;
		ioData->mBuffers[0].mNumberChannels = 2;
		ioData->mBuffers[0].mDataByteSize = player->renderAudioBufferList->mBuffers[0].mDataByteSize;
		ioData->mBuffers[0].mData = player->renderAudioBufferList->mBuffers[0].mData;
		player->renderAudioBufferList->mBuffers[0].mDataByteSize = player->renderBufferSize;
		status = noErr;
	}
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

	// set volume
	CheckError(AudioUnitSetParameter(outputUnit, kHALOutputParam_Volume, kAudioUnitScope_Global, 0, 1.0, 0), "AudioUnitSetParameter failed");

	CAShow(player->graph);
}

@interface NJAudioEngine ()
{
	NJAUGraphPlayer *player;
}
@end

@implementation NJAudioEngine

- (void)dealloc
{
	[self stop];

	AudioConverterReset(player->converter);
	player->renderAudioBufferList->mNumberBuffers = 1;
	player->renderAudioBufferList->mBuffers[0].mNumberChannels = 2;
	player->renderAudioBufferList->mBuffers[0].mDataByteSize = player->renderBufferSize;
	bzero(player->renderAudioBufferList->mBuffers[0].mData, player->renderBufferSize);
	AudioConverterDispose(player->converter);
	free(player->renderAudioBufferList->mBuffers[0].mData);
	free(player->renderAudioBufferList);

	AUGraphUninitialize(player->graph);
	AUGraphClose(player->graph);
}

- (id)initWithDelegate:(id <NJAudioEngineDelegate>)inDelegate
{
	self = [super init];
	if (self) {
		self.delegate = inDelegate;
		NJAUGraphPlayer *newPlayer = calloc(1,sizeof(NJAUGraphPlayer));
		player = newPlayer;
		createAudioGraph(player);
		player->expectedTotalPacketCount = 2048;
		player->packets = (NJAudioPacketInfo *)calloc(player->expectedTotalPacketCount, sizeof(NJAudioPacketInfo)); // allocate buffers for packetData
	}
	return self;
}

- (void)start
{
	CheckError(AUGraphStart(player->graph), "AUGraphStart failed");
}

- (void)pause
{
#warning pause
	CheckError(AUGraphStop(player->graph), "AUGraphStop failed");
}

- (void)stop
{
	CheckError(AUGraphStop(player->graph), "AUGraphStop failed");
}

- (void)setASBD:(AudioStreamBasicDescription)inASBD
{
	// create converter by ASBD
	memcpy(&player->ASBD, &inASBD, sizeof(AudioStreamBasicDescription));
	AudioStreamBasicDescription LPCMASBD = LPCMStreamDescription();
	AudioConverterNew(&inASBD, &LPCMASBD, &player->converter);

	UInt32 second = 1;
	UInt32 packetSize = 44100 * second * 8;
	player->renderBufferSize = packetSize;
	player->renderAudioBufferList = (AudioBufferList *)calloc(1, sizeof(AudioBufferList));
	player->renderAudioBufferList->mNumberBuffers = 1;
	player->renderAudioBufferList->mBuffers[0].mNumberChannels = 2;
	player->renderAudioBufferList->mBuffers[0].mDataByteSize = packetSize;
	player->renderAudioBufferList->mBuffers[0].mData = calloc(1, packetSize);
}

- (void)storePacket:(const void *)inData pakcageCount:(UInt32)inPacketCount packetDescription:(AudioStreamPacketDescription *)inPacketDescription
{
	@synchronized(self) {
		for (size_t i = 0 ; i < inPacketCount; i++) {
			// array size is not enough, so increases it double
			if (player->packetWriteIndex >= player->expectedTotalPacketCount) {
				size_t oldSize = player->expectedTotalPacketCount * sizeof(NJAudioPacketInfo);
				player->expectedTotalPacketCount *= 2;
				player->packets = (NJAudioPacketInfo *)realloc(player->packets, player->expectedTotalPacketCount * sizeof(NJAudioPacketInfo));
				bzero((void *)player->packets + oldSize, oldSize);
			}

			AudioStreamPacketDescription *packetDescription = &inPacketDescription[i];

			NJAudioPacketInfo *packetInfo = &player->packets[player->packetWriteIndex];
			if (packetInfo->data) {
				free(packetInfo->data);
				packetInfo->data = NULL;
			}
			packetInfo->data = malloc(packetDescription->mDataByteSize);
			memcpy(packetInfo->data, inData + packetDescription->mStartOffset, packetDescription->mDataByteSize);
			memcpy(&packetInfo->packetDescription, packetInfo, sizeof(NJAudioPacketInfo));
			player->packetWriteIndex ++;
			player->loadedPacketCount ++;
		}
	}
}

@end
