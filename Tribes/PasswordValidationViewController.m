//
//  EmailValidationViewController.m
//  Tribes
//
//  Created by German Espitia on 5/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "PasswordValidationViewController.h"
#import "UsernameValidationViewController.h"
#import "SignUpValidation.h"
#import "SCLAlertView.h"

@interface PasswordValidationViewController () <UITextFieldDelegate> {
    SignUpValidation * validation;
    UIButton * signUpButton;
    CGRect keyboardFrame;
    BOOL buttonShowing;
    BOOL passwordValid;
}

@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation PasswordValidationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // ui touches
    self.navigationController.navigationBarHidden = false;
    self.navigationItem.title = @"Password";
    _passwordTextField.secureTextEntry = YES;
    
    // lines on top and below email textfield
    UIView *topLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _passwordTextField.frame.origin.y, self.view.bounds.size.width, 1)];
    topLineView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:topLineView];
    UIView * bottomLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _passwordTextField.frame.origin.y + _passwordTextField.frame.size.height, self.view.bounds.size.width, 1)];
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
    _passwordTextField.delegate = self;
    validation = [[SignUpValidation alloc] init];
    
    // add notifier for when app comes into foreground
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [_passwordTextField becomeFirstResponder];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (!buttonShowing)
        [self slideInContinueButton];
    
    return true;
}

-(void)continueToNextVc {
    
    // if password is valid, continue to next vc (username vc)
    if ([validation isPasswordValid:_passwordTextField.text]) {
        
        self.user.password = _passwordTextField.text;
        [self performSegueWithIdentifier:@"continue" sender:self.user];
    } else {
        
        [_passwordTextField resignFirstResponder];
        SCLAlertView * errorAlert = [[SCLAlertView alloc] initWithNewWindow];
        [errorAlert addButton:@"OK" actionBlock:^{
            [_passwordTextField becomeFirstResponder];
        }];
        [errorAlert showError:@"Oh oh... 😯" subTitle:@"Passwords are annoying, we agree. Until mind readers come along, we have to use them 🤓 \n\nYour password should have at least 1 letter, 1 number and at least 6 characters long. No crazy @$#! signs. Try again!" closeButtonTitle:nil duration:0.0];
    }
}


#pragma mark - Notifications

-(void)keyboardDidShow:(id)sender {
    NSDictionary * userInfo = [sender userInfo];
    keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
}

#pragma mark - Sign Up Button

-(void)slideInContinueButton {
    
    if (!buttonShowing) {
        buttonShowing = true;
        [signUpButton setFrame:CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - keyboardFrame.size.height - 60, self.view.frame.size.width, 60)];
        
        [UIView animateWithDuration:0.4 animations:^{
            [signUpButton setFrame:CGRectMake(0, self.view.frame.size.height - keyboardFrame.size.height - 60, self.view.frame.size.width, 60)];
            [self.view addSubview:signUpButton];
        }];
    }
    
}

-(void)slideOutContinueButton {
    
    [UIView animateWithDuration:0.4 animations:^{
        buttonShowing = false;
        [signUpButton setFrame:CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - keyboardFrame.size.height - 60, self.view.frame.size.width, 60)];
    }];
    
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"continue"]) {
        UsernameValidationViewController * vc = (UsernameValidationViewController *)segue.destinationViewController;
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
