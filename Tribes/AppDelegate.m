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
    [Parse setApplicationId:@"k8emsJi8KX6VFiyUESvFQ9sE38Vlj4zEnddpavyJ"
                  clientKey:@"WzlPb6BjwDCuq0eqa1W51I2fn7TtgbOz7vTAueoh"];
    
    // [Optional] Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // initialize Fabric:Digits
    [Fabric with:@[[Digits class]]];

    // create actions
    [self setUpNotifications:application];
    
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
    notDoingItAction.title = @"🖕";
    notDoingItAction.activationMode = UIUserNotificationActivationModeBackground;
    notDoingItAction.destructive = NO;
    notDoingItAction.authenticationRequired = NO;
    
    // CATEGORY
    UIMutableUserNotificationCategory * defaultReplyCategory = [[UIMutableUserNotificationCategory alloc] init];
    defaultReplyCategory.identifier = @"DEFAULT_REPLY";
    [defaultReplyCategory setActions:@[notDoingItAction, acknowledgeAction] forContext:UIUserNotificationActionContextDefault];
    
    NSSet * categories = [NSSet setWithObject:defaultReplyCategory];
    UIUserNotificationSettings * settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:categories];
    
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    
    User * currentUser = [User currentUser];
    NSString * objectIdOfUserToReplyTo = userInfo[@"replyToObjectId"];
    __block NSString * message;
    
    PFQuery * queryForUserToReplyTo = [PFUser query];
    [queryForUserToReplyTo getObjectInBackgroundWithId:objectIdOfUserToReplyTo block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if ([identifier isEqualToString:@"ACKNOWLEDGE"]) {
            message = [NSString stringWithFormat:@"%@: 👌", currentUser[@"username"]];
            [currentUser sendPushToMember:(User *)object withMessage:message withBlock:^(BOOL *success) {
                completionHandler();
            }];
        } else if ([identifier isEqualToString:@"NOT_DOING_IT"]) {
            message = [NSString stringWithFormat:@"%@: 🖕", currentUser[@"username"]];
            [currentUser sendPushToMember:(User *)object withMessage:message withBlock:^(BOOL *success) {
                completionHandler();
            }];
        }
        
    }];


}


@end
