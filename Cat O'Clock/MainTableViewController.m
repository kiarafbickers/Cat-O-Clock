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
#import <ChameleonFramework/Chameleon.h>
#import <Giphy-iOS/AXCGiphy.h>
#import <AnimatedGIFImageSerialization/AnimatedGIFImageSerialization.h>
#import <FLAnimatedImage/FLAnimatedImage.h>
#import "FLAnimatedImage.h"
@import AVFoundation;


@interface MainTableViewController () <ModalViewControllerDelegate>

@property (nonatomic, strong) AlarmManager *alarmManager;
@property (nonatomic, strong) NSMutableArray *alarmsArray;
@property (strong, nonatomic) NSArray * giphyResults;
@property (nonatomic, assign) BOOL showingModalViewController;
@property (nonatomic, strong) ModalViewController *modalVC;

@property (nonatomic, strong) UIView *refreshLoadingView;
@property (nonatomic, strong) UIView *refreshColorView;
@property (nonatomic, strong) UIImageView *compass_background;
@property (nonatomic, strong) UIImageView *compass_spinner;
@property (assign) BOOL isRefreshIconsOverlap;
@property (assign) BOOL isRefreshAnimating;

@end


@implementation MainTableViewController

#pragma mark - View Lifecyle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureBackroundNilSound];
    [self setupRefreshControl];

    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.backgroundColor = [UIColor flatGrayColorDark];
    
    self.view.backgroundColor = [UIColor flatBlackColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor flatWhiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showModalVCWithImage:) name:@"timerPlaying" object:nil];
    
    self.alarmManager = [AlarmManager sharedAlarmDataStore];
    self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
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

#pragma mark - Tableview Data Source Methods

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
        noDataLabel.text = @"Pull To Set Gif Alarm";
        noDataLabel.textAlignment = NSTextAlignmentCenter;
        self.tableView.backgroundView = noDataLabel;
    }
    
    return numOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.alarmsArray.count;
}

-(UIColor*)colorForIndex:(NSInteger)index
{
    NSUInteger itemCount = self.alarmsArray.count - 1;
    float val = 1.0f - (((float)index / (float)itemCount) * 0.99);
    
    if (index == 0) {
        val = 1;
    }
    if (val < 0.15f) {
        val = 0.15f;
    }
    
    return [[UIColor flatBlueColor] colorWithAlphaComponent:val];
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

- (void) switchChanged:(id)sender {
    UISwitch *switchControl = sender;
    
    /* GETS CELL ROW INFO*/
    CGPoint hitPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *hitIndex = [self.tableView indexPathForRowAtPoint:hitPoint];
    
    NSLog(@"The switch is %@ at indexPath %ld", switchControl.on ? @"ON" : @"OFF", (long)hitIndex.row);
    
    [self.alarmManager updateAlarmInAlarmArray:hitIndex.row];
    
    [self reloadDataAndTableView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat viewHeight = self.view.frame.size.height;
    CGFloat customTableCellHeight = viewHeight/4;
    
    return customTableCellHeight;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog( @"The indexPath is %@", indexPath );
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

#pragma mark - Action Methods

- (IBAction)addAlarmButton:(id)sender
{
    [self performSegueWithIdentifier:@"showAddTableViewVC" sender:sender];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDismissSecondViewController) name:@"SecondViewControllerDismissed" object:nil];
}

- (void)newAlarmPull
{
    [self.refreshControl endRefreshing];
    [self performSegueWithIdentifier:@"showAddTableViewVC" sender:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDismissSecondViewController) name:@"SecondViewControllerDismissed" object:nil];
}

- (void)didDismissSecondViewController
{
    NSLog(@"Dismissed SecondViewController");
    
    [self reloadDataAndTableView];
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
                                    imageView.frame = CGRectMake((self.view.frame.size.width - gifNewWidth)/2, (self.view.frame.size.width - gifNewHeight)/2, gifNewWidth, gifNewHeight);
                                    
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
            }
        }];
    }
}

#pragma mark - Pull to Refresh Methods

- (void)setupRefreshControl
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    
    // Setup the loading view, which will hold the moving graphics
    self.refreshLoadingView = [[UIView alloc] initWithFrame:self.refreshControl.bounds];
    self.refreshLoadingView.backgroundColor = [UIColor clearColor];
    
    // Setup the color view, which will display the rainbowed background
    self.refreshColorView = [[UIView alloc] initWithFrame:self.refreshControl.bounds];
    self.refreshColorView.backgroundColor = [UIColor clearColor];
    self.refreshColorView.alpha = 0.70;
    
    // Create the graphic image views
    self.compass_background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compass_background.png"]];
    self.compass_spinner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compass_spinner.png"]];
    
    // Add the graphics to the loading view
    [self.refreshLoadingView addSubview:self.compass_background];
    [self.refreshLoadingView addSubview:self.compass_spinner];
    
    // Clip so the graphics don't stick out
    self.refreshLoadingView.clipsToBounds = YES;
    
    // Hide the original spinner icon
    self.refreshControl.tintColor = [UIColor clearColor];
    
    // Add the loading and colors views to our refresh control
    [self.refreshControl addSubview:self.refreshColorView];
    [self.refreshControl addSubview:self.refreshLoadingView];
    
    // Initalize flags
    self.isRefreshIconsOverlap = NO;
    self.isRefreshAnimating = NO;
    
    // When activated, invoke our refresh function
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
}

