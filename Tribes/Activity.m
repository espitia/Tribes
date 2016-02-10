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
@dynamic weekCompletions;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Activity";
}

+ (void)load {
    [self registerSubclass];
}


#pragma mark - Completions

-(int)weekCompletions {

    // get startOfWeek to hold the first day of the week, according to locale (monday vs. sunday)
    NSCalendar *cal = [NSCalendar currentCalendar];
    [cal setFirstWeekday:2];
    NSDate *now = [NSDate date];
    NSDate *startOfTheWeek;
    NSTimeInterval interval;
    [cal rangeOfUnit:NSCalendarUnitWeekOfYear
           startDate:&startOfTheWeek
            interval:&interval
             forDate:now];
    
    int counter = 0;
    
    // count how many days are in this week
    for (NSDate * date in self.completionDates) {
        if ([self date:date isBetweenDate:startOfTheWeek andDate:[NSDate date]]) {
            counter++;
        }
    }

    return counter;
}

-(void)completeForToday {
    [self addObject:[NSDate date] forKey:@"completionDates"];
    [self updateCompletions];
    [self saveInBackground];
}

-(BOOL)completedForDay {

    //check if completion dates array exists
    if (self.completionDates && self.completionDates.count > 0) {
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

    // make sure date is an nsdate object and not a string
    NSDate * dateToUse = [self getDateFromObject:date];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:dateToUse];
    NSDate * dateToCheck = [cal dateFromComponents:components];
    
    return ([today isEqualToDate:dateToCheck]) ? true : false;
}
/**
 * When editing NSDate objects in Parse, for some reason, it will sometimes return that NSDate as a string and crash the whole app. This method checks to make sure that if it is a string, we turn it into an NSDate object for proper handling.
 * @param Object date to be checked
 * @return Date NSDate object :)
 */
- (NSDate*) getDateFromObject:(id) object{
    if ([object isKindOfClass:[NSDate class]]) {
        return (NSDate*)object;
    } else if ([object isKindOfClass:NSString.class]){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.zzzZ"];
        NSDate *date = [dateFormatter dateFromString:object];
        return date;
    }
    return nil;
}
/**
 * Update completions by counting total dates in completion dates
 */
-(void)updateCompletions {
    self[@"completions"] = [NSNumber numberWithInteger:self.completionDates.count];
}

-(BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    NSDate * dateToCheck = [self getDateFromObject:date];
    if ([dateToCheck compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([dateToCheck compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}
@end
