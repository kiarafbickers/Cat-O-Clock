//
//  MainTableViewController.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/17/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "MainTableViewController.h"
#import "AlarmManager.h"
#import "AlarmModel.h"
#import "ModalViewController.h"
#import "AddAlarmViewContoller.h"
#import <ChameleonFramework/Chameleon.h>
#import <Giphy-iOS/AXCGiphy.h>
#import <AnimatedGIFImageSerialization/AnimatedGIFImageSerialization.h>
#import <FLAnimatedImage/FLAnimatedImage.h>
@import AVFoundation;


@interface MainTableViewController () <AddAlarmViewContollerDelegate>

@property (nonatomic, strong) UIView *refreshLoadingView;
@property (nonatomic, strong) UIView *refreshColorView;
@property (nonatomic, strong) UIImageView *toastImageView;
@property (nonatomic, strong) UIImageView *catImageView;

@property (assign) BOOL isRefreshIconsOverlap;
@property (assign) BOOL isRefreshAnimating;
@property (nonatomic, assign) BOOL showingAlarmViewController;

@property (nonatomic, strong) AddAlarmViewContoller *alarmSetController;
@property (nonatomic, strong) ModalViewController *modalVC;

@property (nonatomic, strong) AlarmManager *alarmManager;

@property (nonatomic, strong) NSMutableArray *alarmsArray;
@property (strong, nonatomic) NSArray * giphyResults;

@end


@implementation MainTableViewController

#pragma mark - View Lifecyle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureBackroundNilSound];
    [self setupRefreshControl];

    self.navigationController.navigationBar.hidden = YES;
    
    UIView *statusBackround = [[UIView alloc] init];
    statusBackround.frame =  CGRectMake(0, 0, self.view.frame.size.width, 20);
    statusBackround.backgroundColor = [UIColor flatBlackColor];
    [self.navigationController.view addSubview:statusBackround];
    
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    self.view.backgroundColor = [UIColor flatBlackColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor flatWhiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"timerPlaying" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showModalVCWithImage:) name:@"timerPlaying" object:nil];
    
    self.alarmManager = [AlarmManager sharedAlarmDataStore];
    self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
    
    [self setTableviewColor];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.refreshControl.superview sendSubviewToBack:self.refreshControl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
    [self showAlarmTimeSelector];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SecondViewControllerDismissed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDismissSecondViewController) name:@"SecondViewControllerDismissed" object:nil];
}

- (void)didDismissSecondViewController
{
    [self reloadDataAndTableView];
    [self hideAlarmTimeSelector];
}

- (void)reloadDataAndTableView
{
    self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
    [self setTableviewColor];
    [self.tableView reloadData];
    [self.alarmManager checkForValidAlarm];
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

    return cell;
}

