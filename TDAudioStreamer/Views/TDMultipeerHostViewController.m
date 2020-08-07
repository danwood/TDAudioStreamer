//
//  TDMultipeerHostViewController.m
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 11/15/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

@import MediaPlayer;
@import MultipeerConnectivity;
@import AVFoundation;

#import "TDMultipeerHostViewController.h"
#import "TDAudioStreamer.h"
#import "TDSession.h"

@interface TDMultipeerHostViewController () <MPMediaPickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *albumImage;
@property (weak, nonatomic) IBOutlet UILabel *songTitle;
@property (weak, nonatomic) IBOutlet UILabel *songArtist;

@property (strong, nonatomic) MPMediaItem *song;
@property (strong, nonatomic) TDAudioOutputStreamer *outputStreamer;
@property (strong, nonatomic) TDSession *session;

//properties for local playback
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *localSong;

@end

@implementation TDMultipeerHostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.session = [[TDSession alloc] initWithPeerDisplayName:@"Host"];
}

#pragma mark - Media Picker delegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [self dismissViewControllerAnimated:YES completion:nil];

    if (self.outputStreamer) return;

    self.song = mediaItemCollection.items[0];

    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[@"title"] = [self.song valueForProperty:MPMediaItemPropertyTitle] ? [self.song valueForProperty:MPMediaItemPropertyTitle] : @"";
    info[@"artist"] = [self.song valueForProperty:MPMediaItemPropertyArtist] ? [self.song valueForProperty:MPMediaItemPropertyArtist] : @"";

    MPMediaItemArtwork *artwork = [self.song valueForProperty:MPMediaItemPropertyArtwork];
    UIImage *image = [artwork imageWithSize:self.albumImage.frame.size];
    if (image)
        info[@"artwork"] = image;

    if (info[@"artwork"])
        self.albumImage.image = info[@"artwork"];
    else
        self.albumImage.image = nil;

    self.songTitle.text = info[@"title"];
    self.songArtist.text = info[@"artist"];

    //uses pre-alloced objects to reduce latency for playback
    NSURL *audioUrl = [self.song valueForProperty:MPMediaItemPropertyAssetURL];
    self.localSong = [[AVPlayerItem alloc] initWithURL:audioUrl];
    

    [self.session sendData:[NSKeyedArchiver archivedDataWithRootObject:[info copy]]];

    NSArray *peers = [self.session connectedPeers];
    
    if (peers.count) {
        
        self.outputStreamer = [[TDAudioOutputStreamer alloc] initWithOutputStream:[self.session outputStreamForPeer:peers[0]]];
        self.outputStreamer.localPlaybackDelegate = self;
        [self.outputStreamer streamAudioFromURL:[self.song valueForProperty:MPMediaItemPropertyAssetURL]];
        [self.outputStreamer start];
    }
}
-(void) localPlayback {
    //starts local playback with delegate from audio output streamer
    NSLog(@"Local playback delegate");
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.localSong];
    [self.player play];
    
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View Actions
- (IBAction)inviteUsers:(id)sender {
    [self presentViewController:[self.session browserViewControllerForSeriviceType:@"dance-party"] animated:YES completion:nil];
}

- (IBAction)invite:(id)sender
{
    [self presentViewController:[self.session browserViewControllerForSeriviceType:@"dance-party"] animated:YES completion:nil];
}

- (IBAction)addSongs:(id)sender
{
#if TARGET_IPHONE_SIMULATOR
	if (self.outputStreamer) return;

	NSMutableDictionary *info = [NSMutableDictionary dictionary];
	info[@"title"] = @"Lorenzo Wood";
	info[@"artist"] = @"Focused on You";

	NSURL *artworkURL = [[NSBundle mainBundle] URLForResource:@"lorenzo" withExtension:@"jpg"];
	UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:artworkURL]];

	if (image)
		info[@"artwork"] = image;

	if (info[@"artwork"])
		self.albumImage.image = info[@"artwork"];
	else
		self.albumImage.image = nil;

	self.songTitle.text = info[@"title"];
	self.songArtist.text = info[@"artist"];

	[self.session sendData:[NSKeyedArchiver archivedDataWithRootObject:[info copy]]];

	NSArray *peers = [self.session connectedPeers];

	if (peers.count) {

		NSURL *songURL = [[NSBundle mainBundle] URLForResource:@"falling" withExtension:@"mp3"];

		self.outputStreamer = [[TDAudioOutputStreamer alloc] initWithOutputStream:[self.session outputStreamForPeer:peers[0]]];
		[self.outputStreamer streamAudioFromURL:songURL];
		[self.outputStreamer start];
	}


#else
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
#endif
}

@end
