//
//  NJAudioStreamParser.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/23.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJAudioStreamParser.h"
#import "AudioUtilities.h"

@interface NJAudioStreamParser()
{
	AudioFileStreamID audioFileStreamID;
}
@property (nonatomic, assign) id<NJAudioStreamParserDelegate> audioParserDelegate;
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
		CheckError(AudioFileStreamOpen((__bridge void *)(self), parserDidParseProperty, parserDidParsePacket,  0, &audioFileStreamID), "Open file stream fail");
    }
    return self;
}

- (void)parseBytes:(NSData *)inData
{
	CheckError(AudioFileStreamParseBytes(audioFileStreamID, inData.length, inData.bytes, 0), "Parse file stream fail");
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
		AudioStreamBasicDescription audioStreamDescription;
        UInt32 descriptionSize = sizeof(AudioStreamBasicDescription);
		CheckError(AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &descriptionSize, &audioStreamDescription), "Get property fail");
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

@end
