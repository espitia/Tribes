//
//  SignUpValidation.h
//  Tribes
//
//  Created by German Espitia on 2/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SignUpValidation : NSObject

- (void)isEmailValid:(NSString *)email withBlock:(void(^)(int error))callback;
-(void)isUsernameValid:(NSString *)usernameToCheck withBlock:(void(^)(int error))callback;
-(BOOL)isPasswordValid:(NSString *)password;

@end
