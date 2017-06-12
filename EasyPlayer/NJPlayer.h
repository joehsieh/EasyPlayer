//
//  NJPlayer.h
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NJAudioFileFetcher.h"
#import "NJAudioStreamParser.h"
//#import "NJAudioQueue.h"
#import "NJAudioEngine.h"

@class NJPlayer;

@protocol NJPlayerDelegate <NSObject>
- (void)playerDidStartPlayingSong:(NJPlayer *)inPlayer;
- (void)playerDidStopPlayingSong:(NJPlayer *)inPlayer;
- (void)playerDidPausePlayingSong:(NJPlayer *)inPlayer;
- (void)playerDidResumePlayingSong:(NJPlayer *)inPlayer;
#warning todo
- (void)player:(NJPlayer *)inPlayer updatePlaybackTime:(NSTimeInterval)inTime;
@end
//@interface NJPlayer : NSObject <NJAudioFileFetcherDelegate, NJAudioStreamParserDelegate, NJAudioQueueDelegate>
@interface NJPlayer : NSObject <NJAudioEngineDelegate>
@property (nonatomic, assign) id <NJPlayerDelegate> delegate;
+ (instancetype)sharedPlayer;
- (void)playTestSongs;
- (void)stop;
- (void)pause;
- (void)resume;
- (void)setVolume:(CGFloat)inVolume forBusIndex:(UInt32)inBusIndex;
@end