- (void) switchChanged:(id)sender
{
    /* GETS CELL ROW INFO*/
    CGPoint hitPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *hitIndex = [self.tableView indexPathForRowAtPoint:hitPoint];

    [self.alarmManager updateAlarmInAlarmArray:hitIndex.row];
    [self reloadDataAndTableView];
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

- (void)setTableviewColor
{
    if (self.alarmsArray.count == 0) {
        self.tableView.backgroundColor = [UIColor clearColor];
    } else {
        self.tableView.backgroundColor = [UIColor flatBlackColor];
    }
}

#pragma mark - ModalViewController Methods

- (void)showModalVCWithImage:(NSNotification *)notification
{
    if (!self.modalVC) {
        NSUInteger randomNumber = [self getRandomNumberBetween:0 to:35488];
        
        [AXCGiphy setGiphyAPIKey:@"dc6zaTOxFJmzC"];
        [AXCGiphy searchGiphyWithTerm:@"cats" limit:1 offset:randomNumber completion:^(NSArray *results, NSError *error) {
            
            if (!error){
                AXCGiphy *gif = results[0];
                
                if(gif.originalImage.url){
                    NSURLRequest *request = [NSURLRequest requestWithURL:gif.originalImage.url];
                    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        
                        UIImage *gifImage = [UIImage imageWithData:data];
                        double gifRatio = gifImage.size.height/gifImage.size.width;
                        NSUInteger gifNewWidth = self.view.frame.size.width - 36;
                        NSUInteger gifNewHeight = gifRatio * gifNewWidth;
                        
                        
                        NSLog(@"width: %f", gifImage.size.width);
                        NSLog(@"height: %f", gifImage.size.height);
                        
                        if(!error){
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                self.modalVC = (ModalViewController *)[storyboard instantiateViewControllerWithIdentifier:@"modalViewController"];
                                
                                self.modalVC.view.alpha = 0;
                                [self presentViewController:self.modalVC animated:YES completion:(^{
                                    FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
                                    FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] init];
                                    imageView.animatedImage = image;
                                    
                                    imageView.contentMode = UIViewContentModeScaleAspectFit;
                                    imageView.frame = CGRectMake((self.modalVC.gifImageView.frame.size.width - gifNewWidth)/2, (self.modalVC.gifImageView.frame.size.width - gifNewHeight)/2, gifNewWidth, gifNewHeight);
                                    
                                    [self.modalVC.gifImageView addSubview:imageView];
                                    
                                    [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                        self.modalVC.view.alpha = 1;
                                    } completion:^(BOOL finished) {
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
                    self.modalVC = (ModalViewController *)[storyboard instantiateViewControllerWithIdentifier:@"modalViewController"];
                    
                    self.modalVC.view.alpha = 0;
                    [self presentViewController:self.modalVC animated:YES completion:(^{
                        
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
                        imageView.frame = CGRectMake((self.modalVC.gifImageView.frame.size.width - imageNewWidth)/2, (self.modalVC.gifImageView.frame.size.width - imageNewHeight)/2, imageNewWidth, imageNewHeight);
                        
                        [self.modalVC.gifImageView addSubview:imageView];
                        
                        [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                            self.modalVC.view.alpha = 1;
                        } completion:^(BOOL finished) {
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

        if (!self.alarmSetController) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            self.alarmSetController = [storyboard instantiateViewControllerWithIdentifier:@"timeSelect"];
            self.alarmSetController.delegate = self;
        }
        [self addChildViewController:self.alarmSetController];
        [self.view addSubview:self.alarmSetController.view];
        [self.alarmSetController didMoveToParentViewController:self];
        
        self.alarmSetController.view.alpha = 0;
        self.alarmSetController.pickerViewVerticalSpaceConstraint.constant = -250;
        [self.view layoutIfNeeded];
        
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.alarmSetController.view.alpha = 1;
            self.alarmSetController.pickerViewVerticalSpaceConstraint.constant = 0;
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
        self.alarmSetController.view.alpha = 0;
        self.alarmSetController.pickerViewVerticalSpaceConstraint.constant = -250;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished) {
            [self.alarmSetController willMoveToParentViewController:nil];
            [self.alarmSetController.view removeFromSuperview];
            [self.alarmSetController removeFromParentViewController];
            self.showingAlarmViewController = NO;
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
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         
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

- (void)configureBackroundNilSound
{
    /* THREAD ISSUE? - ALARM WILL CRASH UNLESS BACKROUND SOUND IS CONFIGURED*/
    NSString *backgroundNilPath = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
    NSURL *backgroundNilURL = [NSURL fileURLWithPath:backgroundNilPath];
    AVAudioPlayer *backgroundNilPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundNilURL error:nil];
    backgroundNilPlayer.numberOfLoops = 0;	// Never Plays
    backgroundNilPlayer.volume = 1;
}

- (int)getRandomNumberBetween:(int)from to:(int)to
{
    return (int)from + arc4random() % (to-from+1);
}

#pragma mark - Override Methods

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
