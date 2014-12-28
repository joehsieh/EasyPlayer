//
//  NJViewController.m
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "NJViewController.h"
#import "NJPlayer.h"
#import "JHProgressBar.h"
@import CoreMotion;

typedef NS_ENUM(NSInteger, PlayerStateType) {
    PlayerStateOff,
    PlayerStatePlaying,
    PlayerStatePaused
};
@interface NJViewController ()
@property (assign, nonatomic) PlayerStateType playerState;
@property (strong, nonatomic) CMMotionManager *motionManager;
@end

@implementation NJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.playerState = PlayerStateOff;
	// Do any additional setup after loading the view, typically from a nib.
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 1.0f;
    if ([self.motionManager isGyroAvailable]) {
        if (![self.motionManager isGyroActive]) {
            [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
                if (motion.gravity.y > 0) {
                    [[NJPlayer sharedPlayer] setVolume:motion.gravity.y forBusIndex:0];
                }
                else {
                    [[NJPlayer sharedPlayer] setVolume:ABS(motion.gravity.y) forBusIndex:1];
                }
            }];
        }
    }
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
        [player playTestSongs];
    }
}

- (IBAction)playPreviousSong:(id)sender
{
#warning todo
}

- (IBAction)playNextSong:(id)sender
{
#warning todo
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

- (void)player:(NJPlayer *)inPlayer updatePlaybackTime:(NSTimeInterval)inTime
{
	[self.progressBar updatePlayProgress:inTime];
}

@end
