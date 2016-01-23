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
//            [self askForUserPermissionOfAddressBook];
            [self lookUpMatches];
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

    // disable user interaction so user doesn't add friend twice
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.userInteractionEnabled = false;
    
    // add loading spinner
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(0, 0, 24, 24);
    cell.accessoryView = spinner;
    [spinner startAnimating];
    
    // weak self to not have any issues to present alert view
    __unsafe_unretained typeof(self) weakSelf = self;
    
    // alert controller
    UIAlertController * __block alert;
    UIAlertAction * __block defaultAction;
    
    // message to go in alert view
    NSString * __block alertTitle = @"";
    NSString * __block alertMessage = @"";
    
    // add user to tribe's members relation
    PFUser * user = [matchedContacts objectAtIndex:indexPath.row];
    [_tribe addUserToTribe:user withBlock:^(BOOL * success) {
        
        // successfully added friend
        if (success) {
            
            NSLog(@"succesfully added user");
            alertTitle = @"✅✅✅";
            alertMessage = @"Successfully added friend.\nInviting friends: Major 🔑!";
            
             defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self.navigationController popViewControllerAnimated:true];
                                                                  }];
        // failed to add friend
        } else {
            NSLog(@"failed to add user");
            alertTitle = @"❌❌❌";
            alertMessage = @"Something went wrong 😬.\n Try again.";
        }
        
        // stop animating spinner
        [spinner stopAnimating];
        
        // finish alert set up
        alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                    message:alertMessage
                                             preferredStyle:UIAlertControllerStyleAlert];
        
        
        // add action (if success, pop to tribe VC)
        [alert addAction:defaultAction];
        
        // present alert
        [weakSelf presentViewController:alert animated:YES completion:nil];

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

        // get matching PFUsers for corresponding digitsID key
        [self fetchMatchedUsers:matches];
    }];
}

-(void)fetchMatchedUsers:(NSArray *)arrayOfMatchedDGTUsers {
    
    // iterate through matched Digits Users and fetch the PFUser associated via digitUser.userId
    for (DGTUser * user in arrayOfMatchedDGTUsers) {
        
        // query
        PFQuery * query = [PFUser query];
        [query whereKey:@"digitsUserId" equalTo:user.userID];
        
        // fetch users by digitsID
        [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable user, NSError * _Nullable error) {
            
            // check if matchedContacts (w/ PFUsers) already has contact
            if (![self contactAlreadyExists:(PFUser *)user]) {
            
                if (![_tribe userAlreadyInTribe:(PFUser *)user]) {
                    // if not, add user to matchedContacts
                    [matchedContacts addObject:user];
                    [self.tableView reloadData];
                }
            }
        }];
        
    }
}

// in case digits brings back two ids pointing to the same PFUser, thus, fethcing two PFUsers
-(BOOL)contactAlreadyExists:(PFUser *)user {
    return ([matchedContacts containsObject:user]) ? true : false;
}

@end
