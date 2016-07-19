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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   switch (section) {
        case 0:
            return 2;
            break;
       case 1:
           return 1;
           break;
       case 2:
           return 1;
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
            sectionName = @"Feedback? Lets connect 📢";
            break;
        case 1:
            sectionName = @"How to do this or that?";
            break;
        case 2:
            sectionName = @"About";
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
                case 0:
                    title = @"Live chat 💬";
                    break;
                case 1:
                    title = @"Email 📧";
                    break;
                    
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    title = @"Frquently Asked Questions ❓";
                    break;
                    
                default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    title = @"By espitia 👦🏽";
                    break;
                    
                default:
                    break;
            }
            break;
            
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
                    [HelpshiftSupport showConversation:self withOptions:nil];
                }
                    break;
                    
                case 1: {
                    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
                    controller.mailComposeDelegate = self;
                    [controller setToRecipients:@[@"german@usetribes.com"]];
                    [controller setSubject:@"About Tribes.."];
                    [controller setMessageBody:@"Hello there 🖖" isHTML:NO];
                    if (self) [self presentViewController:controller animated:true completion:nil];
                }
                    break;
                    
                default:
                    break;
            }
        case 1:
            switch (indexPath.row) {
                case 0:
                    [HelpshiftSupport showFAQs:self withOptions:nil];
                    break;
                    
                default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://twitter.com/espitia7"]];
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

-(void)extendPremiumOptions {
    SCLAlertView * extendPremium = [[SCLAlertView alloc] initWithNewWindow];
    [extendPremium addButton:@"Add 1 month for $1.99" actionBlock:^{
        [iAPHelper makePremiumPurchaseForMonths:1 WithTableViewController:self andReload:true orDismiss:false];
    }];
    [extendPremium addButton:@"Add 3 months for $5.99" actionBlock:^{
        [iAPHelper makePremiumPurchaseForMonths:3 WithTableViewController:self andReload:true orDismiss:false];
    }];
    [extendPremium addButton:@"Add 6 months for $9.99" actionBlock:^{
        [iAPHelper makePremiumPurchaseForMonths:6 WithTableViewController:self andReload:true orDismiss:false];
    }];
    [extendPremium showSuccess:@"Extend Subscription" subTitle:@"You already have Tribes Premium. Would you like to extend your subscription?" closeButtonTitle:@"Maybe later" duration:0.0];
    
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
