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
            [self lookUpMatches];
            NSLog(@"accepted status");
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
    return 1;
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
    
    PFUser * user = [matchedContacts objectAtIndex:indexPath.row];
    
    switch (indexPath.section) {
        case 0:
            // matched users
            cell.textLabel.text = user.objectId;
            break;
        case 1:
        
            break;
            
        default:
            break;
    }
    
    return cell;
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
    
    
    // Objective-C
    DGTSession *userSession = [Digits sharedInstance].session;
    DGTContacts *contacts = [[DGTContacts alloc] initWithUserSession:userSession];
    
    [contacts lookupContactMatchesWithCursor:nil completion:^(NSArray *matches, NSString *nextCursor, NSError *error) {
        // matches is an Array of DGTUser objects.
        // Use nextCursor in a follow-up call to this method to offset the results.
        NSLog(@"%@", matches);
        [self fetchMatchedUsers:matches];
    }];
}

-(void)fetchMatchedUsers:(NSArray *)arrayOfMatchedDGTUsers {
    


    // iterate through matched Digits Users and fetch the PFUser associated via digitUser.userId
    for (DGTUser * user in arrayOfMatchedDGTUsers) {
        
        NSLog(@"user to find: %@", user);
        
        // query
        PFQuery * query = [PFUser query];
        [query whereKey:@"digitsUserId" equalTo:user.userID];
        
        // add to data source
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            NSLog(@"obkdfsdf   :%@", objects);
        }];
         
         
        [matchedContacts addObject:[query getFirstObject]];
        NSLog(@"MATCHED CONTACTS: %@", matchedContacts);
        
        // reload table
        [self.tableView reloadData];
    }
}

@end
