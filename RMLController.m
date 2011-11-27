//
//  RMLController.m
//
//  Created by Alex Varju on 2010-11-14.
//  Copyright 2010 Alex Varju. All rights reserved.
//

#import "RMLController.h"
#import "RMLAlertView.h"
#include "RMLDebug.h"

#include <execinfo.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#pragma mark Fake interfaces to deal with private APIs

@interface NSThread (private)
+(id)callStackSymbols;
@end

#pragma mark Private interface

@interface RMLController (private)
-(void)loadBundle;
-(void)loadPreferences;
@end

#pragma mark Implementation

@implementation RMLController

#pragma mark Properties

@synthesize isVersion4 = _isVersion4;
@synthesize isVersion43 = _isVersion43;
@synthesize isVersion5 = _isVersion5;
@synthesize isEnabled = _isEnabled;
@synthesize snoozeTime = _snoozeTime;
@synthesize keepNagging = _keepNagging;
@synthesize nagInterval = _nagInterval;
@synthesize nagLimit = _nagLimit;
@synthesize jailbreakFacade = _jailbreakFacade;
@synthesize resourceBundle = _resourceBundle;

#pragma mark Object lifecycle

-(id)initWithJailbreakFacade:(id <RMLJailbreakFacade>)facade {
  if ((self = [super init])) {
    self.jailbreakFacade = facade;
    [self loadBundle];
    [self loadPreferences];
  }
  return self;
}

-(void)dealloc {
  [_jailbreakFacade release];
  [_resourceBundle release];
  [super dealloc];
}

#pragma mark Localization

-(void)loadBundle {
#if TARGET_IPHONE_SIMULATOR
  NSString *path = [[NSBundle mainBundle] pathForResource:@"RemindMeLaterSettings" ofType:@"bundle"];
#else
  NSString *path = @"/System/Library/PreferenceBundles/RemindMeLaterSettings.bundle";
#endif
  _resourceBundle = [[NSBundle bundleWithPath:path] retain];

#if DEBUG_LOG
  NSLog(@"RMLController.loadBundle: bundle is %@", _resourceBundle);
#endif
}

#pragma mark Settings

// TODO - make use of the PostNotification hook to avoid constantly reloading these prefs
-(void)loadPreferences {
  _isVersion4 = (objc_getClass("UILocalNotification") != nil);
  _isVersion43 = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"4.3");
  _isVersion5 = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0");

  // Default values
  _isEnabled = YES;
  _snoozeTime = 5;
  _keepNagging = YES;
  _nagInterval = 5;
  _nagLimit = 3;

#if TARGET_IPHONE_SIMULATOR
  NSString *plist = [[NSBundle mainBundle] pathForResource:@"ca.varju.RemindMeLater" ofType:@"plist"];
#else
  NSString *plist = @"/User/Library/Preferences/ca.varju.RemindMeLater.plist";
#endif
  NSDictionary *settings = [[[NSDictionary alloc] initWithContentsOfFile:plist] autorelease];

  if (settings) {
    NSNumber* b;
    
    b = [settings objectForKey:@"SnoozeTime"];
    if (b) {
      _snoozeTime = [b intValue];
    }
    
    b = [settings objectForKey:@"KeepNagging"];
    if (b) {
      _keepNagging = [b boolValue];
    }
    
    b = [settings objectForKey:@"NagInterval"];
    if (b) {
      _nagInterval = [b intValue];
    }

    b = [settings objectForKey:@"NagLimit"];
    if (b) {
      _nagLimit = [b intValue];
    }
  }

#if DEBUG_LOG
  NSLog(@"RMLController.loadPreferences: out with enabled %d, snoozeTime %d, version4 %d, version43 %d, version5 %d, keepNagging %d, nagInterval %d",
        _isEnabled, _snoozeTime, _isVersion4, _isVersion43, _isVersion5, _keepNagging, _nagInterval);
#endif
}

#pragma mark RMLAlertView hooks

-(UIAlertView *)configureAlertView:(UIAlertView *)originalView payload:(id)payload {
  UIAlertView *view = [[RMLAlertView alloc] initWithAlertView:originalView controller:self payload:payload];
  
#if DEBUG_LOG
  NSLog(@"RMLController.configureAlertView: view is %@", view);
#endif
  
  return view;
}

-(void)configureAlertItem:(id<SBAlertItem>)alertItem {
  if (!_isEnabled) {
    return;
  }
  
#if DEBUG_LOG
  [self logCalendarAlertItem:alertItem msg:@"RMLController.configureAlertItem"];
#endif

  UIAlertView *view = alertItem.alertSheet;
#if DEBUG_LOG
  NSLog(@"RMLController.configureAlertItem: alertview delegate is %@", view.delegate);
#endif

  UIView *replacementView = [self configureAlertView:view payload:alertItem];
  [alertItem setValue:replacementView forKey:@"_alertSheet"];
}

-(void)playSound:(BOOL)onlyOn43 {
#if DEBUG_LOG
  NSLog(@"RMLController.playSound: in with onlyOn43=%d", onlyOn43);
#endif

  if (onlyOn43 && ![self isVersion43]) {
#if DEBUG_LOG
    NSLog(@"RMLController.playSound: not forcing sound to repeat");
#endif
    return;
  }

  [self.jailbreakFacade playSound:!onlyOn43];
}

#pragma mark Debug hooks

-(void)logCalendarAlertItem:(id)item msg:(NSString *)msg {
  double date = [[item valueForKey:@"date"] doubleValue];
  NSLog(@"%@: - date: %f", msg, date);

  NSString* title = [item valueForKey:@"title"];
  NSLog(@"%@: - title: %@", msg, title);

  NSString* location = [item valueForKey:@"location"];
  NSLog(@"%@: - location: %@", msg, location);

  if ([self isVersion4]) {
    NSString* zone = [item valueForKey:@"timeZone"];
    NSLog(@"%@: - zone: %@", msg, zone);
  }
  
  int eventId = [[item valueForKey:@"eventId"] intValue];
  NSLog(@"%@: - eventId: %d", msg, eventId);

  BOOL isAllDay = [[item valueForKey:@"isAllDay"] boolValue];
  NSLog(@"%@: - isAllDay: %s", msg, isAllDay ? "true" : "false");
}

-(void) logStack {
  if ([[NSThread class] respondsToSelector:@selector(callStackSymbols)]) {
    NSLog(@"%@", [NSThread callStackSymbols]);
  } else {
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char** strs = backtrace_symbols(callstack, frames);
    int i;
    for (i = 0; i < frames; ++i) {
      NSLog(@"%s", strs[i]);
    }
    free(strs);
  }
}

@end
