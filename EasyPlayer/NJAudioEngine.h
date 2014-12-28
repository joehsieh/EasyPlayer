//
//  NJAudioEngine.h
//  EasyPlayer
//
//  Created by joe on 14/12/17.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

@import Foundation;
@import AudioToolbox;
@class NJAudioEngine;
@class NJPacketArray;

@protocol NJAudioEngineDelegate <NSObject>

- (void)audioEngineDidStart:(NJAudioEngine *)inEngine;
- (void)audioEngineDidStop:(NJAudioEngine *)inEngine;
- (void)audioEngineDidPause:(NJAudioEngine *)inEngine;
- (void)audioEngineDidResume:(NJAudioEngine *)inEngine;
@end

@interface NJAudioEngine : NSObject
@property (strong, nonatomic) NSArray *audioDataProviderList;
@property (weak, nonatomic) id <NJAudioEngineDelegate> delegate;
- (id)initWithDelegate:(id <NJAudioEngineDelegate>)inDelegate audioDataProviderList:(NSArray *)inAudioDataProviderList;
- (void)start;
- (void)pause;
- (void)stop;
@end