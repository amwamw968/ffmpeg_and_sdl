//
//  ViewController.m
//  ffmpeg_and_sdl
//
//  Created by amw on 13-4-18.
//  Copyright (c) 2013年 amw. All rights reserved.
//

#import "ViewController.h"
#import "KxAudioFrame.h"


@interface ViewController ()
{
    NSArray *_localMovies;
    NSArray *_remoteMovies;
}
@property (strong, nonatomic) UITableView *tableView;


@end





@implementation ViewController

@synthesize outputWidth, outputHeight;
static void avStreamFPSTimeBase(AVStream *st, CGFloat defaultTimeBase, CGFloat *pFPS, CGFloat *pTimeBase)
{
    CGFloat fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(st->codec->time_base.den && st->codec->time_base.num)
        timebase = av_q2d(st->codec->time_base);
    else
        timebase = defaultTimeBase;
    
    if (st->codec->ticks_per_frame != 1) {
        NSLog(@"WARNING: st.codec.ticks_per_frame=%d", st->codec->ticks_per_frame);
        //timebase *= st->codec->ticks_per_frame;
    }
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    
    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
}

void SaveFrame(AVFrame *pFrame, int width, int height, int iFrame) {
    FILE *pFile;
    //char szFilename[32];
    NSString *fileName;
    int  y;

    // Open file
    //sprintf(szFilename, "frame%d.ppm", iFrame);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	//[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"image%04d.ppm",iFrame]];
    
    fileName = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"image%04d.ppm",iFrame]];
    NSLog(@"szFilename = %@", fileName);
    pFile=fopen([fileName cStringUsingEncoding:NSASCIIStringEncoding], "wb");
    if(pFile==NULL)
        return;
    // Write header
    fprintf(pFile, "P6\n%d %d\n255\n", width, height);
    // Write pixel data
    for(y=0; y<height; y++)
        fwrite(pFrame->data[0]+y*pFrame->linesize[0], 1, width*3, pFile);
    // Close file
    fclose(pFile);

}

int img_convert(AVPicture *dst, int dst_pix_fmt,
                const AVPicture *src, int src_pix_fmt,
                int src_width, int src_height)
{
    int w;
    int h;
    struct SwsContext *pSwsCtx = NULL;
    
    w = src_width;
    h = src_height;
    
    pSwsCtx = sws_getContext(w, h, src_pix_fmt,
                             w, h, dst_pix_fmt,
                             SWS_FAST_BILINEAR, NULL, NULL, NULL);

    /*pSwsCtx = sws_getCachedContext(pSwsCtx,
                                   w, h, src_pix_fmt,
                                   w, h, dst_pix_fmt,
                                   SWS_FAST_BILINEAR,
                                   NULL, NULL, NULL);*/
    
    
    //NSLog(@"pSwsCtx = %p", pSwsCtx);

    sws_scale(pSwsCtx, src->data, src->linesize, 0, h, dst->data, dst->linesize);
        
    return 0;
}

