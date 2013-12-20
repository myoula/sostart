//
//  SSAppDelegate.h
//  sostart
//
//  Created by myoula on 13-12-18.
//  Copyright (c) 2013年 myoula. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SSAppDelegate : NSObject <NSApplicationDelegate, NSURLConnectionDelegate>

@property (assign) IBOutlet NSWindow *window;
- (IBAction)play:(NSButton *)sender;
- (IBAction)next:(NSButton *)sender;
- (IBAction)help:(NSButton *)sender;


@property (weak) IBOutlet NSButton *playbtn;
@property (weak) IBOutlet NSImageView *cover;
@property (weak) IBOutlet NSTextField *title;
@property (weak) IBOutlet NSTextField *artist;
@property (weak) IBOutlet NSTextField *playtime;
@property (weak) IBOutlet NSProgressIndicator *progressbar;

@end
