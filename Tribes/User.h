//
//  User.h
//  Tribes
//
//  Created by German Espitia on 1/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "Tribe.h"
#import "Habit.h"
#import "Activity.h"

@interface User : PFUser <PFSubclassing>

extern int COMPLETED_HABIT_XP;
extern int RECEIVED_APPLAUSE_XP;

// required parse method
+(void)load;

// LOADING METHODS
-(void)loadTribesWithBlock:(void(^)(bool success))callback;

// UPDATING MEHTODS
-(void)updateMemberActivitiesForAllTribesWithBlock:(void(^)(bool success))callback;
-(void)updateTribesWithBlock:(void(^)(bool success))callback;
-(void)checkForNewDataWithBlock:(void(^)(bool tribes, bool habits, bool members))callback;

// create a tribe
-(void)createNewTribeWithName:(NSString *)name  withBlock:(void(^)(BOOL success))callback;

//removing user from tribe
-(void)removeFromTribe:(Tribe *)tribeToRemoveFrom;

// handling activities w/ habits
-(Activity *)activityForHabit:(Habit *)habit;

// handling activities
-(void)completeActivityForHabit:(Habit *)habit inTribe:(Tribe *)tribe;
-(void)removeAllHibernationFromActivities;

// dealing with pushes
-(void)sendMotivationToMember:(User *)member inTribe:(Tribe *)tribe forHabit:(Habit *)habit withBlock:(void (^)(BOOL))callback;
-(void)sendPushFromMemberToMember:(User *)member withMessage:(NSString *)msg andCategory:(NSString *)category withBlock:(void (^)(BOOL * success))callback;
-(void)sendPushFromMemberToMember:(User *)member withMessage:(NSString *)msg andCategory:(NSString *)category;

// dealing with xp and levels
-(void)addXp:(int)xpToAdd;
-(void)addReceivedApplauseXp;

@property (nonatomic, strong) NSMutableArray * tribes;
@property (nonatomic, strong) NSMutableArray * activities;
@property int lvl;
@property int xp;
@property BOOL loadedInitialTribes;

@end
