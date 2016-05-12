//
//  AddTribeTableViewController.m
//  Tribes
//
//  Created by German Espitia on 1/10/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "TribesTableViewController.h"
#import "AddTribeTableViewController.h"
#import "Parse.h"
#import "Tribe.h"
#import "User.h"
#import "SCLAlertView.h"
#import <DigitsKit/DigitsKit.h>
#import <Crashlytics/Crashlytics.h>


@interface AddTribeTableViewController () {
    User * currentUser;
    UITextField * tribeNameTextField;
    UIBarButtonItem * createTribeButton;
    NSMutableArray * matchedContacts;
    NSMutableArray * tribesToJoin;
    BOOL loadingTribesToJoin;
}

@end

@implementation AddTribeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // right button to create Tribe
    createTribeButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(createTribe)];
    [self.navigationItem setRightBarButtonItem:createTribeButton];
    
    // set current user
    currentUser = [User currentUser];

    // initialize textfield
    tribeNameTextField = [[UITextField alloc] init];
    
    //init instance variables
    matchedContacts = [[NSMutableArray alloc] init];
    tribesToJoin = [[NSMutableArray alloc] init];
    loadingTribesToJoin = true;
    

}

-(void)viewDidAppear:(BOOL)animated {
    // check authorization access to address book status and look up matches to fetch tribes to join
    switch ([DGTContacts contactsAccessAuthorizationStatus]) {
        case 0:
        case 1: {
            
            NSLog(@"pending/denied status");
            SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
            [alert addButton:@"OK 👌" actionBlock:^{
                [self askForUserPermissionOfAddressBook];
            }];
            [alert showNotice:@"Join a Tribe" subTitle:@"In order to join a friend's Tribe, we need permission to look them up through your address book." closeButtonTitle:nil duration:0.0];
            
        }
            break;
        case 2: {
            NSLog(@"accepted status");
            [self lookUpMatches];
        }
            break;
            
        default:
            break;
    }
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return (tribesToJoin.count == 0) ? 1 : tribesToJoin.count;
            break;
        default:
            break;
    }
    return 100;}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 100;
            break;
        case 1:
            return 150;
            break;
        default:
            break;
    }
    return 100;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Create your own Tribe:";
            break;
        case 1:
            return @"Or join your friend's Tribes:";
            break;
        default:
            break;
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TribeCell" forIndexPath:indexPath];
    
    switch (indexPath.section) {
        case 0:
            [self configureCellForCreateTribeCell:cell];
            break;
        case 1:
            [self configureCellForJoinFriendsTribeCell:cell withIndexPath:indexPath] ;
        default:
            break;
    }


    
    return cell;
}

#pragma mark - Configure Cells

-(void)configureCellForCreateTribeCell:(UITableViewCell *)cell {
    // add uitextfield for name fo tribe
    CGRect activityNameFrame = CGRectMake(15,
                                          cell.frame.origin.y - 55,
                                          cell.frame.size.width,
                                          cell.frame.size.height);
    [tribeNameTextField setFrame:activityNameFrame];
    tribeNameTextField.placeholder = @"e.g. The Squad 😎";
    [tribeNameTextField setFont:[UIFont systemFontOfSize:40]];
    [cell.contentView addSubview:tribeNameTextField];
    
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;

    
}

