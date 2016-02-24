//
//  SignupViewController.m
//  Tribes
//
//  Created by German Espitia on 1/13/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "SignupViewController.h"
#import <DigitsKit/DigitsKit.h>
#import "Parse.h"
#import "SCLAlertView.h"
#import "SignUpValidation.h"

@interface SignupViewController () {
    IBOutlet UITextField *username;
    IBOutlet UITextField *password;
    IBOutlet UITextField *email;
    UIButton * signUpButton;
    NSString * completeUsername;
    BOOL usernameValid;
    BOOL emailValid;
    BOOL passwordValid;
    BOOL buttonShowing;
    SignUpValidation * validation;
    CGRect keyboardFrame;
}

@end

@implementation SignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = false;
    self.navigationItem.title = @"Sign Up";
    
    password.secureTextEntry = TRUE;
    
    email.rightViewMode = UITextFieldViewModeAlways;
    username.rightViewMode = UITextFieldViewModeAlways;
    password.rightViewMode = UITextFieldViewModeAlways;
    
    email.rightView.userInteractionEnabled = true;
    username.rightView.userInteractionEnabled = true;
    password.rightView.userInteractionEnabled = true;
    
    // add notifier for when app comes into foreground
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    //add sign up button
    signUpButton = [[UIButton alloc] init];
    signUpButton.backgroundColor = [UIColor orangeColor];
    [signUpButton setTitle:@"Sign up" forState:UIControlStateNormal];
    [signUpButton.titleLabel setTextColor:[UIColor whiteColor]];
    [signUpButton addTarget:self action:@selector(signUpUser) forControlEvents:UIControlEventTouchUpInside];
//    signUpButton.hidden = true;
    
    validation = [[SignUpValidation alloc] init];
}
-(void)viewDidAppear:(BOOL)animated {
    [email becomeFirstResponder];
}


#pragma mark Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
//    textField.rightView = nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString * completeString;

    if ([string isEqualToString:@""]) {
        completeString = [textField.text substringToIndex:[textField.text length]-1];
    } else {
        completeString = [textField.text stringByAppendingString:string];
    }
    
    [self validateTextField:textField withInput:completeString];
    
    return true;
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == email) {
        [textField resignFirstResponder];
        [username becomeFirstResponder];
    } else if (textField == username) {
        [textField resignFirstResponder];
        [password becomeFirstResponder];
    }
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [self validateTextField:textField withInput:textField.text];
}

#pragma mark - Right View Touch Delegate

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

}


#pragma mark - Validation

-(void)validateTextField:(UITextField *)textField withInput:(NSString *)completeString {
    
    __block UIImage * imgSignifier;
    
    if (textField == email) {
        
        if ([validation isEmailValid:completeString]) {
            imgSignifier = [UIImage imageNamed:@"green-check"];
            emailValid = true;
        } else {
            imgSignifier = [UIImage imageNamed:@"red-cross"];
            emailValid = false;
        }
    }
    
    else if (textField == username) {
       
        
        [validation isUsernameValid:completeString withBlock:^(BOOL success) {
            if (success) {
                imgSignifier = [UIImage imageNamed:@"green-check"];
                usernameValid = true;
            } else {
                imgSignifier = [UIImage imageNamed:@"red-cross"];
                usernameValid = false;
            }
            [self setSignifierForTextField:textField withImage:imgSignifier];
            [self isReadyToSignUp];
        }];

    }
    
    else if (textField == password) {
        
        if ([validation isPasswordValid:completeString]) {
            imgSignifier = [UIImage imageNamed:@"green-check"];
            passwordValid = true;
        } else {
            imgSignifier = [UIImage imageNamed:@"red-cross"];
            passwordValid = false;
        }
    }

    
    [self setSignifierForTextField:textField withImage:imgSignifier];
    
    [self isReadyToSignUp];

}

#pragma mark - Sign Up User

- (void)signUpUser {
    
    if (usernameValid && emailValid && passwordValid) {
        
        // sign up with phonenumber (digits by twitter Fabrics)
        [[Digits sharedInstance] authenticateWithCompletion:^(DGTSession *session, NSError *error) {
            
            if (!error) {
                
                PFUser * user = [PFUser user];
                user.username = username.text;
                user.password = password.text;
                user.email = email.text;
                
                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (error) {
                        
                        //handle error
                        NSLog(@"error signing up with Parse");
                        
                    } else {
                        
                        // save installation for pushes
                        PFInstallation *installation = [PFInstallation currentInstallation];
                        installation[@"user"] = [PFUser currentUser];
                        [installation saveInBackground];
                        
                        // add id to digits account to parse user object
                        user[@"digitsUserId"] = session.userID;
                        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            if (error) {
                                // handle error
                                NSLog(@"error saving digits user id to parse user object");
                            } else {
                                [[Digits sharedInstance] authenticateWithCompletion:^(DGTSession *session, NSError *error) {
                                    NSLog(@"we ouchea");
                                }];
                            }
                        }];

                    }
                }];
            }
        }];
    } else {
        if (!emailValid) {
            [self showEmailErrorMessage];
        } else if (!usernameValid) {
            [self showUsernameErrorMessage];
        } else if (!passwordValid) {
            [self showPasswordErrorMessage];
        }
    }

}

#pragma mark - Error messages

-(void)showEmailErrorMessage {

    [self.view endEditing:true];

    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
    [alert addButton:@"OK" actionBlock:^{
        [email becomeFirstResponder];
    }];
    [alert showError:@"Email ❌" subTitle:@"Seems like there is something wrong with your email. Try again! 🙃" closeButtonTitle:nil duration:0.0];
}
-(void)showUsernameErrorMessage {
    
    [self.view endEditing:true];

    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
    [alert addButton:@"OK" actionBlock:^{
        [username becomeFirstResponder];
    }];
    [alert showError:@"Username ❌" subTitle:@"Seems like your username is already taken. Try again! 🙃" closeButtonTitle:nil duration:0.0];
}
-(void)showPasswordErrorMessage {

    [self resignFirstResponder];

    SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];
    [alert addButton:@"OK" actionBlock:^{
        [password becomeFirstResponder];
    }];
    [alert showError:@"Password ❌" subTitle:@"Seems like your password is invalid. Make sure it is at least 8 characters long and include 1 letter and 1 number! 🙃" closeButtonTitle:nil duration:0.0];
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
-(void)isReadyToSignUp {
    if (emailValid && usernameValid && passwordValid) {
        // show sign up button
        [self slideInSignUpButton];
    } else {
        [self slideOutSignUpButton];
    }
}

-(void)setSignifierForTextField:(UITextField *)textField withImage:(UIImage *)image {
    UIImageView * imgView = [[UIImageView alloc] initWithImage:image];
    imgView.userInteractionEnabled = true;
    textField.rightView = imgView;
}
@end
