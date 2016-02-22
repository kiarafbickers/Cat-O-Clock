//
//  Alarm.h
//  Snoozecontrol
//
//  Created by Matthew Kuhlke on 9/17/14.
//  Copyright (c) 2014 Silbertown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Alarm : NSObject <NSCoding>

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic) NSInteger hour;
@property (nonatomic) NSInteger minute;
@property (nonatomic, assign) int snoozeCount;
@property (nonatomic, assign) int snoozeLength;

- (NSDate *)dateFromAlarm;
- (NSString *)timeString;
- (NSString *)firstAlarmTimeString;
- (NSString *)hoursFromNowTimeString;
- (NSDate *)nextAlarm;

- (id)initWithHour:(NSInteger)hour minute:(NSInteger)minute snoozeCount:(int)count snoozeLength:(int)length enabled:(BOOL)enabled;

+ (id)defaultAlarm;

@end
