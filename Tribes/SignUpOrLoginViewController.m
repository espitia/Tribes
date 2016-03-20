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
                if (object) {
                    [PFUser logInWithUsernameInBackground:session.userID password:session.userID block:^(PFUser * _Nullable user, NSError * _Nullable error) {
                        // The current user is now set to user.
                        [self.navigationController dismissViewControllerAnimated:true completion:nil];
                    }];
                } else { // sign up
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
        
        if (error) {
            NSLog(@"Error signing up user to Parse");
        } else {
            
            // save installation for pushes
            PFInstallation *installation = [PFInstallation currentInstallation];
            installation[@"user"] = [PFUser currentUser];
            [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                
                if (error) {
                    NSLog(@"Error saving installation object (for push notif.)");
                } else {
                    [PFUser becomeInBackground:user.sessionToken block:^(PFUser *user, NSError *error) {
                        if (error) {
                            //check for token if error
                            NSLog(@"Error becoming user");
                        } else {
                            
                            // The current user is now set to user.
                            // dismiss signup controller
                            [self.navigationController dismissViewControllerAnimated:true completion:^{
                                
                                [self askForUsername];
                                
                                
                            }];
                            
                        }
                    }];
                }
                
                
            }];
        }
        
        
        
    }];
}
-(void)askForUsername {
    // ask user for last step - setting name
    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];

    UITextField * textField = [alert addTextField:@"Enter your name"];

    [alert addButton:@"READY!" actionBlock:^(void) {
        [[PFUser currentUser] setObject:textField.text forKey:@"name"];
        [[PFUser currentUser] saveInBackground];
    }];
    
    [alert showInfo:@"Almost done!" subTitle:@"To finish signing up, set your name so your friends can identify you!" closeButtonTitle:nil duration:0.0];
}
- (IBAction)signIn:(id)sender {
    
    // alert to notify user of any errors
    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];

    [[Digits sharedInstance] authenticateWithCompletion:^(DGTSession *session, NSError *error) {
        if (error) {
            NSLog(@"Error authenticating user to Digits");
            [alert showError:@"Oh oh!" subTitle:@"There was an error authenticating your phone number. Please try again." closeButtonTitle:@"OK" duration:0.0];
        } else {
            [PFUser logInWithUsernameInBackground:session.userID password:session.userID block:^(PFUser * _Nullable user, NSError * _Nullable error) {
                
                
                if (!error) {
                    // The current user is now set to user.
                    // dismiss login
                    [self.navigationController dismissViewControllerAnimated:true completion:^{

                        //alert user that app is loading tribes
                        [self alertFetchingTribe];
                        
                    }];
                } else {
                    NSLog(@"error logging in to parse.");
                    [alert showError:@"Oh oh!" subTitle:@"There was an error logging in. Please try again." closeButtonTitle:@"OK" duration:0.0];
                }
                
            }];
        }
    }];
}
-(void)alertFetchingTribe {
    
    
    // alert user that app is loading tribes
    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
    [alert showWaiting:@"Fetching Tribes" subTitle:@"🏃💨" closeButtonTitle:nil duration:0.0];
    
    
    [[User currentUser] updateTribesWithBlock:^(bool success) {
        
        [alert hideView];
        NSLog(@"%d", success);
        if (success) {
            
            // reload table view
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            UINavigationController *rootViewController = (UINavigationController *)window.rootViewController;
            TribesTableViewController * tribesVC = rootViewController.viewControllers[0];

            [[User currentUser] loadTribesWithBlock:^(bool success) {
                if (success) {
                    [tribesVC.tableView reloadData];
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
