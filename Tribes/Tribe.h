//
//  TribeHandler.h
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

-(NSMutableArray *)loadMembersOfTribeWithActivitiesWithBlock:(void(^)(void))callback;

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) PFRelation * members;


@end
