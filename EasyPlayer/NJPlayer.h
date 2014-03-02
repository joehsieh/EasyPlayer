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
#import "NJAudioQueue.h"

@class NJPlayer;

@protocol NJPlayerDelegate <NSObject>

- (void)playerDidStartPlayingSong:(NJPlayer *)inPlayer;
- (void)playerDidStopPlayingSong:(NJPlayer *)inPlayer;
- (void)playerDidPausePlayingSong:(NJPlayer *)inPlayer;
- (void)playerDidResumePlayingSong:(NJPlayer *)inPlayer;
@end
@interface NJPlayer : NSObject <NJAudioFileFetcherDelegate, NJAudioStreamParserDelegate, NJAudioQueueDelegate>
+ (instancetype)sharedPlayer;
- (void)playSongWithURL:(NSURL *)inURL;
- (void)stop;
- (void)pause;
- (void)resume;

@property (nonatomic, assign) id <NJPlayerDelegate> delegate;
@end
