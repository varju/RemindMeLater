#import "RMLSnoozer.h"
#include "RMLDebug.h"

#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>

#define WAKE_TIME 8

#pragma mark Fake interfaces to deal with private APIs

@interface NSURL (private)
-(BOOL)checkResourceIsReachableAndReturnError:(NSError **)error;
@end

#pragma mark Implementation

@implementation RMLSnoozer

@synthesize minutes = _minutes;
@synthesize pendingEvent = _pendingEvent;
@synthesize delegate = _delegate;
@synthesize snoozeTimer = _snoozeTimer;

static AVAudioPlayer *audioPlayer = nil;

#pragma mark Object lifecycle

-(id)initWithTime:(int)minutes delegate:(id <RMLSnoozerDelegate>)delegate {
  if ((self = [super init])) {
    self.minutes = minutes;
    self.delegate = delegate;
  }
  return self;
}

-(void)dealloc {
  [_delegate release];
  [_snoozeTimer release];
  [super dealloc];
}

#pragma mark Helpers to keep phone awake while snoozing

-(void)setupAudioPlayer {
#if DEBUG_LOG
  NSLog(@"RMLSnoozer.setupAudioPlayer: in");
#endif
  
  if (nil != audioPlayer) {
    return;
  }
  
#if DEBUG_LOG
  NSLog(@"RMLSnoozer.setupAudioPlayer: configuring audioPlayer");
#endif
  
  // Allow audio mixing - seems to be required on iOS 4.1
  NSError *setCategoryError = nil;
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&setCategoryError];
#if DEBUG_LOG
  if (setCategoryError) {
    NSLog(@"RMLSnoozer.setupAudioPlayer: setCategory failed with %@", setCategoryError);
  }
#endif
  
#if TARGET_IPHONE_SIMULATOR
  NSString *soundFile = [[NSBundle mainBundle] pathForResource:@"silence" ofType:@"wav"];
#else
  NSString *soundFile = @"/Library/RemindMeLater/silence.wav";
#endif
  
  NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:soundFile];
  if ([fileUrl respondsToSelector:@selector(checkResourceIsReachableAndReturnError:)] && [fileUrl checkResourceIsReachableAndReturnError:nil] == NO) {
    NSLog(@"RMLSnoozer.setupAudioPlayer: fileUrl %@ is not reachable", fileUrl);
  }
  
  audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:nil];
#if DEBUG_LOG
  NSLog(@"RMLSnoozer.setupAudioPlayer: fileUrl is %@", fileUrl);
#endif
  [fileUrl release];
  if ([audioPlayer prepareToPlay] == NO) {
#if DEBUG_LOG
    NSLog(@"RMLSnoozer.setupAudioPlayer: prepareToPlay failed");
#endif
  }
  audioPlayer.volume = 0;
#if DEBUG_LOG
  NSLog(@"RMLSnoozer.setupAudioPlayer: audioPlayer is %@", audioPlayer);
#endif
}

-(BOOL)audioIsPlaying {
  UInt32 propertySize = sizeof(UInt32);
  UInt32 audioIsAlreadyPlaying = 0;
  AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &propertySize, &audioIsAlreadyPlaying);
#if DEBUG_LOG
  NSLog(@"RMLSnoozer.audioIsPlaying: audioIsAlreadyPlaying=%d", audioIsAlreadyPlaying);
#endif
  
  return 0 != audioIsAlreadyPlaying;
}

-(void)keepPhoneAwake {
#if DEBUG_LOG
  NSLog(@"RMLSnoozer.keepPhoneAwake: waking up every %d seconds to keep phone from shutting down", WAKE_TIME);
#endif
  
  [self setupAudioPlayer];
  [NSTimer scheduledTimerWithTimeInterval:WAKE_TIME target:self selector:@selector(keepPhoneAwakeTimerCallback:) userInfo:nil repeats:false];
}

-(void)keepPhoneAwakeTimerCallback:(NSTimer *)timer {
#if DEBUG_LOG
  NSLog(@"RMLSnoozer.keepPhoneAwakeCallback: in, pendingEvents is %d", self.pendingEvent);
#endif
  
  if (!self.pendingEvent) {
    return;
  }
  
  if ([self audioIsPlaying]) {
#if DEBUG_LOG
    NSLog(@"RMLSnoozer.keepPhoneAwakeCallback: Audio is playing right now, not doing anything.");
#endif
  } else {
#if DEBUG_LOG
    NSLog(@"RMLSnoozer.keepPhoneAwakeCallback: No audio playing right now, sending a blip to keep the phone awake.");
#endif
    [audioPlayer play];
  }
  
  [self keepPhoneAwake];
}

#pragma mark Core snooze interface

-(void)snoozeTimerCallback:(NSTimer *)timer {
  self.pendingEvent = FALSE;
  self.snoozeTimer = NULL;
  id payload = [timer userInfo];

#if DEBUG_LOG
  NSLog(@"RMLSnoozer.snoozeTimerCallback: timer's payload is %@", payload);
#endif
  
  [_delegate snoozeCallback:payload];
}

-(void)snooze:(id)payload {
  self.pendingEvent = TRUE;
  
  // First schedule our real action
  int sleepSeconds = _minutes * 60;

#if DEBUG_SLEEP_SECONDS || TARGET_IPHONE_SIMULATOR
    // User originally picked snooze time in minutes; change units to seconds instead
    sleepSeconds /= 60;
#endif

#if DEBUG_LOG
  NSLog(@"RMLSnoozer.snooze: Sleeping for %d seconds", sleepSeconds);
#endif
  
  self.snoozeTimer = [NSTimer scheduledTimerWithTimeInterval:sleepSeconds target:self 
                                                    selector:@selector(snoozeTimerCallback:) 
                                                    userInfo:payload
                                                     repeats:false];

  // Now schedule something to keep the phone awake
  [self keepPhoneAwake];
}

-(void)invalidate {
#if DEBUG_LOG
  NSLog(@"RMLSnoozer.invalidate: Aborting timer");
#endif

  [self.snoozeTimer invalidate];
  self.pendingEvent = FALSE;
  self.snoozeTimer = NULL;
}

@end
