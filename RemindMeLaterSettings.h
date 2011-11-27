#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RMLFrameworkHeaders.h"
#import "RMLPreferencesHeaders.h"

@interface RMLListController : PSListController
-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s;
-(id)navigationTitle;
@end

@interface RemindMeLaterSettings : RMLListController
-(void)reportIssue:(id)item;
@end

@interface RMLHelpListController : RMLListController
@end
