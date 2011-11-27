#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "RMLController.h"
#import "RMLFrameworkHeaders.h"
#import "obslider/OBSlider/OBSlider.h"

#pragma mark Forward imports

@class RMLController;

#pragma mark My Interface

@interface RMLAlertView : UIAlertView {
  UIAlertView *_alertView;
  RMLController *_controller;
  id <NSObject> _payload;
  int _frameOffset;
  OBSlider *_minutesSlider;
  UILabel *_minutesLabel;
  int _nagCountdown;
  RMLSnoozer *_nagSnoozer;
}

@property (nonatomic, retain) UIAlertView *alertView;
@property (retain) RMLController *controller;
@property (nonatomic, retain) id /*NSObject*/ payload;
@property (nonatomic, retain) UISlider *minutesSlider;
@property (nonatomic, retain) UILabel *minutesLabel;
@property (nonatomic) int nagCountdown;
@property (nonatomic, retain) RMLSnoozer *nagSnoozer;

-(id)initWithAlertView:(UIAlertView *)view controller:(RMLController *)controller payload:(id <NSObject>)payload;
-(void)alertNag;

@end
