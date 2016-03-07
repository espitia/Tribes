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

-(void)createNewTribeWithName:(NSString *)name {

    Tribe * newTribe = [[Tribe alloc] init];
    newTribe[@"name"] = name;
    
    PFRelation * members = [newTribe relationForKey:@"members"];
    [members addObject:self];
    
    [newTribe saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
        if (!error) {
            
            PFRelation * tribes = [self relationForKey:@"tribess"];
            [tribes addObject:newTribe];

        } else {
            NSLog(@"error saving new tribe");
        }
        
        
        [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (!error) {
                NSLog(@"saved user");
            } else {
                NSLog(@"error");
            }
        }];
        
    }];
}

#pragma mark - Main Loading/Updating methods

-(void)loadTribesWithBlock:(void (^)(void))callback {
    
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

-(void)updateTribesWithBlock:(void(^)(void))callback {
    __block int tribeCounter = 0;
    for (Tribe * tribe in self.tribes) {
        [tribe updateTribeWithBlock:^{
            [tribe updateHabitsWithBlock:^{
                [tribe updateMembersWithBlock:^{
                    [tribe updateMemberActivitiesWithBlock:^{
                        tribeCounter++;
                        if (tribeCounter == self.tribes.count) {
                            callback();
                        }
                    }];
                }];
            }];
        }];
    }
}



#pragma mark - methods to load/update tribe members

-(void)loadActivitiesWithBlock:(void(^)(void))callback {
    __block int counter = 0;
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
