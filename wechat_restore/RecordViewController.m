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
#import "NSString+NSString_MD5.h"
#import "GDataXMLNode.h"


#define MM_SQLITE_PATH @"Documents/Test/AppDomain-com.tencent.xin/Documents/ddac4abdb1c3ba52f3cd4a0a1e1013ef/DB/MM.sqlite"
#define WCDB_CONTACT_SQILTE_PATH @"Documents/Test/AppDomain-com.tencent.xin/Documents/ddac4abdb1c3ba52f3cd4a0a1e1013ef/DB/WCDB_Contact.sqlite"

#define AUD_PATH @"Documents/Test/AppDomain-com.tencent.xin/Documents/ddac4abdb1c3ba52f3cd4a0a1e1013ef/Audio/%@/%@.aud"



@interface RecordViewController () <ContactDelegate>
@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic,retain) NSMutableArray *dataArray;

@property (nonatomic,retain)NSString *wxid;

@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    NSString *strIdt = @"recordID";
    NSTableCellView *cell = [tableView makeViewWithIdentifier:strIdt owner:self];
    if (!cell) {
        cell = [[NSTableCellView alloc]init];
        cell.identifier = strIdt;
    }
    cell.wantsLayer = YES;
    NSDictionary *dict =self.dataArray[row];
    NSString *type = [NSString stringWithFormat:@"%@",[dict valueForKey:@"Type"]];
    if ([type isEqualToString:@"34"]) {
        cell.textField.stringValue = @"语音信息，点击播放！";
    }
    else {
        cell.textField.stringValue = [NSString stringWithFormat:@"%@",[self.dataArray[row]  valueForKey:@"Message"]];
    }
    return cell;
}



- (void)refreshTableView:(NSString *)wxid {
    [self.dataArray removeAllObjects];
    _wxid = wxid;
    [[DBManager sharedInstance] initPath:[[NSHomeDirectory() stringByAppendingPathComponent:MM_SQLITE_PATH] UTF8String]];
    NSString *sql =[NSString stringWithFormat:@"select MesLocalID,Message,Des,Type from Chat_%@",[NSString MD5_Lower:wxid]] ;
    self.dataArray = [[DBManager sharedInstance] execQuery:[sql UTF8String] dbPath:[[NSHomeDirectory() stringByAppendingPathComponent:MM_SQLITE_PATH] UTF8String]];
    
    [self.tableView reloadData];
}


//选中的响应
-(void)tableViewSelectionDidChange:(nonnull NSNotification *)notification{
    NSTableView *table = notification.object;
    
    NSDictionary *dict =self.dataArray[table.selectedRow];
    NSString *type = [NSString stringWithFormat:@"%@",[dict valueForKey:@"Type"]];
    NSString *mesLocalID = [dict valueForKey:@"MesLocalID"];
    
    NSString *message_content = [dict valueForKey:@"Message"];
    
   // NSLog(@"%@",message_content);


    
    if ([type isEqualToString:@"34"]) {
        PCMPlayer *_player = [[PCMPlayer alloc] init];
        NSString *path = [NSString stringWithFormat:AUD_PATH,[NSString MD5_Lower:self.wxid],mesLocalID ];
        NSString *src = [NSHomeDirectory() stringByAppendingPathComponent:path];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_player playWithPath:(char *)[src UTF8String] info:1 API_Fs_Hz:8000];
        });
    } else if ([type isEqualToString:@"49"] || [type isEqualToString:@"3"] || [type isEqualToString:@"50"]  ) {
        GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithXMLString:message_content error:nil];
        GDataXMLElement *elements = [document rootElement];
        
        parseXMLElement(elements,0);
        
       
        
    } else if ([type isEqualToString:@"10000"]) {
        GDataXMLDocument * document = [[GDataXMLDocument alloc] initWithHTMLString:message_content error:nil];
        GDataXMLElement *elements = [document rootElement];
        parseXMLElement(elements,0);

        
    }
    
   // NSLog(@"%@",self.dataArray[table.selectedRow]);
}


void parseXMLElement(GDataXMLElement *elements,int re) {
    
    if (elements != nil) {
        NSArray *array = [elements children];
        for (GDataXMLElement *item in array) {
            NSLog(@"%@:%@",[item name],[item stringValue]);
            NSArray *adsds = [item attributes];
            
            for (GDataXMLNode *item2 in [item attributes]) {
                parseXMLNode(item2);
                
            }
            
            parseXMLElement(item,0);
        }
    }
    
}


void parseXMLNode(GDataXMLNode *node) {
    if (node != nil) {
        NSArray *array = [node children];
        for (GDataXMLNode *item in array) {
            NSLog(@"%@:%@",[item name],[item stringValue]);
            
          
            parseXMLNode(item);
        }
    }
    
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    
}


-(instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _dataArray = [[NSMutableArray alloc] init];
      
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder   ]) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
