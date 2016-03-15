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

int XP_FOR_COMPLETED_HABIT = 100;
int XP_FOR_RECEIVED_APPLAUSE = 10;

@dynamic tribes;
@dynamic activities;
@dynamic lvl;
@dynamic xp;
@synthesize loadedInitialTribes;

#pragma mark - Parse required methods

+ (void)load {
    [self registerSubclass];
}


#pragma mark - Create Tribe 

-(void)createNewTribeWithName:(NSString *)name  withBlock:(void(^)(BOOL success))callback {

    Tribe * newTribe = [[Tribe alloc] init];
    newTribe[@"name"] = name;
    
    PFRelation * members = [newTribe relationForKey:@"members"];
    [members addObject:self];
    
    [newTribe saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
        if (!error) {
            NSLog(@"successfully saved new tribe");
                    
            [self addObject:newTribe forKey:@"tribes"];
        
            [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (!error) {
                    
                    [self updateTribesWithBlock:^{
                        callback(true);

                    }];
                    
                    NSLog(@"successfully saved user with new tribe");
                } else {
                    NSLog(@"error saving user with new tribe");
                    callback(false);
                }
            }];
            
        } else {
            NSLog(@"error saving new tribe");
            callback(false);
        }
        
    }];
}

#pragma mark - Main Loading/Updating methods

-(void)loadTribesWithBlock:(void (^)(void))callback {
    
    
    if (!self.tribes) {
        callback();
    } else {
        
        __block int counter = 0;

        for (Tribe * tribe in self.tribes) {
            [tribe loadTribeWithMembersAndHabitsWithBlock:^{
                counter++;
                if (counter == self.tribes.count) {
                    self.loadedInitialTribes = true;
                    callback();
                }
            }];
        }
    }
    
}

-(void)updateTribesWithBlock:(void(^)(void))callback {
    

    // fetch user and pin
    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [self pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {

            // if user has no tribes - end updating
            if (!self.tribes)
                callback();
            
            // fetch tribes
            [PFObject fetchAllInBackground:self.tribes block:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                
                // pin tribes
                [PFObject pinAllInBackground:objects block:^(BOOL succeeded, NSError * _Nullable error) {
                    
                    // get habits from all tribes to fetch
                    NSMutableArray * habitsToFetch = [[NSMutableArray alloc] init];
                    for (Tribe * tribe in self.tribes) {
                        if (tribe[@"habits"])
                            [habitsToFetch addObjectsFromArray:tribe[@"habits"]];
                    }
                    
                    // feth habits
                    [PFObject fetchAllInBackground:habitsToFetch block:^(NSArray * _Nullable objects, NSError * _Nullable error) {

                        // pin habits
                        [PFObject pinAllInBackground:objects block:^(BOOL succeeded, NSError * _Nullable error) {

                            
                            //fetch all members and pin
                            __block int counter = 0;
                            for (Tribe * tribe in self.tribes) {
                                
                                // fetch members
                                PFRelation * relationForMembers = [tribe relationForKey:@"members"];
                                PFQuery * query = [relationForMembers query];
                                [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {

                                    // add members to tribe.tribemembers
                                    // add members to habits
                                    [tribe addTribeMembersToTribe:objects];
                                    [tribe addTribeMembersToHabits:objects];

                                    // pin members
                                    [PFObject pinAllInBackground:objects block:^(BOOL succeeded, NSError * _Nullable error) {
                                        counter++;

                                        // when all members of tribes have been fetched
                                        if (counter == self.tribes.count) {
                                            
                                            // get all members in one array to fetch their activities
                                            NSMutableArray * membersToFetchActivitesFrom = [[NSMutableArray alloc] init];
                                            for (Tribe * tribe in self.tribes) {
                                                for (User * member in tribe.tribeMembers) {
                                                    [membersToFetchActivitesFrom addObjectsFromArray:member.activities];
                                                }
                                            }
                                            
                                            // fetch all activities
                                            [PFObject fetchAllInBackground:membersToFetchActivitesFrom block:^(NSArray * _Nullable objects, NSError * _Nullable error) {

                                                // pin activities
                                                [PFObject pinAllInBackground:objects block:^(BOOL succeeded, NSError * _Nullable error) {
                                                    
                                                    callback();
                                                    
                                                }];
                                            }];
                                            

    
                                        }
                                        
                                        
                                        
                                    }];
                                }];
                            }
                                
                            
                            
                        }];
                    }];
                    
                }];
            }];
            
            
        }];
    }];
    

}


-(void)updateTribesMembersAndActivities:(void(^)(void))callback {
    
    if (!self.tribes)
        callback();
    
    __block int counter = 0;
    
    for (Tribe * tribe in self.tribes) {
        [tribe updateMembersWithBlock:^{
            [tribe updateMemberActivitiesWithBlock:^{
                counter++;
                if (counter == self.tribes.count) {
                    self.loadedInitialTribes = true;
                    callback();
                }
            }];
        }];
    }
}

#pragma mark - methods to load/update tribe members

