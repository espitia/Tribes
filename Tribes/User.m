//
//  User.m
//  Tribes
//
//  Created by German Espitia on 1/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "User.h"
#import "Tribe.h"
#import <Parse/PFObject+Subclass.h>

@implementation User

@dynamic tribes;
@synthesize loadedInitialTribes;

#pragma mark - Parse required methods

+ (void)load {
    [self registerSubclass];
}


#pragma mark - Loading Tribes

/**
* Loads current tribe objects from current user. Before doing so, it also fetches current user to make sure we have the latest info on which tribes user is in.
 *
 */

-(void)loadTribesWithBlock:(void(^)(void))callback {
    
    // update user in case other users added him/her to a tribe
    [self fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"error loading user: %@", error);
        } else {
            
            // placeholder array to add fetched tribes
            NSMutableArray * loadedTribesPlaceholder = [[NSMutableArray alloc] init];
            
            // iterate through each tribe
            for (Tribe * tribe in self.tribes) {
            
                // load tribe objects
                [tribe fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    
                    if (error) {
                        NSLog(@"error loading tribes: %@", error);
                    } else {
                        
                        // add to placeholder array
                        [loadedTribesPlaceholder addObject:object];
                        
                        // when all tribes have been loaded
                        if (loadedTribesPlaceholder.count == self.tribes.count) {
                            
                            // replae old array of pointers for real tribes
                            self.tribes = loadedTribesPlaceholder;
                            self.loadedInitialTribes = TRUE;
                            callback();
                        }
                    }
                }];
            }
        }
    }];

}

@end
