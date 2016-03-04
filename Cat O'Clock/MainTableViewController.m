//
//  MainTableViewController.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/17/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "MainTableViewController.h"

#import "Constants.h"
#import "AlarmModel.h"
#import "AlarmManager.h"
#import "ModalViewController.h"
#import "AddAlarmViewContoller.h"

#import <Giphy-iOS/AXCGiphy.h>
#import "MMPDeepSleepPreventer.h"
#import <ChameleonFramework/Chameleon.h>

@import AVFoundation;


@interface MainTableViewController () <AddAlarmViewContollerDelegate>

@property (nonatomic, strong) AlarmManager *alarmManager;

@property (nonatomic, strong) ModalViewController *gifViewController;
@property (nonatomic, strong) AddAlarmViewContoller *alarmSetViewController;

@property (nonatomic, strong) UIView *refreshColorView;
@property (nonatomic, strong) UIImageView *catImageView;
@property (nonatomic, strong) UIImageView *toastImageView;
@property (nonatomic, strong) UIView *refreshLoadingView;

@property (nonatomic, assign) BOOL isRefreshAnimating;
@property (nonatomic, assign) BOOL isRefreshIconsOverlap;
@property (nonatomic, assign) BOOL showingAlarmViewController;

@property (nonatomic, strong) NSArray *giphyResults;

@end


@implementation MainTableViewController


#pragma mark - View Lifecyle Methods

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadDataAndTableView) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup the custom refesh control animation
    [self setupRefreshControl];
    
    // Get alarms from alarm Manager data store
    self.alarmManager = [AlarmManager sharedAlarmDataStore];
    self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
    
    // Hide the navigation controller
    self.navigationController.navigationBar.hidden = YES;
    
    // Set a backround color behind the status bar
    UIView *statusBackround = [[UIView alloc] init];
    statusBackround.frame = CGRectMake(0, 0, self.view.frame.size.width, 20);
    statusBackround.backgroundColor = [UIColor flatBlackColor];
    [self.navigationController.view addSubview:statusBackround];
    
    // Set the view and table view color
    self.view.backgroundColor = [UIColor flatBlackColor];
    self.tableView.backgroundColor = [UIColor flatBlackColor];
    
    // Set the table view style
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Remove any potential alarm observers than set one
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"alarmPlaying" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showModalVCWithImage:) name:@"alarmPlaying" object:nil];
    
    // Push local notification if it is the first time loading the app
    NSInteger appLaunchCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"launchAmounts"];
    if (appLaunchCount == 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:appLaunchCount + 1 forKey:@"launchAmounts"];
        [self triggerFirstWarningAlert];
    }
    
    // Push local notification if the app is entered after applicationWillTerminate with alarms on
    if ([UIApplication sharedApplication].applicationIconBadgeNumber >= 1) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        [self triggerWarningAlert];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - Reload Data Methods

- (void)didDismissSecondViewController
{
    [self reloadDataAndTableView];
    [self hideAlarmTimeSelector];
}

- (void)reloadDataAndTableView
{
    NSLog(@"Reloaded Data");
    self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
    [self.alarmManager checkForOldAlarm];
    [self.alarmManager checkForValidAlarm];
    [self.tableView reloadData];
    NSLog(@"____________");
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    for (AlarmModel *alarm in self.alarmsArray) {
        if (alarm.switchState == YES) {
            NSLog(@"Set alarm notification for: %@", alarm.timeString);
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
}

#pragma mark - Action Methods

- (void)refresh:(id)sender
{
    // Let UI refresh control spin for effect
    double delayInSeconds = 1.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self newAlarmPull];
        [self.refreshControl endRefreshing];
    });
}

- (void)newAlarmPull
{
    // Show alarmSetViewController and set observer for its dismissal
    [self showAlarmTimeSelector];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SecondViewControllerDismissed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDismissSecondViewController) name:@"SecondViewControllerDismissed" object:nil];
}

- (void)editAlarmPressed:(id)sender
{
    // Get touched indexpath from tableview
    NSIndexPath *hitIndex = [self getIndexPathFromSender:sender];
    
    // Set properties in alarm manager to indicate which alarm in the array to edit
    self.alarmManager.alarmToEditNSNumber = [NSNumber numberWithInteger:hitIndex.row];
    self.alarmManager.alarmToEditBool = YES;
    
    // Show alarmSetViewController and set observer for its dismissal
    [self showAlarmTimeSelector];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SecondViewControllerDismissed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDismissSecondViewController) name:@"SecondViewControllerDismissed" object:nil];
}

