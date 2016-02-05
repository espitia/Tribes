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
 * Send push to a member in a tribe with category for push notification replys.
 
 @param member Member to send push to.
 @param msg message to send member
 @param category the category of reply actions that will be available to the recepient of the push: "MOTIVATION_REPLY", "COMPLETION_REPLY". !!! LEAVE EMPTY STRING IN ORDER TO NOT HAVE ANY REPLY OPTIONS"
 */
-(void)sendPushFromMemberToMember:(User *)member withMessage:(NSString *)msg andCategory:(NSString *)category withBlock:(void (^)(BOOL * success))callback {

    __block BOOL success;
    
    // security check: if category is anything but the accepeted categories, default to no categories
    if (!(category || ([category isEqualToString:@"COMPLETION_REPLY"]) || ([category isEqualToString:@"MOTIVATION_REPLY"]))) {
        category = @"";
    }
    
    // cloud code to send push
    [PFCloud callFunctionInBackground:@"sendPush"
                       withParameters:@{@"receiverId":member.objectId,
                                        @"senderId":self.objectId,
                                        @"msg":msg,
                                        @"category":category}
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

-(void)sendMotivationToMember:(User *)member inTribe:(Tribe *)tribe withBlock:(void (^)(BOOL))callback {
    
    // don't send push to yourself (user sending push to itself)
    if (self == member) {
        return;
    }
    
    // if member completed activity already, don't send
    if ([[member activityForTribe:tribe] completedForDay]) {
        return;
    }
    
    // message to send
    NSString * msg =  [NSString stringWithFormat:@"%@: breh, %@",self[@"username"],tribe[@"name"]];
    
    [self sendPushFromMemberToMember:member withMessage:msg andCategory:@"MOTIVATION_REPLY" withBlock:^(BOOL *success) {
        if (success) {
            callback(true);
            NSLog(@"sent motivation to %@", member[@"username"]);
        } else {
            callback(false);
            NSLog(@"failed to send motivation to %@", member[@"username"]);
        }
    }];
}
-(void)notifyOfCompletionToMembersInTribe:(Tribe *)tribe {

    // message to send
    NSString * msg =  [NSString stringWithFormat:@"%@ just completed %@.\n🦁🦁🦁!",self[@"username"],tribe[@"name"]];
    
    for (User * member in tribe.members) {
        if (member != self) {
            
            [self sendPushFromMemberToMember:member withMessage:msg andCategory:@"COMPLETION_REPLY" withBlock:^(BOOL *success) {
                if (success) {
                    NSLog(@"sent completion push for %@ to %@",self[@"username"],member[@"username"]);
                } else {
                    NSLog(@"failed to send completion push for %@ to %@",self[@"username"],member[@"username"]);
                }
            }];
        }
    }
}

#pragma mark - Handling tribes

-(void)completeActivityForTribe:(Tribe *)tribe {

    // complete activity for today
    [[self activityForTribe:tribe] completeForToday];
    
    // send push to rest of tribe to notify of completion
    [self notifyOfCompletionToMembersInTribe:tribe];

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
    
    // create a tribe/ setname /add user to relation of members
    Tribe * tribe = [Tribe object];
    [tribe setObject:name forKey:@"name"];
    PFRelation * tribeRelationToUsers = [tribe relationForKey:@"members"];     // add user to tribe relation
    [tribeRelationToUsers addObject:self];
    
    
    // create activity/ set tribe/createdBy for respective keys
    Activity * activity = [Activity object];
    [activity setObject:tribe forKey:@"tribe"];
    [activity setObject:self forKey:@"createdBy"];
    
    // add tribe/activities to user arrays
    [self addObject:tribe forKey:@"tribes"];
    [self addObject:activity forKey:@"activities"];
    
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
