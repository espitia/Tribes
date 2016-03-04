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
@dynamic weekCompletions;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Activity";
}

+ (void)load {
    [self registerSubclass];
}

#pragma mark - Loading/updating methods

-(void)loadWithBlock:(void(^)(void))callback {
    [self fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (error) {
            //fetch from local and pin
            [self updateActivityWithBlock:^{
                callback();
            }];
        } else {
            callback();
        }
    }];
}

-(void)updateActivityWithBlock:(void(^)(void))callback {
    
    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [self pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            callback();
        }];
    }];
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

@end
