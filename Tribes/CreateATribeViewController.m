//
//  CreateATribeTableViewController.m
//  Tribes
//
//  Created by German Espitia on 5/27/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "CreateATribeViewController.h"
#import "SCLAlertView.h"
#import "User.h"

@interface CreateATribeViewController () {
    User * currentUser;
    IBOutlet UITextField *tribeNameTextField;
    UIBarButtonItem * createTribeButton;
}

@end

@implementation CreateATribeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // right button to create Tribe
    createTribeButton = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStylePlain target:self action:@selector(createTribe)];
    [self.navigationItem setRightBarButtonItem:createTribeButton];
    
    // set current user
    currentUser = [User currentUser];

    // ui touches
    self.navigationItem.title = @"Create a Dynasty";
    
    // lines on top and below email textfield
    UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, tribeNameTextField.frame.origin.y - 5, self.view.bounds.size.width, 1)];
    topLineView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:topLineView];
    
    UIView * bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, tribeNameTextField.frame.origin.y + tribeNameTextField.frame.size.height + 30, self.view.bounds.size.width, 1)];
    bottomLineView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:bottomLineView];
}

-(void)viewDidAppear:(BOOL)animated {
//    [tribeNameTextField becomeFirstResponder];
    [tribeNameTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];

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