- (void)switchChanged:(id)sender
{
    // Get touched indexpath from tableview
    NSIndexPath *hitIndex = [self getIndexPathFromSender:sender];
    
    // Update the alarm in alarm array from that corresponds to the indexpath row
    [self.alarmManager updateAlarmInAlarmArray:hitIndex.row];
    [self reloadDataAndTableView];
}


#pragma mark - Tableview Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numOfSections = 0;
    if (self.alarmsArray.count > 0)
    {
        numOfSections = 1;
        self.tableView.backgroundView = nil;
    }
    else
    {
        UILabel *noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        noDataLabel.font = [UIFont fontWithName:@"Code-Pro-Demo" size:15.0f];
        noDataLabel.textColor = [[UIColor flatWhiteColor] colorWithAlphaComponent:0.3f];
        noDataLabel.text = @"Pull to set an alarm";
        noDataLabel.textAlignment = NSTextAlignmentCenter;
        self.tableView.backgroundView = noDataLabel;
    }
    
    return numOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.alarmsArray.count;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [self colorForIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"alarmCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    AlarmModel *currentAlarm = self.alarmsArray[indexPath.row];
    
    UISwitch *switchOutlet = (UISwitch *)[cell viewWithTag:2];
    [switchOutlet setThumbTintColor:[UIColor whiteColor]];
    [switchOutlet setTintColor:[[UIColor clearColor] colorWithAlphaComponent:0.2f]];
    
    BOOL switchState = currentAlarm.switchState;
    [switchOutlet setOn:switchState animated:YES];
    [switchOutlet addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:1];
    timeLabel.text = currentAlarm.timeString;
    if (switchOutlet.on) {
        timeLabel.textColor = [[UIColor flatWhiteColor] colorWithAlphaComponent:1.0f];
    }
    else {
        timeLabel.textColor = [[UIColor flatBlackColor] colorWithAlphaComponent:0.25f];
    }
    
    UIView *lineView;
    if (![lineView isDescendantOfView:cell.contentView]) {
        lineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.contentView.frame.size.height - 1, cell.contentView.frame.size.width, 1)];
        lineView.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.025f];
        [cell.contentView addSubview:lineView];
    }

    UIButton *editAlarm = (UIButton *)[cell viewWithTag:4];
    [editAlarm addTarget:self action:@selector(editAlarmPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat viewHeight = self.view.frame.size.height;
    CGFloat customTableCellHeight = viewHeight/4;
    
    return customTableCellHeight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*CODE IN IF STATEMENT WILL DELETE*/
    if (editingStyle == UITableViewCellEditingStyleDelete){
        [self.alarmManager removeAlarmFromAlarmArrayAtIndex:indexPath.row];
        
        NSArray* paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        [self reloadDataAndTableView];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - ModalViewController Methods

- (void)showModalVCWithImage:(NSNotification *)notification
{
    NSLog(@"Received notification %@", [notification name]);
    
    if (!self.gifViewController) {
        NSUInteger randomNumber = [self getRandomNumberBetween:0 to:2400];
        
        [AXCGiphy setGiphyAPIKey:kGiphyApiKey];
        [AXCGiphy searchGiphyWithTerm:kGiphyQuery limit:1 offset:randomNumber completion:^(NSArray *results, NSError *error) {
            
            if (!error){
                AXCGiphy *gif = results[0];
                
                if(gif.originalImage.url){
                    NSURLRequest *request = [NSURLRequest requestWithURL:gif.originalImage.url];
                    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        
                        UIImage *gifImage = [UIImage imageWithData:data];
                        double gifRatio = gifImage.size.height/gifImage.size.width;
                        NSUInteger gifNewWidth = self.view.frame.size.width - 36;
                        NSUInteger gifNewHeight = gifRatio * gifNewWidth;
                        
                        if(!error){
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                self.gifViewController = (ModalViewController *)[storyboard instantiateViewControllerWithIdentifier:@"modalViewController"];
                                
                                self.gifViewController.view.alpha = 0;
                                [self presentViewController:self.gifViewController animated:YES completion:(^{
                                    FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
                                    FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] init];
                                    imageView.animatedImage = image;
                                    
                                    imageView.contentMode = UIViewContentModeScaleAspectFit;
                                    imageView.frame = CGRectMake((self.gifViewController.gifImageView.frame.size.width - gifNewWidth)/2, (self.gifViewController.gifImageView.frame.size.width - gifNewHeight)/2, gifNewWidth, gifNewHeight);
                                    
                                    [self.gifViewController.gifImageView addSubview:imageView];
                                    
                                    [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                        self.gifViewController.view.alpha = 1;
                                    } completion:^(BOOL finished) {
                                        [self reloadDataAndTableView];
                                    }];
                                })];
                            }];
                        }
                    }] resume];
                }
            }
            else {
                NSLog(@"%@", error);
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    self.gifViewController = (ModalViewController *)[storyboard instantiateViewControllerWithIdentifier:@"modalViewController"];
                    
                    self.gifViewController.view.alpha = 0;
                    [self presentViewController:self.gifViewController animated:YES completion:(^{
                        
                        UIImage *image;
                        if ([error.localizedDescription isEqualToString:@"The Internet connection appears to be offline."]){
                            image = [UIImage imageNamed:@"cat_nointernet"];
                        } else {
                            image = [UIImage imageNamed:@"cat_api"];
                        }
                        
                        UIImageView *imageView = [[UIImageView alloc] init];
                        imageView.image = image;
                        
                        double gifRatio = image.size.height/image.size.width;
                        NSUInteger imageNewWidth = self.view.frame.size.width - 36;
                        NSUInteger imageNewHeight = gifRatio * imageNewWidth;
                        
                        imageView.contentMode = UIViewContentModeScaleAspectFit;
                        imageView.frame = CGRectMake((self.gifViewController.gifImageView.frame.size.width - imageNewWidth)/2, (self.gifViewController.gifImageView.frame.size.width - imageNewHeight)/2, imageNewWidth, imageNewHeight);
                        
                        [self.gifViewController.gifImageView addSubview:imageView];
                        
                        [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                            self.gifViewController.view.alpha = 1;
                        } completion:^(BOOL finished) {
                            [self reloadDataAndTableView];
                        }];
                    })];
                }];

            }
        }];
    }
}

