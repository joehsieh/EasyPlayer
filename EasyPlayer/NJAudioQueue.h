//
//  NJAudioQueue.h
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/28.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
@class NJAudioQueue;

@protocol NJAudioQueueDelegate <NSObject>

- (void)audioQueueDidStart:(NJAudioQueue *)inQueue;
- (void)audioQueueDidStop:(NJAudioQueue *)inQueue;
- (void)audioQueueDidPause:(NJAudioQueue *)inQueue;
- (void)audioQueueDidResume:(NJAudioQueue *)inQueue;
@end
@interface NJAudioQueue : NSObject
{
    AudioQueueRef audioQueue;
    __unsafe_unretained id<NJAudioQueueDelegate> delegate;
}
@property (nonatomic, assign) id <NJAudioQueueDelegate> delegate;
- (id)initWithDelegate:(id<NJAudioQueueDelegate>)inDelegate;
- (OSStatus)start;
- (OSStatus)pause;
- (OSStatus)stop;
- (AudioQueueBufferRef)createAudioQueueBufferRefWithData:(NSData *)data
                                             packetCount:(UInt32)packetCount
                                      packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions;
- (OSStatus)enqueueBuffer:(AudioQueueBufferRef)bufferRef;

- (void)setASBD:(AudioStreamBasicDescription)inASBD;
@end
