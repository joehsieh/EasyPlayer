//
//  NJAudioStreamParser.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/23.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJAudioStreamParser.h"

@interface NJAudioStreamParser()
@property (nonatomic, assign) id<NJAudioStreamParserDelegate> audioParserDelegate;
@property (nonatomic, assign) AudioFileStreamID audioFileStreamID;
@end
void parserDidParseProperty (
    void                        *inClientData,
    AudioFileStreamID           inAudioFileStream,
    AudioFileStreamPropertyID   inPropertyID,
    UInt32                      *ioFlags
);

void parserDidParsePacket (
    void                          *inClientData,
    UInt32                        inNumberBytes,
    UInt32                        inNumberPackets,
    const void                    *inInputData,
    AudioStreamPacketDescription  *inPacketDescriptions
);

@implementation NJAudioStreamParser

-(instancetype)initWithDelegate:(id<NJAudioStreamParserDelegate>)inDelegate
{
    self = [super init];
    if (self) {
        self.audioParserDelegate = inDelegate;
        AudioFileStreamOpen((__bridge void *)(self), parserDidParseProperty, parserDidParsePacket,  0, &audioFileStreamID);
    }
    return self;
}

- (void)parseBytes:(NSData *)inData
{
    AudioFileStreamParseBytes(audioFileStreamID, inData.length, inData.bytes, 0);
}

void parserDidParseProperty (
                             void                        *inClientData,
                             AudioFileStreamID           inAudioFileStream,
                             AudioFileStreamPropertyID   inPropertyID,
                             UInt32                      *ioFlags
                             )
{
    NJAudioStreamParser *self = (__bridge NJAudioStreamParser *)inClientData;
    if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
		OSStatus status = 0;
		AudioStreamBasicDescription audioStreamDescription;
        UInt32 descriptionSize = sizeof(AudioStreamBasicDescription);
        status = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &descriptionSize, &audioStreamDescription);
        [self.audioParserDelegate audioParser:self didParseASBD:audioStreamDescription];
        
    }
    else if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        [self.audioParserDelegate audioParserDidParsedEnoughDataToPlay:self];
    }
}

void parserDidParsePacket (
                           void                          *inClientData,
                           UInt32                        inNumberBytes,
                           UInt32                        inNumberPackets,
                           const void                    *inInputData,
                           AudioStreamPacketDescription  *inPacketDescriptions
                           )
{
    NJAudioStreamParser *self = (__bridge NJAudioStreamParser *)inClientData;
    [self.audioParserDelegate audioParser:self didParsePacket:[NSData dataWithBytes:inInputData length:inNumberBytes] pakcageCount:inNumberPackets packetDescription:inPacketDescriptions];
}

@synthesize audioParserDelegate;
@synthesize audioFileStreamID;
@end
