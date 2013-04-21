//
//  KxAudioFrame.h
//  ffmpeg_and_sdl
//
//  Created by amw on 13-4-21.
//  Copyright (c) 2013年 amw. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    
    KxMovieFrameTypeAudio,
    KxMovieFrameTypeVideo,
    KxMovieFrameTypeArtwork,
    KxMovieFrameTypeSubtitle,
    
} KxMovieFrameType;

@interface KxAudioFrame : NSObject
@property (readwrite, nonatomic) KxMovieFrameType type;
@property (readwrite, nonatomic) CGFloat position;
@property (readwrite, nonatomic) CGFloat duration;
@property (readwrite, nonatomic, strong) NSData *samples;
@end
