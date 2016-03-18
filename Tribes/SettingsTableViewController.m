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

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = 70;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    NSString * title;
    NSString * detailText;
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    title = @"Log out";
                    detailText = @"📲";
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    
    cell.textLabel.text = title;
    cell.detailTextLabel.text = detailText;
    
    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //deselect row
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    [self signOut];
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

-(void)signOut {
    
    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
    [alert addButton:@"Yes! 😄" actionBlock:^{
        [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
            
            [self showLoginScreen];
            [self.navigationController popToRootViewControllerAnimated:true];
        }];
    }];
    [alert showWarning:@"Log out" subTitle:@"Are you sure you want to log out?" closeButtonTitle:@"Never mind.. 🤔" duration:0.0];

}

-(void)showLoginScreen {
    
    UINavigationController * SignUpLoginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SignUpLoginViewController"];
    [self.navigationController presentViewController:SignUpLoginViewController animated:YES completion:nil];
}
@end
