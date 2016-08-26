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
@dynamic onHoldTribes;
@dynamic activities;
@dynamic lvl;
@dynamic xp;
@synthesize loadedInitialTribes;
@dynamic hasTribesWithMembers;
@dynamic signedUpToday;
@dynamic pushNotificationsEnabled;

#pragma mark - Parse required methods

+ (void)load {
    [self registerSubclass];
}

#pragma mark - Main Loading/updating

-(void)loadTribesWithBlock:(void(^)(bool success))callback {
    
    
    [self loadUserWithBlock:^(bool success) {
        if (success) {
            NSLog(@"successfully loaded user");
            callback(true);
        } else {
            NSLog(@"failed to load user.");
            callback(false);
        }
    }];
    
}

-(void)loadUserWithBlock:(void(^)(bool success))callback {
    
    // fetch from local datastore
    PFQuery * queryForUser = [PFUser query];
    [queryForUser includeKey:@"tribes.habits"];
    [queryForUser includeKey:@"activities"];
    [queryForUser fromLocalDatastore];
    [queryForUser getObjectInBackgroundWithId:self.objectId block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error && object) {
            if ([self dataIsLoaded]) {
                NSLog(@"successfully fetched user from datastore");
                callback(true);
            } else {
                [self fetchUserFromNetworkWithBlock:^(bool success) {
                    if (success) {
                        callback(true);
                    } else {
                        callback(false);
                    }
                }];
            }
            
        } else {
            NSLog(@"error fetch user from local datastore, will attempt to fetch from network");
            // fetch user from network
            [self fetchUserFromNetworkWithBlock:^(bool success) {
                if (success) {
                    callback(true);
                } else {
                    callback(false);
                }
            }];
        }
    }];
}


-(void)fetchUserFromNetworkWithBlock:(void(^)(bool success))callback {
    
    PFQuery * queryForUser = [PFUser query];
    [queryForUser includeKey:@"tribes.habits"];
    [queryForUser includeKey:@"activities"];
    [queryForUser getObjectInBackgroundWithId:self.objectId block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (!error && object) {
            // pin data
            NSArray * arrayOfHabitsToPin = [self habitsForAllTribes];
            
            NSMutableArray * arrayOfObjectsToPin = [[NSMutableArray alloc] init];
            [arrayOfObjectsToPin addObject:self];
            
            if (self.tribes.count > 0)
                [arrayOfObjectsToPin addObjectsFromArray:self.tribes];
            
            if (self.activities.count > 0)
                [arrayOfObjectsToPin addObjectsFromArray:self.activities];
            
            if (arrayOfHabitsToPin.count > 0)
                [arrayOfObjectsToPin addObjectsFromArray:arrayOfHabitsToPin];
            
            
            [PFObject pinAllInBackground:arrayOfObjectsToPin block:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded && !error) {
                    NSLog(@"succesfully pinned all data");
                    callback(true);
                } else {
                    NSLog(@"failed to pin all data");
                    callback(false);
                }
            }];
        } else {
            NSLog(@"failed to fetch user from network");
            callback(false);
        }        
    }];
}

-(void)updateHabitProgressChartsWithBlock:(void(^)(bool success))callback {
    
    
    // loop through all tribes
    for (int y = 0; y < self.tribes.count; y++) {
        Tribe * tribe = [self.tribes objectAtIndex:y];

        // fetch members to see their activites and check for completion of habits
        PFRelation * relationToMembers = [tribe relationForKey:@"members"];
        PFQuery * query = [relationToMembers query];
        [query includeKey:@"activities"];
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            
                // loop through all habits of each tribe
                for (int i = 0; i < tribe.habits.count; i++) {
                    
                    Habit * habit = [tribe.habits objectAtIndex:i];
                    
                    float progress = 0; // actual progress counter
                    float watcherAndHibernation = 0; // check for watcher to remove that from denominator
                    
                    // loop through members to get their activities and check completions
                    for (int z = 0; z < objects.count; z++) {
                        
                        User * member = [objects objectAtIndex:z];
                        
                        // check if completed
                        if ([[member activityForHabit:habit withActivities:member[@"activities"]] completedForDay]) {
                            progress++;
                        }
                        // check for watcher/hibernation to remove from denominator
                        if ([member activityForHabit:habit withActivities:member[@"activities"]].watcher ||
                             [member activityForHabit:habit withActivities:member[@"activities"]].hibernation) {
                            watcherAndHibernation++;
                        }
                        
                        // if we get to the end of checking activities
                        if (z == objects.count - 1) {
                            
                            // set progress for habit, save and pin to local store
                            [habit setObject:[NSNumber numberWithFloat:progress/(objects.count - watcherAndHibernation)] forKey:@"completionProgress"];
                            [habit saveEventually];
                            [habit pinInBackground];
                            
                            // callback when at ze true end (all habits, tribes)
                            if (y == self.tribes.count - 1 && habit[@"tribe"] == [self.tribes objectAtIndex:y]) {
                                callback(true);
                            }
                        }
                    }
                }
        }];

    }
    
}

