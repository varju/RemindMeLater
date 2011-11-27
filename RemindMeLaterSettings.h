//
//  RemindMeLaterSettings.h
//
//  Created by Alex Varju on 2011-01-16.
//  Copyright 2011 Alex Varju. All rights reserved.
//
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
