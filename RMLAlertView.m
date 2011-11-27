#import "RMLAlertView.h"
#import "RMLFrameworkHeaders.h"
#include "RMLDebug.h"

#import "UIKit/UILongPressGestureRecognizer.h"

#define VERTICAL_GAP 10
#define HORIZONTAL_GAP 0

#pragma mark Private interface

@interface RMLAlertView (private)
-(void)startNagTimer;
-(void)alertNag;
-(void)startSnoozing:(int)snoozeTimeMinutes payload:(id)payload;
@end

#pragma mark Button snoozer

@interface ButtonSnoozeDelegate : NSObject <RMLSnoozerDelegate> {
  RMLAlertView *_parent;
}
@end
@implementation ButtonSnoozeDelegate
-(id)initWithParent:(RMLAlertView *)parent {
  if ((self = [super init])) {
    _parent = parent;
    [_parent retain];
  }
  return self;
}
-(void)dealloc {
  [_parent release];
  [super dealloc];
}
-(void)snoozeCallback:(id)payload {
#if DEBUG_LOG
  NSLog(@"ButtonSnoozeDelegate.snoozeCallback: in with %@", payload);
#endif

  [_parent.controller.jailbreakFacade showAlert:payload];
}
@end

#pragma mark Nag snoozer

@interface NagSnoozeDelegate : NSObject <RMLSnoozerDelegate> {
  RMLAlertView *_parent;
}
@end
@implementation NagSnoozeDelegate
-(id)initWithParent:(RMLAlertView *)parent {
  if ((self = [super init])) {
    _parent = parent;
    [_parent retain];
  }
  return self;
}
-(void)dealloc {
  [_parent release];
  [super dealloc];
}
-(void)snoozeCallback:(id)payload {
#if DEBUG_LOG
  NSLog(@"NagSnoozeDelegate.snoozeCallback: in with %@", payload);
#endif

  if (![_parent.controller.jailbreakFacade isAlertShowing:_parent.payload]) {
#if DEBUG_LOG
    NSLog(@"NagSnoozeDelegate.snoozeCallback: alert is no longer showing, aborting");
#endif
    return;
  }

  [_parent.controller.jailbreakFacade wakeup];
  [payload alertNag];
  [payload startNagTimer];
}
@end

#pragma mark Implementation

@implementation RMLAlertView

@synthesize alertView = _alertView;
@synthesize controller = _controller;
@synthesize payload = _payload;
@synthesize minutesSlider = _minutesSlider;
@synthesize minutesLabel = _minutesLabel;
@synthesize nagCountdown = _nagCountdown;
@synthesize nagSnoozer = _nagSnoozer;

#pragma mark Helpers

-(BOOL)showViewEventButton {
  return [[_alertView buttons] count] > 0;
}

#pragma mark Object lifecycle

-(id)initWithAlertView:(UIAlertView *)view controller:(RMLController *)controller payload:(id <NSObject>)payload {
  
  NSString *closeStr = [controller.resourceBundle localizedStringForKey:@"CLOSE" value:@"Close" table:nil];
  NSString *viewStr = [controller.resourceBundle localizedStringForKey:@"VIEW_EVENT" value:@"View Event" table:nil];
  NSString *snoozeStr = [controller.resourceBundle localizedStringForKey:@"SNOOZE" value:@"Snooze" table:nil];
  
  if ((self = [super initWithTitle:view.title message:view.message delegate:view.delegate
                 cancelButtonTitle:closeStr otherButtonTitles:nil]))
  {
    self.controller = controller;
    self.payload = payload;
    self.alertView = view;
    
    if ([self showViewEventButton]) {
      [self addButtonWithTitle:viewStr];
    }
    int snoozeIndex = [self addButtonWithTitle:snoozeStr];
    
    NSArray *buttons = [self buttons];
    UIControl *snoozeButton = [buttons objectAtIndex:snoozeIndex];
#if DEBUG_LOG
    NSLog(@"RMLAlertView.initWithAlertView: snoozeButton is %@", snoozeButton);
#endif
    UILongPressGestureRecognizer *longPressGesture = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(snoozeLongPress:)] autorelease];
    [snoozeButton addGestureRecognizer:longPressGesture];
    
    // Note that starting this here leads to slightly weird behaviour during debugging because the timer alerts play before the official alert sometimes.
    // This is not a big deal, and can be ignored.
    self.nagCountdown = controller.nagLimit;
    [self startNagTimer];
    
    _frameOffset = 0;
  }

