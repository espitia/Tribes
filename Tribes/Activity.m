//
//  Activity.m
//  Tribes
//
//  Created by German Espitia on 1/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "Activity.h"
#import <Parse/PFObject+Subclass.h>


@implementation Activity

@dynamic completionDates;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Activity";
}

+ (void)load {
    [self registerSubclass];
}


#pragma mark - Completions

-(void)completeForToday {
    [self addObject:[NSDate date] forKey:@"completionDates"];
    [self updateCompletions];
    [self saveInBackground];
}

-(BOOL)completedForDay {
    
    //check if completion dates array exists
    if (self.completionDates) {
        // if it does, check if last date added was today (thus completed for day)
        return ([self isToday:[self.completionDates lastObject]]) ? true : false;
    }
    
    // if it doesn't exist, it is a new tribe activity
    return false;
}
/**
* Check if date is today
* @param Date to be checked
* @return BOOL with whether or not date is today
*/
-(BOOL)isToday:(NSDate *)date {
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    NSDate * dateToCheck = [cal dateFromComponents:components];
    
    return ([today isEqualToDate:dateToCheck]) ? true : false;
}
/**
 * Update completions by counting total dates in completion dates
 */
-(void)updateCompletions {
    self[@"completions"] = [NSNumber numberWithInteger:self.completionDates.count];
}
@end
