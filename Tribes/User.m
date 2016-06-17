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
@dynamic weeklyReportActive;
@dynamic hasTribesWithMembers;
@dynamic signedUpToday;
@dynamic pushNotificationsEnabled;

#pragma mark - Parse required methods

+ (void)load {
    [self registerSubclass];
}

#pragma mark - Main Loading

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
    [self fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error && object) {
            [self pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded && !error){
                    NSLog(@"successfully pinned user");
                    callback(true);
                } else {
                    NSLog(@"failed to pin user, will attempt to fetch from network");
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
    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error && object) {
            // pin user
            [self pinInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded && !error){
                    NSLog(@"successfully pinned user");
                    callback(true);
                } else {
                    NSLog(@"failed to pin user");
                    callback(false);
                }
            }];
        } else {
            NSLog(@"failed to fetch user from network.");
            callback(false);
        }
    }];
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

-(void)updateTribesWithBlock:(void(^)(bool success))callback {
    
    __block int counter = 0;
    NSLog(@"attempting to update all tribes");
    
    if (!self.tribes) {
        [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object && !error) {
                for (Tribe * tribe in self.tribes) {
                    
                    [tribe updateTribeWithBlock:^(bool success) {
                        if (success) {
                            counter++;
                            if (counter == self.tribes.count) {
                                NSLog(@"successfully updated all tribes");
                                callback(true);
                            }
                        } else {
                            NSLog(@"failed to update tribes");
                            callback(false);
                        }
                    }];
                }
            } else {
                NSLog(@"error fetchign user to grab tribes");
                callback(false);
            }
        }];
    } else {
        for (Tribe * tribe in self.tribes) {
            
            [tribe updateTribeWithBlock:^(bool success) {
                if (success) {
                    counter++;
                    if (counter == self.tribes.count) {
                        NSLog(@"successfully updated all tribes");
                        callback(true);
                    }
                } else {
                    NSLog(@"failed to update tribes");
                    callback(false);
                }
            }];
        }
    }
    
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

-(void)checkForNewHabitsWithBlock:(void(^)(bool available))callback {
    // get array of all habits user is in to compare to new
    NSMutableArray * copyOfOldHabits = [[NSMutableArray alloc] init];
    for (Tribe * tribe in self.tribes) {
        [copyOfOldHabits addObjectsFromArray:tribe.habits];
    }
    
    // arrays to hold new data and compare old data to
    NSMutableArray * arrayOfNewHabits = [[NSMutableArray alloc] init];
    
    // counter to keep tab on tribes
    __block int counter = 0;
    
    for (Tribe * tribe in self.tribes) {
        
        PFQuery * queryForTribe = [PFQuery queryWithClassName:@"Tribe"];
        [queryForTribe getObjectInBackgroundWithId:tribe.objectId block:^(PFObject * _Nullable object, NSError * _Nullable error) {
            
            if (object && !error) {
                counter++;
                [arrayOfNewHabits addObjectsFromArray:object[@"habits"]];
                if (counter == self.tribes.count) {
                    
                    // check if there are new habits available
                    if (copyOfOldHabits.count != arrayOfNewHabits.count) {
                        NSLog(@"new habits found");
                        callback(true);
                    } else {
                        NSLog(@"no new habits found");
                        callback(false);
                    }
                    
                }
            } else {
                NSLog(@"error fetching tribes to check for new data");
                callback(false);
            }
        }];
    }
}

-(void)checkForNewMembersWithBlock:(void(^)(bool available))callback {
    
    // old data to compare new to
    NSMutableArray * oldCopyOfAllMembers = [[NSMutableArray alloc] init];
    
    for (Tribe * tribe in self.tribes) {
        [oldCopyOfAllMembers addObjectsFromArray:tribe.tribeMembers];
    }

    __block int counter = 0;
    __block int totalCount = 0;
    for (Tribe * tribe in self.tribes) {
        
        PFRelation * relationToMembers = [tribe relationForKey:@"members"];
        PFQuery * query = [relationToMembers query];
        [query countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
            
            totalCount += number;
            counter++;
            
            if (number && !error) {
                if (counter == self.tribes.count) {
                    
                    // check if there are new members
                    if (totalCount != oldCopyOfAllMembers.count) {
                        NSLog(@"new members found");
                        callback(true);
                    } else {
                        NSLog(@"no new members found");
                        callback(false);
                    }
                }
            } else {
                NSLog(@"error fetching members relation to check if there is new data available.");
                callback(false);
            }
        }];

    
    }
    
    
  
}

#pragma mark - Create Tribe

-(void)createNewTribeWithName:(NSString *)name  withBlock:(void(^)(BOOL success))callback {
    
    Tribe * newTribe = [[Tribe alloc] init];
    newTribe[@"name"] = name;
    newTribe[@"nameLowerCase"] = [name lowercaseString];
    newTribe[@"admin"] = self;
    newTribe[@"privacy"] = @YES;
    
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
    
    // if member completed activity already, don't send
    if ([[member activityForHabit:habit] completedForDay]) {
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
    
    for (User * member in tribe.tribeMembers) {
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

    // send 100% tribe completed push
    if ([habit allMembersCompletedActivity])
        [habit sendTribe100PercentCompletedPush];

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

-(BOOL)hasTribesWithMembers {
    for (Tribe * tribe in self.tribes) {
        if (tribe.tribeMembers.count > 1) {
            return true;
        }
    }
    return false;
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
    
    // save changes
    [self saveInBackground];
    [tribe saveInBackground];
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

#pragma mark - Weekly Report
-(BOOL)weeklyReportActive {
    
    for (Activity * activity in self.activities) {
        if (activity.completionDates) {
            if (activity.completionDates.count > 3) {
                return true;
            }
        }

    }
    return false;
}
-(int)thisWeekCompletionsForNonWatcherHabitsForTribe:(Tribe *)tribe {
    
    NSMutableArray * arrayOfNonWatcherHabits = [[NSMutableArray alloc] init];
    arrayOfNonWatcherHabits = [tribe nonWatcherHabits];
    
    int totalWeeklyCompletions = 0;
    for (Activity * activity in self.activities) {
        if (activity[@"tribe"] == tribe && [arrayOfNonWatcherHabits containsObject:activity[@"habit"]]) {
            totalWeeklyCompletions = totalWeeklyCompletions + activity.weekCompletions;
        }
    }
    return totalWeeklyCompletions;
}

-(int)thisWeekCompletionsForTribe:(Tribe *)tribe {
    int totalWeeklyCompletions = 0;
    for (Activity * activity in self.activities) {
        if (activity[@"tribe"] == tribe) {
            totalWeeklyCompletions = totalWeeklyCompletions + activity.weekCompletions;
        }
    }
    return totalWeeklyCompletions;
}

-(int)lastWeekCompletionsForTribe:(Tribe *)tribe {
    int totalWeeklyCompletions = 0;
    for (Activity * activity in self.activities) {
        if (activity[@"tribe"] == tribe) {
            totalWeeklyCompletions = totalWeeklyCompletions + activity.lastWeekCompletions;
        }
    }
    return totalWeeklyCompletions;
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