-(void)configureCellForJoinFriendsTribeCell:(UITableViewCell *)cell withIndexPath:(NSIndexPath *)indexPath {
    


    if (loadingTribesToJoin) {
        [cell.textLabel setFont:[UIFont systemFontOfSize:20]];
        [cell.textLabel setText:@"Looking for friend's Tribes... 🕵"];
        cell.detailTextLabel.text = nil;
        return;
    }

    if (tribesToJoin.count == 0) {
        [cell.textLabel setFont:[UIFont systemFontOfSize:20]];
        cell.textLabel.text = @"We couldn't find any friend's Tribe 😞";
        [cell.detailTextLabel setFont:[UIFont systemFontOfSize:20]];
        cell.detailTextLabel.text = @"Create your own! ☝️😄";
        return;
    }
    
    
    
    
    
    //tribe dictionary contains two keys: tribe for tribe obj and memberFriends for an array of the names of members in tribe
    NSDictionary * tribe = [tribesToJoin objectAtIndex:indexPath.row];
    NSLog(@"%@", tribe);
    [cell.textLabel setFont:[UIFont systemFontOfSize:40]];
    cell.textLabel.text = tribe[@"tribe"][@"name"];
    
    NSString * membersInTribeText;
    if ([tribe[@"memberFriends"] count] > 1) {
        membersInTribeText = [NSString stringWithFormat:@"%@, %@ and others are in this Tribe!", tribe[@"memberFriends"][0],tribe[@"memberFriends"][1]];
    } else {
        membersInTribeText = [NSString stringWithFormat:@"%@ is in this Tribe!", tribe[@"memberFriends"][0]];
    }
    [cell.detailTextLabel setFont:[UIFont systemFontOfSize:16]];
    cell.detailTextLabel.text = membersInTribeText;
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

#pragma mark - TableView Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    // tapped on a friends tribe!
    if (indexPath.section == 1 && !loadingTribesToJoin) {
        
        Tribe * tribe = [tribesToJoin objectAtIndex:indexPath.row][@"tribe"];

        if (tribe) {
           
            // if user is already in tribe, dont add, alert
            if ([currentUser.tribes containsObject:tribe]) {
                SCLAlertView * errorAlert = [[SCLAlertView alloc] initWithNewWindow];
                [errorAlert showError:@"Already in Tribe!" subTitle:@"Looks like you already belong to this Tribe!" closeButtonTitle:@"Oh... 🙄" duration:0.0];
            } else {
                
                // if user not in tribe, show alert to confirm they want to join
                SCLAlertView * confirmAlert = [[SCLAlertView alloc] initWithNewWindow];
                
                // message to show in confirm alert
                NSString * msg = [NSString stringWithFormat:@"Are you sure you want to join %@?", tribe[@"name"]];
               
                // button with action of joinign tribe on confirm alert
                [confirmAlert addButton:@"YES 😁" actionBlock:^{
                    
                    // if user is not in tribe, show waiting alert (adding tribe)
                    SCLAlertView * waitingAlert = [[SCLAlertView alloc] initWithNewWindow];
                    [waitingAlert showWaiting:@"Joining Tribe 😎" subTitle:@"It will be just one second ..." closeButtonTitle:nil duration:0.0];
                    
                    [tribe addUserToTribe:[User currentUser] withBlock:^(BOOL *success) {
                        
                        [waitingAlert hideView];
                        
                        // if successfully added user to tribe
                        if (success) {
                            
                            // log event
                            [Answers logCustomEventWithName:@"Joined Friend's Tribe" customAttributes:@{@"success":@true}];
                            
                            
                            SCLAlertView * successAlert = [[SCLAlertView alloc] initWithNewWindow];
                            NSString * successMessage = [NSString stringWithFormat:@"You have now joined %@! Make us proud ✊", tribe[@"name"]];
                            [successAlert addButton:@"Will do!" actionBlock:^{
                                [self.navigationController popViewControllerAnimated:true];
                            }];
                            [successAlert showSuccess:@"Success 😃" subTitle:successMessage  closeButtonTitle:nil duration:0.0];
                        } else {
                            
                            // log event
                            [Answers logCustomEventWithName:@"Joined Friend's Tribe" customAttributes:@{@"success":@false}];
                            
                            SCLAlertView * errorAlert = [[SCLAlertView alloc]  initWithNewWindow];
                            [errorAlert showError:@"Oh oh 😬" subTitle:@"There was an error while joining the Tribe 🤔 Please try again." closeButtonTitle:@"OK" duration:0.0];
                        }
                    }];

                }];
                [confirmAlert showInfo:@"Confirm 📝" subTitle:msg closeButtonTitle:@"Never mind.." duration:0.0];
                
                
                
            }
        } else {
            NSLog(@"error getting tribe to add");
            // log event
            [Answers logCustomEventWithName:@"Joined Friend's Tribe" customAttributes:@{@"success":@true}];
        }

    }
}

#pragma mark - Actions

