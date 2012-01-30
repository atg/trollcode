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
}

@property (assign) IBOutlet NSWindow *window;

- (void)becameResponsive:(BOOL)paused;
- (pid_t)pid;

@end
