//
//  EmailValidationViewController.m
//  Tribes
//
//  Created by German Espitia on 5/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "PasswordValidationViewController.h"
#import "SignUpValidation.h"

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
    
    NSString * completeString;
    
    if ([string isEqualToString:@""]) {
        completeString = [textField.text substringToIndex:[textField.text length]-1];
    } else {
        completeString = [textField.text stringByAppendingString:string];
    }
    
    if ([validation isPasswordValid:completeString]) {
        [self slideInSignUpButton];
        passwordValid = true;
    } else {
        [self slideOutSignUpButton];
        passwordValid = false;
    }
    
    return true;
}

-(void)continueToNextVc {
    if (passwordValid)
        [self performSegueWithIdentifier:@"continue" sender:nil];
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
