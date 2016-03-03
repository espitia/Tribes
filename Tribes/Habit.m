//
//  Habit.m
//  Tribes
//
//  Created by German Espitia on 3/2/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "Habit.h"

@implementation Habit

@synthesize members;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Habit";
}

+ (void)load {
    [self registerSubclass];
}


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

@end
