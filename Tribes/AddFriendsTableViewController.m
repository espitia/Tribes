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
#import "SCLAlertView.h"
#import "User.h"
#import "APAddressBook.h"
#import "APContact.h"


@interface AddFriendsTableViewController () {
    NSMutableArray * matchedContacts;
    NSArray * addressBookContacts;
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
        case 2: {
            NSLog(@"accepted status");
            [self lookUpMatches];
            
            [self setUpAddressBook];
        }
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
    switch (section) {
        case 0:
            return matchedContacts.count;
            break;
        case 1:
            return addressBookContacts.count;
            break;
        default:
            break;
    }
    return 0;
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
    
    PFUser * user;
    APContact * contact;
    
    switch (indexPath.section) {
        case 0:
            if (matchedContacts.count > 0) {
                user = [matchedContacts objectAtIndex:indexPath.row];
                cell.textLabel.text = user[@"name"];
            }
            break;
        case 1:
            if (addressBookContacts.count > 0) {
                contact = [addressBookContacts objectAtIndex:indexPath.row];
                cell.textLabel.text = [self contactName:contact];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
        default:
            break;
    }

    
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // ADD USERS TO A TRIBE
    if (indexPath.section == 0) {
        [self addUserToTribeFromIndexPath:indexPath];
    }
    // SEND TEXT TO INVITE USERS
    else if (indexPath.section == 1) {
        [self sendUserTextFromIndexPath:indexPath];
    }




}

-(void)addUserToTribeFromIndexPath:(NSIndexPath *)indexPath {
    // disable user interaction so user doesn't add friend twice
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.userInteractionEnabled = false;
    
    // add loading spinner
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(0, 0, 24, 24);
    cell.accessoryView = spinner;
    [spinner startAnimating];
    
    
    SCLAlertView * waitingAlert = [[SCLAlertView alloc] initWithNewWindow];
    [waitingAlert showWaiting:@"Adding buddy.. 😀" subTitle:@"It will just take a moment 👌" closeButtonTitle:nil duration:0.0];
    
    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];

    // add user to tribe's members relation
    PFUser * user = [matchedContacts objectAtIndex:indexPath.row];
    [_tribe addUserToTribe:user withBlock:^(BOOL * success) {
        
        
        // successfully added friend
        if (success) {
            [_tribe updateTribeWithBlock:^(bool success) {
                [waitingAlert hideView];
                if (success) {
                    
                    SCLAlertView * successAlert = [[SCLAlertView alloc] initWithNewWindow];
                    [successAlert addButton:@"AWESOME 😁" actionBlock:^{
                        [self.navigationController popToRootViewControllerAnimated:true];
                    }];
                    [successAlert showSuccess:@"Success 😄" subTitle:@"You've successfully added your buddy!" closeButtonTitle:nil duration:0.0];
                    
                    
                } else {
                    SCLAlertView * errorAlert = [[SCLAlertView alloc] initWithNewWindow];
                    [errorAlert showError:@"Oh oh!" subTitle:@"There was an error adding your friend. Please try again" closeButtonTitle:@"OK" duration:0.0];
                }
            }];

        // failed to add friend
        } else {
            
            [waitingAlert hideView];
            
            [alert showError:@"❌❌❌" subTitle:@"Something went wrong 😬.\n Try again." closeButtonTitle:@"OK" duration:0.0];
            NSLog(@"failed to add user");
        }
        
        // stop animating spinner
        [spinner stopAnimating];

    }];
}



-(void)sendUserTextFromIndexPath:(NSIndexPath *)indexPath {
    APContact * contact = [addressBookContacts objectAtIndex:indexPath.row];
    NSString * number = [self contactPhones:contact];
    
    MFMessageComposeViewController *controller =
    [[MFMessageComposeViewController alloc] init];
    
    if([MFMessageComposeViewController canSendText]) {
        NSString *str= @"Hey! I am trying to get the whole squad on Tribes ✊ It's an app to make sure we get our stuff done 😎 Download it here: http://bit.ly/UseTribes";
        controller.body = str;
        controller.recipients = [NSArray arrayWithObjects:
                                 number, nil];
        controller.messageComposeDelegate = self;
        [self presentViewController:controller animated:true completion:nil];
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

#pragma mark - APContacts

-(void)setUpAddressBook {
    
    // init address book object
    APAddressBook *addressBook = [[APAddressBook alloc] init];
    
    // set address book fields, sorters and filters
    addressBook.fieldsMask = APContactFieldName | APContactFieldPhonesOnly;
    addressBook.sortDescriptors = @[
                                    [NSSortDescriptor sortDescriptorWithKey:@"name.firstName" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"name.lastName" ascending:YES]];
    addressBook.filterBlock = ^BOOL(APContact *contact)
    {
        return contact.phones.count > 0;
    };
    
    
    // load contacts
    [addressBook loadContacts:^(NSArray <APContact *> *contacts, NSError *error)
     {
         // hide activity
         if (!error)
         {
             // do something with contacts array
             addressBookContacts = [NSArray arrayWithArray:contacts];
             [self.tableView reloadData];
         }
         else
         {
             // show error
             NSLog(@"error loading address book contacts");
         }
     }];
}

- (NSString *)contactName:(APContact *)contact
{
    if (contact.name.compositeName)
    {
        return contact.name.compositeName;
    }
    else if (contact.name.firstName && contact.name.lastName)
    {
        return [NSString stringWithFormat:@"%@ %@", contact.name.firstName, contact.name.lastName];
    }
    else if (contact.name.firstName || contact.name.lastName)
    {
        return contact.name.firstName ?: contact.name.lastName;
    }
    else
    {
        return @"Untitled contact";
    }
}

- (NSString *)contactPhones:(APContact *)contact
{
    if (contact.phones.count > 0)
    {
        NSMutableString *result = [[NSMutableString alloc] init];
        for (APPhone *phone in contact.phones)
        {
            NSString *string = phone.localizedLabel.length == 0 ? phone.number :
            [NSString stringWithFormat:@"%@ (%@)", phone.number,
             phone.localizedLabel];
            [result appendFormat:@"%@, ", string];
        }
        return result;
    }
    else
    {
        return @"(No phones)";
    }
}

#pragma mark - sending texts delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {
    
    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
    
    switch (result) {
        case MessageComposeResultCancelled:
            NSLog(@"Cancelled sending of text");
            break;
        case MessageComposeResultFailed:
            NSLog(@"Failed to send text");
            [alert showError:self title:@"😥❌📲" subTitle:@"Failed to send text 😞 Please try again." closeButtonTitle:@"OK" duration:0.0];            break;
        case MessageComposeResultSent:
            NSLog(@"Succesfully sent text message invite.");
            [alert showSuccess:self title:@"🤓📲👫" subTitle:@"Successfully sent invite! Once they download the app they will be asked if they want to join your Tribe 🎉" closeButtonTitle:@"OK" duration:0.0];            break;
        default:
            break;
    }
    [self dismissViewControllerAnimated:true completion:nil];
}
@end
