//
//  NJPlayer.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJPlayer.h"

@interface NJPlayer()
@property (nonatomic, strong) NJAudioFileFetcher *fetcher;
@property (nonatomic, strong) NJAudioStreamParser *streamParser;
//@property (nonatomic, strong) NJAudioQueue *audioQueue;
@property (nonatomic, strong) NJAudioEngine *audioEngine;
@end
@implementation NJPlayer

+ (instancetype)sharedPlayer
{
	static dispatch_once_t onceToken;
	static NJPlayer *sharedPlayer = nil;
	dispatch_once(&onceToken, ^{
		sharedPlayer = [[NJPlayer alloc] init];
	});
	return sharedPlayer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.fetcher = [[NJAudioFileFetcher alloc] initWithDelegate:self];
        self.streamParser = [[NJAudioStreamParser alloc] initWithDelegate:self];
//        self.audioQueue = [[NJAudioQueue alloc] initWithDelegate:self];
		self.audioEngine = [[NJAudioEngine alloc] initWithDelegate:self];
    }
    return self;
}

- (void)playSongWithURL:(NSURL *)inURL
{
    NSAssert(self.delegate, @"delegate must exist");
    [self.fetcher fetchMusicWithURL:inURL];
}

- (void)stop
{
//    [self.audioQueue stop];
	[self.audioEngine stop];
}

- (void)pause
{
//    [self.audioQueue pause];
	[self.audioEngine pause];
}

- (void)resume
{
//    [self.audioQueue start];
	[self.audioEngine start];
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
//    [self.audioQueue setASBD:inASBD];
	[self.audioEngine setASBD:inASBD];
}

- (void)audioParserDidParsedEnoughDataToPlay:(NJAudioStreamParser *)inParser
{ 
    dispatch_sync(dispatch_get_main_queue(), ^{
//        [self.audioQueue start];
		[self.audioEngine start];
    });
}

- (void)audioParser:(NJAudioStreamParser *)inParser didParsePacket:(NSData *)inPacket pakcageCount:(UInt32)inPacketCount packetDescription:(AudioStreamPacketDescription *)inPacketDescription
{
	AudioBufferList list;
	AudioBuffer buffer;
//    AudioQueueBufferRef bufferRef = [self.audioQueue createAudioQueueBufferRefWithData:inPacket packetCount:inPacketCount packetDescriptions:inPacketDescription];
//    [self.audioQueue enqueueBuffer:bufferRef];
}

//#pragma mark - NJAudioQueueDelegate
//
//- (void)audioQueueDidStart:(NJAudioQueue *)inQueue
//{
//    [self.delegate playerDidStartPlayingSong:self];
//}
//- (void)audioQueueDidStop:(NJAudioQueue *)inQueue
//{
//    [self.delegate playerDidStopPlayingSong:self];
//}
//- (void)audioQueueDidPause:(NJAudioQueue *)inQueue
//{
//    [self.delegate playerDidPausePlayingSong:self];
//}
//- (void)audioQueueDidResume:(NJAudioQueue *)inQueue
//{
//    [self.delegate playerDidResumePlayingSong:self];
//}

#pragma mark NJAudioEngineDelegate

- (void)audioEngineDidStart:(NJAudioEngine *)inEngine
{
	[self.delegate playerDidStartPlayingSong:self];
}

- (void)audioEngineDidStop:(NJAudioEngine *)inEngine
{
	[self.delegate playerDidStopPlayingSong:self];
}

- (void)audioEngineDidPause:(NJAudioEngine *)inEngine
{
	[self.delegate playerDidPausePlayingSong:self];
}

- (void)audioEngineDidResume:(NJAudioEngine *)inEngine
{
	[self.delegate playerDidResumePlayingSong:self];
}

@end
