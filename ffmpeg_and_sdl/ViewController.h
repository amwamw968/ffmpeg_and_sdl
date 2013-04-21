//
//  ViewController.h
//  ffmpeg_and_sdl
//
//  Created by amw on 13-4-18.
//  Copyright (c) 2013年 amw. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"
#include <libavutil/mathematics.h>
#include <libswscale/swscale_internal.h>
#include <libavutil/imgutils.h>
#include <libavutil/samplefmt.h>
#include <libavutil/timestamp.h>


@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>


/* Output image size. Set to the source size by default. */
@property (nonatomic) int outputWidth, outputHeight;
-(void) initVideo;
@end


