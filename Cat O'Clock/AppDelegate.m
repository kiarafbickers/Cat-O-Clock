//
//  AppDelegate.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/17/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#import "AppDelegate.h"
#import "AlarmManager.h"
#import "AlarmModel.h"
#import "MMPDeepSleepPreventer.h"
@import AVFoundation;

@interface AppDelegate ()

@property (nonatomic, strong) AlarmManager *alarmManager;
@property (nonatomic, strong) NSMutableArray *alarmsArray;
@property (nonatomic, strong) MMPDeepSleepPreventer *sleepPreventer;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    
    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        NSLog(@"Recieved Notification %@", localNotification);
    }
    UILocalNotification *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification) {
        NSLog(@"Recieved Notification %@", remoteNotification);
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    [self.sleepPreventer startPreventSleep];
    
    self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
    for (AlarmModel *alarm in self.alarmsArray) {
        if (alarm.switchState == YES) {
            
            NSLog(@"Set alarm notification for: %@", alarm.date);
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            [localNotification setTimeZone:[NSTimeZone defaultTimeZone]];
            [localNotification setAlertBody:@"Meeeeoww!"];
            [localNotification setAlertAction:@"Open App"];
            [localNotification setHasAction:YES];
            [localNotification setFireDate:alarm.date];
            [localNotification setSoundName:filePath];
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            [self.alarmManager startTimerWithDate:alarm.date];

        }
    }
    
    //[self performSelector:@selector(applicationDidFinishLaunching:) withObject:nil afterDelay:1.0];
    
    NSLog(@"WillResignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits
    NSLog(@"DidEnterBackground");
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"WillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [self.sleepPreventer stopPreventSleep];
    
    NSLog(@"DidBecomeActive");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    if(IS_OS_8_OR_LATER)
    {
        UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    }
    
    self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
    
    for (AlarmModel *alarm in self.alarmsArray) {
        
        if (alarm.switchState == YES) {
            
            if (application.applicationIconBadgeNumber == 0) {
                [application setApplicationIconBadgeNumber:1];
            }
            
            NSDate *warningNotificationTimeDelay = [NSDate dateWithTimeIntervalSinceNow:3.0];
            UILocalNotification *warningNotification = [[UILocalNotification alloc] init];
            [warningNotification setFireDate:warningNotificationTimeDelay];
            [warningNotification setTimeZone:[NSTimeZone defaultTimeZone]];
            [warningNotification setAlertBody:@"Exiting app disables alarms. Come back to re-activate them."];
            [warningNotification setRepeatInterval:0];
            [warningNotification setSoundName:UILocalNotificationDefaultSoundName];
            [[UIApplication sharedApplication] scheduleLocalNotification:warningNotification];
            
            // Pausing the processor is necessary in order to make notification fire
            [NSThread sleepForTimeInterval:2];
            
            NSLog(@"Set alarm warning!!");
            break;
        }
    }
    
    [self.alarmManager stopTimer];
    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
    [self.alarmManager stopAudioPlayer];

    NSLog(@"WillTerminate!");
}

@end
