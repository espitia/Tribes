//
//  ChatViewController.h
//  Tribes
//
//  Created by German Espitia on 8/12/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tribe.h"
#import "JSQMessagesViewController.h"

@interface ChatViewController : JSQMessagesViewController

@property (nonatomic, strong) Tribe * tribe;
@end
