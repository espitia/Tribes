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

@synthesize members;
@synthesize membersAndActivities;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Habit";
}

+ (void)load {
    [self registerSubclass];
}

#pragma mark - Loading Methods

-(void)loadWithBlock:(void(^)(void))callback {
    
    [self fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (error) {
            //fetch from local and pin
            [self updateHabitWithBlock:^{
                callback();
            }];
        } else {
            callback();
        }
    }];
}

-(void)updateHabitWithBlock:(void(^)(void))callback {
    
    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [self pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            callback();
        }];
    }];
}

#pragma mark - Push notifications to Tribe members

-(void)sendTribe100PercentCompletedPush {
    NSString * message = [NSString stringWithFormat:@"%@ 💯 - All tribe members completed the activity ✊", self[@"name"]];
    [self sendPushToAllMembersWithMessage:message andCategory:nil];
}

-(void)sendPushToAllMembersWithMessage:(NSString *)message andCategory:(NSString *)category {
    for (User * user in self.members) {
        [self sendPushToMember:user WithMessage:message andCategory:category];
    }
}

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


#pragma mark - Sorting members by activity

-(void)pairMembersAndActivitiesWithBlock:(void (^)(void))callback {
    
    NSMutableArray * holderArray = [NSMutableArray array];
    
    for (User * member in members) {
        NSLog(@"%@",member);
        Activity * activity = [member activityForHabit:self];
        
        // make dictionary
        NSDictionary * memberAndActivity = @{
                                             @"member":member,
                                             @"activity":activity,
                                             };
        
        
        // add to 'master array'
        [holderArray addObject:memberAndActivity];
        
        if (holderArray.count == self.members.count) {
            self.membersAndActivities = [NSMutableArray arrayWithArray:holderArray];
            callback();
        }
    }
    
    
}

/**
 * Sorts members and activities array by total completions.
 */
-(void)sortMembersAndActivitiesByTotalActivityCompletions {
    [self pairMembersAndActivitiesWithBlock:^{
        [self sortMembersAndActivitiesBy:@"total"];
    }];
}
/**
 * Sorts members and activities array by weekly completions.
 */
-(void)sortMembersAndActivitiesByWeeklyActivityCompletions {
    [self pairMembersAndActivitiesWithBlock:^{
        [self sortMembersAndActivitiesBy:@"weekly"];
    }];
}

/**
 * Sorts members and activities array by indicated time frame.
 *
 * @param timeFrame time frame to sort by, use key "total" or "weekly"
 */
-(void)sortMembersAndActivitiesBy:(NSString *)timeFrame {
    
    NSString * sortByKey;
    
    if ([timeFrame isEqualToString:@"total"]) {
        sortByKey = @"activity.completions";
    } else if ([timeFrame isEqualToString:@"weekly"]) {
        sortByKey = @"activity.weekCompletions";
    } else {
        sortByKey = @"activity.completions"; // default to catch any errors
    }
    
    NSArray * sortedArrayByActivityCompletions = [[NSArray alloc] init];
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:sortByKey  ascending:NO];
    sortedArrayByActivityCompletions = [self.membersAndActivities sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    self.membersAndActivities = [NSMutableArray arrayWithArray:sortedArrayByActivityCompletions];
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

@end
