
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

static CGRect CGRectShrink(CGRect r, CGFloat f) {
    CGRect r2 = r;
    r2.origin.x += (r.size.width - r.size.width * f) / 2.0;
    r2.origin.y += (r.size.height - r.size.height * f) / 2.0;
    r2.size.width *= f;
    r2.size.height *= f;
    return r2;
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
		[trollWindow setOpaque:NO];
		[trollWindow setHasShadow:YES];
        [trollWindow setLevel:NSFloatingWindowLevel];
        [trollWindow orderOut:nil];
        [trollWindow setIgnoresMouseEvents:YES];
        [[trollWindow contentView] setWantsLayer:YES];
        CALayer* backingLayer = [CALayer layer]; // [[trollWindow contentView] makeBackingLayer]
        backingLayer.frame = NSRectToCGRect([[trollWindow contentView] bounds]);
        [[trollWindow contentView] setLayer:backingLayer];
        
        NSImage* happySmilingMan = [NSImage imageNamed:@"happy-smiling-man"];
        trollLayer = [CALayer layer];
        [trollLayer setFrame:[backingLayer bounds]];
        [backingLayer addSublayer:trollLayer];
        
        NSSize s = [happySmilingMan size];
        CGFloat minComponent = MIN(s.width, s.height);
        CGFloat maxComponent = MAX(s.width, s.height);

        CALayer* sublayer = [CALayer layer];
        
        // The maths is totally broken here but whatever, it looks good
        sublayer.frame = CGRectShrink([trollLayer bounds], minComponent / (sqrt(2.0) * maxComponent));
        sublayer.contentsGravity = @"resizeAspect";
        sublayer.contents = happySmilingMan;
        [trollLayer addSublayer:sublayer];
    });
    
    if (show) {
        if (![trollWindow isVisible]) {
            NSNumber* shouldShowTroll = [[NSUserDefaults standardUserDefaults] valueForKey:@"TCShowTrollface"];
            if (shouldShowTroll && [shouldShowTroll boolValue] == NO)
                return;
            
            [trollLayer removeAllAnimations];
            [trollLayer addAnimation:animation forKey:@"trolololol"];
            [trollWindow orderFront:nil];
        }
    }
    else {
        [trollLayer removeAllAnimations];
        [trollWindow orderOut:nil];
    }
}

@implementation TCAppDelegate

@synthesize window = _window;
@synthesize statusMenu;

- (id)init {
    self = [super init];
    if (!self)
        return nil;
    
    newtimes = [[NSMutableArray alloc] init];
    return self;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	CGError err = CGSRegisterNotifyProc(TCNotifyHandler_Unresponsive, kCGSNotificationAppUnresponsive, NULL)
                  || CGSRegisterNotifyProc(TCNotifyHandler_Responsive, kCGSNotificationAppResponsive, NULL);
    
    if (err) {
        CGSGlobalError(err, "");
        [NSApp terminate:nil];
    }
    
    // Send times once every 20 minutes
//    [NSTimer scheduledTimerWithTimeInterval:20 * 60 target:self selector:@selector(sendTimes) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:20 * 60 target:self selector:@selector(sendTimes) userInfo:nil repeats:YES];
    
    NSMutableDictionary* registeredDefaults = [[NSMutableDictionary alloc] init];
    [registeredDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"TCShowTrollface"];
    [registeredDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"TCSendHangDurations"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:registeredDefaults];
}
- (void)awakeFromNib {
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:16];
    [statusItem setImage:[NSImage imageNamed:@"troll-small"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"troll-small-white"]];
    [statusItem setMenu:statusMenu];
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
    [newtimes addObject:[NSNumber numberWithDouble:t]];
}
- (void)sendTimes {
    
    // Don't send anything if there's no times
    if (![newtimes count])
        return;
    
    // Don't send anything if the user has opted out
    NSNumber* shouldSendTimes = [[NSUserDefaults standardUserDefaults] valueForKey:@"TCSendHangDurations"];
    if (shouldSendTimes && [shouldSendTimes boolValue] == NO)
        return;
    
    // Generate a string to send
    NSString* runningTimes = [[newtimes valueForKey:@"stringValue"] componentsJoinedByString:@"$"];
    [newtimes removeAllObjects];
    
    NSString* trollcodev = [self versionForRunningApp:[NSRunningApplication currentApplication]];
    NSString* xcodev = [self versionForRunningApp:[[NSRunningApplication runningApplicationsWithBundleIdentifier:XCODE_IDENTIFIER] lastObject]];
    NSString* submitURLString = [NSString stringWithFormat:@"http://chocolatapp.com/trollcode-server/submit.php?"
                                 @"trollcodev=%@&xcodev=%@&times=%@",
                                 trollcodev, xcodev, runningTimes];
    
    NSLog(@"Submit URL = %@", submitURLString);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSURL* submitURL = [NSURL URLWithString:submitURLString];
        NSString* result = nil;//[NSString stringWithContentsOfURL:submitURL encoding:NSUTF8StringEncoding error:NULL];
        NSLog(@"Our server said: %@", result);
    });
}

- (NSString*)versionForRunningApp:(NSRunningApplication*)runningApp {
    
    NSDictionary* info = [NSDictionary dictionaryWithContentsOfURL:[[runningApp bundleURL] URLByAppendingPathComponent:@"Contents/Info.plist"]];
    if (![info count])
        return nil;
    
    return [info objectForKey:@"CFBundleShortVersionString"];
}

- (IBAction)showPreferences:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
}

- (pid_t)pid {
    return [[[NSRunningApplication runningApplicationsWithBundleIdentifier:XCODE_IDENTIFIER] lastObject] processIdentifier];
}
- (void)fired:(id)unused {
    
    // Is Xcode responsive?
    
    pid_t xcodePid = [self pid];
    if (xcodePid == 0)
        goto giveUp;
    
    CGSConnectionID conn = CGSMainConnectionID();
    ProcessSerialNumber psn;
    OSStatus status = GetProcessForPID(xcodePid, &psn);
    
    if (status != 0)
        goto giveUp;
    
    bool b = CGSEventIsAppUnresponsive(conn, &psn);
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
