//
//  MainTableViewController.m
//  Cat O'Clock
//
//  Created by Kiara Robles on 2/17/16.
//  Copyright © 2016 kiaraRobles. All rights reserved.
//

#import "MainTableViewController.h"
#import "AlarmManager.h"
#import "ModalViewController.h"
@import AVFoundation;
#import "UIImage+Resize.h"
#import <ChameleonFramework/Chameleon.h>
#import <Giphy-iOS/AXCGiphy.h>
#import <AnimatedGIFImageSerialization/AnimatedGIFImageSerialization.h>
#import <FLAnimatedImage/FLAnimatedImage.h>
#import "FLAnimatedImage.h"


@interface MainTableViewController ()<ModalViewControllerDelegate>

@property (nonatomic, strong) AlarmManager *alarmManager;
@property (nonatomic, strong) NSMutableArray *alarmsArray;
@property (strong, nonatomic) NSArray * giphyResults;
@property (nonatomic, assign) BOOL showingModalViewController;
@property (nonatomic, strong) ModalViewController *modalVC;

@end

@implementation MainTableViewController


#pragma mark - View Lifecyle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureBackroundNilSound];

    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    self.view.backgroundColor = [UIColor flatBlackColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor flatWhiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showModalVCWithImage:) name:@"timerPlaying" object:nil];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(newAlarmPull) forControlEvents:UIControlEventValueChanged];
    
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.alarmsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"alarmCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    AlarmModel *currentAlarm = self.alarmsArray[indexPath.row];
    
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:1];
    timeLabel.text = currentAlarm.timeString;
    timeLabel.textColor = [[UIColor clearColor] colorWithAlphaComponent:0.3f];
    
    UISwitch *switchOutlet = (UISwitch *)[cell viewWithTag:2];
    [switchOutlet setThumbTintColor:[UIColor whiteColor]];
    [switchOutlet setOnTintColor:[UIColor flatWhiteColor]];
    [switchOutlet setTintColor:[[UIColor clearColor] colorWithAlphaComponent:0.2f]];
    
    BOOL switchState = currentAlarm.switchState;
    [switchOutlet setOn:switchState animated:YES];
    [switchOutlet addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.contentView.frame.size.height - 1.2, cell.contentView.frame.size.width, 1.2)];
    lineView.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.15f];
    [cell.contentView addSubview:lineView];
    
    NSInteger colorIndex = indexPath.row % 4;
    switch (colorIndex) {
        case 0:
            cell.contentView.backgroundColor = [UIColor flatWatermelonColor];
            break;
        case 1:
            cell.contentView.backgroundColor = [UIColor flatWatermelonColorDark];
            break;
        case 2:
            cell.contentView.backgroundColor = [UIColor flatRedColor];
            break;
        case 3:
            cell.contentView.backgroundColor = [UIColor flatRedColorDark];
            break;
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
    NSUInteger randomNumber = [self getRandomNumberBetween:0 to:35488];
    
    [AXCGiphy setGiphyAPIKey:@"dc6zaTOxFJmzC"];
    [AXCGiphy searchGiphyWithTerm:@"cats" limit:1 offset:randomNumber completion:^(NSArray *results, NSError *error) {
        
        AXCGiphy *gif = results[0];
        
        if(gif.originalImage.url){
            NSURLRequest *request = [NSURLRequest requestWithURL:gif.originalImage.url];
            [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
                UIImage *gifImage = [UIImage imageWithData:data];
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
                            
                            imageView.frame = CGRectMake(0.0, 0.0, 200, 200);
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
    }];
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
                                                                                          
-(UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}

-(int)getRandomNumberBetween:(int)from to:(int)to
{
    return (int)from + arc4random() % (to-from+1);
}

@end
