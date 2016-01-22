//
//  AddFriendsTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/14/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "AddFriendsTableViewController.h"
#import <DigitsKit/DigitsKit.h>
#import "Parse.h"


@interface AddFriendsTableViewController () {
    NSMutableArray * matchedContacts;
}

@end

@implementation AddFriendsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //init instance variables
    matchedContacts = [[NSMutableArray alloc] init];
}
-(void)viewWillAppear:(BOOL)animated {

    // check authorization access to address book status
    switch ([DGTContacts contactsAccessAuthorizationStatus]) {
        case 0:
            NSLog(@"pending status");
            [self askForUserPermissionOfAddressBook];

            break;
        case 1:
            NSLog(@"denied status");
            [self askForUserPermissionOfAddressBook];

            break;
        case 2:
            NSLog(@"accepted status");
            [self askForUserPermissionOfAddressBook];
            break;
            
        default:
            break;
    }
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return matchedContacts.count;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            return @"Users already on Tribes:";
            break;
        case 1:
            return @"Invite your friends to join!";
            break;
        default:
            return @"";
            break;
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Friend" forIndexPath:indexPath];
    
    if (matchedContacts.count == 0) {
        return cell;
    }
    
    PFUser * user = [matchedContacts objectAtIndex:indexPath.row];

    switch (indexPath.section) {
        case 0:
            // matched users
            cell.textLabel.text = user[@"username"];
            break;
        case 1:
        
            break;
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"selected");
    
    // show check
    
    // add user to tribe's members relation
    PFUser * user = [matchedContacts objectAtIndex:indexPath.row];
    PFRelation * memberRelationToTribe = [_tribe relationForKey:@"members"];
    [memberRelationToTribe addObject:user];
    
    // add tribe to user's tribe
    [user addObject:_tribe forKey:@"tribes"];

    // create activity
    PFObject * activity = [PFObject objectWithClassName:@"Activity"];
    
    // add user to activity
    [activity setObject:user forKey:@"createdBy"];
    
    // add activity to user
    [user addObject:activity forKey:@"activities"];
    
    // set tribe in activity
    [activity setObject:_tribe forKey:@"tribe"];
    
    // cloud code to add tribe and activity to user (then save user)
    [PFCloud callFunctionInBackground:@"addTribeAndActivityToUser"
                       withParameters:@{@"tribeObjectID":@"7wKq3nu14E",
                                        @"userObjectID":user.objectId
                                        } block:^(id  _Nullable object, NSError * _Nullable error) {
                                            NSLog(@"object: %@", object);
                                            [self.tableView reloadData];
                                        }];
    // save tribe
    [_tribe saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
        // save user
        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            
            // send back to tribe/allow to add more users
            
            // save activity
            [activity saveInBackground];
        }];
    }];
}

#pragma mark - Helper methods

-(void)askForUserPermissionOfAddressBook {
    // ask for address book permission
    DGTSession *userSession = [Digits sharedInstance].session;
    DGTContacts *contacts = [[DGTContacts alloc] initWithUserSession:userSession];
    
    [contacts startContactsUploadWithCompletion:^(DGTContactsUploadResult *result, NSError *error) {
        if (!error) {
            
            if (result != nil) {
                
                // look for matches
                [self lookUpMatches];
            }
            
        } else {
            
            //analyze what the error is and handle it with alert views for now.
            // more info on errors here: https://docs.fabric.io/ios/digits/find-friends.html#permissions-control-flow
        }
    }];
}

-(void)lookUpMatches {
    
    
    // search for matches
    DGTSession *userSession = [Digits sharedInstance].session;
    DGTContacts *contacts = [[DGTContacts alloc] initWithUserSession:userSession];
    
    
    [contacts lookupContactMatchesWithCursor:nil completion:^(NSArray *matches, NSString *nextCursor, NSError *error) {
        
        if (error) { NSLog(@"error: %@", error); }

        // remove duplicates
        
        [self fetchMatchedUsers:matches];
    }];
}

-(void)fetchMatchedUsers:(NSArray *)arrayOfMatchedDGTUsers {
    


    // iterate through matched Digits Users and fetch the PFUser associated via digitUser.userId
    for (DGTUser * user in arrayOfMatchedDGTUsers) {
        
        // query
        PFQuery * query = [PFUser query];
        [query whereKey:@"digitsUserId" equalTo:user.userID];
        
        // add to data source
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            [matchedContacts addObject:objects[0]];
            [self.tableView reloadData];
        }];

    }
}

@end
