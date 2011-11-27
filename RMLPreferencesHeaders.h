
#if TARGET_IPHONE_SIMULATOR
@interface PSViewController : UIViewController {
  id _specifiers;
}
@end
@interface PSListController : PSViewController
@end
@interface PSListController (private)
-(id)bundle;
-(id)loadSpecifiersFromPlistName:(id)plistName target:(id)target;
@end
@interface PSSpecifier : NSObject
@end
@interface PSSpecifier (private)
-(id)titleDictionary;
-(void)setTitleDictionary:(id)dictionary;
@end
#else
#import <Preferences/Preferences.h>
#endif
