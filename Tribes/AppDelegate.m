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
#import <DigitsKit/DigitsKit.h>
#import "User.h"


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
    
    // initialize Fabric:Digits
    [Fabric with:@[[Digits class]]];

    // create actions
    [self setUpNotifications:application];
    
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
    [PFPush handlePush:userInfo];
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
    
    NSSet * categories = [NSSet setWithArray:@[motivationReplyCategory, completionReplyCategory, watchingYouReplyCategory, thankYouForApplauseReplyCategory]];
    UIUserNotificationSettings * settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:categories];

    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {
    
    User * currentUser = [User currentUser];
    NSString * objectIdOfUserToReplyTo = userInfo[@"senderId"];
    __block NSString * message;
    __block NSString * category;
    
    PFQuery * queryForUserToReplyTo = [PFUser query];
    [queryForUserToReplyTo getObjectInBackgroundWithId:objectIdOfUserToReplyTo block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if ([identifier isEqualToString:@"ACKNOWLEDGE"]) {
            message = [NSString stringWithFormat:@"%@: 👌", currentUser[@"username"]];
            category = @"WATCHING_YOU_REPLY";
            
        } else if ([identifier isEqualToString:@"NOT_DOING_IT"]) {
            message = [NSString stringWithFormat:@"%@: 🖐", currentUser[@"username"]];
            
        } else if ([identifier isEqualToString:@"APPLAUD"]) {
            message = [NSString stringWithFormat:@"%@: 👏", currentUser[@"username"]];
            category = @"THANK_YOU_FOR_APPLAUSE_REPLY";
            //            User * userWhoReceivedApplause = (User *)object;
            //            [userWhoReceivedApplause addReceivedApplauseXp];
        } else if ([identifier isEqualToString:@"WATCHING_YOU"]) {
            message = [NSString stringWithFormat:@"%@: 👀", currentUser[@"username"]];
        } else if ([identifier isEqualToString:@"THANK_YOU_FOR_APPLAUSE"]) {
            message = [NSString stringWithFormat:@"%@: ✊", currentUser[@"username"]];
            
        } else if ([identifier isEqualToString:@"TEXT_REPLY"]) {
            message = [NSString stringWithFormat:@"%@: %@!", currentUser[@"username"], responseInfo[@"UIUserNotificationActionResponseTypedTextKey"]];
        }
        
        
        [currentUser sendPushFromMemberToMember:(User *)object withMessage:message andCategory:category];
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

@end