-(void)createTribe {
    
    // disable button to not allow duplicates
    createTribeButton.enabled = false;
    if (![tribeNameTextField.text isEqualToString:@""]) {
        
        if (currentUser) {
            
            // resign keyboard for asthetics with alert
            [tribeNameTextField resignFirstResponder];
            
            // init waiting alert
            SCLAlertView * waitingAlert = [[SCLAlertView alloc] initWithNewWindow];
            SCLAlertView * stillWaitingAlert = [[SCLAlertView alloc] initWithNewWindow];
            
            // show waiting alerts
            [waitingAlert showWaiting:@"Creating new Tribe 🔨" subTitle:@"It will be just a second.. ⏲" closeButtonTitle:nil duration:6.0];
            [waitingAlert alertIsDismissed:^{
                [stillWaitingAlert showWaiting:@"Taking a bit long.. 😬" subTitle:@"Just a few more seconds.. ⏲" closeButtonTitle:nil duration:0.0];
            }];

            // create the tribe
            [currentUser createNewTribeWithName:tribeNameTextField.text withBlock:^(BOOL success) {
                
                // remove waiting alerts
                [waitingAlert hideView];
                [stillWaitingAlert hideView];
                
                if (success) {
                    
                    // log event
                    [Answers logCustomEventWithName:@"Created Tribe" customAttributes:@{@"success":@true}];
                    
                    // send tribe back to main viewcontroller
                    [self performSegueWithIdentifier:@"unwindFromAddTribe" sender:self];
                } else {
                    
                    // log event
                    [Answers logCustomEventWithName:@"Created Tribe" customAttributes:@{@"success":@false}];
                    
                    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
                    [alert addButton:@"OK" actionBlock:^{
                        [tribeNameTextField becomeFirstResponder];
                        createTribeButton.enabled = true;
                    }];
                    [alert showError:@"😬" subTitle:@"There was an error creating your Tribe. Please try again." closeButtonTitle:nil duration:0.0];
                }

            }];

        } else {
            NSLog(@"error adding tribe, currentUser = nil.");
            createTribeButton.enabled = true;
        }
    } else {
        
        [tribeNameTextField resignFirstResponder];
        
        SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
        [alert addButton:@"OK" actionBlock:^{
            [tribeNameTextField becomeFirstResponder];
            createTribeButton.enabled = true;
        }];
        [alert showError:@"❌" subTitle:@"Make sure your Tribe has a name" closeButtonTitle:nil duration:0.0];
    }

}


#pragma mark - Contacts handling

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
            
            SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
            [alert showError:@"Oh oh 😬" subTitle:@"There was an error searching for Friends, please try again" closeButtonTitle:@"OK" duration:0.0];
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
        
        if (matches.count > 0 && !error) {
            // get matching PFUsers for corresponding digitsID key
            [self fetchMatchedUsers:matches];
        } else if (matches.count == 0 && !error) {
            NSLog(@"%@", error);
            loadingTribesToJoin = false;
            [self.tableView reloadData];
        } else {
            NSLog(@"error: %@", error);
            SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
            [alert showError:@"Oh oh 😬" subTitle:@"There was an error searching for Friends, please try again" closeButtonTitle:@"OK" duration:0.0];
        }

        

    }];
}

-(void)fetchMatchedUsers:(NSArray *)arrayOfMatchedDGTUsers {
    __block int counter = 0;

    // iterate through matched Digits Users and fetch the PFUser associated via digitUser.userId
    for (DGTUser * user in arrayOfMatchedDGTUsers) {
        // query
        PFQuery * query = [PFUser query];
        [query whereKey:@"digitsUserId" equalTo:user.userID];
        
        // fetch users by digitsID
        [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable user, NSError * _Nullable error) {
            counter++;

            if (user && !error) {
                // check if matchedContacts (w/ PFUsers) already has contact
                if (![self contactAlreadyExists:(PFUser *)user]) {
                    // if not, add user to matchedContacts
                    [matchedContacts addObject:user];
                }
            } else {
                NSLog(@"error finding PFUser for DGTUser.");
            }
            if (counter == arrayOfMatchedDGTUsers.count) {
                [self findTribeForMatchedUsers];
            }

        }];
        
    }
}

// in case digits brings back two ids pointing to the same PFUser, thus, fethcing two PFUsers
-(BOOL)contactAlreadyExists:(PFUser *)user {
    return ([matchedContacts containsObject:user]) ? true : false;
}

-(void)findTribeForMatchedUsers {
    
    NSMutableArray * rawArrayOfTribes = [[NSMutableArray alloc] init];
    
    // add all tribes to which matched users belong to
    for (User * matchedUser in matchedContacts) {
        for (Tribe * tribe in matchedUser.tribes) {
            if (![rawArrayOfTribes containsObject:tribe]) {
                [rawArrayOfTribes addObject:tribe];
            }
        }
    }
    
    
    //add all members of selected tribe to tribedictionary in order to display in detail text on table
    __block int counter = 0;

    for (Tribe * tribe in rawArrayOfTribes) {

        NSMutableArray * membersInTribe = [[NSMutableArray alloc] init];

        [tribe fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            counter++;

            
            for (User * matchedUser in matchedContacts) {
                if ([matchedUser.tribes containsObject:tribe]) {
                    //belongs to tribe
                    [membersInTribe addObject:matchedUser[@"name"]];
                }
            }
            NSDictionary * tribeToJoin = @{@"tribe":tribe,
                                           @"memberFriends":membersInTribe};
            [tribesToJoin addObject:tribeToJoin];
            
            if (counter == rawArrayOfTribes.count) {
                loadingTribesToJoin = false;
                [self.tableView reloadData];
            }
    
        }];
        
        
    }



    

    
}



@end
