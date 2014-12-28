//
//  NJPlayer.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJPlayer.h"
#import "NJAudiDataProvider.h"

@interface NJPlayer() <NJAudiDataProviderDelegate>
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
        NJAudiDataProvider *dataProvider1 = [[NJAudiDataProvider alloc] init];
        dataProvider1.delegate = self;
        NJAudiDataProvider *dataProvider2 = [[NJAudiDataProvider alloc] init];
        dataProvider2.delegate = self;
//        self.audioQueue = [[NJAudioQueue alloc] initWithDelegate:self];
		self.audioEngine = [[NJAudioEngine alloc] initWithDelegate:self audioDataProviderList:@[dataProvider1, dataProvider2]];
    }
    return self;
}

- (void)playTestSongs
{
    NSAssert(self.delegate, @"delegate must exist");
    NSArray *urlStrings = @[@"http://zonble.net/MIDI/orz.mp3", @"http://zonble.net/MIDI/mabi.mp3"];
    for (NSUInteger i = 0 ;i < [urlStrings count] ; i++) {
        NJAudiDataProvider *audioDataProvider = self.audioEngine.audioDataProviderList[i];
        [audioDataProvider fetchAudioRawDataByURL:[NSURL URLWithString:urlStrings[i]]];
    }
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

#pragma mark NJAudiDataProviderDelegate

- (void)audioDataProviderDidObtainEnoughPlayableData:(NJAudiDataProvider *)inProvider
{
    [self resume];
    [self.delegate playerDidStartPlayingSong:self];
}

@end
