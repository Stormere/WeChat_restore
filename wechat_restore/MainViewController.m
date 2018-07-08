//
//  MainViewController.m
//  split
//
//  Created by 郜俊博 on 2018/7/8.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import "MainViewController.h"
#import "ContatctViewController.h"
#import "RecordViewController.h"




@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray*item =  self.splitViewItems;
    
    
    ContatctViewController *contact = (ContatctViewController *)[(NSSplitViewItem *)item[0] viewController] ;
    RecordViewController *record = (RecordViewController *)[(NSSplitViewItem *)item[1] viewController] ;
    contact.delegate = (id)record;
    // Do view setup here.
}

@end
