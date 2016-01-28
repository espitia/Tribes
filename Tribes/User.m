//
//  User.m
//  Tribes
//
//  Created by German Espitia on 1/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "User.h"
#import "Tribe.h"
#import "Activity.h"
#import <Parse/PFObject+Subclass.h>

@implementation User

@dynamic tribes;
@dynamic activities;
@synthesize loadedInitialTribes;

#pragma mark - Parse required methods

+ (void)load {
    [self registerSubclass];
}


#pragma mark - Loading Tribes

/**
* Loads current tribe objects from current user. Before doing so, it also fetches current user to make sure we have the latest info on which tribes user is in.
 *
 */

-(void)loadTribesWithBlock:(void(^)(void))callback {
    
    // update user in case other users added him/her to a tribe
    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"error loading user: %@", error);
        } else {
            
            // counter to make sure we load all user's tribes
            int __block counter = 0;

            // iterate through each tribe
            for (Tribe * tribe in self.tribes) {
                
                
                [tribe loadTribeWithMembersAndActivitiesWithBlock:^{
                    counter++;
                    
                    // makes sure all tribes have been loaded before callback()
                    if (counter == self.tribes.count) {
                        self.loadedInitialTribes = TRUE;
                        callback();
                    }
                }];
            }
        }
    }];

}

#pragma mark - Push notifications

/**
 * Send push to a member in a tribe.
 
 @param member Member to send push to.
 @param msg message to send member
 */

-(void)sendPushToMember:(User *)member withMessage:(NSString *)msg withBlock:(void (^)(BOOL * success))callback {
    
    __block BOOL success;
    
    // cloud code to send push
    [PFCloud callFunctionInBackground:@"sendPush"
                       withParameters:@{@"userObjectID":member.objectId,
                                        @"msg":msg}
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                    
                                    if (error) {
                                        NSLog(@"error:\n %@", error);
                                        success = false;
                                        callback(&success);
                                    } else {
                                        NSLog(@"success:\n%@", object);
                                        success = true;
                                        callback(&success);
                                    }
                                    
                                }];
}


-(void)completeActivityForTribe:(Tribe *)tribe {

    //find activity for tribe inside user
    for (Activity * activityToComplete in tribe.activities) {
        if (activityToComplete[@"createdBy"] == self) {
            [activityToComplete completeForToday];
        }
    }

}
-(Activity *)activityForTribe:(Tribe *)tribe {
    for (Activity * activity in tribe.activities) {
        if (activity[@"createdBy"] == self) {
            return activity;
        }
    }
    return nil;
}

-(void)addTribeWithName:(NSString *)name {
    
    // create a tribe
    Tribe * tribe = [Tribe object];
    
    // set name key
    [tribe setObject:name forKey:@"name"];
    
    // add user to tribe relation
    PFRelation * tribeRelationToUsers = [tribe relationForKey:@"members"];
    [tribeRelationToUsers addObject:self];
    
    // add tribe to user array
    [self addObject:tribe forKey:@"tribes"];
    
    // create activity
    Activity * activity = [Activity object];
    
    // add user to activity
    [activity setObject:self forKey:@"createdBy"];
    
    // add activity to user
    [self addObject:activity forKey:@"activities"];
    
    // set tribe in activity
    [activity setObject:tribe forKey:@"tribe"];
    
    // for first time user adding a tribe
    self.loadedInitialTribes = true;
    
    // save tribe
    [tribe saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
        
        if (error) { NSLog(@"eror saving tribe: %@", error); }
        
        // save user
        [self saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
            
            if (error) { NSLog(@"eror saving user: %@", error); }
            
            // save activity
            [activity saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
                
                if (error) { NSLog(@"eror saving activity: %@", error); } 
                
            }];
        }];
    }];
}
@end
