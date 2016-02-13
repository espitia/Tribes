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

@interface SignupViewController () {
    IBOutlet UITextField *username;
    IBOutlet UITextField *password;
    IBOutlet UITextField *confirmPassword;
}

@end

@implementation SignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    password.secureTextEntry = TRUE;
    confirmPassword.secureTextEntry = TRUE;

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

#pragma mark - Sign Up User

- (IBAction)signUp:(id)sender {
    
    // sign up with phonenumber (digits by twitter Fabrics)
    [[Digits sharedInstance] authenticateWithCompletion:^(DGTSession *session, NSError *error) {
        
        if (!error) {

            // sign up anonymously (no user/pass w/ parse and add digits user id to parse user object
            [PFAnonymousUtils logInWithBlock:^(PFUser *user, NSError *error) {
               
                if (error) {
                    // handle error
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
                            [self dismissViewControllerAnimated:true completion:nil];
                        }
                    }];
                }
            }];
        }
    }];
}

@end
