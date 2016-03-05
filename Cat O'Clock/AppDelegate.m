//
//  AppDelegate.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/17/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#import "AppDelegate.h"

#import "AlarmModel.h"
#import "AlarmManager.h"
#import "BackgroundTask.h"
#import "MainTableViewController.h"

@import AVFoundation;


@interface AppDelegate ()

@property (nonatomic, strong) AlarmManager *alarmManager;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundUploadTask;
@property (nonatomic) BackgroundTask *backgroundTask;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //NSLog(@"application didFinishLaunchingWithOptions");
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    
    /* CHECK PERMISSIONS */
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    NSError *setCategoryErr = nil;
    NSError *activationErr  = nil;
    
    /* ENABLE AUDIO */
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&setCategoryErr];
    [[AVAudioSession sharedInstance] setActive:YES error:&activationErr];
    
    self.alarmManager = [AlarmManager sharedAlarmDataStore];
    [self.alarmManager checkForOldAlarm];
    [self.alarmManager checkForValidAlarm];
    
    [self stopBackgroundTask];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //NSLog(@"DidBecomeActive");
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    //NSLog(@"WillResignActive");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //NSLog(@"WillEnterForeground");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    //NSLog(@"applicationDidEnterBackground");

    self.backgroundTask = [[BackgroundTask alloc] init];
    
    // Handle events exceeding 3-10 minutes here
    [self functionYouWantToRunInTheBackground];
    [self startBackgroundTask];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    //NSLog(@"WillTerminate!");
    
    [self.alarmManager stopTimer];
    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
    [self.alarmManager stopAudioPlayer];

    for (AlarmModel *alarm in self.alarmManager.alarmsArray) {
        if (alarm.switchState == YES) {
            if (application.applicationIconBadgeNumber == 0) {
                [application setApplicationIconBadgeNumber:1];
            }
            
            NSDate *warningNotificationTimeDelay = [NSDate dateWithTimeIntervalSinceNow:3.0];
            [self.alarmManager setupWarningNotificationWithDate:warningNotificationTimeDelay];
            
            break;
        }
    }
}


#pragma mark - Backround Methods

-(void) backgroundCallback:(id)info
{
    //NSLog(@"BackroundTaskRunning: %f", [UIApplication sharedApplication].backgroundTimeRemaining);
}

-(void) startBackgroundTask
{
    //NSLog(@"startBackgroundTask");
    [self.backgroundTask startBackgroundTasks:2 target:self selector:@selector(backgroundCallback:)];
}

-(void) stopBackgroundTask
{
    [self.backgroundTask stopBackgroundTask];
}

-(void) functionYouWantToRunInTheBackground
{
    //NSLog(@"functionYouWantToRunInTheBackground");
    
    [self.alarmManager stopTimer];
    
    for (AlarmModel *firstAlarm in self.alarmManager.alarmsArray) {
        if (firstAlarm.switchState == YES) {
            [self.alarmManager startTimerWithDate:firstAlarm.date];
            break;
        }
    }
}

@end
