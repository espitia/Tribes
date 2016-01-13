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

@interface SignupViewController ()

@end

@implementation SignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signUp:(id)sender {
    
    NSLog(@"%@", [Digits sharedInstance].session);
    
    // sign up with phonenumber (digits by twitter Fabrics)
    [[Digits sharedInstance] authenticateWithCompletion:^(DGTSession *session, NSError *error) {
        
        if (!error) {

            // sign up anonymously (no user/pass w/ parse and add digits user id to parse user object
            [PFAnonymousUtils logInWithBlock:^(PFUser *user, NSError *error) {
               
                if (error) {
                    // handle error
                    NSLog(@"error signing up with Parse");
                } else {
                    
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
