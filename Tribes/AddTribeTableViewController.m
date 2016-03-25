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

@interface AddTribeTableViewController () {
    User * currentUser;
    UITextField * tribeNameTextField;
    Tribe * tribe;
    UIBarButtonItem * createTribeButton;
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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
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
            [self addCreateTribeTextFieldToCell:cell];
            break;
        case 1:
            cell.textLabel.text = @"du mon";
        default:
            break;
    }


    
    return cell;
}

#pragma mark - Configure Cells

-(void)addCreateTribeTextFieldToCell:(UITableViewCell *)cell {
    // add uitextfield for name fo tribe
    CGRect activityNameFrame = CGRectMake(15,
                                          cell.frame.origin.y - 55,
                                          cell.frame.size.width,
                                          cell.frame.size.height);
    [tribeNameTextField setFrame:activityNameFrame];
    tribeNameTextField.placeholder = @"e.g. The Squad 😎";
    [tribeNameTextField setFont:[UIFont systemFontOfSize:40]];
    [cell.contentView addSubview:tribeNameTextField];

    
}

#pragma mark - Stuff

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
                    // send tribe back to main viewcontroller
                    [self performSegueWithIdentifier:@"unwindFromAddTribe" sender:self];
                } else {
                    
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
@end
