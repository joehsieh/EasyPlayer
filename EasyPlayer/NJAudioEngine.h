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

typedef struct NJAUGraphPlayer
{
    AUGraph graph;
    AudioConverterRef converter;
    AudioBufferList *renderAudioBufferList;
    UInt32 renderBufferSize;
} NJAUGraphPlayer;

@protocol NJAudioEngineDelegate <NSObject>

- (void)audioEngineDidStart:(NJAudioEngine *)inEngine;
- (void)audioEngineDidStop:(NJAudioEngine *)inEngine;
- (void)audioEngineDidPause:(NJAudioEngine *)inEngine;
- (void)audioEngineDidResume:(NJAudioEngine *)inEngine;
@end
@interface NJAudioEngine : NSObject
@property (weak, nonatomic) id <NJAudioEngineDelegate> delegate;
- (id)initWithDelegate:(id <NJAudioEngineDelegate>)inDelegate;
- (void)start;
- (void)pause;
- (void)stop;
//- (AudioQueueBufferRef)createAudioQueueBufferRefWithData:(NSData *)data
//											 packetCount:(UInt32)packetCount
//									  packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions;
//- (void)enqueueBuffer:(AudioQueueBufferRef)bufferRef;

- (void)storePacket:(const void *)inPacket pakcageCount:(UInt32)inPacketCount packetDescription:(AudioStreamPacketDescription *)inPacketDescription;
- (void)setASBD:(AudioStreamBasicDescription)inASBD;
@end

@interface NJAudioEngine ()
@property (assign, nonatomic) NJAUGraphPlayer *player;
@property (strong, nonatomic) NJPacketArray *packetArray;
@end