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
#import "Activity.h"

@interface User : PFUser <PFSubclassing>

extern int COMPLETED_HABIT_XP;
extern int RECEIVED_APPLAUSE_XP;


// loading methods
+(void)load;
-(void)loadTribesWithBlock:(void(^)(void))callback;

//adding user to tribe
-(void)addTribeWithName:(NSString *)name;

// handling activities
-(void)completeActivityForTribe:(Tribe *)tribe;
-(Activity *)activityForTribe:(Tribe *)tribe;

// delaing with pushes
-(void)sendMotivationToMember:(User *)member inTribe:(Tribe *)tribe withBlock:(void (^)(BOOL))callback;
-(void)sendPushFromMemberToMember:(User *)member withMessage:(NSString *)msg andCategory:(NSString *)category withBlock:(void (^)(BOOL * success))callback;


// dealing with xp and levels
-(void)addXp:(int)xpToAdd;
-(void)addReceivedApplauseXp;
-(NSString *)lvlAndXpDescription;

@property (nonatomic, strong) NSMutableArray * tribes;
@property (nonatomic, strong) NSArray * activities;
@property BOOL loadedInitialTribes;



@end
