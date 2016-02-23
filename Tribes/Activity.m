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
@dynamic hibernation;
@dynamic dueTime;
@dynamic weekCompletions;
@dynamic onStreak;

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

-(BOOL)onStreak {

    NSCalendar *cal = [NSCalendar currentCalendar];
    [cal setFirstWeekday:2];
    NSDate *today = [NSDate date];
    NSDate *startOfTheWeek;
    NSTimeInterval interval;
    [cal rangeOfUnit:NSCalendarUnitWeekOfYear
           startDate:&startOfTheWeek
            interval:&interval
             forDate:today];
    
    int daysBetweenStartOfWeekAndToday = 0;
    NSDate * referenceDateToUse;
    
    // if the date where the activity was created is earlier than the start of the week, use that as reference date to give new tribe members a change at a streak
    referenceDateToUse = ([self.createdAt timeIntervalSinceDate:startOfTheWeek] > 0) ? self.createdAt : startOfTheWeek;
    
    // get dates to count from reference date to yesterday
    daysBetweenStartOfWeekAndToday = (int)[self daysBetweenDate:referenceDateToUse andDate:today];
    daysBetweenStartOfWeekAndToday++; // add 1 to include today
    
    // check that activity has a completion for each day from reference date (e.g. start of week until yest) to validate streak
    for (int i = 0; i < daysBetweenStartOfWeekAndToday;) {
        for (NSDate * date in self.completionDates) {
            // if date was complete, goes to check next day until we hit yesterday (by adding 1 day at a time)
            if ([cal isDate:date inSameDayAsDate:[NSDate dateWithTimeInterval:(86400.0 * i) sinceDate:referenceDateToUse]]) {
                i++;
                if (i == daysBetweenStartOfWeekAndToday) {
                    return true;
                } 
            }
        }
        return false;
    }
    return false;
}


#pragma mark - Action methods

-(void)completeForToday {
    [self addObject:[NSDate date] forKey:@"completionDates"];
    [self updateCompletions];
    [self saveEventually];
}

/**
 * Update completions by counting total dates in completion dates
 */
-(void)updateCompletions {
    self[@"completions"] = [NSNumber numberWithInteger:self.completionDates.count];
}

#pragma mark - State

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

#pragma mark - Util methods

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


-(BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    NSDate * dateToCheck = [self getDateFromObject:date];
    if ([dateToCheck compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([dateToCheck compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

-(NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}
@end
