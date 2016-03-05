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
#import "AlarmManager.h"
#import "ModalViewController.h"
#import "AddAlarmViewContoller.h"

#import <Giphy-iOS/AXCGiphy.h>
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
    
    [self setTableViewCellHeight];
    
    // Setup the custom refesh control animation
    [self setupRefreshControl];
    
    // Get alarms from alarm Manager data store
    self.alarmManager = [AlarmManager sharedAlarmDataStore];

    // Hide the navigation controller
    self.navigationController.navigationBar.hidden = YES;
    
    // Set a backround color behind the status bar
    UIView *statusBackround = [[UIView alloc] init];
    statusBackround.frame = CGRectMake(0, 0, self.view.frame.size.width, 20);
    statusBackround.backgroundColor = [UIColor flatBlackColor];
    [self.navigationController.view addSubview:statusBackround];
    
    // Set the view and tableview color
    self.view.backgroundColor = [UIColor flatBlackColor];
    self.tableView.backgroundColor = [UIColor flatBlackColor];
    
    // Set the table view style
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Remove any potential alarm observers than set one
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"alarmPlaying" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForModalViewController:) name:@"alarmPlaying" object:nil];
    
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
    //NSLog(@"Reloaded Data");
//    self.alarmsArray = [[self.alarmManager getAlarmsFromUserDefaults] mutableCopy];
    [self.alarmManager checkForOldAlarm];
    [self.alarmManager checkForValidAlarm];
    [self.tableView reloadData];
    //NSLog(@"____________");
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
    //NSLog(@"hitIndex.row %ld",(long)hitIndex.row);
    
    // Set properties in alarm manager to indicate which alarm in the array to edit
    self.alarmManager.alarmToEditNSNumber = [NSNumber numberWithInteger:hitIndex.row];
    //NSLog(@"hitIndex.row %@", self.alarmManager.alarmToEditNSNumber);
    
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
    // Set 1 or 0 sections in tableview depending on alarm array count
    NSInteger numOfSections = 0;
    if (self.alarmManager.alarmsArray.count > 0)
    {
        numOfSections = 1;
        self.tableView.backgroundView = nil;
    }
    else
    {
        // Configure background view with instructional label if there are no alarms
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
    // Set the number of tableview cells equal to the alarms in the alarm array count
    return self.alarmManager.alarmsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // WARNING: Views below are referenced with tags, this is a quick and dirty approach.
    // TODO: Refactor, subclass UITableViewCell and add properties to it.
    
    // Get a reusable table-view cell object for the specified reuse identifier and add it to the table
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"alarmCell" forIndexPath:indexPath];
    
    // Set cell style
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [self colorForIndex:indexPath.row];
    
    // Get the alarm from alarm array that corresponds to the indexpath row
    AlarmModel *alarmAtIndexRow = self.alarmManager.alarmsArray[indexPath.row];
    
    // Create an alarm on/off switch from tag, and set its UI values
    UISwitch *alarmSwitch = (UISwitch *)[cell viewWithTag:1];
    [alarmSwitch setThumbTintColor:[UIColor whiteColor]];
    [alarmSwitch setTintColor:[[UIColor clearColor] colorWithAlphaComponent:0.2f]];
    
    // Set the UI switch on/off state from the corresponding property on the alarm model
    BOOL switchState = alarmAtIndexRow.switchState;
    [alarmSwitch setOn:switchState animated:YES];
    
    // Set a selector method to execute when switch changes
    [alarmSwitch  addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    // Create the time display label from tag,
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:2];
    
    // Set labels UI values to to correspond with timeString from alarm model
    // ON == Full Alpha, OFF == Dim
    timeLabel.text = alarmAtIndexRow.timeString;
    if (alarmSwitch.on) {
        timeLabel.textColor = [[UIColor flatWhiteColor] colorWithAlphaComponent:1.0f];
    }
    else {
        timeLabel.textColor = [[UIColor flatBlackColor] colorWithAlphaComponent:0.25f];
    }
    
    // Create a button over the time label to allow for editing the time
    UIButton *editAlarm = (UIButton *)[cell viewWithTag:3];
    
    // Set a selector method to execute when button is pressed
    [editAlarm addTarget:self action:@selector(editAlarmPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // Create view to add slight seperation between the cells
    UIView *cellSeparatorLineView;
    
    // IF statement checks if line exists to guarantee only one line is created on reusable cells
    if (![cellSeparatorLineView isDescendantOfView:cell.contentView]) {
        
        // Set view to x = 0, y = 1 up from the bottom of the cell, width = to the cells, with a height of 1
        cellSeparatorLineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.contentView.frame.size.height - 1, cell.contentView.frame.size.width, 1)];
        
        // Set the view to a clear color with low alpha for dim effect
        cellSeparatorLineView.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.025f];
        
        // Add line view to the cell
        [cell.contentView addSubview:cellSeparatorLineView];
    }

    return cell;
}

