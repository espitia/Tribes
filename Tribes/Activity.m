//
//  Activity.m
//  Tribes
//
//  Created by German Espitia on 1/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "Activity.h"
#import "User.h"
#import <Parse/PFObject+Subclass.h>


@implementation Activity

@dynamic completionDates;
@dynamic hibernation;
@dynamic watcher;
@dynamic weekCompletions;
@dynamic lastWeekCompletions;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Activity";
}

+ (void)load {
    [self registerSubclass];
}

#pragma mark - Loading/updating methods



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
-(int)lastWeekCompletions {

    
    // get startOfWeek to hold the first day of the week, according to locale (monday vs. sunday)
    NSCalendar *cal = [NSCalendar currentCalendar];
    [cal setFirstWeekday:2];
    NSDate *lastWeekDate = [NSDate dateWithTimeIntervalSinceNow:-604800];
    NSDate *startOfLastWeek;
    NSTimeInterval interval;
    [cal rangeOfUnit:NSCalendarUnitWeekOfYear
           startDate:&startOfLastWeek
            interval:&interval
             forDate:lastWeekDate];
    NSDate *endOfLastweek = [NSDate dateWithTimeInterval:604800 sinceDate:startOfLastWeek];
    
    int counter = 0;
    
    // count how many days are in this week
    for (NSDate * date in self.completionDates) {
        if ([self date:date isBetweenDate:startOfLastWeek andDate:endOfLastweek]) {
            counter++;
        }
    }
    return counter;
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

#pragma mark - Hibernation methods for local notification

-(void)makeHibernationNotification {
    
    // if other habits have set hibernation, dont allow for creation of more notifications
    if ([self hibernationNotificationAlreadySet])
        return;
    
    // fire date (tomorrow 10am)
    NSDate* now = [NSDate date] ;
    NSDateComponents* tomorrowComponents = [NSDateComponents new] ;
    tomorrowComponents.day = 1 ;
    NSCalendar* calendar = [NSCalendar currentCalendar] ;
    NSDate* tomorrow = [calendar dateByAddingComponents:tomorrowComponents toDate:now options:0] ;
    NSDateComponents* tomorrowAt9AMComponents = [calendar components:(NSCalendarUnitDay|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:tomorrow] ;
    tomorrowAt9AMComponents.hour = 9;
    NSDate* tomorrowAt9AM = [calendar dateFromComponents:tomorrowAt9AMComponents] ;
    
    // make local notificaiton to take it off the next day
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = tomorrowAt9AM;
    localNotification.repeatInterval = NSCalendarUnitDay;
    localNotification.category = @"HIBERNATION_RESPONSE";
    localNotification.alertBody = @"🐻 It's a new day! Would you like to turn hibernations off?";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    NSLog(@"sceduel notif: %@", [[UIApplication sharedApplication] scheduledLocalNotifications]);
}

-(void)deleteHibernationNotification {
    
    // if other habits have hibernation, dont remove
    if ([self otherHabitsHaveHibernationOn])
        return;
    
    // if no other habit has hibernation on, remove it
    for (UILocalNotification * notificaiton in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if ([notificaiton.category isEqualToString:@"HIBERNATION_RESPONSE"]) {
            [[UIApplication sharedApplication] cancelLocalNotification:notificaiton];
        }
    }
}
-(BOOL)hibernationNotificationAlreadySet {
    for (UILocalNotification * notificaiton in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if ([notificaiton.category isEqualToString:@"HIBERNATION_RESPONSE"]) {
            return true;
        }
    }
    return false;
}

-(BOOL)otherHabitsHaveHibernationOn {
    for (Activity * activity in [User currentUser].activities) {
        if (activity.hibernation) {
            return true;
        }
    }
    return false;
}
@end