#pragma mark - Helper methods for loading
// makes sure all data (tribes, habits and acitvities are fully loaded, not just pointers)
-(BOOL)dataIsLoaded {
    
    // check tribes and tribe habits to see if they are fully loaded
    if (self.tribes.count > 0) {
        for (Tribe * tribe in self[@"tribes"]) {
            if (!tribe.createdAt)
                return false;
            for (Habit * habit in tribe[@"habits"]) {
                if (!habit.createdAt)
                    return false;
            }
        }
    }
    for (Activity * activity in self.activities) {
        if (!activity.createdAt)
            return false;
    }
    
    return true;
    
}
-(NSArray *)habitsForAllTribes {
    NSMutableArray * arrayOfHabits = [[NSMutableArray alloc] init];
    for (Tribe * tribe in self.tribes) {
        [arrayOfHabits addObjectsFromArray:tribe.habits];
    }
    return [NSArray arrayWithArray:arrayOfHabits];
}
#pragma mark - Updating methods

-(void)updateMemberDataWithBlock:(void(^)(bool success))callback  {
    
    [self fetchUserFromNetworkWithBlock:^(bool success) {
        if (success) {
            NSLog(@"successfully updated user's tribes and activities");
            callback(true);
        } else {
            NSLog(@"failed to update activities");
            callback(false);
        }
    }];

}

/**
 * Removes tribe from on hold array if found in regular tribes. means user was accepted to new tribe.
 *
 **/
-(void)updateOnHoldTribes {
    for (Tribe * tribe in self.onHoldTribes) {
        if ([self.tribes containsObject:tribe]) {
            [self removeObject:tribe forKey:@"onHoldTribes"];
            [self saveInBackground];
        }
    }
}

-(BOOL)isAdmin:(Tribe *)tribe {
    return (tribe[@"admin"] == self);
}

-(void)checkForPendingMemberswithBlock:(void(^)(BOOL success))callback {
    
    for (Tribe * tribe in self.tribes) {
        if ([self isAdmin:tribe]) {
            [tribe checkForPendingMemberswithBlock:^(BOOL success) {
                if (success) {
                    callback(true);
                } else {
                    callback(false);
                }
            }];
        }
    }
    
    
}
#pragma mark - Checking for new data before reloading all objects unnecessarily


-(void)checkForNewTribesWithBlock:(void(^)(bool available))callback {
    
    // get array of all habits user is in to compare to new
    NSMutableArray * copyOfOldTribes = [[NSMutableArray alloc] init];
    [copyOfOldTribes addObjectsFromArray:self.tribes];

    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        NSArray * newTribes = [object objectForKey:@"tribes"];
        if (newTribes.count != copyOfOldTribes.count) {
            NSLog(@"found new tribes!");
            callback(true);
        } else {
            NSLog(@"no new tribes found");
            callback(false);
        }
    }];

}

#pragma mark - Create Tribe

-(void)createNewTribeWithName:(NSString *)name  withBlock:(void(^)(BOOL success))callback {
    
    Tribe * newTribe = [[Tribe alloc] init];
    newTribe[@"name"] = name;
    newTribe[@"nameLowerCase"] = [name lowercaseString];
    newTribe[@"admin"] = self;
    newTribe[@"privacy"] = @YES;
    newTribe[@"membersCount"] = @1;
    
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
                            
                            callback(true);
                                                    
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
-(void)sendPushFromMemberToMember:(User *)member withMessage:(NSString *)msg habitName:(NSString *)habitName andCategory:(NSString *)category withBlock:(void (^)(BOOL * success))callback {

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
                                        @"category":category,
                                        @"habitName":habitName}
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

-(void)sendPushFromMemberToMember:(User *)member withMessage:(NSString *)msg habitName:(NSString *)habitName andCategory:(NSString *)category {
    [self sendPushFromMemberToMember:member withMessage:msg habitName:habitName andCategory:category withBlock:^(BOOL *success) {
        
    }];
}

-(void)sendMotivationToMember:(User *)member inTribe:(Tribe *)tribe forHabit:(Habit *)habit withBlock:(void (^)(BOOL))callback {
    
    // don't send push to yourself (user sending push to itself)
    if (self == member) {
        return;
    }
    
    // message to send
    NSString * msg =  [NSString stringWithFormat:@"%@: 👉 %@",self[@"username"],habit[@"name"]];
    
    [self sendPushFromMemberToMember:member withMessage:msg habitName:habit[@"name"] andCategory:@"MOTIVATION_REPLY" withBlock:^(BOOL *success) {
        if (success) {
            callback(true);
            NSLog(@"sent motivation to %@", member[@"username"]);
        } else {
            callback(false);
            NSLog(@"failed to send motivation to %@", member[@"username"]);
        }
    }];
}
-(void)notifyOfCompletionToMembersInTribe:(Tribe *)tribe forHabit:(Habit *)habit {

    // message to send
    NSString * msg =  [NSString stringWithFormat:@"🦁 %@ just completed %@!",self[@"username"],habit[@"name"]];
    
    PFRelation * relationToMembers = [tribe relationForKey:@"members"];
    PFQuery * membersQuery = [relationToMembers query];
    [membersQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        NSArray * members = objects;
        
        for (User * member in members) {
            if (member != self) {
                
                [self sendPushFromMemberToMember:member withMessage:msg habitName:habit[@"name"]andCategory:@"COMPLETION_REPLY" withBlock:^(BOOL *success) {
                    if (success) {
                        NSLog(@"sent completion push for %@ to %@",self[@"username"],member[@"username"]);
                    } else {
                        NSLog(@"failed to send completion push for %@ to %@",self[@"username"],member[@"username"]);
                    }
                }];
            }
        }
        
    }];
    

}