#if DEBUG_LOG
  NSLog(@"RMLAlertView.init: created %@, %@", view.title, self);
#endif
  
  return self;
}

-(void)dealloc {
#if DEBUG_LOG
  NSLog(@"RMLAlertView.dealloc: in");
#endif

  [self.nagSnoozer release];
  [self.alertView release];
  [self.controller release];
  [self.payload release];
  [self.minutesSlider release];
  [self.minutesLabel release];

  [super dealloc];
}

#pragma mark Snooze button handling

-(CGFloat)getMinX:(NSArray *)buttons {
  CGFloat min = CGFLOAT_MAX;
  for (id item in buttons) {
    UIView *button = (UIView *)item;
    CGFloat x = button.frame.origin.x;
    if (x < min) {
      min = x;
    }
  }
  return min;
}

-(CGFloat)getMaxX:(NSArray *)buttons {
  CGFloat max = CGFLOAT_MIN;
  for (id item in buttons) {
    UIView *button = item;
    CGFloat x = button.frame.origin.x + button.frame.size.width;
    if (x > max) {
      max = x;
    }
  }
  return max;
}

-(CGFloat)getMaxY:(NSArray *)buttons {
  CGFloat max = CGFLOAT_MIN;
  for (id item in buttons) {
    UIView *button = item;
    CGFloat x = button.frame.origin.y + button.frame.size.height;
    if (x > max) {
      max = x;
    }
  }
  return max;
}

-(CGFloat)getHeight:(NSArray *)buttons {
  UIView *button = [buttons objectAtIndex:0];
  return button.frame.size.height;
}


-(void)snoozeLongPress:(UILongPressGestureRecognizer *)gesture {
#if DEBUG_LOG
  NSLog(@"RMLAlertView.snoozeLongPress: in with %@", gesture);
#endif
  
  UIView *button = gesture.view;
  UIView *popup = button.superview;
  
#if DEBUG_LOG
  NSLog(@"RMLAlertView.snoozeLongPress: button is %@", button);
#endif
  
  if (!_frameOffset) {
    NSArray *buttons = [super buttons];
    
    int snoozeIndex = [self showViewEventButton] ? 2 : 1;
    UIView *snoozeButton = [buttons objectAtIndex:snoozeIndex];
    
    CGFloat leftX = [self getMinX:buttons];
    CGFloat height = [self getHeight:buttons];
    CGFloat rightX = [self getMaxX:buttons];
    
    CGFloat yPos = snoozeButton.frame.origin.y + snoozeButton.frame.size.height + VERTICAL_GAP;
    CGFloat labelWidth = (rightX - leftX) / 3;
    CGFloat sliderWidth = rightX - leftX - HORIZONTAL_GAP - labelWidth;
    
    CGRect sliderFrame = CGRectMake(leftX, yPos, sliderWidth, height);
    OBSlider *slider = [[OBSlider alloc] initWithFrame:sliderFrame];
    slider.continuous = NO;
    slider.minimumValue = 1;
    slider.maximumValue = 60;
    slider.value = self.controller.snoozeTime;
    [slider addTarget:self action:@selector(sliderUpdated) forControlEvents:UIControlEventValueChanged|UIControlEventTouchDragInside];
    [popup addSubview:slider];
    self.minutesSlider = slider;
    
    CGRect labelFrame = CGRectMake(leftX + sliderWidth + HORIZONTAL_GAP, yPos, labelWidth, height);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.textAlignment = UITextAlignmentRight;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    [popup addSubview:label];
    self.minutesLabel = label;
    
    _frameOffset = height + VERTICAL_GAP;
    [self _layoutIfNeeded];
    
    // Don't respond to this gesture if pressed twice
    [button removeGestureRecognizer:gesture];
  }
}

-(void)snoozeTimePress:(UIButton *)button {
#if DEBUG_LOG
  NSLog(@"RMLAlertView.snoozeTimePress: in with %@", button);
#endif
  
  int snoozeTimeMinutes = [button.currentTitle intValue];
#if DEBUG_LOG
  NSLog(@"RMLAlertView.snoozeTimePress: snoozeTime is %d", snoozeTimeMinutes);
#endif
  
  [self startSnoozing:snoozeTimeMinutes payload:self.payload];
  
  NSArray *buttons = [super buttons];
  UIView *closeButton = [buttons objectAtIndex:self.cancelButtonIndex];
  [self _buttonClicked:closeButton];
}

