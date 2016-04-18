//
//  SignUpOrLoginViewController.m
//  Tribes
//
//  Created by German Espitia on 2/23/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "SignUpOrLoginViewController.h"
#import <DigitsKit/DigitsKit.h>
#import "Parse.h"
#import "SCLAlertView.h"
#import "User.h"
#import "TribesTableViewController.h"

@interface SignUpOrLoginViewController ()

@end

@implementation SignUpOrLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = TRUE;
}

-(void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = TRUE;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)signUp:(id)sender {
    
    
    [[Digits sharedInstance] authenticateWithCompletion:^(DGTSession *session, NSError *error) {

        if (error) {
            NSLog(@"Error authenticating user with Digits");
        } else {
            
            PFQuery * query = [PFUser query];
            [query whereKey:@"username" equalTo:session.userID];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                
                // found user already! -> log them in to old account
                if (object && !error) {
                    
                    SCLAlertView * foundUserAlert = [[SCLAlertView alloc] initWithNewWindow];
                    [foundUserAlert showSuccess:@"Found account!" subTitle:@"We found an account associated with your phone number." closeButtonTitle:nil duration:3.0];
                    
                    NSLog(@"found user for that phone number. Will attempt to login");
                    
                    [PFUser logInWithUsernameInBackground:session.userID password:session.userID block:^(PFUser * _Nullable user, NSError * _Nullable error) {
                        
                        if (user && !error) {
                            NSLog(@"succesfully logged in to already created user");
                            // The current user is now set to user.
                            
                            // set installation to user to receive pushes
                            [[PFInstallation currentInstallation] setObject:user forKey:@"user"];
                            [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                
                                
                                [self.navigationController dismissViewControllerAnimated:true completion:^{
                                    [foundUserAlert hideView];
                                    [self alertFetchingTribe];
                                }];
                                
                                
                            }];

                        } else {
                            NSLog(@"Failed to log in to user");
                        }

                    }];
                } else { // sign up
                    NSLog(@"did not find user for that phone number, will sign up as new user.");
                    [self signUpUserWithDigitsId:session.userID];
                }
            }];
     
        }
        
    }];
    
}

-(void)signUpUserWithDigitsId:(NSString *)digitsId {
    //sign up user with Parse
    PFUser * user = [PFUser user];
    user.username = digitsId;
    user.password = digitsId;
    user[@"digitsUserId"] = digitsId;

    // add id to digits account to parse user object
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
        if (succeeded && !error) {
            
            NSLog(@"succesfully created new user");
            
            // save installation for pushes
            PFInstallation *installation = [PFInstallation currentInstallation];
            installation[@"user"] = [PFUser currentUser];
            [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                
                if (succeeded && !error) {
                    NSLog(@"succesfully created PFInstallation object for user");
                    
                    [PFUser becomeInBackground:user.sessionToken block:^(PFUser *user, NSError *error) {
                        if (user && !error) {
                            // The current user is now set to user.
                            // dismiss signup controller
                            [self.navigationController dismissViewControllerAnimated:true completion:^{
                                
                                // reload table view
                                UIWindow *window = [UIApplication sharedApplication].keyWindow;
                                UINavigationController *rootViewController = (UINavigationController *)window.rootViewController;
                                TribesTableViewController * tribesVC = rootViewController.viewControllers[0];
                       
                                [User currentUser].loadedInitialTribes = true;
                                [tribesVC.tableView reloadData];
                                [tribesVC setUp];
                                [tribesVC UISetUp];
                
                                [self askForUsername];
                                
                                
                            }];
                        } else {
                            NSLog(@"error signing in to user (becomeInBg)");
                        }
                    }];
                } else {
                    NSLog(@"Error saving installation object (for push notif.)");
                }
            }];
        } else {
            NSLog(@"failed to sign up user");
        }
        
        
        
    }];
}
-(void)askForUsername {
    // ask user for last step - setting name
    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];

    UITextField * nameTextField = [alert addTextField:@"Name"];
    UITextField * emailTextField = [alert addTextField:@"Email"];

    [alert addButton:@"READY!" actionBlock:^(void) {
        [[PFUser currentUser] setObject:nameTextField.text forKey:@"name"];
        [[PFUser currentUser] setObject:emailTextField.text forKey:@"email"];
        [[PFUser currentUser] saveInBackground];
    }];
    
    [alert showInfo:@"Almost done 😁" subTitle:@"To finish signing up, set your name and email! " closeButtonTitle:nil duration:0.0];
}
-(void)alertFetchingTribe {
    
    
    // alert user that app is loading tribes
    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
    [alert showWaiting:@"Fetching Tribes" subTitle:@"🏃💨" closeButtonTitle:nil duration:0.0];
    
    
    [[User currentUser] updateTribesWithBlock:^(bool success) {
        
        [alert hideView];
        if (success) {
            
            // reload table view
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            UINavigationController *rootViewController = (UINavigationController *)window.rootViewController;
            TribesTableViewController * tribesVC = rootViewController.viewControllers[0];

            [[User currentUser] loadTribesWithBlock:^(bool success) {
                if (success) {
                    [User currentUser].loadedInitialTribes = true;
                    [tribesVC.tableView reloadData];
                    [tribesVC setUp];
                    [tribesVC UISetUp];
                }
            }];
        } else  {
            SCLAlertView * errorAlert = [[SCLAlertView alloc] initWithNewWindow];
            [errorAlert addButton:@"Try again" actionBlock:^{
                [self alertFetchingTribe];
            }];
            [errorAlert showError:@"Oh oh!" subTitle:@"" closeButtonTitle:nil duration:0.0];

        }
    }];

  
    
}
@end
