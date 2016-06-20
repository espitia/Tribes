//
//  Tribe.m
//  Tribes
//
//  Created by German Espitia on 1/14/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "Tribe.h"
#import "Activity.h"
#import "User.h"
#import "Habit.h"
#import <Parse/PFObject+Subclass.h>


@implementation Tribe

@dynamic name;
@dynamic habits;
@dynamic privacy;
@synthesize onHoldMembers;
@dynamic membersCount;

#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Tribe";
}

+ (void)load {
    [self registerSubclass];
}

#pragma mark - Adding to Tribe

/**
 * Adds a user to tribe's member relation. Then it calls PFCloud code to add tribe, create activity objet and add activity to user.
 *
 * @param User to be added to tribe
 * @return A BOOl value of true or false to let you know if everything went smoothly.
 */
-(void)addUserToTribe:(User *)user withBlock:(void (^)(BOOL * success))callback {


    
    __block BOOL success;
    
    // cloud code to add tribe and activity to user (then save user)
    [PFCloud callFunctionInBackground:@"addTribeAndActivityToUser"
                       withParameters:@{@"tribeObjectID":self.objectId,
                                        @"userObjectID":user.objectId
                                        } block:^(id  _Nullable object, NSError * _Nullable error) {

                                            if (error) {
                                                success = false;
                                                callback(&success);
                                            } else {
                                                [self incrementKey:@"membersCount"];
                                                [self saveEventually];
                                                success = true;
                                                callback(&success);
                                            }
                                        }];

}



-(void)addHabitToTribeWithName:(NSString *)name andBlock:(void(^)(bool success))callback {
    
    // cloud code to add habit and create activites for each user in tribe
    [PFCloud callFunctionInBackground:@"addActivitiesToUsersOfTribe"
                       withParameters:@{@"tribeObjectID":self.objectId,
                                        @"newHabitName":name}
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                    
                                    if (error) {
                                        callback(false);
                                    } else {
                                        callback(true);
                                    }
                                }];
    
}
#pragma mark - Handle On Hold Members

-(void)addUserToTribeOnHold:(PFUser *)user withBlock:(void(^)(BOOL * success))callback {
    __block BOOL success;
    
    // add user to tribe on hold relation
    PFRelation * onHoldMembersRelation = [self relationForKey:@"onHoldMembers"];
    [onHoldMembersRelation addObject:user];
    
    // add tribe to user's onholdtribes
    [user addObject:self forKey:@"onHoldTribes"];
    
    
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
        if (error) {
            success = false;
            callback(&success);
        } else {
            
            [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                
                if (succeeded && !error) {
                    NSString * pushMessage = [NSString stringWithFormat:@"%@ wants to join %@. Tap on your Tribe's menu to accept or decline 👍",user[@"username"],self[@"name"]];
                    [[User currentUser] sendPushFromMemberToMember:self[@"admin"] withMessage:pushMessage habitName:@"" andCategory:@"NEW_PENDING_MEMBER"];
                    
                    success = true;
                    callback(&success);
                } else {
                    success = false;
                    callback(&success);
                }
                
            }];
            

        }
    }];
}
-(void)confirmOnHoldUser:(User *)user withBlock:(void(^)(BOOL * success))callback {
    // remove from on hold pfrelation
    PFRelation * onHoldRelationToTribe = [self relationForKey:@"onHoldMembers"];
    [onHoldRelationToTribe removeObject:user];
    [self.onHoldMembers removeObject:user];
    [self saveEventually];

    
    
    // removes tribe from user's on hold tribes array
    [PFCloud callFunctionInBackground:@"confirmUserToTribe" withParameters:
                                     @{@"tribeId":self.objectId,
                                       @"userId":user.objectId}
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                   

                                }];
    
    
    __block BOOL confirmedUserComplete;
    // add to regular member
    [self addUserToTribe:user withBlock:^(BOOL *success) {
        
        if (success) {
            
            
            NSString * pushMessage = [NSString stringWithFormat:@"You've been accepted to %@. Start motivating your Tribe now!", self[@"name"]];
            // send push to member
            [[User currentUser] sendPushFromMemberToMember:user withMessage:pushMessage habitName:@"" andCategory:@""];
            confirmedUserComplete = true;
            callback(&confirmedUserComplete);
        } else {
            confirmedUserComplete = false;
            callback(&confirmedUserComplete);
        }
        
    }];
}
-(void)declineOnHoldUser:(User *)user {
    
    // removes tribe from user's on hold tribes array
    [PFCloud callFunctionInBackground:@"confirmUserToTribe" withParameters:
     @{@"tribeId":self.objectId,
       @"userId":user.objectId}
                                block:^(id  _Nullable object, NSError * _Nullable error) {
                                    
                                    
                                }];
    
    // remove from on hold pfrelation
    PFRelation * onHoldRelationToTribe = [self relationForKey:@"onHoldMembers"];
    [onHoldRelationToTribe removeObject:user];
    [self.onHoldMembers removeObject:user];
    [self saveEventually];
}

-(void)checkForPendingMemberswithBlock:(void(^)(BOOL success))callback {
    
    PFRelation * onHoldMembersRelation = [self relationForKey:@"onHoldMembers"];
    PFQuery * query = [onHoldMembersRelation query];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects.count > 0) {
            self.onHoldMembers = [NSMutableArray arrayWithArray:objects];
            callback(true);
        } else {
            callback(false);
        }
    }];
}


@end
