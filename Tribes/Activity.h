//
//  Activity.h
//  Tribes
//
//  Created by German Espitia on 1/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parse.h"

@interface Activity : PFObject<PFSubclassing>

+(NSString *)parseClassName;
+(void)load;

@property (nonatomic, strong) NSMutableArray * completionDates;
@property int weekCompletions;

-(void)completeForToday;
-(BOOL)completedForDay;

@end
