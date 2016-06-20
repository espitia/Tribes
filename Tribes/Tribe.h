//
//  Tribe.h
//  Tribes
//
//  Created by German Espitia on 1/14/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parse.h"
#import "Habit.h"

@interface Tribe : PFObject<PFSubclassing>

+(NSString *)parseClassName;
+(void)load;

// adding to the tribe
-(void)addUserToTribe:(PFUser *)user withBlock:(void(^)(BOOL * success))callback;
-(void)addHabitToTribeWithName:(NSString *)name andBlock:(void(^)(bool success))callback;

// on hold users
-(void)addUserToTribeOnHold:(PFUser *)user withBlock:(void(^)(BOOL * success))callback;
-(void)confirmOnHoldUser:(PFUser *)user withBlock:(void(^)(BOOL * success))callback;;
-(void)declineOnHoldUser:(PFUser *)user;
-(void)checkForPendingMemberswithBlock:(void(^)(BOOL success))callback;


@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSMutableArray * onHoldMembers;
@property (nonatomic, strong) NSMutableArray * habits;
@property (nonatomic, strong) NSNumber * membersCount;
@property BOOL privacy;



@end
