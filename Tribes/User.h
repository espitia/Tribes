//
//  User.h
//  Tribes
//
//  Created by German Espitia on 1/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface User : PFUser <PFSubclassing>

+(void)load;

@end
