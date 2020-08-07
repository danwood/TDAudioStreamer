//
//  TDAudioOutputStreamer.m
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 11/14/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//
@import MediaPlayer;

#import <AVFoundation/AVFoundation.h>
#import "TDAudioOutputStreamer.h"
#import "TDAudioStream.h"

@interface TDAudioOutputStreamer () <TDAudioStreamDelegate, MPMediaPickerControllerDelegate,TDAudioOutputStreamerDelegate>

@property (strong, nonatomic) TDAudioStream *audioStream;
@property (strong, nonatomic) AVAssetReader *assetReader;
@property (strong, nonatomic) AVAssetReaderTrackOutput *assetOutput;
@property (strong, nonatomic) NSThread *streamThread;

//properties for playing local song
@property (assign, atomic) BOOL isPlayingLocal;


@property (assign, atomic) BOOL isStreaming;

@end

@implementation TDAudioOutputStreamer
@synthesize localPlaybackDelegate;

- (instancetype) initWithOutputStream:(NSOutputStream *)stream
{
    self = [super init];
    if (!self) return nil;

    self.audioStream = [[TDAudioStream alloc] initWithOutputStream:stream];
    self.audioStream.delegate = self;
    NSLog(@"Init");
    
    return self;
}

- (void)start
{
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]])
	{
		NSLog(@"starting out stream on main thread");
        return [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
    }

    NSLog(@"Start");
	if (self.streamThread != nil)
	{
		[self stop];
	}
    self.streamThread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [self.streamThread start];
}

- (void)run
{
    @autoreleasepool {
        [self.audioStream open];

        self.isStreaming = YES;
        NSLog(@"Loop!");

		while ((![[NSThread currentThread] isCancelled]) && self.isStreaming && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {}


		self.isStreaming = NO;
		[self.audioStream close];
		NSLog(@"Stop");


        NSLog(@"Done");
    }
}

- (void)streamAudioFromURL:(NSURL *)url
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSError *assetError;
    
    self.assetReader = [AVAssetReader assetReaderWithAsset:asset error:&assetError];
    self.assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:asset.tracks[0] outputSettings:nil];
    if (![self.assetReader canAddOutput:self.assetOutput]) return;

    [self.assetReader addOutput:self.assetOutput];
    [self.assetReader startReading];
    NSLog(@"Read Asset");
}

- (void)sendDataChunk
{
    CMSampleBufferRef sampleBuffer;

    sampleBuffer = [self.assetOutput copyNextSampleBuffer];

    if (sampleBuffer == NULL || CMSampleBufferGetNumSamples(sampleBuffer) == 0) {
        CFRelease(sampleBuffer);
        return;
    }

    CMBlockBufferRef blockBuffer;
    AudioBufferList audioBufferList;

    OSStatus err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(AudioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);

    if (err) {
		NSLog(@"sendDataChunk error = %d", (int)err);
        CFRelease(sampleBuffer);
        return;
    }

    for (NSUInteger i = 0; i < audioBufferList.mNumberBuffers; i++) {
        AudioBuffer audioBuffer = audioBufferList.mBuffers[i];
        [self.audioStream writeData:audioBuffer.mData maxLength:audioBuffer.mDataByteSize];
        NSLog(@"buffer size: %u", (unsigned int)audioBuffer.mDataByteSize);
        NSLog(@"play local");
        if (self.isPlayingLocal != true) {
            //calls method for local playback, uses the if statement with boolean to only call the delegate method once
            [self play];
            self.isPlayingLocal = true;
        }
    }

    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
}
- (void)play {
    //play local playback
    NSLog(@"succeed playing local");
    [[self localPlaybackDelegate] localPlayback];
}

- (void)stop
{
	NSLog(@"stopping out stream");
	[self.streamThread cancel];
}

#pragma mark - TDAudioStreamDelegate

- (void)audioStream:(TDAudioStream *)audioStream didRaiseEvent:(TDAudioStreamEvent)event
{
    switch (event) {
        case TDAudioStreamEventWantsData:
            [self sendDataChunk];
            break;

        case TDAudioStreamEventError:
            // TODO: shit!
            NSLog(@"Stream Error");
            break;

        case TDAudioStreamEventEnd:
            // TODO: shit!
            NSLog(@"Stream Ended");
            break;

        default:
            break;
    }
}

@end
