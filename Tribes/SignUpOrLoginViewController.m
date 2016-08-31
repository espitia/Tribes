//
//  SignUpOrLoginViewController.m
//  Tribes
//
//  Created by German Espitia on 2/23/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "SignUpOrLoginViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "Parse.h"
#import "SCLAlertView.h"
#import "User.h"
#import "TribesTableViewController.h"
#import "SignUpValidation.h"
#import <Leanplum/Leanplum.h>

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

@end
