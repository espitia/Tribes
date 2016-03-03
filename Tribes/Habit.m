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



@end
