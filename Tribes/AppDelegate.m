//
//  AppDelegate.m
//  Tribes
//
//  Created by German Espitia on 1/8/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "AppDelegate.h"
#import "Parse.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "User.h"
#import "SCLAlertView.h"
#import "HelpshiftAll.h"
#import "HelpshiftCore.h"
#import <Leanplum/Leanplum.h>
#import "TribesTableViewController.h"
#import <UXCam/UXCam.h>


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // [Optional] Power your app with Local Datastore. For more info, go to
    // https://parse.com/docs/ios/guide#local-datastore
    [Parse enableLocalDatastore];
    
    // Initialize Parse.
    [Parse setApplicationId:@"qkVfFQQyzW0O8hMLqYoqaOqltuJtF1qlMDOahqfO"
                  clientKey:@"e5jVDLbxBVEw9KMZivDMh1NZaXCzdxIRhiXpXMmO"];
    
    // [Optional] Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // initialize Fabric:Crashlytics
    [Fabric with:@[[Crashlytics class]]];
    
    // Helpshift
    [HelpshiftCore initializeWithProvider:[HelpshiftAll sharedInstance]];
    [HelpshiftCore installForApiKey:@"a250753efe5cf80517add93d137cea11" domainName:@"tribes.helpshift.com" appID:@"tribes_platform_20160505142741624-1e3d5fb2e22f334"];
    
    // We've inserted your Tribes API keys here for you :)
#ifdef DEBUG
    LEANPLUM_USE_ADVERTISING_ID;
    [Leanplum setAppId:@"app_FhrLCghhaaP94pieozdYqwWaEhKDnGgJ2WmFMwZIZTk" withDevelopmentKey:@"dev_JJ9hrT9zgGyMn0qv2hGgk1k9na0CkkXlNgZrV33l1xM"];
#else
    [Leanplum setAppId:@"app_FhrLCghhaaP94pieozdYqwWaEhKDnGgJ2WmFMwZIZTk" withProductionKey:@"prod_9FosQkjVydQXufcZg9ra3nXr09HAIeHjlyaQu9Ay1UQ"];
