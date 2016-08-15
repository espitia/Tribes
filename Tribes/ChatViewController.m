//
//  ChatViewController.m
//  Tribes
//
//  Created by German Espitia on 8/12/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "ChatViewController.h"
@import Firebase;
#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "JSQMessagesBubbleImage.h"
#import "UIImage+JSQMessages.h"
#import "UIColor+JSQMessages.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessage.h"

@interface ChatViewController () {
    NSMutableArray * messages;
    JSQMessagesBubbleImage * outgoingBubbleImageView;
    JSQMessagesBubbleImage * incomingBubbleImageView;
    FIRDatabaseReference * messageRef;

}
@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // data spurce for messages
    messages = [[NSMutableArray alloc] init];
    
    // remove avatars
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    // set title for vc
    self.title = self.tribe.name;
    
    // set up bubbles
    [self setupBubbles];
    
    // set reference to fetch messages
    messageRef = [[[[FIRDatabase database] reference] child:@"messages"] child:self.tribe.objectId];
    
    //remove accessory (left button)
    self.inputToolbar.contentView.leftBarButtonItem = nil;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self observeMessages];
}

#pragma mark - Data Source

-(id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return messages[indexPath.item];
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return messages.count;
}

-(id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage * message = messages[indexPath.item];
    if ([message.senderId isEqualToString:self.senderId]) {
        return outgoingBubbleImageView;
    } else {
        return incomingBubbleImageView;
    }
}
-(id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    JSQMessagesCollectionViewCell * cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    JSQMessage * message = messages[indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        cell.textView.textColor = [UIColor whiteColor];
    } else {
        cell.textView.textColor = [UIColor whiteColor];
        NSAttributedString * displayName = [[NSAttributedString alloc] initWithString:message.senderDisplayName];
        cell.cellTopLabel.attributedText = displayName;
        cell.cellTopLabel.textAlignment = NSTextAlignmentLeft;
        cell.cellTopLabel.textInsets = UIEdgeInsetsMake(0.0f, 15.0f, 0.0f, 0.0f);
    }
    return cell;
}

-(CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 20;
}


#pragma mark - Delegate

-(void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath {
    
}

-(void)didPressAccessoryButton:(UIButton *)sender {
    
}

-(void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    
    FIRDatabaseReference * itemRef = [messageRef childByAutoId];
    id messageItem = @{
                       @"text" : text,
                       @"senderId": self.senderId,
                       @"displayName": senderDisplayName
                       
                       };
    [itemRef setValue:messageItem];
    [self finishSendingMessage];
    
}
-(void)observeMessages {
    FIRDatabaseQuery * query = [messageRef queryLimitedToLast:30];
    
    
    [query observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSString * senderId = [[snapshot childSnapshotForPath:@"senderId"] value];
        NSString * text = [[snapshot childSnapshotForPath:@"text"] value];
        NSString * displayName = [[snapshot childSnapshotForPath:@"displayName"] value];
        [self addMessageWithSenderId:senderId displayName:displayName andText:text];
        [self finishReceivingMessage];
    }];
}



#pragma mark - Helper methods

-(void)addMessageWithSenderId:(NSString *)senderId displayName:(NSString *)displayName andText:(NSString*)text {
    
    JSQMessage * message = [JSQMessage messageWithSenderId:senderId displayName:displayName text:text];
    [messages addObject:message];
}


-(void)setupBubbles {
    JSQMessagesBubbleImageFactory * factory = [[JSQMessagesBubbleImageFactory alloc] init];
    UIColor * baseColor = [UIColor colorWithRed:255.0f/255.0f green:177.0f/255.0f blue:0.0f/255.0f alpha:1.0];
    outgoingBubbleImageView = [factory outgoingMessagesBubbleImageWithColor:[UIColor lightGrayColor]];
    incomingBubbleImageView = [factory incomingMessagesBubbleImageWithColor:baseColor];
}



@end
