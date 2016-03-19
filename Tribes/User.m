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

#pragma mark - Main Loading/Updating methods

-(void)loadTribesWithBlock:(void(^)(bool success))callback {
    
    
    [self loadUserWithBlock:^(bool success) {
        if (success) {
            
            // load all tribes only if there are tribes available
            if (false) {
//            if (self.tribes.count > 0) {
                
                __block int counter = 0;
                // iterate through each tribe to load
                for (Tribe * tribe in self.tribes) {
                    
                    [tribe loadTribeWithBlock:^(bool success) {
                        if (success) {
                            counter++;
                            if (counter == self.tribes.count) {
                                NSLog(@"successfully loaded all tribes");
                                callback(true);
                            }
                        } else {
                            NSLog(@"failed to load tribes");
                            callback(false);
                        }
                    }];
                    counter++;
                }
            } else {
                NSLog(@"no tribes were found to load. loading user complete.");
                callback(true);
            }
            
        } else {
            NSLog(@"failed to load user.");
            callback(false);
        }
    }];
    
}

-(void)loadUserWithBlock:(void(^)(bool success))callback {
    
    // fetch from local datastore
    [self fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        // if no errors were found in object, done
        if (!error && object && object.createdAt) {
            NSLog(@"successfully loaded user from local datastore");
            callback(true);
        } else {
            NSLog(@"error fetching user from local datastore .. will attempt to fetch from network.");
            //if not found in datastore, fetch from network
            [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object && !error) {
                    NSLog(@"successfully fetched user frmo network");
                    // if user is found, pin it to local datastore
                    [self pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded && !error) {
                            NSLog(@"successfully pinned user to local datastore");
                            callback(true);
                        } else {
                            NSLog(@"error pinning user");
                            callback(false);
                        }
                    }];
                } else {
                    NSLog(@"error fetching user object from network");
                    callback(false);
                }
            }];
            
        }
    }];
    
}

#pragma mark - Create Tribe 

-(void)createNewTribeWithName:(NSString *)name  withBlock:(void(^)(BOOL success))callback {

    Tribe * newTribe = [[Tribe alloc] init];
    newTribe[@"name"] = name;
    
    PFRelation * members = [newTribe relationForKey:@"members"];
    [members addObject:self];
    
    [newTribe saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (!error && succeeded) {
            [newTribe pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (!error && succeeded) {
                    NSLog(@"successfully saved new tribe");
                    
                    [self addObject:newTribe forKey:@"tribes"];
                    
                    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (!error && succeeded) {
                            
                            //                    [self updateTribesWithBlock:^{
                            callback(true);
                            
                            //                    }];
                            
                            NSLog(@"successfully saved user with new tribe");
                        } else {
                            NSLog(@"error saving user with new tribe");
                            callback(false);
                        }
                    }];
                    
                } else {
                    NSLog(@"error saving pinning new tribe");
                    callback(false);
                }
            }];
        } else {
            NSLog(@"error saving new tribe");
            callback(false);
        }
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
    NSString * msg =  [NSString stringWithFormat:@"%@: 👉 %@",self[@"name"],habit[@"name"]];
    
    [self sendPushFromMemberToMember:member withMessage:msg andCategory:@"MOTIVATION_REPLY" withBlock:^(BOOL *success) {
        if (success) {
            callback(true);
            NSLog(@"sent motivation to %@", member[@"name"]);
        } else {
            callback(false);
            NSLog(@"failed to send motivation to %@", member[@"name"]);
        }
    }];
}
-(void)notifyOfCompletionToMembersInTribe:(Tribe *)tribe forHabit:(Habit *)habit {

    // message to send
    NSString * msg =  [NSString stringWithFormat:@"🦁 %@ just completed %@!",self[@"name"],habit[@"name"]];
    
    for (User * member in tribe.tribeMembers) {
        if (member != self) {
            
            [self sendPushFromMemberToMember:member withMessage:msg andCategory:@"COMPLETION_REPLY" withBlock:^(BOOL *success) {
                if (success) {
                    NSLog(@"sent completion push for %@ to %@",self[@"name"],member[@"name"]);
                } else {
                    NSLog(@"failed to send completion push for %@ to %@",self[@"name"],member[@"name"]);
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
    [self notifyOfCompletionToMembersInTribe:tribe forHabit:habit];

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
