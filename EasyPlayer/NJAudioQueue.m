//
//  NJAudioQueue.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/28.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJAudioQueue.h"
#import "AudioUtilities.h"

void audioQueueOutputCallback (void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
void audioQueuePropertyDidChange(void *inData, AudioQueueRef inAQ, AudioQueuePropertyID inID);

@implementation NJAudioQueue

- (void)dealloc
{
	CheckError(AudioQueueDispose(audioQueue, YES), "Dispose audio queue fail.");
}

- (id)initWithDelegate:(id<NJAudioQueueDelegate>)inDelegate
{
    self = [super init];
    if (self) {
        self.delegate = inDelegate;
    }
    return self;
}
- (void)start
{
	CheckError(AudioQueueStart(audioQueue, NULL), "Start queue fail");
    [self.delegate audioQueueDidResume:self];
}

- (void)pause
{
	CheckError(AudioQueuePause(audioQueue), "Pause queue fail");
    [self.delegate audioQueueDidPause:self];
}

- (void)stop
{
	CheckError(AudioQueueStop(audioQueue, true), "Stop queue fail");
}

- (void)setASBD:(AudioStreamBasicDescription)inASBD
{
	CheckError(AudioQueueNewOutput (
									&inASBD,
									audioQueueOutputCallback,
									(__bridge void *)(self),
									CFRunLoopGetMain (),
									kCFRunLoopCommonModes,
									0,
									&audioQueue
									), "New audio queue fail");

	CheckError(AudioQueueAddPropertyListener (audioQueue, kAudioQueueProperty_IsRunning, audioQueuePropertyDidChange, (__bridge void *)(self)), "Add property listener fail");
	CheckError(AudioQueuePrime(audioQueue, 0, NULL), "Prime audio queue fail");
}

- (AudioQueueBufferRef)createAudioQueueBufferRefWithData:(NSData *)data
					   packetCount:(UInt32)packetCount
				packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions
{
    AudioQueueBufferRef outBufferRef;
	CheckError(AudioQueueAllocateBufferWithPacketDescriptions(self->audioQueue, (UInt32)data.length, packetCount, &outBufferRef), "Allocate buffer fail");
    memcpy(outBufferRef->mAudioData, data.bytes, data.length);
    outBufferRef->mAudioDataByteSize = (UInt32)data.length;
    memcpy(outBufferRef->mPacketDescriptions, packetDescriptions, sizeof(AudioStreamPacketDescription) * packetCount);
    outBufferRef->mPacketDescriptionCount = packetCount;
	return outBufferRef;
}

- (void)enqueueBuffer:(AudioQueueBufferRef)bufferRef
{
	CheckError(AudioQueueEnqueueBuffer(audioQueue, bufferRef, 0, NULL), "Enqueue buffer fail");
}

void audioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
	if (inBuffer) {
		CheckError(AudioQueueFreeBuffer(inAQ, inBuffer), "Must free incoming buffer");
	}
}

void audioQueuePropertyDidChange(void *inData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
    NJAudioQueue *self = (__bridge NJAudioQueue *)inData;
	int result = 0;
	UInt32 size = sizeof(UInt32);
	CheckError(AudioQueueGetProperty(self->audioQueue, kAudioQueueProperty_IsRunning, &result, &size), "Get property fail");
    result ? [self.delegate audioQueueDidStart:self] : [self.delegate audioQueueDidStop:self];
}
@end