-(void) initVideo
{
    AVFormatContext *pFmt = NULL;
    
    NSString *path = (NSString *)[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"test_format_1.3gp"];
    
    
    NSLog(@"enter initVideo");
    av_register_all();

    
    avformat_alloc_output_context2(&pFmt, NULL, NULL, [path cStringUsingEncoding: NSUTF8StringEncoding]);
    if (!pFmt) {
        NSLog(@"Could not deduce output format from file extension: using MPEG.\n");
        avformat_alloc_output_context2(&pFmt, NULL, "mpeg", [path cStringUsingEncoding: NSUTF8StringEncoding]);
    }
    
    if (avformat_open_input(&pFmt, [path cStringUsingEncoding: NSUTF8StringEncoding], NULL, NULL) != 0)
    {
        NSLog(@"avformat_open_input err");
        return ;
    }
    
    if (avformat_find_stream_info(pFmt, NULL) < 0)
    {
        NSLog(@"avformat_find_stream_info err");
        return ;
    }
    
    av_dump_format(pFmt, 0, [path.lastPathComponent cStringUsingEncoding: NSUTF8StringEncoding], 0);
    
    
    
    
    
    int i, videoStream,audioStream;
    AVCodecContext *pCodecCtx, *aCodecCtx;
    // Find the first video stream
    videoStream=-1;
    audioStream=-1;
    for(i=0; i < pFmt->nb_streams; i++)
    {
        if(pFmt->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            videoStream = i;
            //break;
        }
        
        if(pFmt->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO && audioStream < 0)
        {
            audioStream=i;
        }
    }
    if(videoStream==-1)
    {
        NSLog(@"videoStream==-1");
        return ; // Didn't find a video stream
    }
    if(audioStream==-1)
        return ;
    
    NSLog(@"videoStream==%d", videoStream);
     NSLog(@"audioStream==%d", audioStream);
    // Get a pointer to the codec context for the video stream
    pCodecCtx = pFmt->streams[videoStream]->codec;
    
   
    
   // aCodecCtx=pFmt->streams[audioStream]->codec;
    
    AVCodec *pCodec;
    AVCodec *aCodec;
    
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    
    if(pCodec==NULL)
    {
        NSLog(@"Unsupported codec! %s\n", avcodec_get_name(pCodecCtx->codec_id));
        return ; // Codec not found
    }
    
    NSLog(@"pCodecCtx->codec_id==%s", avcodec_get_name(pCodecCtx->codec_id));
    
    /*aCodec = avcodec_find_decoder(aCodecCtx->codec_id);
    if(!aCodec)
    {
        NSLog(@"Unsupported codec! %s\n", avcodec_get_name(aCodecCtx->codec_id));

        return ;
    }
    NSLog(@"aCodecCtx->codec_id==%s", avcodec_get_name(aCodecCtx->codec_id));*/

    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
            NSLog(@"avcodec_open codec error!\n");
            return ; // Could not open codec
    }
    
   /* if (avcodec_open2(aCodecCtx, aCodec, NULL) < 0)
    {
        NSLog(@"avcodec_open codec error! audio\n");
        return ; // Could not open codec
    }*/
    
    AVFrame *pFrameRGB;
    CGFloat             videoTimeBase;
    CGFloat fps;
    
    pFrameRGB = avcodec_alloc_frame();
    
    if (!pFrameRGB) {
        NSLog(@"avcodec_alloc_frame  error!\n");

        avcodec_close(pCodecCtx);
        return ;
    }
    
    
    
    uint8_t *buffer;
    int     numBytes;
    
    // Determine required buffer size and allocate buffer
    numBytes = avpicture_get_size(AV_PIX_FMT_RGB24, pCodecCtx->width,
                                pCodecCtx->height);
    NSLog(@"before av_malloc");
    buffer=(uint8_t *)av_malloc(numBytes*sizeof(uint8_t));
    

    // Assign appropriate parts of buffer to image planes in pFrameRGB
    // Note that pFrameRGB is an AVFrame, but AVFrame is a superset
    // of AVPicture
    NSLog(@"before avpicture_fill");
    avpicture_fill((AVPicture *)pFrameRGB, buffer, AV_PIX_FMT_RGB24,
                   pCodecCtx->width, pCodecCtx->height);
    
    
    
    int frameFinished;
    AVPacket packet;
    AVFrame *pFrame = NULL;
    
    pFrame =avcodec_alloc_frame();
    
    i=0;
    NSLog(@"before av_read_frame");
    
    
   // NSMutableArray *result = [NSMutableArray array];
    
    while(av_read_frame(pFmt, &packet) >= 0)
    {

        if(packet.stream_index == videoStream)
        {

            avcodec_decode_video2(pCodecCtx, pFrame, &frameFinished, &packet);
            
            if(frameFinished)
            {
                avpicture_deinterlace((AVPicture*)pFrame,
                                      (AVPicture*)pFrame,
                                      pCodecCtx->pix_fmt,
                                      pCodecCtx->width,
                                      pCodecCtx->height);
                
                img_convert((AVPicture *)pFrameRGB, PIX_FMT_RGB24,
                            (AVPicture*)pFrame, pCodecCtx->pix_fmt, pCodecCtx->width,
                            pCodecCtx->height);
                
                
                // Save the frame to disk
                
                ++i;
                if(i == 111 || i == 211 || i == 311 || i == 411 || i == 511)
                {                
                    SaveFrame(pFrameRGB, pCodecCtx->width, pCodecCtx->height, i);                
                }
                
                
            }
        }
#if 0
        else if (packet.stream_index == audioStream)
        {
            
            int pktSize = packet.size;
            AVFrame *audioFrame;
            SwrContext *swrContext = NULL;
            UInt32             numOutputChannels;
            Float64            samplingRate;
            void * audioData;
            void                *_swrBuffer;
             NSUInteger          _swrBufferSize;
            NSInteger numFrames;
            
            //swr_init(swrContext);
            
            swrContext = swr_alloc_set_opts(NULL,
                                            av_get_default_channel_layout(numOutputChannels),
                                            AV_SAMPLE_FMT_S16,
                                            samplingRate,
                                            av_get_default_channel_layout(aCodecCtx->channels),
                                            aCodecCtx->sample_fmt,
                                            aCodecCtx->sample_rate,
                                            0,
                                            NULL);
            
            if (!swrContext /*||
                swr_init(swrContext)*/) {
                
                if (swrContext)
                    swr_free(&swrContext);
                avcodec_close(aCodecCtx);
                NSLog(@"swrContext   ALLOC ERROR");
                return ;
            }
            
            AVStream *st = pFmt->streams[audioStream];
            CGFloat             audioTimeBase;
            
            avStreamFPSTimeBase(st, 0.025, 0, &audioTimeBase);
            
           /* NSLog(@"audio codec smr: %.d fmt: %d chn: %d tb: %f %@",
                  aCodecCtx->sample_rate,
                  aCodecCtx->sample_fmt,
                  aCodecCtx->channels,
                  audioTimeBase,
                  swrContext ? @"resample" : @"");*/
            
            if(frameFinished)
            {
                
                int gotframe = 0;
                if(!audioFrame)
                {
                    if (!(audioFrame = avcodec_alloc_frame()))
                    {
                        if (swrContext)
                            swr_free(&swrContext);
                        avcodec_close(aCodecCtx);
                        NSLog(@"audioFrame ALLOC ERROR");
                        return;
                    }
                }
                
                int len = avcodec_decode_audio4(aCodecCtx,
                                                audioFrame,
                                                &gotframe,
                                                &packet);
                
                if (len < 0) {
                    NSLog(@"decode audio error, skip packet");
                    break;
                }
                
                if (gotframe) {

                    if (!audioFrame->data[0])
                    {
                            NSLog(@"audioFrame->data[0] ALLOC ERROR");
                            return ;
                    }
                    
                    if (swrContext)
                    {
                        
                        const NSUInteger ratio = MAX(1, samplingRate / aCodecCtx->sample_rate) * MAX(1, numOutputChannels / aCodecCtx->channels) * 2;
                        
                        const int bufSize = av_samples_get_buffer_size(NULL,
                                                                       numOutputChannels,
                                                                       audioFrame->nb_samples * ratio,
                                                                       AV_SAMPLE_FMT_S16,
                                                                       1);
                        
                        if (!_swrBuffer || _swrBufferSize < bufSize) {
                            _swrBufferSize = bufSize;
                            _swrBuffer = realloc(_swrBuffer, _swrBufferSize);
                        }
                        
                        Byte *outbuf[2] = { _swrBuffer, 0 };
                        
                        numFrames = swr_convert(swrContext,
                                                outbuf,
                                                audioFrame->nb_samples * ratio,
                                                (const uint8_t **)audioFrame->data,
                                                audioFrame->nb_samples);
                        
                        if (numFrames < 0) {
                            NSLog(@"fail resample audio");
                            return ;
                        }
                        
                        //int64_t delay = swr_get_delay(_swrContext, audioManager.samplingRate);
                        //if (delay > 0)
                        //    NSLog(@"resample delay %lld", delay);
                        
                        audioData = _swrBuffer;
                        
                    }else {
                        
                        if (aCodecCtx->sample_fmt != AV_SAMPLE_FMT_S16) {
                            NSAssert(false, @"bucheck, audio format is invalid");
                            return ;
                        }
                        
                        audioData = audioFrame->data[0];
                        numFrames = audioFrame->nb_samples;
                    }

                    
                    const NSUInteger numElements = numFrames * numOutputChannels;
                    NSMutableData *data = [NSMutableData dataWithLength:numElements * sizeof(float)];
                    
                    float scale = 1.0 / (float)INT16_MAX ;
                    vDSP_vflt16((SInt16 *)audioData, 1, data.mutableBytes, 1, numElements);
                    vDSP_vsmul(data.mutableBytes, 1, &scale, data.mutableBytes, 1, numElements);
                    
                    KxAudioFrame *frame = [[KxAudioFrame alloc] init];
                    frame.position  = av_frame_get_best_effort_timestamp(audioFrame) * audioTimeBase;
                    frame.duration = av_frame_get_pkt_duration(audioFrame) * audioTimeBase;
                    frame.samples = data;
                    
                    if (frame.duration == 0) {
                        // sometimes ffmpeg can't determine the duration of audio frame
                        // especially of wma/wmv format
                        // so in this case must compute duration
                        frame.duration = frame.samples.length / (sizeof(float) * numOutputChannels * samplingRate);
                    }
                    
#if 0
                    NSLog(@"AFD: %.4f %.4f | %.4f ",
                          frame.position,
                          frame.duration,
                          frame.samples.length / (8.0 * 44100.0));
#endif
                    
                    /*audioFrame = frame;
                    
                    if (audioFrame) {
                        
                        [result addObject:frame];
                        
                        if (videoStream == -1) {
                            
                            position = frame.position;
                            decodedDuration += frame.duration;
                            if (decodedDuration > minDuration)
                                finished = YES;
                        }
                    }*/
                }
                
                /*if (0 == len)
                    break;
                
                pktSize -= len;*/
            }
            
        }
#endif
        // Free the packet that was allocated by av_read_frame
        av_free_packet(&packet);
    }
    
    // determine fps
    NSLog(@"after read frame, i=%d", i);
    AVStream *st = pFmt->streams[videoStream];
    avStreamFPSTimeBase(st, 0.04, &fps, &videoTimeBase);
    
    NSLog(@"video codec fps: %.3f tb: %f",
          fps,
          videoTimeBase);
    
    NSLog(@"video start time %f", st->start_time * videoTimeBase);
    NSLog(@"video disposition %d", st->disposition);
    
    // Free the RGB image
    av_free(buffer);
    av_free(pFrameRGB);
    
    // Free the YUV frame
    av_free(pFrame);
    
    // Close the codec
    avcodec_close(pCodecCtx);
    avformat_close_input(&pFmt);
    NSLog(@"leave initVideo");

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
         self.title = @"Movies";
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFeatured tag: 0];
        
        _remoteMovies = @[
                          
                       //   @"http://eric.cast.ro/stream2.flv",
                       //   @"http://liveipad.wasu.cn/cctv2_ipad/z.m3u8",
                      //    @"http://www.wowza.com/_h264/BigBuckBunny_175k.mov",
                          // @"http://www.wowza.com/_h264/BigBuckBunny_115k.mov",
                      //    @"rtsp://184.72.239.149/vod/mp4:BigBuckBunny_115k.mov",
                          @"http://santai.tv/vod/test/test_format_1.3gp",
                     //     @"http://santai.tv/vod/test/test_format_1.mp4",
                     //     @"rtsp://184.72.239.149/vod/mp4://BigBuckBunny_175k.mov",
                     //     @"http://santai.tv/vod/test/BigBuckBunny_175k.mov",
                          
                          // @"rtmp://aragontvlivefs.fplive.net/aragontvlive-live/stream_normal_abt",
                          // @"rtmp://ucaster.eu:1935/live/_definst_/discoverylacajatv",
                          // @"rtmp://edge01.fms.dutchview.nl/botr/bunny.flv"
                          
                          ];
        _localMovies = @[
                         (NSString *)[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"test_format_1.3gp"],
                         (NSString *)[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"01.avi"],
                         (NSString *)[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"BigBuckBunny_175k.mov"],
                         (NSString *)[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"123.mp3"]
                         ];
    }
    return self;
}


- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor whiteColor];
    //self.tableView.backgroundView = [[UIImageView alloc] initWithImage:image];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
        [self initVideo];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
   

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:     return @"Remote";
        case 1:     return @"Local";
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:     return _remoteMovies.count;
        case 1:     return _localMovies.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSString *path;
    
    if (indexPath.section == 0) {
        
        path = _remoteMovies[indexPath.row];
        
    } else {
        
        path = _localMovies[indexPath.row];
    }
    
    cell.textLabel.text = path.lastPathComponent;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *path;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (indexPath.section == 0) {
        
        path = _remoteMovies[indexPath.row];
        
    } else {
        
        path = _localMovies[indexPath.row];
    }
    
    // increase buffering for .wmv, it solves problem with delaying audio frames
    //if ([path.pathExtension isEqualToString:@"wmv"])
    //    parameters[KxMovieParameterMinBufferedDuration] = @(5.0);
    
    // disable deinterlacing for iPhone, because it's complex operation can cause stuttering
    //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    //    parameters[KxMovieParameterDisableDeinterlacing] = @(YES);
    
    // disable buffering
    //parameters[KxMovieParameterMinBufferedDuration] = @(0.0f);
    //parameters[KxMovieParameterMaxBufferedDuration] = @(0.0f);
    NSLog(@"path=%@",path);
    //ViewController *vc = [ViewController movieViewControllerWithContentPath:path
     //                                                                          parameters:parameters];
    //[self presentViewController:vc animated:YES completion:nil];
    //[self.navigationController pushViewController:vc animated:YES];
}


- (void)dealloc {
    //[self.view release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setView:nil];
    [super viewDidUnload];
}
@end
