//
//  NJPacketArray.h
//  EasyPlayer
//
//  Created by joehsieh on 2014/12/25.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

@import Foundation;
@import AudioToolbox;

typedef struct {
    AudioStreamPacketDescription packetDescription;
    void *data;
} NJAudioPacketInfo;

@interface NJPacketArray : NSObject
- (void)storePacket:(NJAudioPacketInfo *)packetInfo;
- (NJAudioPacketInfo *)readNextPacket;
@end