// Using heightForRowAtIndexPath with the cell delete fuctionality causes a thread error
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
- (void)setTableViewCellHeight
{
    // Set 4 cells to fill the view
    CGFloat statusBar = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat viewHeight = self.view.bounds.size.height - statusBar;
    CGFloat customTableCellHeight = viewHeight/4;
    
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.rowHeight  = customTableCellHeight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return YES to enable swipe to delete
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Code in if statement will execute on delete
    if (editingStyle == UITableViewCellEditingStyleDelete){
    
        // Remove alarm from alarm array at index path row
        [self.alarmManager removeAlarmFromAlarmArrayAtIndex:indexPath.row];

        // Animate alarm/cell delete
         NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
         [tableView beginUpdates];
         //[tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
         [tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
         [tableView endUpdates];

        [self reloadDataAndTableView];
    }
}


#pragma mark - ModalViewController Methods

- (void)checkForModalViewController:(NSNotification *)notification
{
    //NSLog(@"Received notification %@", [notification name]);
    
    // Present GIF view controller if one does not already exist
    if (!self.gifViewController) {
        [self callGiphyApiForGifImage];
    }
}

- (void)callGiphyApiForGifImage
{
    // Random number corresponds to the maximum possible return values from giphy in the search/kGiphyQuery
    NSUInteger randomNumber = [self getRandomNumberBetween:0 to:2400];
    
    // Set the Giphy API Key
    [AXCGiphy setGiphyAPIKey:kGiphyApiKey];
    
    // Set the search term with a limit and random offset to return a random GIF each time
    [AXCGiphy searchGiphyWithTerm:kGiphyQuery limit:1 offset:randomNumber completion:^(NSArray *results, NSError *error) {
        if (!error) {
            
            // Get the GIF from Giphy results index array
            AXCGiphy *gif = results[0];
            
            
            // *Some images do not have URLs
            if (gif.originalImage.url) {
                
                // Create NSURLRequest from GIF URL
                NSURLRequest *request = [NSURLRequest requestWithURL:gif.originalImage.url];
                [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (!error) {

                        // Get image size parameters from data
                        // TODO: Change the way this is done to use autolayout instead of frames
                        UIImage *gifImage = [UIImage imageWithData:data];
                        double gifRatio = gifImage.size.height/gifImage.size.width;
                        
                        // Create new GIF width & height for to fit on screen
                        NSUInteger gifNewWidth = self.view.frame.size.width;
                        NSUInteger gifNewHeight = gifRatio * gifNewWidth;
                        
                        if (gifNewHeight < self.view.bounds.size.width) {
                        
                            // Update UI on mainQueue
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                
                                // Creates a storyboard object for the specified storyboard resource file
                                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                
                                // Instantiates and creates the 0 alpha view controller frome the specified identifier.
                                self.gifViewController = (ModalViewController *)[storyboard instantiateViewControllerWithIdentifier:@"modalViewController"];
                                self.gifViewController.view.alpha = 0;
                                
                                // Create GIF from data and set it to the image view
                                FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
                                FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] init];
                                imageView.animatedImage = image;
                                
                                // Ensure the image keep its ratio in the view
                                imageView.contentMode = UIViewContentModeScaleAspectFit;
                                
                                NSUInteger gifY = 0;
                                if (gifNewHeight < self.view.bounds.size.width) {
                                    gifY = (self.view.bounds.size.width - gifNewHeight)/2;
                                    //NSLog(@"gifY %lu", (long)gifY);
                                }
                                
                                // Set new size to image
                                imageView.frame = CGRectMake(0, gifY, gifNewWidth, gifNewHeight);
                                
                                [self presentAndAnimateModalGifViewControllerWithImageView:imageView];
                            }];
                            }
                        } else {
                        // If the image is too big
                        [self callGiphyApiForGifImage];
                    }
                }] resume];
            } else {
                // If there is no gif.originalImage.url call the method again
                [self callGiphyApiForGifImage];
            }
        } else {
            //NSLog(@"%@", error);
            
            // Update UI on mainQueue
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                // Creates a storyboard object for the specified storyboard resource file
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                
                // Instantiates and creates the 0 alpha view controller frome the specified identifier.
                self.gifViewController = (ModalViewController *)[storyboard instantiateViewControllerWithIdentifier:@"modalViewController"];
                self.gifViewController.view.alpha = 0;
                
                // Set cat image based on error localized description
                UIImage *image;
                if ([error.localizedDescription isEqualToString:@"The Internet connection appears to be offline."]){
                    image = [UIImage imageNamed:@"cat_nointernet"];
                } else {
                    image = [UIImage imageNamed:@"cat_api"];
                }
                
                // Add image to image view
                UIImageView *imageView = [[UIImageView alloc] init];
                imageView.image = image;
                
                // Get image size parameters from data
                // TODO: Change the way this is done to use autolayout instead of frames
                double gifRatio = image.size.height/image.size.width;
                NSUInteger imageNewWidth = self.view.frame.size.width;
                NSUInteger imageNewHeight = gifRatio * imageNewWidth;
                
                // Ensure the image keep its ratio in the view
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                
                // Set the image view frame x and y coordinate to half of the space around the image width and height
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
    // Add the image view to the gif image view
    [self.gifViewController.gifImageView addSubview:imageView];
    
    // Present the GIF view controller
    [self presentViewController:self.gifViewController animated:YES completion:(^{
        
        // Animate its alpha for a fade in effect
        [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.gifViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [self reloadDataAndTableView];
        }];
    })];
}

