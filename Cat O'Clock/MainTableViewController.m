//
//  MainTableViewController.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/17/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "MainTableViewController.h"

#import "Constants.h"
#import "NetworkKey.h"
#import "AlarmModel.h"
#import "ModalViewController.h"
#import "AddAlarmViewContoller.h"
#import "AlarmTableViewCell.h"

#import <Giphy-iOS/AXCGiphy.h>
#import <ChameleonFramework/Chameleon.h>

@import AVFoundation;


@interface MainTableViewController ()

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
    
    [self setTableViewCellHeight];
    [self setupRefreshControl];
    
    self.alarmManager = [AlarmManager sharedAlarmDataStore];
    
    self.navigationController.navigationBar.hidden = YES;
    
    UIView *statusBackround = [[UIView alloc] init];
    statusBackround.frame = CGRectMake(0, 0, self.view.frame.size.width, 20);
    statusBackround.backgroundColor = [UIColor flatBlackColor];
    [self.navigationController.view addSubview:statusBackround];
    
    self.view.backgroundColor = [UIColor flatBlackColor];
    self.tableView.backgroundColor = [UIColor flatBlackColor];
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"alarmPlaying" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForModalViewController:) name:@"alarmPlaying" object:nil];
    
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
    [self.alarmManager refreshAlarmData];
    [self.tableView reloadData];
}

#pragma mark - Action Methods

- (void)refresh:(id)sender
{
    double delayInSeconds = 1.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self newAlarmPull];
        [self.refreshControl endRefreshing];
    });
}

- (void)newAlarmPull
{
    self.alarmManager.isAlarmToEdit = NO;
    [self showAlarmTimeSelectorAtIndex:@0];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SecondViewControllerDismissed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDismissSecondViewController) name:@"SecondViewControllerDismissed" object:nil];
}

#pragma mark - Tableview Methods

- (void)setTableViewCellHeight
{
    NSUInteger cellsPerView = 4;
    CGFloat statusBar = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat viewHeight = self.view.bounds.size.height - statusBar;
    CGFloat customTableCellHeight = viewHeight/cellsPerView;
    
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.rowHeight  = customTableCellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numOfSections = 0;
    if (self.alarmManager.alarmsArray.count > 0) {
        numOfSections = 1;
        self.tableView.backgroundView = nil;
    }
    else {
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
    return self.alarmManager.alarmsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlarmTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"alarmCell" forIndexPath:indexPath];
    AlarmModel *alarmAtIndexRow = self.alarmManager.alarmsArray[indexPath.row];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [self colorForIndex:indexPath.row];
    
    cell.switchControl.thumbTintColor = [UIColor whiteColor];
    cell.switchControl.tintColor = [[UIColor clearColor] colorWithAlphaComponent:0.2f];
    
    BOOL switchState = alarmAtIndexRow.switchState;
    cell.switchControl.on = switchState;
    cell.onSwitchChange=^(AlarmTableViewCell *cellAffected){
        [self.alarmManager switchAlarmAtIndex:indexPath.row];
        [self reloadDataAndTableView];
    };
    
    cell.timeLabel.text = alarmAtIndexRow.timeString;
    if (cell.switchControl.on) {
        cell.timeLabel.textColor = [[UIColor flatWhiteColor] colorWithAlphaComponent:1.0f];
    } else {
        cell.timeLabel.textColor = [[UIColor flatBlackColor] colorWithAlphaComponent:0.25f];
    }
    
    
    cell.editAlarmButton = [[UIButton alloc] init];
    [cell.editAlarmButton addTarget:self action:@selector(editAlarmAtIndex:) forControlEvents:UIControlEventTouchDown];
    
    cell.onEditAlarmButton=^(AlarmTableViewCell *cellAffected){
        [self.alarmManager switchAlarmAtIndex:indexPath.row];
        [self showAlarmTimeSelectorAtIndex:@(indexPath.row)];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SecondViewControllerDismissed" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDismissSecondViewController) name:@"SecondViewControllerDismissed" object:nil];
    };
    
    UIView *cellSeparatorLineView;
    if (![cellSeparatorLineView isDescendantOfView:cell.contentView]) {
        cellSeparatorLineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.contentView.frame.size.height - 1, cell.contentView.frame.size.width, 1)];
        cellSeparatorLineView.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.025f];
        [cell.contentView addSubview:cellSeparatorLineView];
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.alarmManager removeAlarmAtIndex:indexPath.row];
        
         NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
         [tableView beginUpdates];
         [tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
         [tableView endUpdates];

        [self reloadDataAndTableView];
    }
}

- (void)editAlarmAtIndex:(NSIndexPath *)indexPath
{
    [self.alarmManager switchAlarmAtIndex:indexPath.row];
    [self showAlarmTimeSelectorAtIndex:@(indexPath.row)];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SecondViewControllerDismissed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDismissSecondViewController) name:@"SecondViewControllerDismissed" object:nil];
}

#pragma mark - ModalViewController Methods

- (void)checkForModalViewController:(NSNotification *)notification
{
    if (!self.gifViewController) {
        [self callGiphyApiForGifImage];
    }
}

