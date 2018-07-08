//
//  RecordViewController.m
//  split
//
//  Created by 郜俊博 on 2018/7/8.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import "ContatctViewController.h"
#import "MainViewController.h"
#import "RecordViewController.h"
#import "PCMPlayer.h"
#import "DBManager.h"
#import <objc/runtime.h>
#import "NSString+NSString_MD5.h"

#define MM_SQLITE_PATH @"Documents/Test/AppDomain-com.tencent.xin/Documents/ddac4abdb1c3ba52f3cd4a0a1e1013ef/DB/MM.sqlite"
#define WCDB_CONTACT_SQILTE_PATH @"Documents/Test/AppDomain-com.tencent.xin/Documents/ddac4abdb1c3ba52f3cd4a0a1e1013ef/DB/WCDB_Contact.sqlite"

@interface RecordViewController () <ContactDelegate>
@property (weak) IBOutlet NSTableView *recordTableView;

@property (nonatomic,retain) NSMutableArray *recordDataArray;

@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.recordTableView.usesAlternatingRowBackgroundColors = YES; //背景颜色的交替，一行白色，一行灰色。设置后，原来设置的 backgroundColor 就无效了。
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.recordDataArray.count;
}
#pragma mark - 行高
-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 44;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *strIdt = @"recordID";
    NSTableCellView *cell = [tableView makeViewWithIdentifier:strIdt owner:self];
    if (!cell) {
        cell = [[NSTableCellView alloc]init];
        cell.identifier = strIdt;
    }
    cell.wantsLayer = YES;
    cell.textField.stringValue = [NSString stringWithFormat:@"%@",self.recordDataArray[row]];
    return cell;
}



- (void)refreshTableView:(NSString *)wxid {
    [self.recordDataArray removeAllObjects];
    [[DBManager sharedInstance] initPath:[[NSHomeDirectory() stringByAppendingPathComponent:MM_SQLITE_PATH] UTF8String]];
    NSString *sql =[NSString stringWithFormat:@"select MesLocalID,Message,Des from Chat_%@",[NSString MD5_Lower:wxid]] ;
    NSMutableArray *result = [[DBManager sharedInstance] execQuery:[sql UTF8String] className:"MessageModel" dbPath:[[NSHomeDirectory() stringByAppendingPathComponent:MM_SQLITE_PATH] UTF8String]];
    for (int i=0; i<result.count; i++) {
        Class messageModel = objc_getClass("MessageModel");
        Ivar ivar_message_name = class_getInstanceVariable(messageModel, "Message");
        id  message_name_id =  object_getIvar(result[i], ivar_message_name);
        NSString *message = [NSString stringWithFormat:@"%@",message_name_id];
        [self.recordDataArray addObject:message];
    }
    [self.recordTableView reloadData];
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    
}


-(instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _recordDataArray = [[NSMutableArray alloc] init];
      
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder   ]) {
        _recordDataArray = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