#pragma mark - AddAlarmViewContoller Methods

- (void)showAlarmTimeSelector
{
    // Check if showingAlarmViewController BOOL == NO
    if (!self.showingAlarmViewController) {

        // Check if there is not a alarmSetViewController in view hierarchy
        if (!self.alarmSetViewController) {
            
            // Creates a storyboard object for the specified storyboard resource file
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            
            // Instantiates and creates the view controller frome the specified identifier
            self.alarmSetViewController = [storyboard instantiateViewControllerWithIdentifier:@"timeSelect"];
            
            // Set this view controller as the delegate of alarmSetViewControllerVC
            self.alarmSetViewController.delegate = self;
        }

        // Add view and bring it to front
        [self addChildViewController:self.alarmSetViewController];
        [self.view addSubview:self.alarmSetViewController.view];
        [self.alarmSetViewController didMoveToParentViewController:self];
        
        // Set view alpha and constraint to animate
        self.alarmSetViewController.view.alpha = 0;
        self.alarmSetViewController.pickerViewVerticalSpaceConstraint.constant = kVerticalSpaceConstraint;
        [self.view layoutIfNeeded];
        
        // Animate view alpha and constraint
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.alarmSetViewController.view.alpha = 1;
            self.alarmSetViewController.pickerViewVerticalSpaceConstraint.constant = 0;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (finished) {
                
                // Reset showingAlarmViewController BOOL
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
    NSUInteger itemCount = self.alarmManager.alarmsArray.count - 1;
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
