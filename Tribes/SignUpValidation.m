//
//  SignUpValidation.m
//  Tribes
//
//  Created by German Espitia on 2/24/16.
//  Copyright © 2016 German Espitia. All rights reserved.
//

#import "SignUpValidation.h"
#import <Parse/Parse.h>

@implementation SignUpValidation

// *** Validation for Password ***
// "^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$" --> (Minimum 8 characters at least 1 Alphabet and 1 Number)
// "^(?=.*[A-Za-z])(?=.*\d)(?=.*[$@$!%*#?&])[A-Za-z\d$@$!%*#?&]{8,16}$" --> (Minimum 8 and Maximum 16 characters at least 1 Alphabet, 1 Number and 1 Special Character)
// "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$" --> (Minimum 8 characters at least 1 Uppercase Alphabet, 1 Lowercase Alphabet and 1 Number)
// "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[$@$!%*?&])[A-Za-z\d$@$!%*?&]{8,}" --> (Minimum 8 characters at least 1 Uppercase Alphabet, 1 Lowercase Alphabet, 1 Number and 1 Special Character)
// "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[$@$!%*?&])[A-Za-z\d$@$!%*?&]{8,10}" --> (Minimum 8 and Maximum 10 characters at least 1 Uppercase Alphabet, 1 Lowercase Alphabet, 1 Number and 1 Special Character)

-(BOOL)isPasswordValid:(NSString *)password {
    NSString *stricterFilterString = @"^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\fd22\\d]{8,}$";
    NSPredicate *passwordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", stricterFilterString];
    return [passwordTest evaluateWithObject:password];
}

-(void)isUsernameValid:(NSString *)usernameToCheck withBlock:(void(^)(BOOL success))callback {
    
    __block BOOL valid;
    
    if ([usernameToCheck isEqualToString:@""] || usernameToCheck.length < 3) {
        callback(false);
        return;
    }
    
    PFQuery * query = [PFUser query];
    [query whereKey:@"username" equalTo:usernameToCheck];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (!error) {
            if (objects.count > 0) {
                valid = false;
            } else {
                valid = true;
            }
            callback(valid);
        }
    }];
}

/**
 * Validate a string to be an acceptable email.
 * Errors returned are ints.
 * 0 = no error
 * 1 = syntax is wrong
 * 2 = email is already taken
 */
- (void)isEmailValid:(NSString *)email withBlock:(void(^)(int error))callback {
    
    // check for syntax
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    // check for syntax
    if (![emailTest evaluateWithObject:email]) {
        callback(1);
    }
    
    // check if email already taken
    else {

        PFQuery * queryForEmail = [PFUser query];
        [queryForEmail whereKey:@"emailLowerCase" equalTo:[email lowercaseString]]; // remember to compare to lowercase copy
        [queryForEmail getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object && !error) {
                callback(2);
            } else {
                callback(0);
            }
        }];
        
    }
}


@end