- (void)refresh:(id)sender{
    NSLog(@"");
    
    // Just wait 1.5 seconds for effect
    double delayInSeconds = 1.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"DONE");
        
        // When done requesting/reloading/processing invoke endRefreshing, to close the control
        [self newAlarmPull];
        [self.refreshControl endRefreshing];
    });
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Get the current size of the refresh controller
    CGRect refreshBounds = self.refreshControl.bounds;
    
    // Distance the table has been pulled >= 0
    CGFloat pullDistance = MAX(0.0, -self.refreshControl.frame.origin.y);
    
    // Half the width of the table
    CGFloat midX = self.tableView.frame.size.width / 2.0;
    
    // Calculate the width and height of our graphics
    CGFloat compassHeight = self.compass_background.bounds.size.height;
    CGFloat compassHeightHalf = compassHeight / 2.0;
    
    CGFloat compassWidth = self.compass_background.bounds.size.width;
    CGFloat compassWidthHalf = compassWidth / 2.0;
    
    CGFloat spinnerHeight = self.compass_spinner.bounds.size.height;
    CGFloat spinnerHeightHalf = spinnerHeight / 2.0;
    
    CGFloat spinnerWidth = self.compass_spinner.bounds.size.width;
    CGFloat spinnerWidthHalf = spinnerWidth / 2.0;
    
    // Calculate the pull ratio, between 0.0-1.0
    CGFloat pullRatio = MIN( MAX(pullDistance, 0.0), 100.0) / 100.0;
    
    // Set the Y coord of the graphics, based on pull distance
    CGFloat compassY = pullDistance / 2.0 - compassHeightHalf;
    CGFloat spinnerY = pullDistance / 2.0 - spinnerHeightHalf;
    
    // Calculate the X coord of the graphics, adjust based on pull ratio
    CGFloat compassX = (midX + compassWidthHalf) - (compassWidth * pullRatio);
    CGFloat spinnerX = (midX - spinnerWidth - spinnerWidthHalf) + (spinnerWidth * pullRatio);
    
    // When the compass and spinner overlap, keep them together
    if (fabs(compassX - spinnerX) < 1.0) {
        self.isRefreshIconsOverlap = YES;
    }
    
    // If the graphics have overlapped or we are refreshing, keep them together
    if (self.isRefreshIconsOverlap || self.refreshControl.isRefreshing) {
        compassX = midX - compassWidthHalf;
        spinnerX = midX - spinnerWidthHalf;
    }
    
    // Set the graphic's frames
    CGRect compassFrame = self.compass_background.frame;
    compassFrame.origin.x = compassX;
    compassFrame.origin.y = compassY;
    
    CGRect spinnerFrame = self.compass_spinner.frame;
    spinnerFrame.origin.x = spinnerX;
    spinnerFrame.origin.y = spinnerY;
    
    self.compass_background.frame = compassFrame;
    self.compass_spinner.frame = spinnerFrame;
    
    // Set the encompassing view's frames
    refreshBounds.size.height = pullDistance;
    
    self.refreshColorView.frame = refreshBounds;
    self.refreshLoadingView.frame = refreshBounds;
    
    // If we're refreshing and the animation is not playing, then play the animation
    if (self.refreshControl.isRefreshing && !self.isRefreshAnimating) {
        [self animateRefreshView];
    }
    
    NSLog(@"pullDistance: %.1f, pullRatio: %.1f, midX: %.1f, isRefreshing: %i", pullDistance, pullRatio, midX, self.refreshControl.isRefreshing);
}

- (void)animateRefreshView
{
    // Background color to loop through for our color view
    NSArray *colorArray = @[[UIColor flatWhiteColor], [UIColor flatGrayColor]];
    static int colorIndex = 0;
    
    // Flag that we are animating
    self.isRefreshAnimating = YES;
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{

                         // Change the background color
                         self.refreshColorView.backgroundColor = [colorArray objectAtIndex:colorIndex];
                         colorIndex = (colorIndex + 1) % colorArray.count;
                     }
                     completion:^(BOOL finished) {
                         // If still refreshing, keep spinning, else reset
                         if (self.refreshControl.isRefreshing) {
                             [self animateRefreshView];
                         }else{
                             [self resetAnimation];
                         }
                     }];
}

- (void)resetAnimation
{
    // Reset our flags and background color
    self.isRefreshAnimating = NO;
    self.isRefreshIconsOverlap = NO;
    self.refreshColorView.backgroundColor = [UIColor clearColor];
}

#pragma mark - Helper Methods

- (void)reloadDataAndTableView
{
    self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
    [self.tableView reloadData];
    
    [self.alarmManager checkForValidAlarm];
}

- (void)configureBackroundNilSound
{
    /* THREAD ISSUE? - ALARM WILL CRASH UNLESS BACKROUND SOUND IS CONFIGURED*/
    NSString *backgroundNilPath = [[NSBundle mainBundle] pathForResource:@"meow" ofType:@"wav"];
    NSURL *backgroundNilURL = [NSURL fileURLWithPath:backgroundNilPath];
    AVAudioPlayer *backgroundNilPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundNilURL error:nil];
    backgroundNilPlayer.numberOfLoops = 0;	// Never Plays
    backgroundNilPlayer.volume = 1;
}

-(int)getRandomNumberBetween:(int)from to:(int)to
{
    return (int)from + arc4random() % (to-from+1);
}

- (BOOL)shouldAutorotate
{
    return NO;
}


@end
