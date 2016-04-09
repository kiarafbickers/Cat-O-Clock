//
//  AlarmManager.h
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/21/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AlarmModel.h"

@import AVFoundation;


@interface AlarmManager : NSObject

@property (nonatomic, retain) NSArray *alarmsArray;
@property (nonatomic, strong) AVAudioPlayer *alarmAudioPlayer;
@property (nonatomic, strong) NSNumber *alarmToEditNSNumber;
@property (nonatomic) NSInteger alarmToEditAtIndex;
@property (nonatomic) BOOL alarmToEditBool;

+ (instancetype)sharedAlarmDataStore;


# pragma mark - MainTableView Methods

- (void)checkForOldAlarm;
- (void)checkForValidAlarm;

- (void)removeAlarmFromAlarmArrayAtIndex:(NSUInteger)alarmIndex;
- (void)updateAlarmInAlarmArray:(NSUInteger)alarmIndex;

- (void)sendNoticationInAppBackgroundAndInactiveState;

- (void)startTimerWithDate:(NSDate *)date;
- (void)startAudioPlayer;


# pragma mark - AddAlarmViewContoller Methods

- (void)addAlarmToAlarmArray:(AlarmModel *)alarmModel;
- (void)updateAlarmInAlarmArray:(NSNumber *)alarmIndex andAlarm:(AlarmModel *)newAlarm;


# pragma mark - ModalViewController Methods

- (void)stopTimer;
- (void)stopAudioPlayer;


# pragma mark - AppDelegate Methods

- (void)setupWarningNotificationWithDate:(NSDate *)date;

@end