-(void)updateLabelText {
  int minutes = self.minutesSlider.value;
  NSString *minutesStr = [self.controller.resourceBundle localizedStringForKey:@"SNOOZE_TIME" value:@"%d minutes" table:nil];
  self.minutesLabel.text = [NSString stringWithFormat:minutesStr, minutes];
}

-(void)sliderUpdated {
  [self updateLabelText];
}

-(void)_buttonClicked:(id)clicked {
#if DEBUG_LOG
  NSLog(@"RMLAlertView._buttonClicked: in for %@", clicked);
#endif
  
  NSArray *buttons = [super buttons];
  UIView *snoozeButton = [buttons objectAtIndex:[buttons count] - 1];
  if (clicked == snoozeButton) {
    int snoozeTimeMinutes = -1;
    if (nil != self.minutesSlider) {
      snoozeTimeMinutes = self.minutesSlider.value;
    }
 
    [self startSnoozing:snoozeTimeMinutes payload:self.payload];
    clicked = [buttons objectAtIndex:0];
  }

  [self.nagSnoozer invalidate];

  [super _buttonClicked:clicked];
}

-(void)startSnoozing:(int)snoozeTimeMinutes payload:(id)payload {
#if DEBUG_LOG
  NSLog(@"RMLController.startSnoozing: in with payload %@, snoozeTime %d", payload, snoozeTimeMinutes);
#endif
  
  if (-1 == snoozeTimeMinutes) {
    snoozeTimeMinutes = self.controller.snoozeTime;
  }

  ButtonSnoozeDelegate *snoozeDelegate = [[[ButtonSnoozeDelegate alloc] initWithParent:self] autorelease];
  RMLSnoozer *snoozer = [[[RMLSnoozer alloc] initWithTime:snoozeTimeMinutes delegate:snoozeDelegate] autorelease];
  [snoozer snooze:payload];
}

#pragma mark UIAlertView overrides

-(void)_layoutIfNeeded {
  [super _layoutIfNeeded];
  
  if (_frameOffset != 0) {
    NSArray *buttons = [super buttons];
    int sleepIndex = [self showViewEventButton] ? 2 : 1;
    UIView *sleepButton = [buttons objectAtIndex:sleepIndex];
    
    // Fix position of slider and label
    CGRect sliderFrame = self.minutesSlider.frame;
    sliderFrame.origin.y = sleepButton.frame.origin.y + sleepButton.frame.size.height + VERTICAL_GAP;
    self.minutesSlider.frame = sliderFrame;
    
    CGRect labelFrame = self.minutesLabel.frame;
    labelFrame.origin.y = sliderFrame.origin.y;
    self.minutesLabel.frame = labelFrame;
    
    if ([self showViewEventButton]) {
      // Move the close button down
      UIView *button0 = [buttons objectAtIndex:0];
      CGRect b0frame = button0.frame;
      b0frame.origin.y += b0frame.size.height;
      button0.frame = b0frame;
    }
    
    // Fix dialog's height and re-centre it
    CGRect popupFrame = self.frame;
    popupFrame.size.height += _frameOffset;
    popupFrame.origin.y -= _frameOffset / 2;
    self.frame = popupFrame;
    
    [self updateLabelText];
  }

#if DEBUG_LOG
  NSLog(@"RMLAlertView._layoutIfNeeded: my frame height is now %f", self.frame.size.height);
#endif

}

-(void)layout {
  [super layout];
  if (_frameOffset) {
    [self _layoutIfNeeded];
  }
}

#pragma mark Alert nagging

-(void)startNagTimer {
#if DEBUG_LOG
  NSLog(@"RMLAlertView.startNagTimer: in");
#endif
  
  if (!self.controller.keepNagging || self.nagCountdown-- == 0) {
#if DEBUG_LOG
    NSLog(@"RMLAlertView.startNagTimer: will not nag anymore");
#endif
    return;
  }

  NagSnoozeDelegate *snoozeDelegate = [[[NagSnoozeDelegate alloc] initWithParent:self] autorelease];
  self.nagSnoozer = [[[RMLSnoozer alloc] initWithTime:self.controller.nagInterval delegate:snoozeDelegate] autorelease];
  [self.nagSnoozer snooze:self];
}

-(void)alertNag {
  [self.controller playSound:NO];
}

@end
