//
//  Activity.m
//  Tribes
//
//  Created by German Espitia on 1/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "Activity.h"
#import <Parse/PFObject+Subclass.h>


@implementation Activity


#pragma mark - Parse required methods

+ (NSString *)parseClassName {
    return @"Activity";
}

+ (void)load {
    [self registerSubclass];
}

@end