#endif
    
    // Optional: Syncs the files between your main bundle and Leanplum.
    // This allows you to swap out and A/B test any resource file
    // in your project in realtime.
    // Replace MyResources with a list of actual paths to include.
    // [Leanplum syncResourcePaths:@[@"MyResources/.*"] excluding:nil async:YES];
    
    // Optional: Tracks in-app purchases automatically as the "Purchase" event.
    // To require valid receipts upon purchase or change your reported
    // currency code from USD, update your app settings.
    // [Leanplum trackInAppPurchases];
    
    // Optional: Tracks all screens in your app as states in Leanplum.
    // [Leanplum trackAllAppScreens];
    
    // Starts a new session and updates the app content from Leanplum.
    [Leanplum start];
    
    [UXCam startWithKey:@"88d0935a20b0ad1"];
    
    // ui changes
    [self colorNavBar];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *installation = [PFInstallation currentInstallation];
    [installation setDeviceTokenFromData:deviceToken];
    installation.channels = @[ @"global" ];
    [installation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    if ([userInfo objectForKey:@"aps"]) {
    
        User * currentUser = [User currentUser];
        NSString * title;
        NSString * messageToDisplay = userInfo[@"aps"][@"alert"];
        NSString * objectIdOfUserToReplyTo = userInfo[@"senderId"];
        NSString * habitName = userInfo[@"habitName"];
        __block NSString * messageToSend;
        __block NSString * categoryToSend;
        SCLAlertView * alert = [[SCLAlertView alloc] initWithNewWindow];

        NSString * category = userInfo[@"aps"][@"category"];   // The one we want to switch on
        NSArray * possibleCategories = @[@"MOTIVATION_REPLY",
                                         @"COMPLETION_REPLY",
                                         @"WATCHING_YOU_REPLY",
                                         @"THANK_YOU_FOR_APPLAUSE_REPLY",
                                         @"HIBERNATION_RESPONSE",
                                         @"NEW_PENDING_MEMBER",
                                         @"RELOAD"];
        
        int item = (int)[possibleCategories indexOfObject:category];
        
        switch (item) {
            case 0: {
                // MOTIVATIONAL REPLY
                title = @"Motivation Received 💪";
                [alert addButton:@"👌" actionBlock:^{
                    messageToSend = [NSString stringWithFormat:@"%@: 👌 (%@)", currentUser[@"username"], habitName];
                    categoryToSend = @"WATCHING_YOU_REPLY";
                    [self sendPushWithMessage:messageToSend toUserWithObjectId:objectIdOfUserToReplyTo habitName:habitName andCategory:categoryToSend];
                }];
                [alert addButton:@"✋" actionBlock:^{
                    messageToSend = [NSString stringWithFormat:@"%@: 🖐 (%@)", currentUser[@"username"], habitName];
                    [self sendPushWithMessage:messageToSend toUserWithObjectId:objectIdOfUserToReplyTo habitName:habitName andCategory:nil];
                }];
            }
                break;
            case 1: {
                // COMPLETION REPLY
                title = @"Squad is up!";
                [alert addButton:@"👏" actionBlock:^{
                    messageToSend = [NSString stringWithFormat:@"%@: 👏 (%@)", currentUser[@"username"], habitName];
                    categoryToSend = @"THANK_YOU_FOR_APPLAUSE_REPLY";
                    [self sendPushWithMessage:messageToSend toUserWithObjectId:objectIdOfUserToReplyTo habitName:habitName andCategory:categoryToSend];
                }];
            }
                break;
            case 2: {
                // WATCHING YOU REPLY
                title = @"Watch em!";
                messageToSend = [NSString stringWithFormat:@"%@: 👀 (%@)", currentUser[@"username"], habitName];
                [alert addButton:@"👀" actionBlock:^{
                    [self sendPushWithMessage:messageToSend toUserWithObjectId:objectIdOfUserToReplyTo habitName:habitName andCategory:categoryToSend];
                }];
            }
                break;
            case 3: {
                // THANK YOU FOR APPLAUSE REPLY
                title = @"Great job!";
                [alert addButton:@"✊" actionBlock:^{
                    messageToSend = [NSString stringWithFormat:@"%@: ✊ (%@)", currentUser[@"username"], habitName];
                    [self sendPushWithMessage:messageToSend toUserWithObjectId:objectIdOfUserToReplyTo habitName:habitName andCategory:nil];
                }];
            }
                break;
            case 4: {
                // HIBERNATION REPONSE
                title = @"Wake up 💤";
                [alert addButton:@"Yes" actionBlock:^{
                    [[User currentUser] removeAllHibernationFromActivities];
                    [self deleteHibernationNotification];
                }];
                [alert addButton:@"No" actionBlock:^{
                }];
            }
                break;
                
            case 5: {
                // NEW PENDING MEMBER
                title = @"NEW MEMBER 👬";
                [alert addButton:@"GOT IT" actionBlock:^{
                    [[User currentUser] fetchUserFromNetworkWithBlock:^(bool success) {
                        UINavigationController * navController = (UINavigationController *)self.window.rootViewController;
                        TribesTableViewController * vc = (TribesTableViewController *)navController.viewControllers[0];
                        [vc.tableView reloadData];
                    }];
                }];
            }
                
                break;
            case 6: {
                // ADMIN ADDED MEMBER
                title = @"NEW TRIBE 👬";
                [alert addButton:@"AWESOME" actionBlock:^{
                    UINavigationController * navController = (UINavigationController *)self.window.rootViewController;
                    [[User currentUser] fetchUserFromNetworkWithBlock:^(bool success) {
                        TribesTableViewController * vc = (TribesTableViewController *)navController.viewControllers[0];
                        [vc.tableView reloadData];
                    }];
                }];
            }
                
                break;
            default:
                [alert addButton:@"OK" actionBlock:^{
                }];
                break;
        }
        
        [alert showInfo:title subTitle:messageToDisplay closeButtonTitle:nil duration:0.0];
    }

}
-(void)sendPushWithMessage:(NSString *)message toUserWithObjectId:(NSString *)objectId habitName:(NSString *)habitName andCategory:(NSString *)category {
    PFQuery * queryForUserToReplyTo = [PFUser query];
    [queryForUserToReplyTo getObjectInBackgroundWithId:objectId block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [[User currentUser] sendPushFromMemberToMember:(User *)object withMessage:message habitName:habitName andCategory:category];
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Notificaitons

-(void)setUpNotifications:(UIApplication *)application {
    
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    
    // ACTION 1
    UIMutableUserNotificationAction * acknowledgeAction = [[UIMutableUserNotificationAction alloc] init];
    acknowledgeAction.identifier = @"ACKNOWLEDGE";
    acknowledgeAction.title = @"👌";
    acknowledgeAction.activationMode = UIUserNotificationActivationModeBackground;
    acknowledgeAction.destructive = NO;
    acknowledgeAction.authenticationRequired = NO;
    
    // ACTION 2
    UIMutableUserNotificationAction * notDoingItAction = [[UIMutableUserNotificationAction alloc] init];
    notDoingItAction.identifier = @"NOT_DOING_IT";
    notDoingItAction.title = @"🖐";
    notDoingItAction.activationMode = UIUserNotificationActivationModeBackground;
    notDoingItAction.destructive = NO;
    notDoingItAction.authenticationRequired = NO;
    
    // ACTION 3
    UIMutableUserNotificationAction * applaudAction = [[UIMutableUserNotificationAction alloc] init];
    applaudAction.identifier = @"APPLAUD";
    applaudAction.title = @"👏";
    applaudAction.activationMode = UIUserNotificationActivationModeBackground;
    applaudAction.destructive = NO;
    applaudAction.authenticationRequired = NO;
    
    // ACTION 4
    UIMutableUserNotificationAction * textReplyAction = [[UIMutableUserNotificationAction alloc] init];
    textReplyAction.identifier = @"TEXT_REPLY";
    textReplyAction.title = @"💬";
    textReplyAction.activationMode = UIUserNotificationActivationModeBackground;
    textReplyAction.destructive = NO;
    textReplyAction.authenticationRequired = NO;
    textReplyAction.behavior = UIUserNotificationActionBehaviorTextInput;
    
    // ACTION 5
    UIMutableUserNotificationAction * watchingYouAction = [[UIMutableUserNotificationAction alloc] init];
    watchingYouAction.identifier = @"WATCHING_YOU";
    watchingYouAction.title = @"👀";
    watchingYouAction.activationMode = UIUserNotificationActivationModeBackground;
    watchingYouAction.destructive = NO;
    watchingYouAction.authenticationRequired = NO;
    
    // ACTION 6
    UIMutableUserNotificationAction * thankYouForApplauseAction = [[UIMutableUserNotificationAction alloc] init];
    thankYouForApplauseAction.identifier = @"THANK_YOU_FOR_APPLAUSE";
    thankYouForApplauseAction.title = @"✊";
    thankYouForApplauseAction.activationMode = UIUserNotificationActivationModeBackground;
    thankYouForApplauseAction.destructive = NO;
    thankYouForApplauseAction.authenticationRequired = NO;
    
    // ACTION 7
    UIMutableUserNotificationAction * removeHibernationAction = [[UIMutableUserNotificationAction alloc] init];
    removeHibernationAction.identifier = @"TURN_OFF_HIBERNATION";
    removeHibernationAction.title = @"Yes";
    removeHibernationAction.activationMode = UIUserNotificationActivationModeBackground;
    removeHibernationAction.destructive = NO;
    removeHibernationAction.authenticationRequired = NO;
    
    // ACTION 8
    UIMutableUserNotificationAction * dontRemoveHibernationAction = [[UIMutableUserNotificationAction alloc] init];
    dontRemoveHibernationAction.identifier = @"DONT_TURN_OFF_HIBERNATION";
    dontRemoveHibernationAction.title = @"No";
    dontRemoveHibernationAction.activationMode = UIUserNotificationActivationModeBackground;
    dontRemoveHibernationAction.destructive = NO;
    dontRemoveHibernationAction.authenticationRequired = NO;
    
    // CATEGORY 1 (ACTION 1 AND ACTION 2)
    UIMutableUserNotificationCategory * motivationReplyCategory = [[UIMutableUserNotificationCategory alloc] init];
    motivationReplyCategory.identifier = @"MOTIVATION_REPLY";
    [motivationReplyCategory setActions:@[notDoingItAction, acknowledgeAction] forContext:UIUserNotificationActionContextDefault];

    // CATEGORY 2 (ACTION 3)
    UIMutableUserNotificationCategory * completionReplyCategory = [[UIMutableUserNotificationCategory alloc] init];
    completionReplyCategory.identifier = @"COMPLETION_REPLY";
    [completionReplyCategory setActions:@[applaudAction] forContext:UIUserNotificationActionContextDefault];
    
    // CATEGORY 3 (ACTION 5)
    UIMutableUserNotificationCategory * watchingYouReplyCategory = [[UIMutableUserNotificationCategory alloc] init];
    watchingYouReplyCategory.identifier = @"WATCHING_YOU_REPLY";
    [watchingYouReplyCategory setActions:@[watchingYouAction] forContext:UIUserNotificationActionContextDefault];
    
    // CATEGORY 4 (ACTION 6)
    UIMutableUserNotificationCategory * thankYouForApplauseReplyCategory = [[UIMutableUserNotificationCategory alloc] init];
    thankYouForApplauseReplyCategory.identifier = @"THANK_YOU_FOR_APPLAUSE_REPLY";
    [thankYouForApplauseReplyCategory setActions:@[thankYouForApplauseAction] forContext:UIUserNotificationActionContextDefault];
    
    // CATEGORY 5 (ACTION 7 AND ACTION 8)
    UIMutableUserNotificationCategory * hibernationCategory = [[UIMutableUserNotificationCategory alloc] init];
    hibernationCategory.identifier = @"HIBERNATION_RESPONSE";
    [hibernationCategory setActions:@[dontRemoveHibernationAction, removeHibernationAction] forContext:UIUserNotificationActionContextDefault];
    
    NSSet * categories = [NSSet setWithArray:@[motivationReplyCategory, completionReplyCategory, watchingYouReplyCategory, thankYouForApplauseReplyCategory, hibernationCategory]];
    UIUserNotificationSettings * settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:categories];

    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
    
    // set device token
    PFInstallation *installation = [PFInstallation currentInstallation];
    [installation setObject:[PFUser currentUser] forKey:@"user"];
    [PFPush storeDeviceToken:[installation deviceToken]];
    [installation saveInBackground];
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {
    
    if ([identifier isEqualToString:@"TURN_OFF_HIBERNATION"]) {
        [[User currentUser] removeAllHibernationFromActivities];
        [self deleteHibernationNotification];
    }
    completionHandler();
}
-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {
    
    // log event
    NSString * identifierStringForEvent = identifier;
    [Answers logCustomEventWithName:@"Replied to push via action" customAttributes:@{@"action":identifierStringForEvent}];
    [Leanplum track:@"Replied to push via action" withInfo:identifierStringForEvent];
    
    User * currentUser = [User currentUser];
    NSString * objectIdOfUserToReplyTo = userInfo[@"senderId"];
    NSString * habitName = userInfo[@"habitName"];
    __block NSString * message;
    __block NSString * category;
    
    PFQuery * queryForUserToReplyTo = [PFUser query];
    [queryForUserToReplyTo getObjectInBackgroundWithId:objectIdOfUserToReplyTo block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if ([identifier isEqualToString:@"ACKNOWLEDGE"]) {
            message = [NSString stringWithFormat:@"%@: 👌 (%@)", currentUser[@"username"], habitName];
            category = @"WATCHING_YOU_REPLY";
            
        } else if ([identifier isEqualToString:@"NOT_DOING_IT"]) {
            message = [NSString stringWithFormat:@"%@: 🖐 (%@)", currentUser[@"username"], habitName];
            
        } else if ([identifier isEqualToString:@"APPLAUD"]) {
            message = [NSString stringWithFormat:@"%@: 👏 (%@)", currentUser[@"username"], habitName];
            category = @"THANK_YOU_FOR_APPLAUSE_REPLY";
        } else if ([identifier isEqualToString:@"WATCHING_YOU"]) {
            message = [NSString stringWithFormat:@"%@: 👀 (%@)", currentUser[@"username"], habitName];
        } else if ([identifier isEqualToString:@"THANK_YOU_FOR_APPLAUSE"]) {
            message = [NSString stringWithFormat:@"%@: ✊ (%@)", currentUser[@"username"], habitName];
            
        } else if ([identifier isEqualToString:@"TEXT_REPLY"]) {
            message = [NSString stringWithFormat:@"%@: %@!", currentUser[@"username"], responseInfo[@"UIUserNotificationActionResponseTypedTextKey"]];
            
        }
        
        
        [currentUser sendPushFromMemberToMember:(User *)object withMessage:message habitName:habitName andCategory:category];
        completionHandler();
        
    }];
}
#pragma mark - Util

-(void)colorNavBar {
    UIColor * baseColor = [UIColor colorWithRed:255.0f/255.0f green:177.0f/255.0f blue:0.0f/255.0f alpha:1.0];
    [[UINavigationBar appearance] setBarTintColor: baseColor];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

-(void)deleteHibernationNotification {
    for (UILocalNotification * notificaiton in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if ([notificaiton.category isEqualToString:@"HIBERNATION_RESPONSE"]) {
            [[UIApplication sharedApplication] cancelLocalNotification:notificaiton];
        }
    }
}
@end
