//
//  RMLController.h
//
//  Created by Alex Varju on 2010-11-14.
//  Copyright 2010 Alex Varju. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RMLSnoozer.h"
#import <UIKit/UIKit.h>

@protocol RMLJailbreakFacade <NSObject>
-(void)showAlert:(id)alert;
-(BOOL)isAlertShowing:(id)alert;
-(void)wakeup;
-(void)playSound:(BOOL)isRepeat;
@end

@interface RMLController : NSObject {
  BOOL _isVersion4;
  BOOL _isVersion43;
  BOOL _isEnabled;
  int _snoozeTime;
  BOOL _keepNagging;
  int _nagInterval;
  int _nagLimit;
  id <RMLJailbreakFacade> _jailbreakFacade;
  NSBundle *_resourceBundle;
}

@property (assign, readonly) BOOL isVersion4;
@property (assign, readonly) BOOL isVersion43;
@property (assign, readonly) BOOL isEnabled;
@property (assign, readonly) int snoozeTime;
@property (assign, readonly) BOOL keepNagging;
@property (assign, readonly) int nagInterval;
@property (assign, readonly) int nagLimit;
@property (nonatomic, retain) id /*RMLJailbreakFacade*/ jailbreakFacade;
@property (nonatomic, retain) NSBundle *resourceBundle;

-(id)initWithJailbreakFacade:(id <RMLJailbreakFacade>)facade;

-(void)configureAlertItem:(id)item;
-(UIAlertView *)configureAlertView:(UIAlertView *)alertView payload:(id)payload;

-(void)playSound:(BOOL)onlyOn43;

-(void)logCalendarAlertItem:(id)item msg:(NSString *)msg;
-(void)logStack;

@end
