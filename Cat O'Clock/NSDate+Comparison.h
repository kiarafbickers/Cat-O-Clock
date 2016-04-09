//
//  NSDate+Comparison.h
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/24/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Compare)

- (BOOL)isLaterThanOrEqualTo:(NSDate*)date;
- (BOOL)isEarlierThanOrEqualTo:(NSDate*)date;
- (BOOL)isLaterThan:(NSDate*)date;
- (BOOL)isEarlierThan:(NSDate*)date;
- (NSDate *)returnTimeOfFutureDate;

@end
