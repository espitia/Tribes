//
//  SettingsTableViewController.m
//  Tribes
//
//  Created by German Espitia on 3/17/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "Parse.h"
#import "SCLAlertView.h"
#import "IAPHelper.h"
#import "PremiumViewController.h"
#import "SCLAlertView.h"
#import "HelpshiftSupport.h"
#import <MessageUI/MFMailComposeViewController.h>


@interface SettingsTableViewController () <MFMailComposeViewControllerDelegate> {
    IAPHelper * iAPHelper;
}

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = 70;
    iAPHelper = [[IAPHelper alloc] init];
}

-(void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   switch (section) {
       case 0: {
           IAPHelper * helper = [[IAPHelper alloc] init];
           return ([helper userIsPremium]) ? 2 : 1;
       }
        case 1:
            return 4;
            break;
            
        default:
            return 1;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = @"General";
            break;
        case 1:
            sectionName = @"Feedback? Lets connect 📢";
            break;
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    NSString * title;
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: {
                    if ([iAPHelper userIsPremium]) {
                        title = [NSString stringWithFormat:@"Subscribed!🏅Expires in %d days", [iAPHelper daysRemainingOnSubscription]];
                    } else {
                        title = @"Upgrade ⭐️";
                    }
                }
                    break;
                    // 2nd row of 1st section only shown if user is premium
                case 1: {
                        title = @"Extend your subscription ⭐";
                }
                    break;
                    
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    title = @"Live chat 💬";
                    break;
                case 1:
                    title = @"Snapchat 👻";
                    break;
                case 2:
                    title = @"Email 📧";
                    break;
                case 3:
                    title = @"Twitter 🐦";
                    break;
                    
                default:
                    break;
            }
            
        default:
            break;
    }
    
    cell.textLabel.text = title;

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //deselect row
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: {
                    // if premium, ask to extend, if not, show premium vc
                    if ([iAPHelper userIsPremium]) {
                        [self extendPremiumOptions];
                    } else {
                        PremiumViewController * premiumVC = [[PremiumViewController alloc] initWithFeature:PremiumWeeklyReport];
                        [self presentViewController:premiumVC animated:true completion:nil];
                    }
                }
                    break;
                case 1: {
                    // if premium, ask to extend, if not, this row is not shown
                    [self extendPremiumOptions];
                }
                    break;
                    
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0: {
                    [HelpshiftSupport showConversation:self withOptions:nil];
                }
                    break;
                case 1: {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://www.snapchat.com/add/tribeshq"]];
                }
                    break;
                    
                case 2: {
                    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
                    controller.mailComposeDelegate = self;
                    [controller setToRecipients:@[@"tribeshq@gmail.com"]];
                    [controller setSubject:@"About Tribes.."];
                    [controller setMessageBody:@"Hello there 🖖" isHTML:NO];
                    if (self) [self presentViewController:controller animated:true completion:nil];
                }
                    break;
                case 3: {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://www.twitter.com/tribeshq"]];
                }
                    break;
                    
                default:
                    break;
            }
            
        default:
            break;
    }
}

-(void)extendPremiumOptions {
    SCLAlertView * extendPremium = [[SCLAlertView alloc] initWithNewWindow];
    [extendPremium addButton:@"ADD 1 MONTH" actionBlock:^{
        [iAPHelper make1MonthPremiumPurchaseWithTableViewController:self andReload:true orDismiss:false];
    }];
    [extendPremium showSuccess:@"Extend Subscription" subTitle:@"You already have Tribes Premium. Would you like to extend your subscription?" closeButtonTitle:@"MAYBE LATER" duration:0.0];
    
}

#pragma mark - Mail Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error; {
    if (result == MFMailComposeResultSent) {
        SCLAlertView * emailSentAlert = [[SCLAlertView alloc] initWithNewWindow];
        [emailSentAlert showSuccess:@"Email sent 📧" subTitle:@"Thank you for reaching out. I will get back to you as soon as possible 🏃" closeButtonTitle:@"AWESOME" duration:0.0];
    }
    [self dismissViewControllerAnimated:true completion:nil];
}
@end
