//
//  NJViewController.h
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JHProgressBar;

@protocol JHProgressBarDelegate <NSObject>
@required
- (void)progressBar:(JHProgressBar *)progressBar didChangeHandlePosition:(double )playedPercent;
@end

@interface JHProgressBar : UIControl
@property (weak, nonatomic) id<JHProgressBarDelegate> delegate;

- (void)updateDownloadProgress:(float)completedPercent;
- (void)updatePlayProgress:(float)completedPercent;
@end
