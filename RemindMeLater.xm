#import <substrate.h>
#import <SpringBoard/SpringBoard.h>
#import <AudioToolbox/AudioToolbox.h>

#import "RMLController.h"
#import "RMLAlertView.h"
#import "RMLSnoozer.h"
#include "RMLDebug.h"

static Class $SBCalendarAlertItem = objc_getClass("SBCalendarAlertItem");
static Class $SBAlertItemsController = objc_getClass("SBAlertItemsController");
static Class $SBAwayController = objc_getClass("SBAwayController");
static Class $SBCalendarController = objc_getClass("SBCalendarController");

static RMLController *controller;

@interface SBCalendarAlertItem (hidden)
-(id)initWithDate:(double)arg1 title:(id)arg2 location:(id)arg3 eventId:(int)arg4 isAllDay:(BOOL)arg5;
-(id)initWithDate:(double)arg1 timeZone:(id)arg2 title:(id)arg3 location:(id)arg4 eventId:(int)arg5 isAllDay:(BOOL)arg6;
@end


@interface PhoneJailbreakImpl : NSObject <RMLJailbreakFacade>
@end
@implementation PhoneJailbreakImpl

-(void)showAlert:(id)alert {
	SBCalendarAlertItem *alertItem = (SBCalendarAlertItem *)alert;
	SBAlertItemsController *ctrl = [$SBAlertItemsController sharedInstance];
	[ctrl activateAlertItem:alertItem];
	[controller playSound:YES];
}

-(BOOL)isAlertShowing:(id)alert {
	SBAlertItemsController *ctrl = [$SBAlertItemsController sharedInstance];
	id visibleItem = [ctrl visibleAlertItem];
#if DEBUG_LOG
	NSLog(@"PhoneJailbreakImpl.isAlertShowing: visibleItem is %@, alert is %@", visibleItem, alert);
#endif
	return visibleItem == alert;
}

-(void)wakeup {
	SBAwayController *ctrl = [$SBAwayController sharedAwayController];
	[ctrl undimScreen];
	[ctrl restartDimTimer:20.0];
}

-(void)playSound:(BOOL)isRepeat {
	SBCalendarController *ctrl = [$SBCalendarController sharedInstance];
	[ctrl playAlertSound];
}
@end


%group RML4
%hook SBCalendarAlertItem
- (void)configure:(BOOL)configure requirePasscodeForActions:(BOOL)passcode {
	%orig;
  [controller configureAlertItem:self];
}
%end
%end


%ctor {
	%init;

	PhoneJailbreakImpl *jailbreakFacade = [[[PhoneJailbreakImpl alloc] init] autorelease];
	controller = [[RMLController alloc] initWithJailbreakFacade:jailbreakFacade];

#if DEBUG_LOG
	NSLog(@"RemindMeLater: initializing, enabled=%d", [controller isEnabled]);
#endif

	if ([controller isVersion5]) {
		NSLog(@"RemindMeLater: iOS5 detected, not hooking");
	} else {
#if DEBUG_LOG
		NSLog(@"RemindMeLater: iOS5 not detected, hooking");
#endif
		%init(RML4);
	}
}
