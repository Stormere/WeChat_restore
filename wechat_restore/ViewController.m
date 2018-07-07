//
//  ViewController.m
//  wechat_restore
//
//  Created by 郜俊博 on 2018/6/27.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import "ViewController.h"
#import "PCMPlayer.h"
#import "DBManager.h"
#import <objc/runtime.h>
#include <stdio.h>
#include <stdlib.h>


@interface ViewController ()


@property (nonatomic,retain) PCMPlayer *player;
@property (nonatomic,retain) NSMutableArray *fileArray;
@property (weak) IBOutlet NSTextField *pathTextField;
@property (nonatomic,retain) DBManager *mmdb;



@end



@implementation ViewController

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
        [self.mmdb initDB:dbPath];
        NSMutableArray *result =  [self.mmdb execQuery:sql className:"FileModel" ];
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
                    [fileManager createDirectoryAtPath:dstPath withIntermediateDirectories:YES attributes:nil error:&error];
                    [fileManager copyItemAtPath:srcPath toPath:dstPath error:&error];
                }
                if (error != nil) {
                    NSLog(@"%@",error);
                }
           }
        }
        [self.mmdb closeDB];
    }
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

-(instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _fileArray = [[NSMutableArray alloc] init];
        _player = [[PCMPlayer alloc] init];
        _mmdb = [[DBManager alloc] init];
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder   ]) {
        _player = [[PCMPlayer alloc] init];
        _fileArray = [[NSMutableArray alloc] init];
        _mmdb = [[DBManager alloc] init];

    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    NSButton *button = [[NSButton alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
    [button setTitle:@"play"];
    [button setBezelStyle:NSRegularSquareBezelStyle];
    [button setAction:@selector(click:)];
    [self.view addSubview:button];
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


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}


@end
