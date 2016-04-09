//
//  NSDate+Comparison.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/24/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "NSDate+Comparison.h"

@implementation NSDate (Compare)

-(BOOL)isLaterThanOrEqualTo:(NSDate*)date
{
    return !([self compare:date] == NSOrderedAscending);
}

-(BOOL)isEarlierThanOrEqualTo:(NSDate*)date
{
    return !([self compare:date] == NSOrderedDescending);
}

-(BOOL)isLaterThan:(NSDate*)date
{
    return ([self compare:date] == NSOrderedDescending);
    
}

-(BOOL)isEarlierThan:(NSDate*)date
{
    return ([self compare:date] == NSOrderedAscending);
}

- (NSDate *)returnTimeOfFutureDate
{
    NSDate *nextTime;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSCalendarUnit calendarUnits = NSCalendarUnitTimeZone | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *components = [calendar components:calendarUnits fromDate:[NSDate date]];
    components.day += 1;
    NSDate *oneDayFromNow = [calendar dateFromComponents:components];
    
    NSCalendarOptions options = NSCalendarMatchNextTime;
    if ([self isEarlierThan:[NSDate date]]){
        NSDateComponents *oldComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:self];
        NSInteger hour = [oldComponents hour];
        NSInteger minute = [oldComponents minute];
        
        nextTime = [calendar nextDateAfterDate:self matchingHour:hour minute:minute second:0 options:options];
    } else if ([self isLaterThan:oneDayFromNow]) {
        NSDateComponents *oldComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:self];
        NSInteger hour = [oldComponents hour];
        NSInteger minute = [oldComponents minute];
        
        nextTime = [calendar dateBySettingHour:hour minute:minute second:0 ofDate:[NSDate date] options:options];
    } else {
        nextTime = self;
    }
    
    return nextTime;
}

@end
