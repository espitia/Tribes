//
//  LogInViewController.m
//  Tribes
//
//  Created by German Espitia on 5/26/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "LogInViewController.h"
#import "TribesTableViewController.h"
#import "User.h"
#import "SCLAlertView.h"
#import <Parse/Parse.h>

@interface LogInViewController ()
@property (strong, nonatomic) IBOutlet UITextField *emailAddress;
@property (strong, nonatomic) IBOutlet UITextField *password;

@end

@implementation LogInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = false;

    // right button to log in
    UIBarButtonItem * logInButton = [[UIBarButtonItem alloc] initWithTitle:@"Log in" style:UIBarButtonItemStylePlain target:self action:@selector(logIn:)];
    [self.navigationItem setRightBarButtonItem:logInButton];
    
    // lines on top and below email/password textfield
    UIView *topLineOfEmail = [[UIView alloc] initWithFrame:CGRectMake(0, _emailAddress.frame.origin.y, self.view.bounds.size.width, 1)];
    topLineOfEmail.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:topLineOfEmail];
    
    UIView * topLineOfPassWord = [[UIView alloc] initWithFrame:CGRectMake(0, _password.frame.origin.y, self.view.bounds.size.width, 1)];
    topLineOfPassWord.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:topLineOfPassWord];
    
    UIView * bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _password.frame.origin.y + _password.frame.size.height, self.view.bounds.size.width, 1)];
    bottomLineView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:bottomLineView];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [_emailAddress becomeFirstResponder];
}
- (IBAction)logIn:(id)sender {
    
    // find pfuser with email
    PFQuery *query = [PFUser query];
    [query whereKey:@"emailLowerCase" equalTo:[_emailAddress.text lowercaseString]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (objects.count > 0 && !error) {
            
            PFObject * object = [objects objectAtIndex:0];
            NSString * username = [object objectForKey:@"username"];

            // login with username of email found and password field
            [PFUser logInWithUsernameInBackground:username password:_password.text block:^(PFUser * _Nullable user, NSError * _Nullable error) {
                
                if (user && !error) {
                    
                    
                    
                    [self dismissViewControllerAnimated:true completion:^{
                        
                        // get tribes main table vc
                        UIWindow *window = [UIApplication sharedApplication].keyWindow;
                        UINavigationController *rootViewController = (UINavigationController *)window.rootViewController;
                        TribesTableViewController * tribesVC = rootViewController.viewControllers[0];
                       
                        // alert user account was found
                        SCLAlertView * successAlert = [[SCLAlertView alloc] initWithNewWindow];
                        [successAlert showSuccess:tribesVC title:@"Found your account 😄" subTitle:@"It should take just a few seconds to load it.. ⏰" closeButtonTitle:nil duration:0.0];
                        
                        // load tribes
                        [(User *)user loadTribesWithBlock:^(bool success) {
                            if (success) {
                                [User currentUser].loadedInitialTribes = true;
                                [tribesVC.tableView reloadData];
                                [tribesVC setUp];
                                [tribesVC UISetUp];
                                [successAlert hideView];
                            }
                        }];
                    }];
                    
                    
                    
                }
                else {
                    [self showErrorAlert];
                }
            }];
            
            
        } else {
            [self showErrorAlert];
        }
        
        
    }];
    
    

}

-(void)showErrorAlert {
    
    [_emailAddress resignFirstResponder];
    [_password resignFirstResponder];
    
    SCLAlertView * errorAlert = [[SCLAlertView alloc] initWithNewWindow];
    [errorAlert addButton:@"GOT IT" actionBlock:^{
        [_emailAddress becomeFirstResponder];
    }];
    [errorAlert showError:@"Oh oh ... 😯" subTitle:@"The gods of log ins tell us that there was an error. We all make them. No worries. Try again!" closeButtonTitle:nil duration:0.0];
    
}


@end
