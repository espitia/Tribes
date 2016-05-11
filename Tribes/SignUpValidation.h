//
//  SignUpValidation.h
//  Tribes
//
//  Created by German Espitia on 2/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SignUpValidation : NSObject

-(BOOL)isEmailValid:(NSString *)email;
-(void)isUsernameValid:(NSString *)usernameToCheck withBlock:(void(^)(BOOL success))callback;
-(BOOL)isPasswordValid:(NSString *)password;

@end
