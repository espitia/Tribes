//
//  Habit.m
//  Tribes
//
//  Created by German Espitia on 3/2/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "Habit.h"
#import "User.h"

@implementation Habit

@synthesize completionDates;
@synthesize completionProgress;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Habit";
}

+ (void)load {
    [self registerSubclass];
}
#pragma mark - Push notifications to Tribe members


/**
 * Send push to a member in tribe with category for push notification replys.
 
 @param member Member to send push to.
 @param msg message to send member
 @param category the category of reply actions that will be available to the recepient of the push: "MOTIVATION_REPLY", "COMPLETION_REPLY". !!! LEAVE EMPTY STRING IN ORDER TO NOT HAVE ANY REPLY OPTIONS"
 */

-(void)sendPushToMember:(User *)member WithMessage:(NSString *)message andCategory:(NSString *)category {
    
    // security check: if category is anything but the accepeted categories, default to no categories
    if (!(category || ([category isEqualToString:@"COMPLETION_REPLY"]) || ([category isEqualToString:@"MOTIVATION_REPLY"]))) {
        category = @"";
    }
    
    // cloud code to send push
    [PFCloud callFunctionInBackground:@"sendPush"
                       withParameters:@{@"receiverId":member.objectId,
                                        @"msg":message,
                                        @"category":category}
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                    
                                    if (error) {
                                        NSLog(@"error:\n %@", error);
                                    } else {
                                        NSLog(@"success:\n%@", object);
                                        
                                    }
                                    
                                }];
}
#pragma mark - State

-(BOOL)completedForDay {
    
    // get activity obj that olds all data for user
    Activity * activity = [[User currentUser] activityForHabit:self];

    //check if completion dates array exists
    if (activity.completionDates && activity.completionDates.count > 0) {
        // if it does, check if last date added was today (thus completed for day)
        return ([self isToday:[activity.completionDates lastObject]]) ? true : false;
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

@end
