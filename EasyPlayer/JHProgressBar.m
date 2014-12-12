//
//  NJViewController.h
//  EasyPlayer
//
//  Created by joehsieh on 2014/2/22.
//  Copyright (c) 2014年 NJ. All rights reserved.
//

#import "JHProgressBar.h"

@interface JHProgressBar ()
@property (assign, nonatomic) BOOL maxThumbOn;
@property (strong, nonatomic) UIImageView *trackBackground;
@property (strong, nonatomic) UIImageView *track;
@property (strong, nonatomic) UIImageView *maxThumb;
@property (assign, nonatomic) CGFloat miniumValue;
@property (assign, nonatomic) CGFloat maxiumValue;
@property (assign, nonatomic) CGFloat selectedMaxiumValue;
@property (assign, nonatomic) CGFloat padding;
@property (assign, nonatomic) CGPoint maxThumbCenterPoint;
@property (assign, nonatomic) CGPoint downloadIndex;
- (float)xForValue:(float)value;
- (void)updateTrackHighlight;
- (float) valueForX:(float)x;

@end

@implementation JHProgressBar

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
    if (self) {
        self.selectedMaxiumValue = 0;
        self.maxiumValue = 10;
        self.miniumValue = 0;
        
        self.maxThumbOn = NO;
        
        UIImageView *trackBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar-background.png"]];
		self.trackBackground = trackBackground;
        self.padding = (self.frame.size.width - _trackBackground.frame.size.width) / 2;
        trackBackground.frame = CGRectMake((self.frame.size.width - trackBackground.frame.size.width) / 2, (self.frame.size.height - trackBackground.frame.size.height) / 2, trackBackground.frame.size.width, trackBackground.frame.size.height);
        [self addSubview:trackBackground];
        
        UIImageView *track = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar-highlight.png"]];
		self.track = track;
        track.frame = CGRectMake((self.frame.size.width - track.frame.size.width) / 2, (self.frame.size.height - track.frame.size.height) / 2, track.frame.size.width, track.frame.size.height);
        [self addSubview:track];
        
        UIImageView *maxThumb = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"handle.png"] highlightedImage:[UIImage imageNamed:@"handle-hover.png"]];
		self.maxThumb = maxThumb;
        maxThumb.frame = CGRectMake(0,0, self.frame.size.height / 2,self.frame.size.height / 2);
        maxThumb.center = CGPointMake([self xForValue:self.selectedMaxiumValue],  self.frame.size.height / 2);
        [self addSubview:maxThumb];
        self.maxThumbCenterPoint = maxThumb.center;
        
        [self updateTrackHighlight];
    }
    return self;
}

- (float)xForValue:(float)value
{
    return (self.frame.size.width - (self.padding * 2)) * ((value - self.miniumValue) / (self.maxiumValue - self.miniumValue)) + self.padding;
}

- (float)valueForX:(float)x
{
    return self.miniumValue + (x - self.padding) / (self.frame.size.width - (self.padding * 2)) * (self.maxiumValue - self.miniumValue);
}

- (void)updateTrackHighlight
{
    self.track.frame = CGRectMake(
                              10,
                              self.track.center.y - (self.track.frame.size.height/2),
                              self.downloadIndex.x,
                              self.track.frame.size.height
                              );
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
     
    CGPoint touchPoint = [touch locationInView:self];
    if(CGRectContainsPoint(self.maxThumb.frame, touchPoint)){
        self.maxThumbOn = true;
    }
     
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    _maxThumbOn = false;
	if (self.delegate) {
		[self.delegate progressBar:self didChangeHandlePosition:self.selectedMaxiumValue / self.maxiumValue];
	}
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.selectedMaxiumValue = [self valueForX:self.maxThumb.center.x];
    if(!_maxThumbOn){
        return YES;
    }
    
    CGPoint touchPoint = [touch locationInView:self];
    if(self.maxThumbOn){
        self.maxThumb.center = CGPointMake(MAX([self xForValue:self.miniumValue],MIN(touchPoint.x, self.downloadIndex.x)), self.maxThumb.center.y);
        self.maxThumbCenterPoint = self.maxThumb.center;
    }
    
    [self updateTrackHighlight];
    [self setNeedsDisplay];
    return YES;
}

- (void)updateDownloadProgress:(float)completedPercent
{
    self.downloadIndex = CGPointMake([self xForValue:completedPercent * self.maxiumValue], self.maxThumb.center.y);
    [self updateTrackHighlight];
    [self setNeedsDisplay];
}

- (void)updatePlayProgress:(float)completedPercent
{
    self.selectedMaxiumValue = completedPercent * self.maxiumValue;
    self.maxThumb.center = CGPointMake([self xForValue:self.selectedMaxiumValue], self.maxThumb.center.y);
    self.maxThumbCenterPoint = self.maxThumb.center;
}

@end