- (void)callGiphyApiForGifImage
{
    NSUInteger randomNumber = [self getRandomNumberBetween:0 to:2400];
    
    [AXCGiphy setGiphyAPIKey:kGiphyApiKey];
    [AXCGiphy searchGiphyWithTerm:kGiphyQuery limit:1 offset:randomNumber completion:^(NSArray *results, NSError *error) {
        if (!error) {
            
            AXCGiphy *gif = results[0];
            if (gif.originalImage.url) {
                
                NSURLRequest *request = [NSURLRequest requestWithURL:gif.originalImage.url];
                [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (!error) {

                        UIImage *gifImage = [UIImage imageWithData:data];
                        double gifRatio = gifImage.size.height/gifImage.size.width;
                        
                        NSUInteger gifNewWidth = self.view.frame.size.width;
                        NSUInteger gifNewHeight = gifRatio * gifNewWidth;
                        
                        if (gifNewHeight < self.view.bounds.size.width) {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            
                                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                self.gifViewController = (ModalViewController *)[storyboard instantiateViewControllerWithIdentifier:@"modalViewController"];
                                self.gifViewController.view.alpha = 0;
                                
                                FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
                                FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] init];
                                imageView.animatedImage = image;
                                imageView.contentMode = UIViewContentModeScaleAspectFit;
                                
                                NSUInteger gifY = 0;
                                if (gifNewHeight < self.view.bounds.size.width) {
                                    gifY = (self.view.bounds.size.width - gifNewHeight)/2;
                                }
                                
                                imageView.frame = CGRectMake(0, gifY, gifNewWidth, gifNewHeight);
                                [self presentAndAnimateModalGifViewControllerWithImageView:imageView];
                            }];
                            }
                        } else {
                        [self callGiphyApiForGifImage];
                    }
                }] resume];
            } else {
                [self callGiphyApiForGifImage];
            }
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                self.gifViewController = (ModalViewController *)[storyboard instantiateViewControllerWithIdentifier:@"modalViewController"];
                self.gifViewController.view.alpha = 0;
                
                UIImage *image;
                if ([error.localizedDescription isEqualToString:@"The Internet connection appears to be offline."]) {
                    image = [UIImage imageNamed:@"cat_nointernet"];
                } else {
                    image = [UIImage imageNamed:@"cat_api"];
                }
                
                UIImageView *imageView = [[UIImageView alloc] init];
                imageView.image = image;
                
                double gifRatio = image.size.height/image.size.width;
                NSUInteger imageNewWidth = self.view.frame.size.width;
                NSUInteger imageNewHeight = gifRatio * imageNewWidth;
                
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                NSInteger imageX = (self.gifViewController.gifImageView.frame.size.width - imageNewWidth)/2;
                NSInteger imageY = (self.gifViewController.gifImageView.frame.size.width - imageNewHeight)/2;
                imageView.frame = CGRectMake(imageX, imageY, imageNewWidth, imageNewHeight);
                
                [self presentAndAnimateModalGifViewControllerWithImageView:imageView];
            }];
        }
    }];
}

- (void)presentAndAnimateModalGifViewControllerWithImageView:(UIImageView *)imageView
{
    [self.gifViewController.gifImageView addSubview:imageView];
    UIViewController *topViewController = [self topMostController];
    [topViewController presentViewController:self.gifViewController animated:YES completion:(^{
    
        [self.alarmManager startAudioPlayer];
        [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.gifViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [self reloadDataAndTableView];
        }];
    })];
}


#pragma mark - AddAlarmViewContoller Methods

- (void)showAlarmTimeSelectorAtIndex:(NSNumber *)index
{
    if (!self.showingAlarmViewController) {
        if (!self.alarmSetViewController) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            self.alarmSetViewController = [storyboard instantiateViewControllerWithIdentifier:@"timeSelect"];
            
            if (self.alarmManager.isAlarmToEdit == YES) {
                self.alarmManager.indexOfAlarm = index;
            }
        }

        [self addChildViewController:self.alarmSetViewController];
        [self.view addSubview:self.alarmSetViewController.view];
        [self.alarmSetViewController didMoveToParentViewController:self];

        self.alarmSetViewController.view.alpha = 0;
        self.alarmSetViewController.pickerViewVerticalSpaceConstraint.constant = kVerticalSpaceConstraint;
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
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alarmSetViewController.view.alpha = 0;
        self.alarmSetViewController.pickerViewVerticalSpaceConstraint.constant = kVerticalSpaceConstraint;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished) {
            [self.alarmSetViewController willMoveToParentViewController:nil];
            [self.alarmSetViewController.view removeFromSuperview];
            [self.alarmSetViewController removeFromParentViewController];
            self.showingAlarmViewController = NO;
            self.alarmManager.isAlarmToEdit = NO;
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
         } else {
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
    NSUInteger itemCount = self.alarmManager.alarmsArray.count;
    float val = 1.0f - (((float)index / (float)itemCount) * 0.99);
    
    if (index == 0) {
        val = 1.0f;
    }
    if (index == 1 && self.alarmManager.alarmsArray.count == 2) {
        val = 0.5f;
    }
    if (val < 0.15f) {
        val = 0.15f;
    }
    
    return [[UIColor flatBlueColor] colorWithAlphaComponent:val];
}

- (UIViewController *)topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}


#pragma mark - Alert Methods

- (void)triggerWarningAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Alarms wont run if the app is closed. Leave the app running or turn off alarms." preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *okayAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:okayAction];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Override Methods

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
