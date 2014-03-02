//
//  NJViewController.h
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NJPlayer.h"

@interface NJViewController : UIViewController <NJPlayerDelegate>
@property (nonatomic, assign) IBOutlet UIButton *playSongBtn;
@property (nonatomic, assign) IBOutlet UITextField *songURLTextField;
- (IBAction)playSong:(id)sender;
@end
