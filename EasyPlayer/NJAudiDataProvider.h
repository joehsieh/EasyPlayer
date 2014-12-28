//
//  NJAudiDataProvider.h
//  EasyPlayer
//
//  Created by joehsieh on 2014/12/27.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

@import Foundation;
@import AudioToolbox;
@class NJAudiDataProvider;
@class NJPacketArray;

@protocol NJAudiDataProviderDelegate <NSObject>
- (void)audioDataProviderDidObtainEnoughPlayableData:(NJAudiDataProvider *)inProvider;
@end

@interface NJAudiDataProvider : NSObject
{
    AudioConverterRef converter;
    AudioBufferList *renderAudioBufferList;
    AURenderCallbackStruct renderCallbackStruct;
}
- (AudioBufferList *)renderAudioBufferList;
- (AudioConverterRef)converter;
- (AURenderCallbackStruct)renderCallbackStruct;
@property (nonatomic, strong) NJPacketArray *packetArray;
@property (weak, nonatomic) id <NJAudiDataProviderDelegate> delegate;
- (void)fetchAudioRawDataByURL:(NSURL *)inURL;
@end
