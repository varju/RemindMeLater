
#pragma mark Fake interfaces to deal with private APIs

#if TARGET_IPHONE_SIMULATOR
@interface UIModalView : UIView <UITextFieldDelegate>
@end

@protocol UIModalViewDelegate <NSObject>
@optional
-(void)modalView:(id)view clickedButtonAtIndex:(int)index;
-(void)modalViewCancel:(id)cancel;
-(void)willPresentModalView:(id)view;
-(void)didPresentModalView:(id)view;
-(void)modalView:(id)view willDismissWithButtonIndex:(int)buttonIndex;
-(void)modalView:(id)view didDismissWithButtonIndex:(int)buttonIndex;
@end

@interface UIAlertView (private)
-(NSMutableArray *)buttons;
-(void)_buttonClicked:(id)arg1;
-(void)layout;
-(void)_layoutIfNeeded;
-(void)popupAlertAnimated:(BOOL)animated;
@end

@interface UIModalView (private)
-(NSMutableArray *)buttons;
-(id)initWithTitle:(id)title buttons:(id)buttons defaultButtonIndex:(int)index delegate:(id)delegate context:(id)context;
-(void)setBodyText:(id)text;
-(void)setNumberOfRows:(int)rows;
-(void)popupAlertAnimated:(BOOL)animated;
-(void)dismissWithClickedButtonIndex:(int)arg1 animated:(BOOL)arg2;
-(void)_buttonClicked:(id)arg1;
-(void)_setupInitialFrame;
@end

#else
#import "UIKit/UIAlertView.h"
#import "UIKit/UIModalView.h"
#import "UIKit/UIModalViewDelegate.h"
#endif

@interface UIView (privatein31)
- (void)addGestureRecognizer:(id)gestureRecognizer;
- (void)removeGestureRecognizer:(id)gestureRecognizer;
@end

@protocol SBAlertItem<NSObject>
-(id)alertSheet;
-(void)setValue:(id)value forKey:(NSString *)key;
@end

@protocol UIThreePartButtonType
- (void)setTitle:(id)arg1;
@end
