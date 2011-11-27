#import "RemindMeLaterSettings.h"
#include "RMLDebug.h"

@implementation RMLListController

-(NSString *)getPhrase:(NSString *)key {
  NSString *result = [[self bundle] localizedStringForKey:key value:key table:nil];
#if DEBUG_LOG
  //  NSLog(@"RMLListController.getPhrase: in for %@, out with %@", key, result);
#endif
  return result;
}

- (NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)specifiers {
#if DEBUG_LOG
  NSLog(@"RMLListController.localizedSpecifiersForSpecifiers: in with %d items", [specifiers count]);
#endif
  for (PSSpecifier *item in specifiers) {
#if DEBUG_LOG
    NSLog(@"RMLListController.localizedSpecifiersForSpecifiers: item is a %@", [item class]);
#endif	
    
    NSString *itemName = [item name];
		if (itemName) {
#if DEBUG_LOG
      NSLog(@"RMLListController.localizedSpecifiersForSpecifiers: item has name %@", itemName);
#endif	
  		[item setName:[self getPhrase:itemName]];
#if DEBUG_LOG
      NSLog(@"RMLListController.localizedSpecifiersForSpecifiers: localized name is %@", [item name]);
#endif
		}
    
#if 1
    NSDictionary *itemTitleDict = [item titleDictionary];
		if (itemTitleDict) {
#if DEBUG_LOG
      NSLog(@"RMLListController.localizedSpecifiersForSpecifiers: titleDictionary is %@", itemTitleDict);
#endif
			NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
			for (NSString *key in itemTitleDict) {
				[newTitles setObject:[self getPhrase:[itemTitleDict objectForKey:key]] forKey:key];
			}
			[item setTitleDictionary: [newTitles autorelease]];

#if DEBUG_LOG
      NSLog(@"RMLListController.localizedSpecifiersForSpecifiers: now titleDictionary is %@", [item titleDictionary]);
#endif
		}
#endif

    NSString *footerText = [item propertyForKey:@"footerText"];
#if DEBUG_LOG
    NSLog(@"RMLListController.localizedSpecifiersForSpecifiers: footerText was %@", footerText);
#endif
    if (footerText) {
      [item setProperty:[self getPhrase:footerText] forKey:@"footerText"];
#if DEBUG_LOG
      NSLog(@"RMLListController.localizedSpecifiersForSpecifiers: now footerText is %@", [item propertyForKey:@"footerText"]);
#endif
    }
	}
  
#if DEBUG_LOG
  NSLog(@"RMLListController.localizedSpecifiersForSpecifiers: out with %d items", [specifiers count]);
#endif
	return specifiers;
};

- (id)navigationTitle {
#if DEBUG_LOG
  NSLog(@"RMLListController.navigationTitle: in for %@", self.title);
#endif
	return [[self bundle] localizedStringForKey:self.title value:self.title table:nil];
}
@end




@implementation RemindMeLaterSettings

- (NSArray *)specifiers {
#if DEBUG_LOG
  NSLog(@"RemindMeLaterSettings.specifiers: in");
#endif
  
  if (!_specifiers) {
    NSArray *s = [self loadSpecifiersFromPlistName:@"RemindMeLater" target: self];
#if DEBUG_LOG
    NSLog(@"RemindMeLaterSettings.specifiers: loaded %d specifiers", [s count]);
#endif
    _specifiers = [[self localizedSpecifiersForSpecifiers:s] retain];
  }
  
  return _specifiers;
}

-(void)reportIssue:(id)item {
#if DEBUG_LOG
  NSLog(@"RemindMeLaterSettings.reportIssue: in with %@", item);
#endif

  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.varju.ca/redmine/projects/remindmelater"]];
}

@end



@implementation RMLHelpListController

- (NSArray *)specifiers {
#if DEBUG_LOG
  NSLog(@"RMLHelpListController.specifiers: in");
#endif
  
  if (!_specifiers) {
    NSArray *s = [self loadSpecifiersFromPlistName:@"RMLHelp" target: self];
#if DEBUG_LOG
    NSLog(@"RMLHelpListController.specifiers: loaded %d specifiers", [s count]);
#endif
    _specifiers = [[self localizedSpecifiersForSpecifiers:s] retain];
  }
  
  return _specifiers;
}

@end
