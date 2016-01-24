//
//  User.m
//  Tribes
//
//  Created by German Espitia on 1/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "User.h"
#import <Parse/PFObject+Subclass.h>

@implementation User


#pragma mark - Parse required methods


+ (void)load {
    [self registerSubclass];
}


@end
