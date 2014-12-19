//
//  NJAudioStreamParser.h
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/23.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
@class  NJAudioStreamParser;

@protocol NJAudioStreamParserDelegate <NSObject>

- (void)audioParser:(NJAudioStreamParser *)inParser didParseASBD:(AudioStreamBasicDescription)inASBD;

- (void)audioParserDidParsedEnoughDataToPlay:(NJAudioStreamParser *)inParser;

- (void)audioParser:(NJAudioStreamParser *)inParser didParsePacket:(const void *)inPacket pakcageCount:(UInt32)inPacketCount packetDescription:(AudioStreamPacketDescription *)inPacketDescription;

@end
@interface NJAudioStreamParser : NSObject
- (instancetype)initWithDelegate:(id<NJAudioStreamParserDelegate>)inDelegate;
- (void)parseBytes:(NSData *)inData;
@end
