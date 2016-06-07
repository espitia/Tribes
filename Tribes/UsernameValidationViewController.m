//
//  EmailValidationViewController.m
//  Tribes
//
//  Created by German Espitia on 5/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "UsernameValidationViewController.h"
#import "TribesTableViewController.h"
#import "SignUpValidation.h"
#import "SCLAlertView.h"
#import <Parse/Parse.h>

@interface UsernameValidationViewController () <UITextFieldDelegate> {
    SignUpValidation * validation;
    UIButton * signUpButton;
    CGRect keyboardFrame;
    BOOL buttonShowing;
    BOOL usernameIsValid;
}

@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;

@end

@implementation UsernameValidationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // ui touches
    self.navigationController.navigationBarHidden = false;
    self.navigationItem.title = @"Username";

    
    // lines on top and below email textfield
    UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _usernameTextField.frame.origin.y, self.view.bounds.size.width, 1)];
    topLineView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:topLineView];
    
    UIView * bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _usernameTextField.frame.origin.y + _usernameTextField.frame.size.height, self.view.bounds.size.width, 1)];
    bottomLineView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:bottomLineView];
    
    //add sign up button
    signUpButton = [[UIButton alloc] init];
    signUpButton.backgroundColor = [UIColor orangeColor];
    [signUpButton setTitle:@"Continue" forState:UIControlStateNormal];
    [signUpButton.titleLabel setTextColor:[UIColor whiteColor]];
    [signUpButton addTarget:self action:@selector(continueToNextVc) forControlEvents:UIControlEventTouchUpInside];
    
    // init  vars
    buttonShowing = false;
    _usernameTextField.delegate = self;
    validation = [[SignUpValidation alloc] init];
    
    // add notifier for when app comes into foreground
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [_usernameTextField becomeFirstResponder];
}

#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (!buttonShowing)
        [self slideInSignUpButton];
    
    return true;
}

#pragma mark - Continue Button

-(void)continueToNextVc {
    
    signUpButton.enabled = false;
    
    [validation isUsernameValid:_usernameTextField.text withBlock:^(int error) {
        
        if (error == 0) {
            
            [self signUpNewUser];
            
        } else {
            [self showErrorAlertWithErrorCode:error];
        }
        
    }];
}

#pragma mark - Sign up

-(void)signUpNewUser {
    
    // SIGN UP
    self.user.username = _usernameTextField.text;
    self.user[@"usernameLowerCase"] = [_usernameTextField.text lowercaseString];
    self.user[@"emailLowerCase"] = [self.user.email lowercaseString];

    [self.user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {

        if (!error && succeeded) {
            
            
            // save installation for pushes
            PFInstallation *installation = [PFInstallation currentInstallation];
            installation[@"user"] = [PFUser currentUser];
            [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                
                if (succeeded && !error) {
                    NSLog(@"succesfully created PFInstallation object for user");
                    
                    [PFUser becomeInBackground:self.user.sessionToken block:^(PFUser *user, NSError *error) {
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
                                [tribesVC makeItRainConfetti];
                                [self congratulationsAlert];
                                
                                
                            }];
                        } else {
                            signUpButton.enabled = true;
                            NSLog(@"error signing in to user (becomeInBg)");
                        }
                    }];
                } else {
                    signUpButton.enabled = true;
                    NSLog(@"Error saving installation object (for push notif.)");
                }
            }];
        }

    }];
}

#pragma mark - Alerts

-(void)congratulationsAlert {
    
    SCLAlertView *  congratulationsAlert = [[SCLAlertView alloc] initWithNewWindow];
    [congratulationsAlert showSuccess:@"Congratulations 🎈" subTitle:@"You are now ready to set up your Tribe and start building those new habits." closeButtonTitle:@"LET'S GO!" duration:0.0];
    
}

-(void)showErrorAlertWithErrorCode:(int)error {
    
    NSString * errorMessage = @"";
    [_usernameTextField resignFirstResponder];
    
    if (error == 1) {
        
        // syntx error
        errorMessage = @"Make sure your username has letter and numbers only. It must be at least 3 characters long. No spaces or dashes or other weird stuff.";
        
    } else if (error == 2) {
        
        // username taken
        errorMessage = @"Looks like that username is taken! Try another please.";
    }
    
    SCLAlertView * errorAlert = [[SCLAlertView alloc] initWithNewWindow];
    [errorAlert addButton:@"GOT IT" actionBlock:^{
        [_usernameTextField becomeFirstResponder];
    }];
    [errorAlert showError:@"Oh oh... 😯" subTitle:errorMessage closeButtonTitle:nil duration:0.0];
    signUpButton.enabled = true;

}
#pragma mark - Notifications

-(void)keyboardDidShow:(id)sender {
    NSDictionary * userInfo = [sender userInfo];
    keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
}

#pragma mark - Sign Up Button

-(void)slideInSignUpButton {
    
    if (!buttonShowing) {
        buttonShowing = true;
        [signUpButton setFrame:CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - keyboardFrame.size.height - 60, self.view.frame.size.width, 60)];
        
        [UIView animateWithDuration:0.4 animations:^{
            [signUpButton setFrame:CGRectMake(0, self.view.frame.size.height - keyboardFrame.size.height - 60, self.view.frame.size.width, 60)];
            [self.view addSubview:signUpButton];
        }];
    }
    
}

-(void)slideOutSignUpButton {
    
    [UIView animateWithDuration:0.4 animations:^{
        buttonShowing = false;
        [signUpButton setFrame:CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - keyboardFrame.size.height - 60, self.view.frame.size.width, 60)];
    }];
    
}

#pragma mark - Util

-(void)setSignifierForTextField:(UITextField *)textField withImage:(UIImage *)image {
    UIImageView * imgView = [[UIImageView alloc] initWithImage:image];
    imgView.userInteractionEnabled = true;
    textField.rightView = imgView;
}


@end
