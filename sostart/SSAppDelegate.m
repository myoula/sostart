//
//  SSAppDelegate.m
//  sostart
//
//  Created by myoula on 13-12-18.
//  Copyright (c) 2013年 myoula. All rights reserved.
//

#import "SSAppDelegate.h"
#import "AudioStreamer.h"

@implementation SSAppDelegate {
    NSMutableArray* musics;
    AudioStreamer* streamer;
    NSTimer* progressUpdateTimer;
    NSURLConnection* aSynConnection;
    NSMutableData* buf;
    NSImage* playimg;
    NSImage* playhighimg;
    NSImage* stopimg;
    NSImage* stophighimg;
    BOOL isok;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    aSynConnection = [NSURLConnection alloc];
    buf = [NSMutableData alloc];
    isok = FALSE;
    
    playimg = [NSImage imageNamed:@"play"];
    playhighimg = [NSImage imageNamed:@"play-high"];
    stopimg = [NSImage imageNamed:@"stop"];
    stophighimg = [NSImage imageNamed:@"stop-high"];
    musics = [[NSMutableArray alloc] init];
    [self getmusiclist];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [self destroyStreamer];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)getmusiclist {
    [self destroyStreamer];
    
    if ([musics count] == 0)
    {
        NSString* musiclisturl = [[NSString alloc] initWithFormat:@"http://sostart.cdn.duapp.com/api.php?_%d", (int)random()];
        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:musiclisturl]];
        
        [request setValue:@"http://www.sostart.com/" forHTTPHeaderField:@"Referer"];
        [request setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
        [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        [request setTimeoutInterval: 60];
        [request setHTTPShouldHandleCookies:FALSE];
        [request setHTTPMethod:@"GET"];
        
        aSynConnection = [aSynConnection initWithRequest:request delegate:self];
        buf = [buf initWithLength:0];
    } else {
        [musics removeObjectAtIndex:0];
        
        if ([musics count] == 0)
        {
            [self getmusiclist];
        } else {
            [self playmusic];
        }
        
    }
    
}

- (void)playmusic {
    NSDictionary* music = (NSDictionary *)[musics objectAtIndex:0];
    NSURL* coverurl =[[NSURL alloc] initWithString:[music objectForKey:@"cover"]];
    NSImage* coverimg = [[NSImage alloc] initWithContentsOfURL:coverurl];
    [self.cover setImage:coverimg];
    [self.title setStringValue:[music objectForKey:@"title"]];
    [self.artist setStringValue:[music objectForKey:@"artist"]];
    [self createStreamer:[music objectForKey:@"source"]];
    [streamer start];
}

- (IBAction)play:(NSButton *)sender {
    if ([streamer isPlaying])
    {
        [streamer pause];
    } else {
        [streamer start];
    }
}

- (IBAction)next:(NSButton *)sender {
    [self getmusiclist];
}

- (IBAction)help:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.sostart.com/"]];
}

#pragma mark- AudioStreamer
- (void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([streamer isWaiting])
	{
		//NSLog(@"waiting");
	}
	else if ([streamer isPlaying])
	{
		[self.playbtn setImage:stopimg];
        [self.playbtn setAlternateImage:stophighimg];
	}
    else if ([streamer isPaused])
    {
        [self.playbtn setImage:playimg];
        [self.playbtn setAlternateImage:playhighimg];
    }
	else if ([streamer isIdle])
	{
        NSLog(@"stoping");
        [self.playbtn setImage:playimg];
        [self.playbtn setAlternateImage:playhighimg];
        
        [self.progressbar setDoubleValue:0.0];
        [self.title setStringValue:@""];
        [self.artist setStringValue:@""];
        [self.playtime setStringValue:@"00:00"];
		[self getmusiclist];
	}
}

- (void)updateProgress:(NSTimer *)updatedTimer
{
	if (streamer.bitRate != 0.0)
	{
		double progress = streamer.progress;
		double duration = streamer.duration;

		if (duration > 0)
		{
            NSString* playtime = [[NSString alloc] initWithFormat:@"%02d:%02d", (int)progress / 60, (int)progress % 60];
            [self.playtime setStringValue:playtime];
            
            double st = progress / duration * 100;
            [self.progressbar setDoubleValue:st];
		}
		else
		{
		}
	}
	else
	{
	}
}

- (void)createStreamer:(NSString *) musicpath
{
	if (streamer)
	{
		return;
	}
    
	[self destroyStreamer];
    
	NSURL *url = [NSURL URLWithString:musicpath];
	streamer = [[AudioStreamer alloc] initWithURL:url];
    
	progressUpdateTimer =
    [NSTimer
     scheduledTimerWithTimeInterval:0.1
     target:self
     selector:@selector(updateProgress:)
     userInfo:nil
     repeats:YES];
	
	[[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(playbackStateChanged:)
     name:ASStatusChangedNotification object:streamer];
}

- (void)destroyStreamer
{
	if (streamer)
	{
		[[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:ASStatusChangedNotification
         object:streamer];
		
		[streamer stop];
		streamer = nil;
	}
}

#pragma mark- NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse {
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)aResponse;
    if ([httpResponse statusCode] != 200) {
        isok = FALSE;
    } else {
        isok = TRUE;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (isok) {
        [buf appendData:data];
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"请求失败！");
    isok = FALSE;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"获取成功！");
    if(isok && [connection isEqual: aSynConnection])
    {
        NSError* e = nil;
        musics = [(NSArray *)[NSJSONSerialization JSONObjectWithData:buf options:NSJSONReadingMutableContainers error:&e] mutableCopy];
        [self playmusic];
        
        isok = FALSE;
    }
}

@end
