//
//  NJAudiDataProvider.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/12/27.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJAudiDataProvider.h"
#import "NJAudioFileFetcher.h"
#import "NJAudioStreamParser.h"
#import "NJPacketArray.h"
#import "AudioUtilities.h"

#pragma render callback

OSStatus NJFillRawPacketData(AudioConverterRef               inAudioConverter,
                                UInt32*                         ioNumberDataPackets,
                                AudioBufferList*                ioData,
                                AudioStreamPacketDescription**  outDataPacketDescription,
                                void*                           inUserData)
{
    NJAudiDataProvider *audioDataProvider = (__bridge NJAudiDataProvider *)inUserData;
    NJAudioPacketInfo *packetInfo = [audioDataProvider.packetArray readNextPacket];
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
    NJAudiDataProvider *audioDataProvider = (__bridge NJAudiDataProvider *)(inRefCon);
    OSStatus status = AudioConverterFillComplexBuffer(audioDataProvider.converter, NJFillRawPacketData, (__bridge void *)(audioDataProvider), &inNumberFrames, audioDataProvider.renderAudioBufferList, NULL);
    if (noErr == status && inNumberFrames) {
        ioData->mNumberBuffers = 1;
        ioData->mBuffers[0].mNumberChannels = 2;
        ioData->mBuffers[0].mDataByteSize = audioDataProvider.renderAudioBufferList->mBuffers[0].mDataByteSize;
        ioData->mBuffers[0].mData = audioDataProvider.renderAudioBufferList->mBuffers[0].mData;
#warning why?
        //		player->renderAudioBufferList->mBuffers[0].mDataByteSize = player->renderBufferSize;
        status = noErr;
    }
    return status;
}

@interface NJAudiDataProvider () <NJAudioFileFetcherDelegate, NJAudioStreamParserDelegate>
{
    UInt32 renderBufferSize;
}
@property (nonatomic, strong) NJAudioFileFetcher *fetcher;
@property (nonatomic, strong) NJAudioStreamParser *streamParser;
@end
@implementation NJAudiDataProvider

- (void)dealloc
{
    AudioConverterReset(converter);
    renderAudioBufferList->mNumberBuffers = 1;
    renderAudioBufferList->mBuffers[0].mNumberChannels = 2;
    renderAudioBufferList->mBuffers[0].mDataByteSize = renderBufferSize;
    bzero(renderAudioBufferList->mBuffers[0].mData, renderBufferSize);
    AudioConverterDispose(converter);
    free(renderAudioBufferList->mBuffers[0].mData);
    free(renderAudioBufferList);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.fetcher = [[NJAudioFileFetcher alloc] initWithDelegate:self];
        self.streamParser = [[NJAudioStreamParser alloc] initWithDelegate:self];
        self.packetArray = [[NJPacketArray alloc] init];
        UInt32 second = 1;
        UInt32 packetSize = 44100 * second * 8;
        renderAudioBufferList = (AudioBufferList *)calloc(1, sizeof(AudioBufferList));
        renderAudioBufferList->mNumberBuffers = 1;
        renderAudioBufferList->mBuffers[0].mNumberChannels = 2;
        renderAudioBufferList->mBuffers[0].mDataByteSize = packetSize;
        renderAudioBufferList->mBuffers[0].mData = calloc(1, packetSize);
        renderCallbackStruct.inputProc = NJAURenderCallback;
        renderCallbackStruct.inputProcRefCon = (__bridge void *)(self);
    }
    return self;
}

- (void)fetchAudioRawDataByURL:(NSURL *)inURL
{
    [self.fetcher fetchMusicWithURL:inURL];
}

#pragma mark - NJMusicFileFetcherDelegate

- (void)musicFileFetcher:(NJAudioFileFetcher *)inFetcher didReceiveData:(NSData *)inData
{
    [self.streamParser parseBytes:inData];
}

- (void)musicFileFetcher:(NJAudioFileFetcher *)inFetcher didFailedWithError:(NSError *)inError
{
    
}

- (void)musicFileFetcherDidFetchAllData:(NJAudioFileFetcher *)inFetcher
{
    
}

#pragma mark - NJAudioStreamParserDelegate

- (void)audioParser:(NJAudioStreamParser *)inParser didParseASBD:(AudioStreamBasicDescription)inASBD
{
    [self _createConverterByASBD:inASBD];
}

- (void)audioParserDidParsedEnoughDataToPlay:(NJAudioStreamParser *)inParser
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (self.delegate) {
            [self.delegate audioDataProviderDidObtainEnoughPlayableData:self];
        }
    });
}

- (void)audioParser:(NJAudioStreamParser *)inParser didParsePacket:(const void *)inPacket pakcageCount:(UInt32)inPacketCount packetDescription:(AudioStreamPacketDescription *)inPacketDescription
{
    [self _storePacket:inPacket pakcageCount:inPacketCount packetDescription:inPacketDescription];
}

#pragma mark private functions

- (void)_storePacket:(const void *)inData pakcageCount:(UInt32)inPacketCount packetDescription:(AudioStreamPacketDescription *)inPacketDescription
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

- (void)_createConverterByASBD:(AudioStreamBasicDescription)inASBD
{
    // create converter by ASBD
    AudioStreamBasicDescription LPCMASBD = LPCMStreamDescription();
    AudioConverterNew(&inASBD, &LPCMASBD, &(converter));
}

#pragma mark properties

- (AudioBufferList *)renderAudioBufferList
{
    return renderAudioBufferList;
}

- (AudioConverterRef)converter
{
    return converter;
}

- (AURenderCallbackStruct)renderCallbackStruct
{
    return renderCallbackStruct;
}
@end
