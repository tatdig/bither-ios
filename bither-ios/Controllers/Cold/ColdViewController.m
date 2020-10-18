//
//  ColdViewController.m
//
//  bither-ios
//
//  Copyright 2014 http://Bither.net
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "ColdViewController.h"
#import  "BitherSetting.h"
#import "IOS7ContainerViewController.h"
#import "AppDelegate.h"
#import "BTAddressManager.h"
#import "UIViewController+PiShowBanner.h"
#import "DialogFirstRunWarning.h"


@interface ColdViewController ()
@property(strong, nonatomic) NSArray *tabButtons;
@property(strong, nonatomic) IBOutlet TabButton *tabCheck;
@property(strong, nonatomic) IBOutlet TabButton *tabAddress;
@property(strong, nonatomic) IBOutlet TabButton *tabSetting;
@property(weak, nonatomic) IBOutlet UIView *vTab;

@property(strong, nonatomic) PiPageViewController *page;
@end

@implementation ColdViewController

- (void)loadView {
    [super loadView];
    [self initTabs];
    self.page = [[PiPageViewController alloc] initWithStoryboard:self.storyboard andViewControllerIdentifiers:[[NSArray alloc] initWithObjects:@"tab_check", @"tab_cold_address", @"tab_option_cold", nil]];
    self.page.pageDelegate = self;
    [self addChildViewController:self.page];
    self.page.index = 1;
    self.page.view.frame = CGRectMake(0, TabBarHeight, self.view.frame.size.width, self.view.frame.size.height - TabBarHeight);
    [self.view insertSubview:self.page.view atIndex:0];
    ApplicationDelegate.coldController = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [DialogFirstRunWarning show:self.view.window];
    });
}

- (void)initTabs {
    self.tabButtons = [[NSArray alloc] initWithObjects:self.tabCheck, self.tabAddress, self.tabSetting, nil];
    self.tabCheck.imageUnselected = [UIImage imageNamed:@"tab_guard"];
    self.tabCheck.imageSelected = [UIImage imageNamed:@"tab_guard_checked"];
    self.tabAddress.imageUnselected = [UIImage imageNamed:@"tab_main"];
    self.tabAddress.imageSelected = [UIImage imageNamed:@"tab_main_checked"];
    self.tabAddress.selected = YES;
    self.tabSetting.imageUnselected = [UIImage imageNamed:@"tab_option"];
    self.tabSetting.imageSelected = [UIImage imageNamed:@"tab_option_checked"];
    for (int i = 0; i < self.tabButtons.count; i++) {
        TabButton *tab = [self.tabButtons objectAtIndex:i];
        tab.index = i;
        tab.delegate = self;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    isInit = YES;
    cnt = 4;
    self.dict = [[NSMutableDictionary alloc] init];
    [self.view bringSubviewToFront:self.addAddressBtn];
    ApplicationDelegate.coldController = self;
    
}

#pragma mark - TabBar delegate

- (void)setTabBarSelectedItem:(int)index {
    for (int i = 0; i < self.tabButtons.count; i++) {
        TabButton *tabButton = (TabButton *) [self.tabButtons objectAtIndex:i];
        if (i == index) {
            tabButton.selected = YES;
        } else {
            tabButton.selected = NO;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.navigationController.navigationBar.hidden) {
        self.navigationController.navigationBar.hidden = YES;
    }
}

- (void)pageIndexChanged:(int)index {
    for (int i = 0; i < self.tabButtons.count; i++) {
        TabButton *tab = [self.tabButtons objectAtIndex:i];
        tab.selected = i == index;
    }
}

- (void)tabButtonPressed:(int)index {
    if (index != self.page.index) {
        [self.page setIndex:index animated:YES];
    }
}

- (void)viewDidUnload {
    [self setTabCheck:nil];
    [self setTabAddress:nil];
    [self setTabSetting:nil];

    self.tabButtons = nil;
    [self.page removeFromParentViewController];
    self.page = nil;
    [super viewDidUnload];
}

- (IBAction)addPressed:(id)sender {
    if ([BTAddressManager instance].privKeyAddresses.count >= PRIVATE_KEY_OF_COLD_COUNT_LIMIT && [BTAddressManager instance].hasHDMKeychain) {
        [self showBannerWithMessage:NSLocalizedString(@"reach_address_count_limit", nil) belowView:self.vTab];
        return;
    }
    IOS7ContainerViewController *container = [[IOS7ContainerViewController alloc] init];
    container.controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ColdAddressAdd"];
    container.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:container animated:YES completion:nil];
}

- (void)toChooseModeViewController {
    UIViewController *chooseModeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChooseModeViewController"];
    chooseModeViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:chooseModeViewController animated:YES completion:nil];
}

@end
