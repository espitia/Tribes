//
//  SendTextTableViewController.m
//  Tribes
//
//  Created by German Espitia on 6/7/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "SendTextTableViewController.h"
#import "APAddressBook.h"
#import "APContact.h"
#import <Leanplum/Leanplum.h>
#import "SCLAlertView.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface SendTextTableViewController () <UINavigationControllerDelegate,MFMessageComposeViewControllerDelegate, UISearchBarDelegate> {
    NSMutableArray * addressBookContacts;
    NSMutableArray * filteredAddressBookContacts;
    APAddressBook * addressBook;
    IBOutlet UISearchBar *searchBar;
    BOOL isFiltered;
}

@end

@implementation SendTextTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    addressBook = [[APAddressBook alloc] init];
    searchBar.delegate = self;
    
    switch([APAddressBook access])
    {
        case APAddressBookAccessUnknown: {
            // Application didn't request address book access yet
            
            SCLAlertView * askForPermissionAlert = [[SCLAlertView alloc] initWithNewWindow];
            [askForPermissionAlert addButton:@"OK" actionBlock:^{
                [addressBook requestAccess:^(BOOL granted, NSError *error)
                 {
                     if (granted) {
                         [self setUpAddressBook];
                     } else {
                         NSLog(@"not granted");
                     }
                     // check `granted`
                 }];
            }];
            [askForPermissionAlert showInfo:@"ADDRESS BOOK" subTitle:@"In order to send text invites to your buddies, Tribes needs your holy permission to access your address book. No worries, we never send anything. Only you have the power 🙌" closeButtonTitle:@"MAYBE LATER" duration:0.0];

        }
            break;
            
        case APAddressBookAccessGranted: {
            // Access granted
            [self setUpAddressBook];
        }
            break;
            
        case APAddressBookAccessDenied: {
            // Access denied or restricted by privacy settings
            SCLAlertView * accessDeniedAlert = [[SCLAlertView alloc] initWithNewWindow];
            [accessDeniedAlert showError:@"Oh oh.. 🙄" subTitle:@"Tribes does not have permission to access your address book. In order to send invites through text, please go to your phone's setting and allow Tribes to access your address book!" closeButtonTitle:@"GOT IT" duration:0.0];
        }
            break;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (isFiltered) ? filteredAddressBookContacts.count : addressBookContacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Friend" forIndexPath:indexPath];
    
    APContact * contact;
    
    if (isFiltered) {
        contact = [filteredAddressBookContacts objectAtIndex:indexPath.row];
        cell.textLabel.text = [self contactName:contact];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        contact = [addressBookContacts objectAtIndex:indexPath.row];
        cell.textLabel.text = [self contactName:contact];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // SEND TEXT TO INVITE USERS
    [self sendUserTextFromIndexPath:indexPath];
}




-(void)sendUserTextFromIndexPath:(NSIndexPath *)indexPath {
    
    APContact * contact;
    if (isFiltered) {
        contact = [filteredAddressBookContacts objectAtIndex:indexPath.row];
    } else {
        contact = [addressBookContacts objectAtIndex:indexPath.row];
    }
    NSString * number = [self contactPhones:contact];
    
    MFMessageComposeViewController *controller =
    [[MFMessageComposeViewController alloc] init];
    
    if([MFMessageComposeViewController canSendText]) {
        NSString * textMessage = [NSString stringWithFormat:@"Hey! I am trying to get the whole squad on Tribes ✊ It's an app to make sure we get our stuff done 😎 Download it here and join our Tribe %@: http://bit.ly/TribeSquad", _tribe[@"name"]];
        controller.body = textMessage;
        controller.recipients = [NSArray arrayWithObjects:
                                 number, nil];
        controller.messageComposeDelegate = self;
        [self presentViewController:controller animated:true completion:nil];
    }
}



#pragma mark - APContacts

-(void)setUpAddressBook {

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
             addressBookContacts = [NSMutableArray arrayWithArray:contacts];
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
            [Leanplum track:@"Txt message invite" withParameters:@{@"success":@false}];
            [alert showError:self title:@"😥❌📲" subTitle:@"Failed to send text 😞 Please try again." closeButtonTitle:@"OK" duration:0.0];            break;
        case MessageComposeResultSent:
            [Leanplum track:@"Txt message invite" withParameters:@{@"success":@true}];
            NSLog(@"Succesfully sent text message invite.");
            [alert showSuccess:self title:@"🤓📲👫" subTitle:@"Successfully sent invite! Make sure they download the app and register to be able to join your Tribe 🎉" closeButtonTitle:@"OK" duration:0.0];
            break;
        default:
            break;
    }
    [self dismissViewControllerAnimated:true completion:nil];
}


#pragma mark - Search Bar Delegate

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(searchText.length == 0)
    {
        isFiltered = FALSE;
    }
    else
    {
        isFiltered = true;
        filteredAddressBookContacts = [[NSMutableArray alloc] init];
        
        for (APContact * contact in addressBookContacts)
        {
            if ([contact.name.firstName containsString:searchText] ||
                [contact.name.lastName containsString:searchText]) {
                [filteredAddressBookContacts addObject:contact];
            }
//            NSRange nameRange = [contact.name.firstName rangeOfString:searchText options:NSCaseInsensitiveSearch];
//            NSRange descriptionRange = [contact.name.lastName rangeOfString:searchText options:NSCaseInsensitiveSearch];
//            if(nameRange.location != NSNotFound || descriptionRange.location != NSNotFound)
//            {
//                [filteredAddressBookContacts addObject:contact];
//            }
        }
    }
    
    [self.tableView reloadData];
}

@end
