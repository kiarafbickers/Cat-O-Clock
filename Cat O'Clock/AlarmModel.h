//
//  AlarmModel.h
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/18/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlarmModel : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *timeString;
@property (nonatomic) BOOL switchState;

- (instancetype)initWithDate:(NSDate *)date withSwitchState:(BOOL)switchState;
- (instancetype)initWithDate:(NSDate *)date WithString:(NSString *)timeString withSwitchState:(BOOL)switchState;

@end
