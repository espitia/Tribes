//
//  EmailValidationViewController.m
//  Tribes
//
//  Created by German Espitia on 5/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "EmailValidationViewController.h"
#import "PasswordValidationViewController.h"
#import "SignUpValidation.h"
#import "SCLAlertView.h"
#import "User.h"

@interface EmailValidationViewController () <UITextFieldDelegate> {
    SignUpValidation * validation;
    UIButton * signUpButton;
    CGRect keyboardFrame;
    BOOL buttonShowing;
}

@property (strong, nonatomic) IBOutlet UITextField *emailTextField;

@end

@implementation EmailValidationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // ui touches
    self.navigationController.navigationBarHidden = false;
    self.navigationItem.title = @"Email";
    
    // lines on top and below email textfield
    UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _emailTextField.frame.origin.y, self.view.bounds.size.width, 1)];
    topLineView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:topLineView];
    
    UIView * bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _emailTextField.frame.origin.y + _emailTextField.frame.size.height, self.view.bounds.size.width, 1)];
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
    _emailTextField.delegate = self;
    validation = [[SignUpValidation alloc] init];
    
    // add notifier for when app comes into foreground
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];

}

-(void)viewDidAppear:(BOOL)animated {
    [_emailTextField becomeFirstResponder];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (!buttonShowing)
        [self slideInSignUpButton];

    return true;
}

-(void)continueToNextVc {
    
    [validation isEmailValid:_emailTextField.text withBlock:^(int error) {
        
        if (error == 0) {
            
            User * user = [User user];
            user.email = _emailTextField.text;
            
            [self performSegueWithIdentifier:@"continue" sender:user];
        } else {
            [self showErrorAlertWithError:error];
        }
        
    }];
}

-(void)showErrorAlertWithError:(int)error {
    
    NSString * errorMessage = @"";
    [_emailTextField resignFirstResponder];
    
    if (error == 1) {
        
        // syntax is wrong
        errorMessage = @"The magical unicorn of knowledge tells us there is a typo in your email. Double check to make sure it is right!";
        
        
    } else if (error == 2) {
        
        // email is already taken
        errorMessage = @"Looks like that email is already taken. Have an account already? Go back and sign in!";
    }
    
    SCLAlertView * errorAlert = [[SCLAlertView alloc] initWithNewWindow];
    [errorAlert addButton:@"GOT IT" actionBlock:^{
        [_emailTextField becomeFirstResponder];
    }];
    [errorAlert showError:@"Oh oh.. 😯" subTitle:errorMessage closeButtonTitle:nil duration:0.0];
    
    
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

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"continue"]) {
        PasswordValidationViewController * vc = (PasswordValidationViewController *)segue.destinationViewController;
        vc.user = sender;
    }
}

#pragma mark - Util

-(void)setSignifierForTextField:(UITextField *)textField withImage:(UIImage *)image {
    UIImageView * imgView = [[UIImageView alloc] initWithImage:image];
    imgView.userInteractionEnabled = true;
    textField.rightView = imgView;
}


@end
