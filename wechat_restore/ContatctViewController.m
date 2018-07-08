//
//  ContatctViewController.m
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
#include <stdio.h>
#include <stdlib.h>
#import "NSString+NSString_MD5.h"

#define MM_SQLITE_PATH @"Documents/Test/AppDomain-com.tencent.xin/Documents/ddac4abdb1c3ba52f3cd4a0a1e1013ef/DB/MM.sqlite"
#define WCDB_CONTACT_SQILTE_PATH @"Documents/Test/AppDomain-com.tencent.xin/Documents/ddac4abdb1c3ba52f3cd4a0a1e1013ef/DB/WCDB_Contact.sqlite"


@interface ContatctViewController ()

@property (weak) IBOutlet NSTextField *pathTextField;
@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic,retain) NSMutableArray *dataArray;
@property (nonatomic,retain) PCMPlayer *player;
@property (nonatomic,retain) NSMutableArray *fileArray;


@end

@implementation ContatctViewController


- (IBAction)openClick:(NSButton *)sender {
    NSArray<NSURL * > *folderArray = [self openFinder];
    NSError *error;
    if (folderArray.count == 1) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path =[folderArray.firstObject path];
        _pathTextField.stringValue = path;
        NSString *dbPath =[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Manifest.db"];
        if ([fileManager fileExistsAtPath:[path stringByAppendingPathComponent:@"Manifest.db"]]) {
            if ([fileManager fileExistsAtPath:dbPath ]) {
                [fileManager removeItemAtPath:dbPath error:&error];
                if (error != nil) {
                    NSLog(@"%@",error);
                }
            }
            [fileManager copyItemAtPath:[path stringByAppendingPathComponent:@"Manifest.db"] toPath:dbPath error:&error];
            if (error != nil) {
                NSLog(@"%@",error);
            }
        }
        
        const char *sql = "select fileid,relativepath,domain from Files where domain = 'AppDomain-com.tencent.xin'";
        [[DBManager sharedInstance] initPath:[dbPath UTF8String] ];
        
        NSMutableArray *result =  [[DBManager sharedInstance]execQuery:sql className:"FileModel" dbPath:[dbPath UTF8String]];
        Class fileModel = objc_getClass("FileModel");
        Ivar ivar_file_id = class_getInstanceVariable(fileModel, "fileID");
        Ivar ivar_relative_path = class_getInstanceVariable(fileModel, "relativePath");
        Ivar ivar_domain = class_getInstanceVariable(fileModel, "domain");
        [fileManager createDirectoryAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Test"] withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil) {
            NSLog(@"%@",error);
        }
        NSLog(@"%@",NSHomeDirectory());
        for (int i=0; i<result.count; i++) {
            id  value =  object_getIvar(result[i], ivar_file_id);
            id  relativePath =  object_getIvar(result[i], ivar_relative_path);
            id  domain =  object_getIvar(result[i], ivar_domain);
            NSString *fileID =[NSString stringWithFormat:@"%@",value];
            NSString *start = [fileID substringWithRange:NSMakeRange(0, 2)];
            NSString *srcPath = [[path  stringByAppendingPathComponent:start] stringByAppendingPathComponent:fileID];
            if ([fileManager fileExistsAtPath:srcPath]) {
                NSString *dstPath =[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/Test/%@/%@",domain,relativePath]];
                if (![fileManager fileExistsAtPath:dstPath]) {
                    [fileManager createDirectoryAtPath:[dstPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
                    [fileManager copyItemAtPath:srcPath toPath:dstPath error:&error];
                }
                if (error != nil) {
                    NSLog(@"%@--->%@",srcPath,dstPath);
                    // NSLog(@"%@",dstPath);
                    
                }
            }
        }
        
        [self readChatRecord];
    }
}


-(void)readChatRecord{
    
    [self.dataArray removeAllObjects];
    
    [[DBManager sharedInstance] initPath:[[NSHomeDirectory() stringByAppendingPathComponent:MM_SQLITE_PATH] UTF8String]];
    [[DBManager sharedInstance] initPath:[[NSHomeDirectory() stringByAppendingPathComponent:WCDB_CONTACT_SQILTE_PATH] UTF8String]];
    
    NSMutableArray *result = [[DBManager sharedInstance] execQuery:"select name,tbl_name from sqlite_master where type = 'table' " className:"MMTables" dbPath:[[NSHomeDirectory() stringByAppendingPathComponent:MM_SQLITE_PATH] UTF8String]];
    
    NSMutableArray *contact_result = [[DBManager sharedInstance] execQuery:"select * from Friend" className:"FriendModel" dbPath:[[NSHomeDirectory() stringByAppendingPathComponent:WCDB_CONTACT_SQILTE_PATH] UTF8String]];
    
    for (int i=0; i<result.count; i++) {
        Class fileModel = objc_getClass("MMTables");
        Ivar ivar_table_name = class_getInstanceVariable(fileModel, "name");
        id  table_name_id =  object_getIvar(result[i], ivar_table_name);
        NSString *table_name = [NSString stringWithFormat:@"%@",table_name_id];
        if ([table_name hasPrefix:@"Chat"]) {
            Class friendModel = objc_getClass("FriendModel");
            Ivar ivar_user_name = class_getInstanceVariable(friendModel, "userName");
            
            
            for (int j=0; j<contact_result.count; j++) {
                id  user_name_id =  object_getIvar(contact_result[j], ivar_user_name);
                NSString *user_name = [NSString stringWithFormat:@"%@",user_name_id];
                if ([[NSString MD5_Lower:user_name] isEqualToString:[table_name componentsSeparatedByString:@"_"][1]]) {
                    [contact_result removeObjectAtIndex:j];
                    [_dataArray addObject:user_name];
                }
            }
        }
        
    }
    [self.tableView reloadData];
}


- (NSArray<NSURL *> *)openFinder{
    NSArray<NSURL *> *result = [[NSArray<NSURL*> alloc] init];
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setMessage:@"请选择文件夹路径"];
    [panel setCanChooseFiles:false];  //是否能选择文件file
    [panel setCanChooseDirectories:YES];  //是否能打开文件夹
    [panel setAllowsMultipleSelection:false];  //是否允许多选file
    [panel setCanCreateDirectories:YES];
    NSInteger finded = [panel runModal];   //获取panel的响应
    if (finded == NSModalResponseOK) {
        result = [panel URLs];
    }
    return  result;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@",[NSString MD5_Lower:@"wxid_8baaf23wanms22"]);
    self.tableView.usesAlternatingRowBackgroundColors = YES; //背景颜色的交替，一行白色，一行灰色。设置后，原来设置的 backgroundColor 就无效了。
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    
    return self.dataArray.count;
}
#pragma mark - 行高
-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 44;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *strIdt = @"contactID";
    NSTableCellView *cell = [tableView makeViewWithIdentifier:strIdt owner:self];
    if (!cell) {
        cell = [[NSTableCellView alloc]init];
        cell.identifier = strIdt;
    }
    cell.wantsLayer = YES;
    cell.textField.stringValue = [NSString stringWithFormat:@"%@",self.dataArray[row]];
    return cell;
}
//选中的响应
-(void)tableViewSelectionDidChange:(nonnull NSNotification *)notification{
    NSTableView *table = notification.object;
    
    
    if ([self.delegate respondsToSelector:@selector(refreshTableView:)]) {
        [self.delegate performSelector:@selector(refreshTableView:) withObject:self.dataArray[table.selectedRow]];
    }
}


-(instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _fileArray = [[NSMutableArray alloc] init];
        _player = [[PCMPlayer alloc] init];
        _dataArray = [[NSMutableArray alloc] init];
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder   ]) {
        _player = [[PCMPlayer alloc] init];
        _fileArray = [[NSMutableArray alloc] init];
        _dataArray = [[NSMutableArray alloc] init];
        
    }
    return self;
}

-(void)click:(NSButton *)button {
    _player = NULL;
    _player = [[PCMPlayer alloc] init];
    NSString *src = [[NSBundle mainBundle] pathForResource:@"1652" ofType:@"aud"];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.player playWithPath:(char *)[src UTF8String] info:1 API_Fs_Hz:24000];
    });
}
@end
