//
//  SignUpOrLoginViewController.m
//  Tribes
//
//  Created by German Espitia on 2/23/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "SignUpOrLoginViewController.h"
#import <DigitsKit/DigitsKit.h>
#import <Crashlytics/Crashlytics.h>
#import "Parse.h"
#import "SCLAlertView.h"
#import "User.h"
#import "TribesTableViewController.h"
#import "SignUpValidation.h"

@import AVFoundation;
@import AVKit;

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
- (IBAction)playIntroVideo:(id)sender {

    
    // grab a local URL to our video
    NSURL *videoURL = [[NSBundle mainBundle]URLForResource:@"Tribes-Intro" withExtension:@"mp4"];
    
    // create an AVPlayer
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    
    // create a player view controller
    AVPlayerViewController *controller = [[AVPlayerViewController alloc]init];
    controller.player = player;
    
    // present view controller
    [self presentViewController:controller animated:true completion:nil];
    [player play];
    
    
}
- (IBAction)signUp:(id)sender {
    
    
    [[Digits sharedInstance] authenticateWithCompletion:^(DGTSession *session, NSError *error) {

        if (error) {
            NSLog(@"Error authenticating user with Digits");
        } else {
            
            PFQuery * query = [PFUser query];
            [query whereKey:@"username" equalTo:session.userID];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                
                // FOUND USER ALREADY -> LOG INTO OLD ACCOUNT
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
                } else {
                    
                    // ELSE IF NOT FOUND OLD ACCOUNT -> sign up
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
                                
                                [Answers logSignUpWithMethod:@"Digits"
                                                     success:@YES
                                            customAttributes:@{}];
                                
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
        
        SignUpValidation * validate = [[SignUpValidation alloc] init];
        
        // check to make sure username is valid
        [validate isUsernameValid:nameTextField.text withBlock:^(BOOL success) {
            if (success) {
                
                // if username is valid, check email to see if it is valid
                if ([validate isEmailValid:emailTextField.text]) {
                    
                    // if both are valid, set and save 
                    [[PFUser currentUser] setObject:nameTextField.text forKey:@"name"];
                    [[PFUser currentUser] setObject:emailTextField.text forKey:@"email"];
                    [[PFUser currentUser] saveInBackground];
                } else {
                    SCLAlertView * error = [[SCLAlertView alloc] initWithNewWindow];
                    [error addButton:@"OK" actionBlock:^{
                        [self askForUsername];
                    }];
                    [error showError:@"Error" subTitle:@"Looks like your email is invalid 😞 Please try again" closeButtonTitle:nil duration:0.0];
                }
            } else {
                SCLAlertView * error = [[SCLAlertView alloc] initWithNewWindow];
                [error addButton:@"OK" actionBlock:^{
                    [self askForUsername];
                }];
                [error showError:@"Error" subTitle:@"Looks like your username is taken :( Please try again" closeButtonTitle:nil duration:0.0];
            }
        }];
        

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
