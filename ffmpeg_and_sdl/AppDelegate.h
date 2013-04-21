//
//  AppDelegate.h
//  ffmpeg_and_sdl
//
//  Created by amw on 13-4-18.
//  Copyright (c) 2013年 amw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    UIWindow *window;
	IBOutlet UIImageView *imageView;
	IBOutlet UILabel *label;
	IBOutlet UIButton *playButton;
	ViewController *video;
	float lastFrameTime;
}
//@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) ViewController *video;
@end
