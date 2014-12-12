//
//  NJAudioQueue.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/28.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJAudioQueue.h"

void audioQueueOutputCallback (void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
void audioQueuePropertyDidChange(void *inData, AudioQueueRef inAQ, AudioQueuePropertyID inID);

@implementation NJAudioQueue

- (void)dealloc
{
	AudioQueueDispose(audioQueue, YES);
}

- (id)initWithDelegate:(id<NJAudioQueueDelegate>)inDelegate
{
    self = [super init];
    if (self) {
        self.delegate = inDelegate;
    }
    return self;
}
- (OSStatus)start
{
	OSStatus status = AudioQueueStart(audioQueue, NULL);
    [self.delegate audioQueueDidResume:self];
    return status;
}

- (OSStatus)pause
{
	OSStatus status = AudioQueuePause(audioQueue);
    [self.delegate audioQueueDidPause:self];
    return status;
}

- (OSStatus)stop
{
	return AudioQueueStop(audioQueue, true);
}

- (void)setASBD:(AudioStreamBasicDescription)inASBD
{
    OSStatus status = AudioQueueNewOutput (
        &inASBD,
        audioQueueOutputCallback,
        (__bridge void *)(self),
        CFRunLoopGetMain (),
        kCFRunLoopCommonModes,
        0,
        &audioQueue
    );
    assert(status == noErr);
    status = AudioQueueAddPropertyListener (audioQueue, kAudioQueueProperty_IsRunning, audioQueuePropertyDidChange, (__bridge void *)(self));
    AudioQueuePrime(audioQueue, 0, NULL);
	assert(status == noErr);
}

- (AudioQueueBufferRef)createAudioQueueBufferRefWithData:(NSData *)data
					   packetCount:(UInt32)packetCount
				packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions
{
    AudioQueueBufferRef outBufferRef;
	OSStatus status = AudioQueueAllocateBufferWithPacketDescriptions(self->audioQueue, (UInt32)data.length, packetCount, &outBufferRef);
    memcpy(outBufferRef->mAudioData, data.bytes, data.length);
    outBufferRef->mAudioDataByteSize = (UInt32)data.length;
    memcpy(outBufferRef->mPacketDescriptions, packetDescriptions, sizeof(AudioStreamPacketDescription) * packetCount);
    outBufferRef->mPacketDescriptionCount = packetCount;
	
    assert(status == noErr);
	return outBufferRef;
}

- (OSStatus)enqueueBuffer:(AudioQueueBufferRef)bufferRef
{
	OSStatus status = AudioQueueEnqueueBuffer(audioQueue, bufferRef, 0, NULL);
    assert(status == noErr);
	return status;
}

void audioQueueOutputCallback (void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    
}

void audioQueuePropertyDidChange(void *inData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
    NJAudioQueue *self = (__bridge NJAudioQueue *)inData;
	int result = 0;
	UInt32 size = sizeof(UInt32);
	OSStatus status = AudioQueueGetProperty (self->audioQueue, kAudioQueueProperty_IsRunning, &result, &size);
    assert(status == noErr);
    result ? [self->delegate audioQueueDidStart:self] : [self->delegate audioQueueDidStop:self];
}
@synthesize delegate;
@end