-(void)loadActivitiesWithBlock:(void(^)(void))callback {
    __block int counter = 0;
    
    if (!self[@"activities"])
        callback();
    
    for (Activity * activity in self[@"activities"]) {
        counter++;
        [activity loadWithBlock:^{
            if (counter == [self[@"activities"] count]) {
                callback();
            }
        }];
    }

}
-(void)updateActivitiesWithBlock:(void(^)(void))callback {
    __block int counter = 0;
    
    if (!self[@"activities"])
        callback();
    
    for (Activity * activity in self[@"activities"]) {
        counter++;
        [activity updateActivityWithBlock:^{
            if (counter == [self[@"activities"] count]) {
                NSLog(@"successfuly member activities object from network.");
                callback();
            }
        }];
    }
    
}

-(void)updateMemberWithBlock:(void(^)(void))callback {
    
    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [self pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            callback();
        }];
    }];
}



#pragma mark - Push notifications

/**
 * Send push to a member in a tribe with category for push notification replys.
 
 @param member Member to send push to.
 @param msg message to send member
 @param category the category of reply actions that will be available to the recepient of the push: "MOTIVATION_REPLY", "COMPLETION_REPLY". 
 */
-(void)sendPushFromMemberToMember:(User *)member withMessage:(NSString *)msg andCategory:(NSString *)category withBlock:(void (^)(BOOL * success))callback {

    __block BOOL success;
    
    // security check: if category is anything but the accepeted categories, default to no categories
    if (!(category || ([category isEqualToString:@"COMPLETION_REPLY"]) ||
          ([category isEqualToString:@"MOTIVATION_REPLY"]) ||
          ([category isEqualToString:@"WATCHING_YOU_REPLY"]) ||
          ([category isEqualToString:@"THANK_YOU_FOR_APPLAUSE_REPLY"]))) {
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

-(void)sendPushFromMemberToMember:(User *)member withMessage:(NSString *)msg andCategory:(NSString *)category {
    [self sendPushFromMemberToMember:member withMessage:msg andCategory:category withBlock:^(BOOL *success) {
        
    }];
}

-(void)sendMotivationToMember:(User *)member inTribe:(Tribe *)tribe forHabit:(Habit *)habit withBlock:(void (^)(BOOL))callback {
    
    // don't send push to yourself (user sending push to itself)
    if (self == member) {
        return;
    }
    
    // if member completed activity already, don't send
    if ([[member activityForHabit:habit] completedForDay]) {
        return;
    }
    
    // message to send
    NSString * msg =  [NSString stringWithFormat:@"%@: 👉 %@",self[@"username"],tribe[@"name"]];
    
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
    NSString * msg =  [NSString stringWithFormat:@"🦁 %@ just completed %@!",self[@"username"],tribe[@"name"]];
    
    for (User * member in tribe.tribeMembers) {
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

#pragma mark - Handling tribes/habits


-(void)completeActivityForHabit:(Habit *)habit inTribe:(Tribe *)tribe {

    // complete activity for today
    [[self activityForHabit:habit] completeForToday];

    // send push to rest of tribe to notify of completion
    [self notifyOfCompletionToMembersInTribe:tribe];

    // send 100% tribe completed push
    if ([habit allMembersCompletedActivity])
        [habit sendTribe100PercentCompletedPush];

}



-(Activity *)activityForHabit:(Habit *)habit {

    for (Activity * activity in self.activities) {
        if (activity[@"habit"] == habit) {
            return activity;
        }
    }
    return nil;
}



-(void)removeFromTribe:(Tribe *)tribeToRemoveFrom {
    
    // remove tribe from user
    [self removeObject:tribeToRemoveFrom forKey:@"tribes"];
    
    // find activity for tribe IN user
    Activity * activityToRemove;
    for (Activity * activity in self.activities) {
        if (activity[@"createdBy"] == self) {
            activityToRemove = activity;
        }
    }
    
    // remove activity from user
    [self removeObject:activityToRemove forKey:@"activities"];
    
    // remove user from tribe relation "members"
    PFRelation * relation = [tribeToRemoveFrom relationForKey:@"members"];
    [relation removeObject:self];
    
    // save changes
    [self saveInBackground];
    [tribeToRemoveFrom saveInBackground];

}

#pragma mark - Levels and XP

-(void)addXp:(int)xpToAdd {

    // get user xp
    NSNumber * userXp = self[@"xp"];

    // add new xp
    int userXpInt = [userXp intValue];
    int newXpTotal = userXpInt + xpToAdd;

    // save user xp
    self[@"xp"] = [NSNumber numberWithInt:newXpTotal];
    [self save];
}
-(void)addReceivedApplauseXp {
    [self addXp:XP_FOR_RECEIVED_APPLAUSE];
}

-(int)lvl {
    double xp = [self[@"xp"] doubleValue];
    for (double level = 99; level > 0; level--) {
        double levelAc = ((1.0/8.0 * level) * (level - 1.0)) + (75.0 * ( ((pow(2.0,(level - 1.0)/7.0)- 1.0) / (1.0 - pow(2.0, -1.0/7.0)))));
        if (xp >= levelAc) {
            return level;
        }
    }
    return 0;
}
-(int)xp {
    int xp = [self[@"xp"] intValue];
    return xp;
}












@end
