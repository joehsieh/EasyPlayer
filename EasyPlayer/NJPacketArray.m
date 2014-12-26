//
//  NJPacketArray.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/12/25.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJPacketArray.h"

@interface NJPacketArray ()
@property (assign, nonatomic) NSUInteger maxPacketCount;
@property (assign, nonatomic) NSUInteger packetWriteIndex;
@property (assign, nonatomic) NSUInteger packetReadIndex;
@property (assign, nonatomic) NJAudioPacketInfo *packets;
@end
@implementation NJPacketArray

- (void)dealloc
{
    free(self.packets);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.maxPacketCount = 2048;
        self.packets = (NJAudioPacketInfo *)calloc(self.maxPacketCount, sizeof(NJAudioPacketInfo)); // allocate buffers for packetData
    }
    return self;
}
- (void)storePacket:(NJAudioPacketInfo *)packetInfo
{
    if (self.packetWriteIndex >= self.maxPacketCount) {
        [self _adjuctArraySize];
    }
    self.packets[self.packetWriteIndex] = *packetInfo;
    self.packetWriteIndex ++;
}

- (NJAudioPacketInfo *)readNextPacket
{
    NJAudioPacketInfo *packet = &self.packets[self.packetReadIndex];
    self.packetReadIndex++;
    return packet;
}

- (void)_adjuctArraySize
{
    size_t oldSize = self.maxPacketCount * sizeof(NJAudioPacketInfo);
    self.maxPacketCount *= 2;
    self.packets = (NJAudioPacketInfo *)realloc(self.packets, self.maxPacketCount * sizeof(NJAudioPacketInfo));
    bzero((void *)self.packets + oldSize, oldSize);
}

@end
