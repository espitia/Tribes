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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Text Field Delegate

-(void)textFieldDidEndEditing:(UITextField *)textField {
   
    // HANDLE USERNAME
    if (textField == username) {
        
        PFQuery * query = [PFUser query];
        [query whereKey:@"username" equalTo:textField.text];
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (!error) {
                if (objects.count > 0) {
                    [self showAlertWithTitle:@"❌❌❌" andMessage:@"Username is taken! Please try another one."];
                } else {
                    NSLog(@"username NOT TAKEN");
                }
            }
        }];
        
    }
    // HANDLE FIRST PASSWORD FIELD
    else if (textField == password) {
        
        if ([self isValidPassword:password.text]) {
            NSLog(@"password valid");
        } else {
            [self showAlertWithTitle:@"❌❌❌" andMessage:@"Pass word must be 8 characters long and include at least 1 letter and 1 number."];
        }
        
        
    }
    // HANDLE SECOND PASSWORD FIELD
    else if (textField == confirmPassword) {
        
        if ([textField.text isEqualToString:password.text]) {
            NSLog(@"second pass valid");
        } else {
            [self showAlertWithTitle:@"❌❌❌" andMessage:@"Passwords don't match!"];
        }
        
    }
}

#pragma mark - Util
// *** Validation for Password ***

// "^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$" --> (Minimum 8 characters at least 1 Alphabet and 1 Number)
// "^(?=.*[A-Za-z])(?=.*\d)(?=.*[$@$!%*#?&])[A-Za-z\d$@$!%*#?&]{8,16}$" --> (Minimum 8 and Maximum 16 characters at least 1 Alphabet, 1 Number and 1 Special Character)
// "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$" --> (Minimum 8 characters at least 1 Uppercase Alphabet, 1 Lowercase Alphabet and 1 Number)
// "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[$@$!%*?&])[A-Za-z\d$@$!%*?&]{8,}" --> (Minimum 8 characters at least 1 Uppercase Alphabet, 1 Lowercase Alphabet, 1 Number and 1 Special Character)
// "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[$@$!%*?&])[A-Za-z\d$@$!%*?&]{8,10}" --> (Minimum 8 and Maximum 10 characters at least 1 Uppercase Alphabet, 1 Lowercase Alphabet, 1 Number and 1 Special Character)

-(BOOL)isValidPassword:(NSString *)passwordString {
    NSString *stricterFilterString = @"^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\fd22\\d]{8,}$";
    NSPredicate *passwordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", stricterFilterString];
    return [passwordTest evaluateWithObject:passwordString];
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    
    // weak self to not have any issues to present alert view
    __unsafe_unretained typeof(self) weakSelf = self;
    
    // alert controller
    UIAlertController * __block alert;
    UIAlertAction * __block defaultAction;
    
    // message to go in alert view
    NSString * __block alertTitle = title;
    NSString * __block alertMessage = message;
    
    defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                                               
                                           }];
    
    // finish alert set up
    alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                message:alertMessage
                                         preferredStyle:UIAlertControllerStyleAlert];
    
    
    // add action (if success, pop to tribe VC)
    [alert addAction:defaultAction];
    
    // present alert
    [weakSelf presentViewController:alert animated:YES completion:nil];
}

-(BOOL)isUsernameValid:(NSString *)usernameToCheck {
    
    __block BOOL valid;
    
    PFQuery * query = [PFUser query];
    [query whereKey:@"username" equalTo:usernameToCheck];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            if (objects.count > 0) {
                valid = false;
            } else {
                valid = true;
            }
        }
    }];
    
    return valid;
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
