//
// main.m
// ScreenTimeTest
//
// This is a demo app for the STWebpageController API to determine how it
// lets consumers know a webpage is blocked.
//
// Set a 1 minute limit for facebook.com in Screen Time settings. Then wait
// a minute after the app opens and observe that an observer event will be
// printed in console, saying that facebook.com is blocked. Click the "Switch
// site" button to "load" youtube.com. After a few seconds, observe that
// another event is fired saying that YouTube is not blocked.
//
// Created by Harry Twyford on 2021-11-19.
//

#import <Cocoa/Cocoa.h>
#include <ScreenTime/ScreenTime.h>

// Helper method to print the NSView hierarchy.
static void DumpViewHierarchy(NSView *aView, int32_t aDepth) {
  NSLog(@"%*s%@  frame: %@", aDepth * 4, "", aView,
        NSStringFromRect(aView.frame));
  for (NSView *sv in [aView subviews]) {
    DumpViewHierarchy(sv, aDepth + 1);
  }
}

@interface TerminateOnClose : NSObject <NSWindowDelegate>
@end

@implementation TerminateOnClose
- (void)windowWillClose:(NSNotification *)notification {
  [NSApp terminate:self];
}
@end

// Boilerplate NSView subclass to show in our app.
@interface TestView: NSView
{
}
@end

@implementation TestView

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (id)initWithFrame:(NSRect)aFrame {
  if (self = [super initWithFrame:aFrame]) {
  }
  return self;
}

- (void)awakeFromNib {
   self.wantsLayer = YES;  // NSView will create a CALayer automatically
}

- (BOOL)wantsUpdateLayer {
   return YES; // Tells NSView to call `updateLayer` instead of `drawRect:`
}

- (void)updateLayer {
   self.layer.backgroundColor = [NSColor colorWithCalibratedRed:0
                                                          green:0
                                                           blue:1
                                                          alpha:0.8].CGColor;
}
@end

// STObserver listens for URL-blocked events from STWebpageController.
@interface STObserver : NSObject
@end

@implementation STObserver {
    STWebpageController* _controller;
}
- (instancetype)initWithController:(STWebpageController*)stController {
    if (self = [super init]) {
        _controller = stController;
        NSLog(@"Adding observer");
        [_controller addObserver:self
                      forKeyPath:@"URLIsBlocked"
                         options:NSKeyValueObservingOptionNew
                         context:NULL];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id>*)change
                       context:(void*)context {
    NSLog(@"Change %@", change);
    NSLog(@"URL: %@, isBlocked: %@", _controller.URL, _controller.URLIsBlocked ? @"blocked" : @"unblocked");
    NSWindow *window = [NSApp mainWindow];
    DumpViewHierarchy([window contentView], 0);
}

// Simulates toggling loads of facebook.com and youtube.com.
- (void)switchSite {
    NSLog(@"Switching away from URL: %@", [_controller URL].absoluteString);
    if ([[_controller URL].absoluteString isEqualToString:@"https://www.facebook.com"]) {
        [_controller setURL:[NSURL URLWithString:@"https://www.youtube.com"]];
    } else {
        [_controller setURL:[NSURL URLWithString:@"https://www.facebook.com"]];
    }
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
    }
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    
    // Set up our window.
    NSRect contentRect = NSMakeRect(400, 300, 600, 400);
    int style =
      NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskFullSizeContentView;
    NSWindow* window = [[NSWindow alloc] initWithContentRect:contentRect
                                         styleMask:style
                                           backing:NSBackingStoreBuffered
                                             defer:NO];
    [window setDelegate:[TerminateOnClose alloc]];
    [NSApp activateIgnoringOtherApps:YES];
    [window makeKeyAndOrderFront:window];

    // Populate the window with a view.
    NSView* view = [[TestView alloc] init];
    [window setContentView:view];

    // Create our Screen Time controller and observer.
    STWebpageController* stController = [[STWebpageController alloc] init];
    STObserver* observer = [[STObserver alloc] initWithController:stController];
    
    // Add a button to the view that toggles facebook.com and youtube.com
    CGRect buttonFrame = CGRectMake(250, 320, 100, 40);
    NSButton *button = [[NSButton alloc] initWithFrame:buttonFrame];
    [button setTarget:observer];
    [button setAction:@selector(switchSite)];
    [button setTitle:@"Switch site"];
    [view addSubview:button];

    // Add Screen Time to view hierarchy.
    stController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    stController.preferredContentSize = window.frame.size;
    stController.preferredScreenOrigin = window.frame.origin;
    [view addSubview:[stController view]];

    // Set the initial "load" to Facebook.
    [stController setURL:[NSURL URLWithString:@"https://www.facebook.com"]];
    
    [NSApp run];

    return 0;
}