#pragma mark - AddAlarmViewContoller Methods

- (void)showAlarmTimeSelector
{
    if (!self.showingAlarmViewController) {

        if (!self.alarmSetViewController) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            self.alarmSetViewController = [storyboard instantiateViewControllerWithIdentifier:@"timeSelect"];
            
            self.alarmSetViewController.delegate = self;
        }
        [self addChildViewController:self.alarmSetViewController];
        [self.view addSubview:self.alarmSetViewController.view];
        [self.alarmSetViewController didMoveToParentViewController:self];
        
        self.alarmSetViewController.view.alpha = 0;
        self.alarmSetViewController.pickerViewVerticalSpaceConstraint.constant = -250;
        [self.view layoutIfNeeded];
        
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.alarmSetViewController.view.alpha = 1;
            self.alarmSetViewController.pickerViewVerticalSpaceConstraint.constant = 0;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (finished) {
                self.showingAlarmViewController = YES;
            }
        }];
    }
}

- (void)hideAlarmTimeSelector
{
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alarmSetViewController.view.alpha = 0;
        self.alarmSetViewController.pickerViewVerticalSpaceConstraint.constant = -250;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished) {
            [self.alarmSetViewController willMoveToParentViewController:nil];
            [self.alarmSetViewController.view removeFromSuperview];
            [self.alarmSetViewController removeFromParentViewController];
            self.showingAlarmViewController = NO;
            self.alarmManager.alarmToEditBool = NO;
        }
    }];
}

#pragma mark - Pull to Refresh Methods

