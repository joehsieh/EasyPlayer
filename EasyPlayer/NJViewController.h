//
//  NJViewController.h
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NJPlayer.h"
@class JHProgressBar;

@interface NJViewController : UIViewController <NJPlayerDelegate>
@property (assign, nonatomic) IBOutlet UIButton *playSongBtn;
@property (assign, nonatomic) IBOutlet JHProgressBar *progressBar;
@property (assign, nonatomic) IBOutlet UITextField *songURLTextField;
- (IBAction)playSong:(id)sender;
- (IBAction)playPreviousSong:(id)sender;
- (IBAction)playNextSong:(id)sender;
@end
