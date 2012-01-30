//
//  TCAppDelegate.h
//  trollcode
//
//  Created by Alex Gordon on 29/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CGSNotifications.h"

static NSString* const XCODE_IDENTIFIER = @"com.apple.dt.Xcode";

void TCNotifyHandler_Unresponsive(CGSNotificationType type, void *data, unsigned int dataLength, void *userData);
void TCNotifyHandler_Responsive(CGSNotificationType type, void *data, unsigned int dataLength, void *userData);
void TCTroll(BOOL show);

@interface TCAppDelegate : NSObject <NSApplicationDelegate> {
    NSTimer* timer;
    NSTimeInterval startTime;
    
    NSMutableArray* newtimes;
    NSStatusItem* statusItem;
}

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSMenu *statusMenu;

- (void)becameResponsive:(BOOL)paused;
- (pid_t)pid;
- (NSTimeInterval)adjustedTime;
- (void)processTime;
- (NSString*)versionForRunningApp:(NSRunningApplication*)runningApp;
- (IBAction)showPreferences:(id)sender;

@end
