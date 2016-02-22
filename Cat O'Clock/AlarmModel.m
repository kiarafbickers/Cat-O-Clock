//
//  AlarmModel.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/18/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "AlarmModel.h"

@implementation AlarmModel

#pragma mark - Initialization Method

- (instancetype)initWithDate:(NSDate *)date withSwitchState:(BOOL)switchState
{
    self = [super init];
    if (self) {
        _date = [self setSecondsToZeroWithDate:date];
        _timeString = [self getTimeStringFromDate:date];
        _switchState = switchState;
    }
    return self;
}

- (instancetype)initWithDate:(NSDate *)date WithString:(NSString *)timeString withSwitchState:(BOOL)switchState
{
    self = [super init];
    if (self) {
        _date = [self setSecondsToZeroWithDate:date];
        _timeString = timeString;
        _switchState = switchState;
    }
    return self;
}

#pragma mark - Helper Methods

- (NSString *)getTimeStringFromDate:(NSDate *)alarmTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (alarmTime != nil) {
        [formatter setDateFormat:@"hh:mm a"];
    }
    
    return [formatter stringFromDate:alarmTime];
}

-(NSDate *)setSecondsToZeroWithDate:(NSDate *)setDate
{
    /*SET SECONDS ON DATE To ZERO*/
    NSDateComponents *comp = [[NSCalendar currentCalendar] components:NSCalendarUnitSecond fromDate:setDate];
    return [setDate dateByAddingTimeInterval:-comp.second];
}

# pragma mark - NSDefaults Methods

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.date forKey:@"date"];
    [encoder encodeObject:self.timeString forKey:@"timeString"];
    [encoder encodeObject:[NSNumber numberWithInt:self.switchState] forKey:@"switchState"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if( self != nil )
    {
        self.date = [decoder decodeObjectForKey:@"date"];
        self.timeString = [decoder decodeObjectForKey:@"timeString"];
        self.switchState = [[decoder decodeObjectForKey:@"switchState"] intValue];
    }
    return self;
}


@end
