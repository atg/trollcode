//
//  TCAppDelegate.m
//  trollcode
//
//  Created by Alex Gordon on 29/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TCAppDelegate.h"

// Thanks wolf
#import "ForceQuitUnresponsiveAppsAppDelegate.h"
#import "CGSNotifications.h"

void MyNotifyProc(CGSNotificationType type, void *data, unsigned int dataLength, void *userData) {
    assert(kCGSNotificationAppUnresponsive == type);
    assert(data);
    assert(dataLength >= sizeof(CGSProcessNotificationData));
    
    CGSProcessNotificationData *noteData = (CGSProcessNotificationData*)data;
    
    NSRunningApplication *unresponsiveProcess = [NSRunningApplication runningApplicationWithProcessIdentifier:noteData->pid];
    
    NSLog(@"Force-Quitting Unresponsive Application: %@", unresponsiveProcess.localizedName);
    
    [unresponsiveProcess forceTerminate];
}

@implementation ForceQuitUnresponsiveAppsAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification*)notification_ {
	CGError err = CGSRegisterNotifyProc(MyNotifyProc,
                                        kCGSNotificationAppUnresponsive,
                                        NULL);
    if (err) {
        CGSGlobalError(err, "");
        [NSApp terminate:nil];
    }
}

@end


@implementation TCAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

@end
