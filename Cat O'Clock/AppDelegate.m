//
//  AppDelegate.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/17/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "AppDelegate.h"
#import "AlarmManager.h"
#import "AlarmModel.h"
@import AVFoundation;

@interface AppDelegate ()

@property (nonatomic, strong) AlarmManager *alarmManager;
@property (nonatomic, strong) NSMutableArray *alarmsArray;
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
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"WillTerminate");
    
    [self.alarmManager stopAlarmTimer];
    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [self.alarmManager stopAudioPlayer];
    
    self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
    for (AlarmModel *alarm in self.alarmsArray) {
        if (alarm.switchState == YES) {
            NSDate * theDate = [[NSDate date] dateByAddingTimeInterval:10]; // set a localnotificaiton for 10 seconds
            UIApplication *app = [UIApplication sharedApplication];
            NSArray *oldNotifications = [app scheduledLocalNotifications];
            
            // Clear out the old notification before scheduling a new one.
            if ([oldNotifications count] > 0)
                [app cancelAllLocalNotifications];
            
            // Create a new notification.
            UILocalNotification* alarm = [[UILocalNotification alloc] init];
            if (alarm)
            {
                alarm.fireDate = theDate;
                alarm.timeZone = [NSTimeZone defaultTimeZone];
                alarm.repeatInterval = 0;
                //alarm.soundName = @"sonar";
                alarm.alertBody = @"Merrr... Exiting app disables alarms. Come back to re-activate them." ;
                
                [app scheduleLocalNotification:alarm];
            }
            break;
        }
    }
}

@end
