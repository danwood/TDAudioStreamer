//
//  TDAudioFileStream.m
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDAudioFileStream.h"

@interface TDAudioFileStream ()

@property (assign, nonatomic) AudioFileStreamID audioFileStreamID;

- (void)didChangeProperty:(AudioFileStreamPropertyID)propertyID flags:(UInt32 *)flags;
- (void)didReceivePackets:(const void *)packets packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberOfPackets:(UInt32)numberOfPackets numberOfBytes:(UInt32)numberOfBytes;

@end

void TDAudioFileStreamPropertyListener(void *inClientData, AudioFileStreamID inAudioFileStreamID, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags)
{
    TDAudioFileStream *audioFileStream = (__bridge TDAudioFileStream *)inClientData;
    [audioFileStream didChangeProperty:inPropertyID flags:ioFlags];
}

void TDAudioFileStreamPacketsListener(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions)
{
    
    NSLog(@"TDAudioFileStream received packets %i", (unsigned int)inNumberPackets);
    
    TDAudioFileStream *audioFileStream = (__bridge TDAudioFileStream *)inClientData;
    [audioFileStream didReceivePackets:inInputData packetDescriptions:inPacketDescriptions numberOfPackets:inNumberPackets numberOfBytes:inNumberBytes];
}

@implementation TDAudioFileStream

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    OSStatus err = AudioFileStreamOpen((__bridge void *)self, TDAudioFileStreamPropertyListener, TDAudioFileStreamPacketsListener, 0 /* hint */, &_audioFileStreamID);

	if (err) {
		NSLog(@"TDAudioFileStream init error = %d", (int)err);
		return nil;
	}

    self.discontinuous = YES;

    return self;
}

- (void)didChangeProperty:(AudioFileStreamPropertyID)propertyID flags:(UInt32 *)flags
{
    if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        UInt32 basicDescriptionSize = sizeof(self.basicDescription);
        OSStatus err = AudioFileStreamGetProperty(self.audioFileStreamID, kAudioFileStreamProperty_DataFormat, &basicDescriptionSize, &_basicDescription);

        if (err) return [self.delegate audioFileStream:self didReceiveError:err];

        UInt32 byteCountSize;
        AudioFileStreamGetProperty(self.audioFileStreamID, kAudioFileStreamProperty_AudioDataByteCount, &byteCountSize, &_totalByteCount);

        UInt32 sizeOfUInt32 = sizeof(UInt32);
        err = AudioFileStreamGetProperty(self.audioFileStreamID, kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32, &_packetBufferSize);

        if (err || !self.packetBufferSize) {
            AudioFileStreamGetProperty(self.audioFileStreamID, kAudioFileStreamProperty_MaximumPacketSize, &sizeOfUInt32, &_packetBufferSize);
        }

        Boolean writeable;
        err = AudioFileStreamGetPropertyInfo(self.audioFileStreamID, kAudioFileStreamProperty_MagicCookieData, &_magicCookieLength, &writeable);

        if (!err) {
            self.magicCookieData = calloc(1, self.magicCookieLength);
            AudioFileStreamGetProperty(self.audioFileStreamID, kAudioFileStreamProperty_MagicCookieData, &_magicCookieLength, self.magicCookieData);
        }

        [self.delegate audioFileStreamDidBecomeReady:self];
    }
}

- (void)didReceivePackets:(const void *)packets packetDescriptions:(AudioStreamPacketDescription *)packetDescriptions numberOfPackets:(UInt32)numberOfPackets numberOfBytes:(UInt32)numberOfBytes
{
    
    NSLog(@"TDAudioFileStream received packets %i", (unsigned int)numberOfPackets);
    
    if (packetDescriptions) {
        for (NSUInteger i = 0; i < numberOfPackets; i++) {
            [self.delegate audioFileStream:self didReceiveData:(const void *)(packets) packetDescription:(AudioStreamPacketDescription)packetDescriptions[i]];
        }
    } else {
        [self.delegate audioFileStream:self didReceiveData:(const void *)packets length:numberOfBytes];
    }
}

- (void)parseData:(const void *)data length:(UInt32)length
{
    OSStatus err;

    //NSLog(@"parseData discont: %i length: %i",self.discontinuous, length);
    
    if (self.discontinuous) {
        err = AudioFileStreamParseBytes(self.audioFileStreamID, length, data, kAudioFileStreamParseFlag_Discontinuity);
        self.discontinuous = NO;
    } else {
        err = AudioFileStreamParseBytes(self.audioFileStreamID, length, data, 0);
    }

    if (err)
	{
		switch (err) {
			case kAudioFileStreamError_UnsupportedFileType:
				NSLog(@"error unsupported file type: %d", (int)err);
				break;
			case kAudioFileStreamError_UnsupportedDataFormat:
				NSLog(@"error unsupported data format: %d", (int)err);
				break;
			case kAudioFileStreamError_UnsupportedProperty:
				NSLog(@"error unsupported property: %d", (int)err);
				break;
			case kAudioFileStreamError_BadPropertySize:
				NSLog(@"error bad property size: %d", (int)err);
				break;
			case kAudioFileStreamError_NotOptimized:
				NSLog(@"error not optimized: %d", (int)err);
				break;
			case kAudioFileStreamError_InvalidPacketOffset:
				NSLog(@"error invliad packet offset: %d", (int)err);
				break;
			case kAudioFileStreamError_InvalidFile:
				NSLog(@"error invalid file: %d", (int)err);
				break;
			case kAudioFileStreamError_ValueUnknown:
				NSLog(@"error value unknown: %d", (int)err);
				break;
			case kAudioFileStreamError_DataUnavailable:
				NSLog(@"error data unavailable: %d", (int)err);
				break;
			case kAudioFileStreamError_IllegalOperation:
				NSLog(@"error illegal operation: %d", (int)err);
				break;
			case kAudioFileStreamError_UnspecifiedError:
				NSLog(@"error unspecified error: %d", (int)err);
				break;
			case kAudioFileStreamError_DiscontinuityCantRecover:
				NSLog(@"error discontinuity can't recover: %d", (int)err);
				break;
			default:
				break;
		}
		NSLog(@"error parsing stream data: %d", (int)err);
		[self.delegate audioFileStream:self didReceiveError:err];
	}
}

- (void)dealloc
{
    AudioFileStreamClose(self.audioFileStreamID);
    free(_magicCookieData);
}

@end
