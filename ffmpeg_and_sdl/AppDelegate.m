//
//  AppDelegate.m
//  ffmpeg_and_sdl
//
//  Created by amw on 13-4-18.
//  Copyright (c) 2013年 amw. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

@synthesize window, imageView, label, playButton, video;

- (void)dealloc
{
    [video release];
	[imageView release];
	[label release];
	[playButton release];
    [window release];
    [super dealloc];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"test_format_1.3gp"]
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

   // self.video = [[ViewController alloc] init];
    //[video release];
    
	//video.outputWidth = 426;
	//video.outputHeight = 320;
    
    UIViewController *vc = [[ViewController alloc] init];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[
                                         [[UINavigationController alloc] initWithRootViewController:vc],
                                         ];
    
    
   // [imageView setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    
    self.window.rootViewController = tabBarController;
    
    // Override point for customization after application launch.
    //self.window.backgroundColor = [UIColor greenColor];
    
    
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