- (void)setupRefreshControl
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshLoadingView = [[UIView alloc] initWithFrame:self.refreshControl.bounds];
    self.refreshLoadingView.backgroundColor = [UIColor clearColor];
    self.refreshColorView = [[UIView alloc] initWithFrame:self.refreshControl.bounds];
    self.refreshColorView.backgroundColor = [UIColor clearColor];
    self.refreshColorView.alpha = 0.70;
    
    self.catImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cat"]];
    self.toastImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"toast"]];
    
    [self.refreshLoadingView addSubview:self.catImageView];
    [self.refreshLoadingView addSubview:self.toastImageView];
    self.refreshLoadingView.clipsToBounds = NO;
    
    self.refreshControl.tintColor = [UIColor clearColor];
    
    [self.refreshControl addSubview:self.refreshColorView];
    [self.refreshControl addSubview:self.refreshLoadingView];
    
    self.isRefreshIconsOverlap = NO;
    self.isRefreshAnimating = NO;
    
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGRect refreshBounds = self.refreshControl.bounds;
    CGFloat pullDistance = MAX(0.0, -self.refreshControl.frame.origin.y);
    CGFloat midX = self.tableView.frame.size.width / 2.0;
    CGFloat compassHeight = self.catImageView.bounds.size.height;
    CGFloat compassHeightHalf = compassHeight / 2.0;
    CGFloat compassWidth = self.catImageView.bounds.size.width;
    CGFloat compassWidthHalf = compassWidth / 2.0;
    CGFloat spinnerHeight = self.toastImageView.bounds.size.height;
    CGFloat spinnerHeightHalf = spinnerHeight / 2.0;
    CGFloat spinnerWidth = self.toastImageView.bounds.size.width;
    CGFloat spinnerWidthHalf = spinnerWidth / 2.0;
    CGFloat pullRatio = MIN( MAX(pullDistance, 0.0), 100.0) / 100.0;
    CGFloat compassY = pullDistance / 2.0 - compassHeightHalf;
    CGFloat spinnerY = pullDistance / 2.0 - spinnerHeightHalf;
    CGFloat compassX = (midX + compassWidthHalf) - (compassWidth * pullRatio);
    CGFloat spinnerX = (midX - spinnerWidth - spinnerWidthHalf) + (spinnerWidth * pullRatio);
    
    if (fabs(compassX - spinnerX) < 1.0) {
        self.isRefreshIconsOverlap = YES;
    }
    
    if (self.isRefreshIconsOverlap || self.refreshControl.isRefreshing) {
        compassX = midX - compassWidthHalf;
        spinnerX = midX - spinnerWidthHalf;
    }
    
    CGRect compassFrame = self.catImageView.frame;
    compassFrame.origin.x = compassX;
    compassFrame.origin.y = compassY;
    CGRect spinnerFrame = self.toastImageView.frame;
    spinnerFrame.origin.x = spinnerX;
    spinnerFrame.origin.y = spinnerY;
    
    self.catImageView.frame = compassFrame;
    self.toastImageView.frame = spinnerFrame;
    
    refreshBounds.size.height = pullDistance;
    self.refreshColorView.frame = refreshBounds;
    self.refreshLoadingView.frame = refreshBounds;
    
    if (self.refreshControl.isRefreshing && !self.isRefreshAnimating) {
        [self animateRefreshView];
    }
}

- (void)animateRefreshView
{
    NSArray *colorArray = @[[UIColor flatBlackColor]];
    static int colorIndex = 0;
    self.isRefreshAnimating = YES;
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                         
         [self.toastImageView setTransform:CGAffineTransformRotate(self.toastImageView.transform, M_PI_2)];
         self.refreshColorView.backgroundColor = [colorArray objectAtIndex:colorIndex];
         colorIndex = (colorIndex + 1) % colorArray.count;
     }
     completion:^(BOOL finished) {
         
         if (self.refreshControl.isRefreshing) {
             [self animateRefreshView];
         }else{
             [self resetAnimation];
         }
    }];
}

- (void)resetAnimation
{
    self.isRefreshAnimating = NO;
    self.isRefreshIconsOverlap = NO;
    self.refreshColorView.backgroundColor = [UIColor clearColor];
}

#pragma mark - Helper Methods

- (int)getRandomNumberBetween:(int)from to:(int)to
{
    return (int)from + arc4random() % (to-from+1);
}

-(NSIndexPath *)getIndexPathFromSender:(id)sender
{
    CGPoint hitPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *hitIndex = [self.tableView indexPathForRowAtPoint:hitPoint];
    
    return hitIndex;
}

- (UIColor *)colorForIndex:(NSInteger)index
{
    NSUInteger itemCount = self.alarmsArray.count - 1;
    float val = 1.0f - (((float)index / (float)itemCount) * 0.99);
    
    if (index == 0) {
        val = 1.0f;
    }
    if (index == 1 && self.alarmsArray.count == 2) {
        val = 0.5f;
    }
    if (val < 0.15f) {
        val = 0.15f;
    }
    
    return [[UIColor flatBlueColor] colorWithAlphaComponent:val];
}

#pragma mark - Alert Methods

- (void)triggerFirstWarningAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"To create an alarm set them to on, and press the hold button." message: @"" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    
    UIImage *alertImage = [UIImage imageNamed:@"iphone"];
    UIImageView *alertImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    [alertImageView setImage:alertImage];
    
    [alertView  setValue:alertImageView forKey:@"accessoryView"];
    [alertView  show];
}

- (void)triggerWarningAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Turn off alarms or set them and press the hold button." message: @"" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    
    UIImage *alertImage = [UIImage imageNamed:@"iphone"];
    UIImageView *alertImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    [alertImageView setImage:alertImage];
    
    [alertView  setValue:alertImageView forKey:@"accessoryView"];
    [alertView  show];
}

#pragma mark - Override Methods

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