-(void)sendPushToMembersOfTribe:(Tribe *)tribe withText:(NSString *)text {
    
    //message to send
    NSString * msg =  [NSString stringWithFormat:@"%@ @ %@: %@", self.username, tribe[@"name"], text];
    
    // get each member from tribe
    PFRelation * relationToMembers = [tribe relationForKey:@"members"];
    PFQuery * membersQuery = [relationToMembers query];
    [membersQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        NSArray * members = objects;
        
        // flip through each member
        for (User * member in members) {
            if (member != self) {
                
                //send push
                [self sendPushFromMemberToMember:member withMessage:msg habitName:@"" andCategory:@""];
            }
        }
        
    }];
}


#pragma mark - Handling tribes/habits


-(void)completeActivityForHabit:(Habit *)habit inTribe:(Tribe *)tribe {

    // complete activity for today
    [[self activityForHabit:habit] completeForToday];
    
    //remove hibernation for activity and local notifications
    Activity * activityForHabit = [self activityForHabit:habit];
    if (activityForHabit.hibernation) {
        activityForHabit.hibernation = false;
        [activityForHabit deleteHibernationNotification];
        [activityForHabit saveEventually];
    }

    // send push to rest of tribe to notify of completion
    [self notifyOfCompletionToMembersInTribe:tribe forHabit:habit];
    
    // update completion progress for habit
    [habit updateCompletionProgress];
}

/**
 * Get Activity object that corresponds to Habit.
 */

-(Activity *)activityForHabit:(Habit *)habit {

    for (Activity * activity in self.activities) {
        if (activity[@"habit"] == habit) {
            return activity;
        }
    }
    return nil;
}
-(Activity *)activityForHabit:(Habit *)habit withActivities:(NSArray *)activities {
    
    for (Activity * activity in activities) {
        if (activity[@"habit"]) {
            if (activity[@"habit"] == habit) {
                return activity;
            }
        }
    }
    return nil;
}

-(void)leaveTribe:(Tribe *)tribe {
    
    // remove tribe from user
    [self removeObject:tribe forKey:@"tribes"];
    
    // find activity for tribe IN user
    NSMutableArray * activitiesToRemove = [[NSMutableArray alloc] init];
    for (Activity * activity in self.activities) {
        if (activity[@"tribe"] == tribe) {
            [activitiesToRemove addObject:activity];
        }
    }
    
    // remove activities from user
    [self removeObjectsInArray:activitiesToRemove forKey:@"activities"];
    
    // remove user from tribe relation "members"
    PFRelation * relation = [tribe relationForKey:@"members"];
    [relation removeObject:self];
    
    // update member count
    [tribe incrementKey:@"membersCount" byAmount:@-1];
    
    // save changes
    [self saveEventually];
    [tribe saveEventually];
}

#pragma mark - User states

-(BOOL)signedUpToday {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self.createdAt];
    NSDate *otherDate = [cal dateFromComponents:components];
    
    return ([today isEqualToDate:otherDate]);
}

-(BOOL)pushNotificationsEnabled {

    UIApplication *application = [UIApplication sharedApplication];
    
    BOOL enabled;
    
    // Try to use the newer isRegisteredForRemoteNotifications otherwise use the enabledRemoteNotificationTypes.
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        enabled = [application isRegisteredForRemoteNotifications];
    } else {
        UIRemoteNotificationType types = [application enabledRemoteNotificationTypes];
        enabled = types & UIRemoteNotificationTypeAlert;
    }
    
    return enabled;
}

#pragma mark - Hibernation

-(void)removeAllHibernationFromActivities {
    for (Activity * activity in self.activities) {
        activity.hibernation = false;
        [activity saveEventually];
    }
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
