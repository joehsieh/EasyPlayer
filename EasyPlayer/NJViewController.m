//
//  NJViewController.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJViewController.h"
#import "NJPlayer.h"
typedef NS_ENUM(NSInteger, PlayerStateType) {
    PlayerStateOff,
    PlayerStatePlaying,
    PlayerStatePaused
};
@interface NJViewController ()
@property (nonatomic, assign) PlayerStateType playerState;
@end

@implementation NJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.songURLTextField.text = @"http://f10.wretch.yimg.com/a33233323/2/1418398424.mp3";
    self.songURLTextField.text = @"http://zonble.net/MIDI/orz.mp3";
    self.playerState = PlayerStateOff;
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)playSong:(id)sender
{
    NJPlayer *player = [NJPlayer sharedPlayer];
    player.delegate = self;
    if (self.playerState == PlayerStatePlaying) {
        [player pause];
    }
    else if (self.playerState == PlayerStatePaused) {
        [player resume];
    }
    else if (self.playerState == PlayerStateOff) {
        NSString *songURLString = self.songURLTextField.text;
        [player playSongWithURL:[NSURL URLWithString:songURLString]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NJPlayerDelegate

- (void)playerDidStartPlayingSong:(NJPlayer *)inPlayer
{
    self.playerState = PlayerStatePlaying;
    [self.playSongBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
}
- (void)playerDidStopPlayingSong:(NJPlayer *)inPlayer
{
    self.playerState = PlayerStateOff;
    [self.playSongBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
}
- (void)playerDidPausePlayingSong:(NJPlayer *)inPlayer
{
    self.playerState  = PlayerStatePaused;
    [self.playSongBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
}
- (void)playerDidResumePlayingSong:(NJPlayer *)inPlayer
{
    self.playerState  = PlayerStatePlaying;
    [self.playSongBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
}
@end
