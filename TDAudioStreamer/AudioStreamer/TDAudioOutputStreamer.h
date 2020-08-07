//
//  TDAudioOutputStreamer.h
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 11/14/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//
@import MediaPlayer;
#import <Foundation/Foundation.h>

@protocol TDAudioOutputStreamerDelegate <NSObject>

-(void)localPlayback;

@end

@interface TDAudioOutputStreamer : NSObject

@property (nonatomic, assign) id <TDAudioOutputStreamerDelegate> localPlaybackDelegate;

- (instancetype)initWithOutputStream:(NSOutputStream *)stream;

- (void)streamAudioFromURL:(NSURL *)url;
- (void)start;
- (void)stop;

@end
