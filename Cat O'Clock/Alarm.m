//
//  Alarm.m
//  Snoozecontrol
//
//  Created by Matthew Kuhlke on 9/17/14.
//  Copyright (c) 2014 Silbertown. All rights reserved.
//

#import "Alarm.h"

@interface Alarm()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation Alarm

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return _dateFormatter;
}

#pragma mark NSCoding

#define kDateKey       @"Date"
#define kEnabledKey @"Enabled"
#define kHourKey @"Hour"
#define kMinuteKey @"Minute"
#define kSnoozeCountKey  @"Count"
#define kSnoozeLengthKey @"Length"

- (NSDateComponents *)dateComponentsFromAlarm {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay | NSCalendarUnitSecond | NSCalendarUnitTimeZone;
    
    NSDateComponents *components =
    [calendar components:unitFlags fromDate:[NSDate date]];
    
    [components setHour:self.hour];
    [components setMinute:self.minute];
    [components setSecond:0];
    return components;
}

- (NSDate *)dateFromAlarm {
    return [[NSCalendar currentCalendar] dateFromComponents:[self dateComponentsFromAlarm]];
}

- (NSDate *)nextAlarm {
    NSDate *now = [NSDate date];
    
    NSDate *alarm = [self dateFromAlarm];
    
    NSComparisonResult compare = [alarm compare:now];
    
    if (compare == NSOrderedAscending) {
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 1;
        
        alarm = [[NSCalendar currentCalendar] dateByAddingComponents:dayComponent toDate:alarm options:0];
    }
    return alarm;
}

- (NSString *)timeString {
    return [self.dateFormatter stringFromDate:[self dateFromAlarm]];
}

- (NSString *)firstAlarmTimeString {
    
    
    NSInteger aheadOffset = -self.snoozeCount * self.snoozeLength;
    
    NSDateComponents *aheadComponents = [[NSDateComponents alloc] init];
    aheadComponents.minute = aheadOffset;
    
    NSDate *firstAlarmTime = [[NSCalendar currentCalendar] dateByAddingComponents:aheadComponents toDate:[self dateFromAlarm] options:0];
    
    return [self.dateFormatter stringFromDate:firstAlarmTime];
}

- (NSString *)hoursFromNowTimeString {
    
    NSDate *now = [NSDate date];
    
    NSDate *alarm = [self nextAlarm];
    
    NSUInteger unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute |NSCalendarUnitTimeZone;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags
                                                        fromDate:now
                                                          toDate:alarm
                                                         options:0];
    
    return [NSString stringWithFormat:@"%li:%02li", components.hour, components.minute + 1];
}

- (id)initWithHour:(NSInteger)hour minute:(NSInteger)minute snoozeCount:(int)count snoozeLength:(int)length enabled:(BOOL)enabled {
    
    if (self = [super init]) {
        self.hour = hour;
        self.minute = minute;
        self.enabled = enabled;
        self.snoozeCount = count;
        self.snoozeLength = length;
    }
    
    return self;
}


- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeBool:self.enabled forKey:kEnabledKey];
    [encoder encodeInteger:self.hour forKey:kHourKey];
    [encoder encodeInteger:self.minute forKey:kMinuteKey];
    [encoder encodeInt:self.snoozeLength forKey:kSnoozeLengthKey];
    [encoder encodeInt:self.snoozeCount forKey:kSnoozeCountKey];
}


- (id)initWithCoder:(NSCoder *)decoder {
   
    NSInteger hour = [decoder decodeIntegerForKey:kHourKey];
    NSInteger minute = [decoder decodeIntegerForKey:kMinuteKey];
    BOOL enabled = [decoder decodeBoolForKey:kEnabledKey];
    int snoozeCount = [decoder decodeIntForKey:kSnoozeCountKey];
    int snoozeLength = [decoder decodeIntForKey:kSnoozeLengthKey];
    
    return [self initWithHour:hour minute:minute snoozeCount:snoozeCount snoozeLength:snoozeLength enabled:enabled];
}


#pragma mark Class Methods

+ (id)defaultAlarm {
    return [[Alarm alloc] initWithHour:8 minute:0 snoozeCount:0 snoozeLength:5 enabled:YES];
}


@end
