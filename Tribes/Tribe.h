//
//  Tribe.h
//  Tribes
//
//  Created by German Espitia on 1/14/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parse.h"

@interface Tribe : PFObject<PFSubclassing>

+(NSString *)parseClassName;
+(void)load;

-(void)loadMembersOfTribeWithActivitiesWithBlock:(void(^)(void))callback;
-(BOOL)userAlreadyInTribe:(PFUser *)user;
-(void)addUserToTribe:(PFUser *)user withBlock:(void(^)(BOOL * success))callback;

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSMutableArray * membersAndActivities;
@property (nonatomic, strong) NSMutableArray * members;
@property (nonatomic, strong) NSMutableArray * activities;



@end
