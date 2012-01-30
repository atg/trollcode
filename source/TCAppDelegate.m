
// Thanks, wolf!
// http://github.com/rentzsch/ForceQuitUnresponsiveApps



#import "TCAppDelegate.h"
#import <dispatch/source.h>
#import <QuartzCore/QuartzCore.h>

// Also
//   bool CGSEventIsAppUnresponsive(CGSConnectionID cid, const ProcessSerialNumber *psn);
//   CGError CGSEventSetAppIsUnresponsiveNotificationTimeout(CGSConnectionID cid, double theTime);

#define sanity_check() assert(kCGSNotificationAppUnresponsive == type || kCGSNotificationAppResponsive == type); assert(data); assert(dataLength >= sizeof(CGSProcessNotificationData))


static NSRunningApplication* TCCheckIsXcode(void *data) {
    CGSProcessNotificationData *noteData = (CGSProcessNotificationData*)data;
    NSRunningApplication *unresponsiveProcess = [NSRunningApplication runningApplicationWithProcessIdentifier:noteData->pid];
    
    if ([unresponsiveProcess.bundleIdentifier isEqual:XCODE_IDENTIFIER])
        return unresponsiveProcess;
    
    return nil;
}

void TCNotifyHandler_Unresponsive(CGSNotificationType type, void *data, unsigned int dataLength, void *userData) {
    sanity_check();
    
    NSRunningApplication* xcode = TCCheckIsXcode(data);
    if (!xcode)
        return;
    NSLog(@"NOTIFY Unresponsive");
    [[NSApp delegate] becameResponsive:NO];
}
void TCNotifyHandler_Responsive(CGSNotificationType type, void *data, unsigned int dataLength, void *userData) {
    sanity_check();
    
    NSRunningApplication* xcode = TCCheckIsXcode(data);
    if (!xcode)
        return;
    
    NSLog(@"NOTIFY Responsive");
    TCTroll(NO);
    [[NSApp delegate] becameResponsive:YES];
}

// Display or hide a spinning troll face
void TCTroll(BOOL show) {
    
    static NSWindow* trollWindow;
    static CALayer* trollLayer;
    static CABasicAnimation* animation;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSRect contentRect = [[NSScreen mainScreen] visibleFrame];
        trollWindow = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
        
        animation = [CABasicAnimation animationWithKeyPath:@"transform"];
        animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI, 0.0, 0.0, 1.0)];
        animation.cumulative = YES;
        animation.repeatCount = 10.0e6;
        animation.duration = 2.0;
        
        [trollWindow setBackgroundColor:[NSColor clearColor]];
        [trollWindow orderOut:nil];
        [[trollWindow contentView] setWantsLayer:YES];
        CALayer* backingLayer = [[CALayer alloc] init]; // [[trollWindow contentView] makeBackingLayer]
        backingLayer.frame = NSRectToCGRect([[trollWindow contentView] bounds]);
        [[trollWindow contentView] setLayer:backingLayer];
        
        NSImage* happySmilingMan = [NSImage imageNamed:@"happy-smiling-man"];
        trollLayer = [[CALayer alloc] init];
        [trollLayer setContents:happySmilingMan];
        [trollLayer setFrame:[backingLayer bounds]];
        trollLayer.contentsGravity = @"resizeAspect";
        
        [backingLayer addSublayer:trollLayer];
    });
    
    if (show) {
        if (![trollWindow isVisible]) {
            [trollLayer addAnimation:animation forKey:@"trolololol"];
            [trollWindow orderFront:nil];
        }
    }
    else {
        NSLog(@"UNTROLL");
        [trollLayer removeAllAnimations];
        [trollWindow orderOut:nil];
    }
}

@implementation TCAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	CGError err = CGSRegisterNotifyProc(TCNotifyHandler_Unresponsive, kCGSNotificationAppUnresponsive, NULL)
                  || CGSRegisterNotifyProc(TCNotifyHandler_Responsive, kCGSNotificationAppResponsive, NULL);
    
    if (err) {
        CGSGlobalError(err, "");
        [NSApp terminate:nil];
    }
}

- (void)becameResponsive:(BOOL)paused {
    
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    if (paused) {
        [self processTime];
        startTime = 0;
        return;
    }
    
    startTime = [NSDate timeIntervalSinceReferenceDate];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fired:) userInfo:nil repeats:YES];
}
- (NSTimeInterval)adjustedTime {
    NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate] - startTime;
    if (t < 0.0)
        t = 0.0;
    return t;
}
- (void)processTime {
    NSTimeInterval t = [self adjustedTime];
    
    // Log in a file somewhere
}
- (pid_t)pid {
    return [[[NSRunningApplication runningApplicationsWithBundleIdentifier:XCODE_IDENTIFIER] lastObject] processIdentifier];
}
- (void)fired:(id)unused {
    
    // Is Xcode responsive?
    
    pid_t xcodePid = [self pid];
    NSLog(@"xcodePid = %d", xcodePid);
    if (xcodePid == 0)
        goto giveUp;
    
    CGSConnectionID conn = CGSMainConnectionID();
    ProcessSerialNumber psn;
    OSStatus status = GetProcessForPID(xcodePid, &psn);
    
    NSLog(@"status = %d", status);
    if (status != 0)
        goto giveUp;
    
    bool b = CGSEventIsAppUnresponsive(conn, &psn);
    NSLog(@"Responsive: %d : %lf", b, [self adjustedTime]);
    if (b) {
        // Still trollin'
        if ([self adjustedTime] > 0.5)
            TCTroll(YES);
    }
    else {
        TCTroll(NO);
        [self becameResponsive:YES];
    }

    return;
giveUp:
    NSLog(@"Could not get process status");
    
    TCTroll(NO);
    [self becameResponsive:YES];
}

@end
