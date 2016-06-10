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

@end
