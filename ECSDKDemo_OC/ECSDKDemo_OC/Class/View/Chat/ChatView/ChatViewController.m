//
//  ChatViewController.m
//  ECSDKDemo_OC
//
//  Created by jiazy on 14/12/5.
//  Copyright (c) 2014年 ronglian. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

#import <AssetsLibrary/ALAssetsLibrary.h>
#import <AssetsLibrary/ALAssetRepresentation.h>

#import "ChatViewController.h"
#import "ChatViewCell.h"
#import "ChatViewTextCell.h"
#import "ChatViewFileCell.h"
#import "ChatViewVoiceCell.h"
#import "ChatViewImageCell.h"
#import "ChatViewVideoCell.h"
#import "DetailsViewController.h"
#import "ContactDetailViewController.h"

#import "HPGrowingTextView.h"
#import "CommonTools.h"

#import "MWPhotoBrowser.h"
#import "MWPhoto.h"

#import "CustomEmojiView.h"
#import "VoipCallController.h"
#import "VideoViewController.h"

#import "ECMessage.h"
#import "ECDevice.h"
#import "ECFileMessageBody.h"
#import "ECVideoMessageBody.h"
#import "ECVoiceMessageBody.h"
#import "ECImageMessageBody.h"

#import "GroupMembersViewController.h"
#import "NSString+containsString.h"

#define ToolbarInputViewHeight 43.0f
#define ToolbarMoreViewHeight 110.0f
#define ToolbarMoreViewHeight1 153.0f
#define ToolbarDefaultTotalHeigth 153.0f //ToolbarInputViewHeight+ToolbarEmojiViewHeight

#define Alert_ResendMessage_Tag 1500


#define KNOTIFICATION_ScrollTable       @"KNOTIFICATION_ScrollTable"
#define KNOTIFICATION_RefreshMoreData   @"KNOTIFICATION_RefreshMoreData"

#define MessagePageSize 15

typedef enum {
    ToolbarDisplay_None=0,
    ToolbarDisplay_Emoji,
    ToolbarDisplay_More,
    ToolbarDisplay_Record
}ToolbarDisplay;

@interface ChatViewController()<UITableViewDataSource, UITableViewDelegate,HPGrowingTextViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,MWPhotoBrowserDelegate,CustomEmojiViewDelegate,UIActionSheetDelegate> {
    BOOL isGroup;
    dispatch_once_t emojiCreateOnce;
    dispatch_once_t scrollBTMOnce;
    NSIndexPath* _longPressIndexPath;
    UIMenuController*  _menuController;
    UIMenuItem *_copyMenuItem;
    UIMenuItem *_deleteMenuItem;
    CGFloat viewHeight;
    BOOL isScrollToButtom;
    BOOL isOpenMembersList;
    NSInteger arrowLocation;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSString* sessionId;
@property (nonatomic, strong) NSMutableArray* messageArray;
@property (strong, nonatomic) NSMutableArray *photos;

#warning 录音效果页面
@property (nonatomic, strong) UIImageView *amplitudeImageView;
@property (nonatomic, strong) UILabel *recordInfoLabel;
@property (nonatomic, strong) ECMessage *playVoiceMessage;

@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UILabel *stateLabel;
//群组还是讨论组
@property (nonatomic, copy) NSString *isDiscussOrGroupName;

@end

const char KAlertResendMessage;

@implementation ChatViewController{
    
#warning 切换工具栏显示
    UIView* _containerView;
    UIImageView *_inputMaskImage;
    HPGrowingTextView *_inputTextView;
    ToolbarDisplay toolbarDisplay;
    BOOL _isDisplayKeyborad;
    CGFloat _oldInputHeight;
    UIView* _inputView;
    UIButton *_recordBtn;
    
#warning 表情页面
    UIButton *_emojiBtn;
    UIButton *_switchVoiceBtn;
    UIButton *_moreBtn;
    CustomEmojiView *_emojiView;
    NSString *_GroupMemberNickName;
    
    BOOL _isReadDeleteMessage;
}

- (instancetype)init {
    NSAssert(NO, @"ChatViewController: use +initWithSessionId");
    return nil;
}

-(instancetype)initWithSessionId:(NSString*)aSessionId {
    if (self = [super init]) {
        self.sessionId = aSessionId;
        isGroup = [aSessionId hasPrefix:@"g"];
    }
    return self;
}

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout =  UIRectEdgeNone;
    }
    
    [DeviceDelegateHelper sharedInstance].sessionId = self.sessionId;
    
    viewHeight = [UIScreen mainScreen].bounds.size.height-64.0f;
    
    
    self.view.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1];
    self.messageArray = [NSMutableArray array];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width,self.view.frame.size.height-ToolbarInputViewHeight-64.0f) style:UITableViewStylePlain];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.tableView.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width,self.view.frame.size.height-ToolbarInputViewHeight-64.0f);
    } else {
        self.tableView.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width,self.view.frame.size.height-ToolbarInputViewHeight-44.0f);
    }
    self.tableView.scrollsToTop = YES;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    isScrollToButtom = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewWillBeginDragging:)];
    [self.tableView addGestureRecognizer:tap];

    [self.view addSubview:self.tableView];
    
    UIView *titleview = [[UIView alloc] initWithFrame:CGRectMake(160.0f, 0.0f, 120.0f, 44.0f)];
    titleview.backgroundColor = [UIColor clearColor];
    self.navigationItem.titleView = titleview;
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 30.0f)];
    _titleLabel = titleLabel;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.backgroundColor = [UIColor clearColor];
    [titleview addSubview:_titleLabel];
    if ([[DemoGlobalClass sharedInstance] getOtherNameWithPhone:self.sessionId]) {
        
        _titleLabel.text = [[DemoGlobalClass sharedInstance] getOtherNameWithPhone:self.sessionId];
    }
    
    UILabel* stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 30.0f, 120.0f, 10.0f)];
    _stateLabel = stateLabel;
    _stateLabel.font = [UIFont systemFontOfSize:11.0f];
    _stateLabel.textAlignment = NSTextAlignmentCenter;
    _stateLabel.textColor = [UIColor whiteColor];
    _stateLabel.backgroundColor = [UIColor clearColor];
    [titleview addSubview:_stateLabel];
    self.navigationItem.titleView = titleview;
    
    UIBarButtonItem * leftItem = nil;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7){
        leftItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"title_bar_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(popViewController:)];
    } else {
        leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"title_bar_back"] style:UIBarButtonItemStyleDone target:self action:@selector(popViewController:)];
    }
    
    self.navigationItem.leftBarButtonItem =leftItem;
    
    if (isGroup) {
        
        if ([[DemoGlobalClass sharedInstance] isDiscussGroupOfId:self.sessionId]) {
            self.isDiscussOrGroupName = @"讨论组";
        } else {
            self.isDiscussOrGroupName = @"群组";
        }

        UIBarButtonItem * rigthItem = nil;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7){
            rigthItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"title_bar_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(navRightBarItemTap:)];
        }else{
            rigthItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"title_bar_more"] style:UIBarButtonItemStyleDone target:self action:@selector(navRightBarItemTap:)];
        }
        self.navigationItem.rightBarButtonItem = rigthItem;
    } else {
        UIBarButtonItem * rightItem = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStyleDone target:self action:@selector(clearBtnClicked)];
        [rightItem setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
        [rightItem setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem =rightItem;
        
        __weak __typeof(self)weakSelf = self;
        [[ECDevice sharedInstance] getUserState:self.sessionId completion:^(ECError *error, ECUserState *state) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if ([strongSelf.sessionId isEqualToString:state.userAcc]) {
                if (state.isOnline) {
                    _stateLabel.text = [NSString stringWithFormat:@"%@-%@", [strongSelf getDeviceWithType:state.deviceType], [strongSelf getNetWorkWithType:state.network]];
                } else {
                    _stateLabel.text = @"对方不在线";
                }
            }
        }];
    }
    
    [self createToolBarView];
    
    self.amplitudeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"press_speak_icon_07"]];
    _amplitudeImageView.center = self.view.center;
    self.recordInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, _amplitudeImageView.frame.size.height-40.0f, _amplitudeImageView.frame.size.width, 30.0f)];
    _recordInfoLabel.backgroundColor = [UIColor clearColor];
    _recordInfoLabel.textAlignment = NSTextAlignmentCenter;
    _recordInfoLabel.textColor = [UIColor whiteColor];
    _recordInfoLabel.font = [UIFont systemFontOfSize:13.0f];
    
    [_amplitudeImageView addSubview:_recordInfoLabel];
    [self.view addSubview:_amplitudeImageView];
    [self.view sendSubviewToBack:_amplitudeImageView];
    
    [self refreshTableView:nil];
}

-(NSString*)getDeviceWithType:(ECDeviceType)type{
    switch (type) {
        case ECDeviceType_AndroidPhone:
            return @"Android手机";
            
        case ECDeviceType_iPhone:
            return @"iPhone手机";
            
        case ECDeviceType_iPad:
            return @"iPad平板";
            
        case ECDeviceType_AndroidPad:
            return @"Android平板";
            
        case ECDeviceType_PC:
            return @"PC";
            
        case ECDeviceType_Web:
            return @"Web";
            
        default:
            return @"未知";
    }
}

-(NSString*)getNetWorkWithType:(ECNetworkType)type{
    switch (type) {
        case ECNetworkType_WIFI:
            return @"wifi";
            
        case ECNetworkType_4G:
            return @"4G";
            
        case ECNetworkType_3G:
            return @"3G";
            
        case ECNetworkType_GPRS:
            return @"GRPS";
            
        case ECNetworkType_LAN:
            return @"Internet";
        default:
            return @"其他";
    }
}

//获取会话消息里面为图片消息的路径数组
- (NSArray *)getImageMessageLocalPath
{
   NSArray *imageMessage = [[DeviceDBHelper sharedInstance] getAllTypeMessageLocalPathOfSessionId:self.sessionId type:MessageBodyType_Image];
    NSMutableArray *localPathArray = [NSMutableArray array];
    NSString *localPath = [NSString string];
    for (int index = 0; index < imageMessage.count; index++) {
        localPath = [[imageMessage objectAtIndex:index] localPath];
        if (localPath) {//图片路径
            localPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:localPath.lastPathComponent];
            [localPathArray addObject:localPath];
        }
    }
    return localPathArray;
}

// 返回点击图片的索引号
- (NSInteger)getImageMessageIndex:(ECImageMessageBody *)mediaBody
{
    NSArray *array = [self getImageMessageLocalPath];
    NSInteger index = 0;
    for (int i= 0;i<array.count;i++) {
        
        if ([[array objectAtIndex:i] isEqualToString:mediaBody.localPath]) {
            index = i;
        }
    }
    return index;
}

- (void)scrollViewToBottom:(BOOL)animated {
    if (self.tableView && self.tableView.contentSize.height > self.tableView.frame.size.height) {
        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
        [self.tableView setContentOffset:offset animated:YES];
    }
}

//view出现时触发
-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];

    [self.tableView reloadData];
    
    dispatch_once(&scrollBTMOnce , ^{
        [self scrollViewToBottom:YES];
    });
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView:) name:KNOTIFICATION_onMesssageChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingAmplitude:) name:KNOTIFICATION_onRecordingAmplitude object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMessageCompletion:) name:KNOTIFICATION_SendMessageCompletion object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearMessageArray:) name:KNotification_DeleteLocalSessionMessage object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadMediaAttachFileCompletion:) name:KNOTIFICATION_DownloadMessageCompletion object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ReceiveMessageDelete:) name:KNOTIFICATION_ReceiveMessageDelete object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollTableView) name:KNOTIFICATION_ScrollTable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMoreMessage) name:KNOTIFICATION_RefreshMoreData object:nil];
    
    _GroupMemberNickName = [[NSUserDefaults standardUserDefaults] objectForKey:@"GroupMemberNickName"];
}

//view出现后触发
-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    extern NSString *const Notification_ChangeMainDisplay;
    [[NSNotificationCenter defaultCenter] postNotificationName:Notification_ChangeMainDisplay object:@0];
    
    dispatch_once(&emojiCreateOnce, ^{
        _emojiView = [CustomEmojiView shardInstance];
        _emojiView.delegate = self;
        _emojiView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 216.0f);
    });
    
    BOOL isHas = NO;
    for (UIView* view in self.view.subviews) {
        if (view == _emojiView) {
            isHas = YES;
            break;
        }
    }
    if (!isHas) {
        [self.view addSubview:_emojiView];
    }
    
    [[DeviceDBHelper sharedInstance] markMessagesAsReadOfSession:self.sessionId];
}

//view消失时触发
-(void)viewWillDisappear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KNOTIFICATION_onRecordingAmplitude object:nil];
    
    if (self.playVoiceMessage) {
        //如果前一个在播放
        objc_setAssociatedObject(self.playVoiceMessage, &KVoiceIsPlayKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [[ECDevice sharedInstance].messageManager stopPlayingVoiceMessage];
    }
    
    self.playVoiceMessage = nil;
    
    [super viewWillDisappear:animated];
}

-(void)dealloc {
    [self.tableView.layer removeAllAnimations];
    self.tableView = nil;
    [DeviceDelegateHelper sharedInstance].sessionId = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - private method
-(void)loadMoreMessage {
    
    ECMessage *message = [self.messageArray objectAtIndex:1];
    NSArray * array = [[DeviceDBHelper sharedInstance] getMessageOfSessionId:self.sessionId beforeTime:message.timestamp andPageSize:MessagePageSize];
    
    CGFloat offsetOfButtom = self.tableView.contentSize.height-self.tableView.contentOffset.y;
    
    NSInteger arraycount = array.count;
    if (array.count == 0) {
        [self.messageArray removeObjectAtIndex:0];
    } else {
        NSIndexSet *indexset = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, arraycount)];
        [self.messageArray insertObjects:array atIndexes:indexset];
        if (array.count < MessagePageSize) {
            [self.messageArray removeObjectAtIndex:0];
        }
    }
    [self.tableView reloadData];
    self.tableView.contentOffset = CGPointMake(0.0f, self.tableView.contentSize.height-offsetOfButtom);

//    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:arraycount inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

//清空聊天记录
-(void)clearBtnClicked {
    [self endOperation];
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if ([[DeviceDBHelper sharedInstance] getAllMessagesOfSessionId:self.sessionId].count == 0) {
        hud.labelText = @"没有内容可以清除";
    } else {
        hud.labelText = @"正在清除聊天内容";
    }
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    
    [self performSelectorOnMainThread:@selector(clearTableView) withObject:nil waitUntilDone:[NSThread isMainThread]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[DeviceDBHelper sharedInstance] deleteAllMessageSaveSessionOfSession:self.sessionId];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"mainviewdidappear" object:nil];
            [hud hide:YES afterDelay:1.0];
        });
    });
}

//导航栏的右按钮
-(void)navRightBarItemTap:(id)sender {
    
    DetailsViewController *groupDetailView = [[DetailsViewController alloc] init];
    groupDetailView.groupId = self.sessionId;
    groupDetailView.isDiscussOrGroupName = self.isDiscussOrGroupName;
    [self.navigationController pushViewController:groupDetailView animated:YES];
}

//返回上一层
-(void)popViewController:(id)sender {
    
    if ([self.sessionId isEqualToString:KDeskNumber]) {
        [[ECDevice sharedInstance].messageManager finishConsultationWithAgent:KDeskNumber completion:^(ECError *error, NSString *agent) {
            
        }];
    }
    
    isScrollToButtom = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KNOTIFICATION_ScrollTable object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KNOTIFICATION_RefreshMoreData object:nil];
    [[DeviceDBHelper sharedInstance] markMessagesAsReadOfSession:self.sessionId];
    [self.view.layer removeAllAnimations];
    [self.tableView.layer removeAllAnimations];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)showMenuViewController:(UIView *)showInView messageType:(MessageBodyType)messageType {
    
    if (_menuController == nil) {
        _menuController = [UIMenuController sharedMenuController];
    }
    
    if (_copyMenuItem == nil) {
        _copyMenuItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(copyMenuAction:)];
    }
    
    if (_deleteMenuItem == nil) {
        _deleteMenuItem = [[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(deleteMenuAction:)];
    }
    
    if (messageType == MessageBodyType_Text) {
        [_menuController setMenuItems:@[_copyMenuItem, _deleteMenuItem]];
    } else {
        [_menuController setMenuItems:@[_deleteMenuItem]];
    }
    
    [_menuController setTargetRect:showInView.frame inView:showInView.superview];
    [_menuController setMenuVisible:YES animated:YES];
}

#pragma mark - notification method

-(void)clearMessageArray:(NSNotification*)notification{
    NSString *session = (NSString*)notification.object;
    if ([session isEqualToString:self.sessionId]) {
        [self performSelectorOnMainThread:@selector(clearTableView) withObject:nil waitUntilDone:[NSThread isMainThread]];
    }
}

-(void)clearTableView {
    [self.messageArray removeAllObjects];
    [self.tableView reloadData];
}

-(void)refreshTableView:(NSNotification*)notification {
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    if (notification == nil) {
        
        [self.messageArray removeAllObjects];
        
        NSArray* message = [[DeviceDBHelper sharedInstance] getLatestHundredMessageOfSessionId:self.sessionId andSize:MessagePageSize];
        if (message.count == MessagePageSize) {
            [self.messageArray addObject:[NSNull null]];
        }
        [self.messageArray addObjectsFromArray:message];
        [self.tableView reloadData];
        
    } else {
        
        ECMessage *message = (ECMessage*)notification.object;
        if (![message.sessionId isEqualToString:self.sessionId]) {
            return;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:@"mainviewdidappear" object:nil];
        [self.messageArray addObject:message];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.messageArray.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }

    if (self.messageArray.count>0){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_ScrollTable object:nil];
        });
    }
}

-(void)scrollTableView {
    if (self && self.tableView && self.messageArray.count>0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messageArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

-(void)scrollViewtobottom{
    [self scrollViewToBottom:YES];
}

/**
 *@brief 键盘的frame更改监听函数
 */
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect beginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat frameY = self.view.frame.size.height-ToolbarInputViewHeight;
    CGRect frame = _containerView.frame;
    
    if (beginFrame.origin.y == [[UIScreen mainScreen] bounds].size.height) {
        //显示键盘
        toolbarDisplay = ToolbarDisplay_None;
        _isDisplayKeyborad = YES;
        
        //只显示输入view
        frameY = endFrame.origin.y-_containerView.frame.size.height+ToolbarMoreViewHeight;
    } else if (endFrame.origin.y == [[UIScreen mainScreen] bounds].size.height) {
        //隐藏键盘
        _isDisplayKeyborad = NO;
        
        //根据不同的类型显示toolbar
        switch (toolbarDisplay) {
            case ToolbarDisplay_Emoji: {
                __weak __typeof(self)weakSelf = self;
                frameY = endFrame.origin.y-frame.size.height-103.0f;
                void(^animations)() = ^{
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    if (strongSelf) {
                        CGRect frame = _emojiView.frame;
                        frame.origin.y = viewHeight-_emojiView.frame.size.height;
                        _emojiView.frame=frame;
                    }
                };

                [UIView animateWithDuration:0.25 delay:0.1f options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:nil];
            }
                break;
                
            case ToolbarDisplay_Record:
                frameY = endFrame.origin.y-frame.size.height+ToolbarMoreViewHeight;
                break;
                
            case ToolbarDisplay_More:
                frameY = endFrame.origin.y-frame.size.height-ToolbarInputViewHeight;
                break;
                
            default:
                frameY = endFrame.origin.y-frame.size.height+ToolbarMoreViewHeight;
                break;
        }
    } else {
        frameY = endFrame.origin.y-frame.size.height+ToolbarMoreViewHeight;
    }
    
    frameY -= 64.0f;
    [self toolbarDisplayChangedToFrameY:frameY andDuration:duration];
    
}

#pragma mark - UITableViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    NSLog(@"scrollViewWillBeginDragging");
    isScrollToButtom = NO;
    if (_isDisplayKeyborad) {
        [self.view endEditing:YES];
    } else {
        [self toolbarDisplayChangedToFrameY:viewHeight-_containerView.frame.size.height+ToolbarMoreViewHeight andDuration:0.25];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    id content = [self.messageArray objectAtIndex:indexPath.row];
    if ([content isKindOfClass:[NSNull class]]) {
        return 44.0f;
    }
    
    ECMessage *message = (ECMessage*)content;
    
#warning 判断Cell是否显示时间
    BOOL isShow = NO;
    if (indexPath.row == 0) {
        isShow = YES;
    } else {
        id preMessagecontent = [self.messageArray objectAtIndex:indexPath.row-1];
        if ([preMessagecontent isKindOfClass:[NSNull class]]) {
            isShow = YES;
        } else {
            
            NSNumber *isShowNumber = objc_getAssociatedObject(message, &KTimeIsShowKey);
            if (isShowNumber) {
                isShow = isShowNumber.boolValue;
            } else {
                ECMessage *preMessage = (ECMessage*)preMessagecontent;
                long long timestamp = message.timestamp.longLongValue;
                long long pretimestamp = preMessage.timestamp.longLongValue;
                isShow = ((timestamp-pretimestamp)>180000); //与前一条消息比较大于3分钟显示
            }
        }
    }
    objc_setAssociatedObject(message, &KTimeIsShowKey, @(isShow), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //根据cell内容获取高度
    CGFloat height = 0.0f;
    switch (message.messageBody.messageBodyType) {
        case MessageBodyType_Text:
            height = [ChatViewTextCell getHightOfCellViewWith:message.messageBody];
            break;
        case MessageBodyType_Voice:
        case MessageBodyType_Video:
        case MessageBodyType_Image:
        case MessageBodyType_File: {
#warning 根据文件的后缀名来获取多媒体消息的类型 麻烦 缺少displayName
            ECFileMessageBody *body = (ECFileMessageBody *)message.messageBody;
            if (body.localPath.length > 0) {
                body.localPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:body.localPath.lastPathComponent];
            }
            
            if (body.displayName.length==0) {
                if (body.localPath.length > 0) {
                    body.displayName = body.localPath.lastPathComponent;
                } else if (body.remotePath.length>0) {
                    body.displayName = body.remotePath.lastPathComponent;
                } else {
                    body.displayName = @"无名字";
                }
            }
            
            switch (message.messageBody.messageBodyType) {
                case MessageBodyType_Voice:
                    height = [ChatViewVoiceCell getHightOfCellViewWith:body];
                    break;
                case MessageBodyType_Image:
                    height = [ChatViewImageCell getHightOfCellViewWith:body];
                    break;
                    
                case MessageBodyType_Video:
                    height = [ChatViewVideoCell getHightOfCellViewWith:body];
                    break;
                    
                default:
                    height = [ChatViewFileCell getHightOfCellViewWith:body];
                    break;
            }
        }
            break;
        default: {
            ECFileMessageBody *body = (ECFileMessageBody *)message.messageBody;
            body.displayName = body.remotePath.lastPathComponent;
            height = [ChatViewFileCell getHightOfCellViewWith:body];
            break;
        }
    }
    
    CGFloat addHeight = 0.0f;
    BOOL isSender = (message.messageState==ECMessageState_Receive?NO:YES);
    if (!isSender && message.isGroup) {
        addHeight = 15.0f;
    }
#warning 显示的时间高度为30.0f
    return height+(isShow?30.0f:0.0f)+addHeight;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messageArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    id cellContent = [self.messageArray objectAtIndex:indexPath.row];
    
    if ([cellContent isKindOfClass:[NSNull class]]) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellrefresscellid"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellrefresscellid"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1];
            UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            activityView.tag = 100;
            activityView.center = cell.contentView.center;
            [cell.contentView addSubview:activityView];
        }
        UIActivityIndicatorView * activityView = (UIActivityIndicatorView *)[cell.contentView viewWithTag:100];
        [activityView startAnimating];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_RefreshMoreData object:nil];
        });
        return cell;
    }
    
    ECMessage *message = (ECMessage*)cellContent;
    BOOL isSender = (message.messageState==ECMessageState_Receive?NO:YES);
    
    NSInteger fileType = message.messageBody.messageBodyType;
    
    NSString *cellidentifier = [NSString stringWithFormat:@"%@_%@_%d", isSender?@"issender":@"isreceiver",NSStringFromClass([message.messageBody class]),(int)fileType];
    
    
//    NSLog(@"\r\n\r\n------->:cellidentifier__%@",cellidentifier);
    
    ChatViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellidentifier];
    if (cell == nil) {
        switch (message.messageBody.messageBodyType) {
                
            case MessageBodyType_Text:
                cell = [[ChatViewTextCell alloc] initWithIsSender:isSender reuseIdentifier:cellidentifier];
                break;
            case MessageBodyType_Voice:
                cell = [[ChatViewVoiceCell alloc] initWithIsSender:isSender reuseIdentifier:cellidentifier];
                break;
            case MessageBodyType_Video:
    NSLog(@"\r\n\r\n------->:cellidentifier__%@",cellidentifier);
                cell = [[ChatViewVideoCell alloc] initWithIsSender:isSender reuseIdentifier:cellidentifier];
                break;
            case MessageBodyType_Image:
    NSLog(@"\r\n\r\n------->:cellidentifier__%@",cellidentifier);
                cell = [[ChatViewImageCell alloc] initWithIsSender:isSender reuseIdentifier:cellidentifier];
                break;
            default:
    NSLog(@"\r\n\r\n------->:cellidentifier__%@",cellidentifier);
                cell = [[ChatViewFileCell alloc] initWithIsSender:isSender reuseIdentifier:cellidentifier];
                break;
        }
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(cellHandleLongPress:)];
        [cell.bubbleView addGestureRecognizer:longPress];
    }
    
    [cell bubbleViewWithData:[self.messageArray objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark - GestureRecognizer

//点击tableview，结束输入操作
-(void)endOperation{
    if (toolbarDisplay == ToolbarDisplay_Record) {
        return;
    }
    toolbarDisplay = ToolbarDisplay_None;
    if (_isDisplayKeyborad) {
        [self.view endEditing:YES];
    } else {
        [self toolbarDisplayChangedToFrameY:viewHeight-_containerView.frame.size.height+ToolbarMoreViewHeight andDuration:0.25];
    }
}

-(void)cellHandleLongPress:(UILongPressGestureRecognizer * )longPress{
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        
        CGPoint point = [longPress locationInView:self.tableView];
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:point];
        if(indexPath == nil) return;
        
        id tableviewcell = [self.tableView cellForRowAtIndexPath:indexPath];
        if ([tableviewcell isKindOfClass:[ChatViewCell class]]) {
            ChatViewCell *cell = (ChatViewCell *)tableviewcell;
            [cell becomeFirstResponder];
            _longPressIndexPath = indexPath;
            [self showMenuViewController:cell.bubbleView messageType:cell.displayMessage.messageBody.messageBodyType];
        }
    }
}

#pragma mark - MenuItem actions

- (void)copyMenuAction:(id)sender {
    [_menuController setMenuItems:nil];
    //复制
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (_longPressIndexPath.row < self.messageArray.count) {
        ECMessage *message = [self.messageArray objectAtIndex:_longPressIndexPath.row];
        ECTextMessageBody *body = (ECTextMessageBody*)message.messageBody;
        pasteboard.string = body.text;
    }
    _longPressIndexPath = nil;
}

- (void)deleteMenuAction:(id)sender {
    [_menuController setMenuItems:nil];
    if (_longPressIndexPath && _longPressIndexPath.row >= 0) {
        ECMessage *message = [self.messageArray objectAtIndex:_longPressIndexPath.row];
        NSNumber* isplay = objc_getAssociatedObject(message, &KVoiceIsPlayKey);
        if (isplay.boolValue) {
            objc_setAssociatedObject(self.playVoiceMessage, &KVoiceIsPlayKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [[ECDevice sharedInstance].messageManager stopPlayingVoiceMessage];
            self.playVoiceMessage = nil;
        }
        
        if (message==self.messageArray.lastObject) {
            //删除最后消息才需要刷新session
            if (message==self.messageArray.firstObject) {
                //如果删除的也是唯一一个消息，删除session
                [[DeviceDBHelper sharedInstance] deleteMessage:message andPre:nil];
            } else {
                //使用前一个消息刷新session
                [[DeviceDBHelper sharedInstance] deleteMessage:message andPre:[self.messageArray objectAtIndex:_longPressIndexPath.row-1]];
            }
        } else {
            [[IMMsgDBAccess sharedInstance] deleteMessage:message.messageId andSession:self.sessionId];
        }
        
        [self.messageArray removeObject:message];
        [self.tableView deleteRowsAtIndexPaths:@[_longPressIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    _longPressIndexPath = nil;
}

#pragma mark - UIResponder custom
- (void)dispatchCustomEventWithName:(NSString *)name userInfo:(NSDictionary *)userInfo {
    ECMessage * message = [userInfo objectForKey:KResponderCustomECMessageKey];
    if ([name isEqualToString:KResponderCustomChatViewFileCellBubbleViewEvent]) {
        NSLog(@"\r\n\r\n------->:FileCell_Tap");
        
        [self fileCellBubbleViewTap:message];
    } else if ([name isEqualToString:KResponderCustomChatViewImageCellBubbleViewEvent]) {
        NSLog(@"\r\n\r\n------->:ImageCell_Tap");
        
        [self imageCellBubbleViewTap:message];
    } else if ([name isEqualToString:KResponderCustomChatViewVoiceCellBubbleViewEvent]) {
        NSLog(@"\r\n\r\n------->:VoiceCell_Tap");
        [self voiceCellBubbleViewTap:message];
    } else if ([name isEqualToString:KResponderCustomChatViewVideoCellBubbleViewEvent]) {
        NSLog(@"\r\n\r\n------->:VideoCell_Tap");
        [self videoCellPlayVideoTap:message];
    } else if ([name isEqualToString:KResponderCustomChatViewCellResendEvent]) {
        NSLog(@"\r\n\r\n------->:ReSendEvent_Tap");
        ChatViewCell *resendCell = [userInfo objectForKey:KResponderCustomTableCellKey];
        ECMessage *message = resendCell.displayMessage;

        UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:nil message:@"重发该消息？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"重发",nil];
        objc_setAssociatedObject(alertView, &KAlertResendMessage, message, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        alertView.tag = Alert_ResendMessage_Tag;
        [alertView show];
    } else if ([name isEqualToString:KResponderCustomECMessagePortraitImgKey]){
        
        NSLog(@"\r\n\r\n------->:头像点击Portrait_Tap");
        NSString *phone = message.from;
        ContactDetailViewController *contactVC = [[ContactDetailViewController alloc] init];
        contactVC.dict = @{nameKey:[[DemoGlobalClass sharedInstance] getOtherNameWithPhone:phone],phoneKey:phone,imageKey:[[DemoGlobalClass sharedInstance] getOtherImageWithPhone:phone]};
        [self.navigationController pushViewController:contactVC animated:YES];
    }
   
}

-(void)videoCellPlayVideoTap:(ECMessage*)message {
    
    ECVideoMessageBody *mediaBody = (ECVideoMessageBody*)message.messageBody;

    if (message.messageState != ECMessageState_Receive && mediaBody.localPath.length>0) {
        [self createMPPlayerController:mediaBody.localPath];
        return;
    }
    
    if (mediaBody.mediaDownloadStatus != ECMediaDownloadSuccessed || mediaBody.localPath.length == 0) {
        
        MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.labelText = @"正在加载视频，请稍后";
        
        __weak typeof(self) weakSelf = self;
        [[DeviceChatHelper sharedInstance] downloadMediaMessage:message andCompletion:^(ECError *error, ECMessage *message) {
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [MBProgressHUD hideHUDForView:strongSelf.view animated:YES];
            if (error.errorCode == ECErrorType_NoError) {

                [strongSelf createMPPlayerController:mediaBody.localPath];
                NSLog(@"%@",[NSString stringWithFormat:@"file://localhost%@", mediaBody.localPath]);
            }
        }];
    } else {
        [self createMPPlayerController:mediaBody.localPath];
    }
}

- (void)createMPPlayerController:(NSString *)fileNamePath {
    
    MPMoviePlayerViewController* playerView = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://localhost%@", fileNamePath]]];
    
    playerView.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    [playerView.view setBackgroundColor:[UIColor clearColor]];
    [playerView.view setFrame:self.view.bounds];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinishedCallback:) name:MPMoviePlayerPlaybackDidFinishNotification object:playerView.moviePlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieStateChangeCallback:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:playerView.moviePlayer];
    
    [self presentViewController:playerView animated:NO completion:nil];
}

-(void)movieStateChangeCallback:(NSNotification*)notify  {
    
    //点击播放器中的播放/ 暂停按钮响应的通知
    MPMoviePlayerController *playerView = notify.object;
    MPMoviePlaybackState state = playerView.playbackState;
    switch (state) {
        case MPMoviePlaybackStatePlaying:
            NSLog(@"正在播放...");
            break;
        case MPMoviePlaybackStatePaused:
            NSLog(@"暂停播放.");
            break;
        case MPMoviePlaybackStateSeekingForward:
            NSLog(@"快进");
            break;
        case MPMoviePlaybackStateSeekingBackward:
            NSLog(@"快退");
            break;
        case MPMoviePlaybackStateInterrupted:
            NSLog(@"打断");
            break;
        case MPMoviePlaybackStateStopped:
            NSLog(@"停止播放.");
            break;
        default:
            NSLog(@"播放状态:%li",state);
            break;
    }
}

-(void)movieFinishedCallback:(NSNotification*)notify{
    
    // 视频播放完或者在presentMoviePlayerViewControllerAnimated下的Done按钮被点击响应的通知。
    MPMoviePlayerController* theMovie = [notify object];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:theMovie];
    [self dismissMoviePlayerViewControllerAnimated];
}

-(void)fileCellBubbleViewTap:(ECMessage*)message {
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"无法打开该文件";
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:2];
}

-(void)playVoiceMessage:(ECMessage*)message {
    
    NSNumber* isplay = objc_getAssociatedObject(message, &KVoiceIsPlayKey);
    
    NSLog(@"\r\n\r\n------->:isplay 是个什么东东 :%@ ",isplay);
    
    if (isplay == nil) {
        //首次点击
        isplay = @YES;
        NSLog(@"\r\n\r\n------->:首次点击 isplay 是个什么东东 :%@ ",isplay);
    } else {
        isplay = @(!isplay.boolValue);
        
        NSLog(@"\r\n\r\n------->:isplay 是个什么东东 :%@ ",isplay);
    }
    
    if (self.playVoiceMessage) {
        //如果前一个在播放
        NSLog(@"\r\n\r\n------->:self.playVoiceMessage = 存在");
        objc_setAssociatedObject(self.playVoiceMessage, &KVoiceIsPlayKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        
        [[ECDevice sharedInstance].messageManager stopPlayingVoiceMessage];
        
        
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.messageArray indexOfObject:self.playVoiceMessage] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        self.playVoiceMessage = nil;
    }

    __weak __typeof(self) weakSelf = self;
    if (isplay.boolValue) {
        
        NSLog(@"\r\n\r\n------->:isplay.boolValue = 存在__%d",isplay.boolValue);
        
        
        self.playVoiceMessage = message;
        objc_setAssociatedObject(message, &KVoiceIsPlayKey, isplay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if ([DemoGlobalClass sharedInstance].isPlayEar) {
            NSLog(@"耳机播放");
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        } else {
            NSLog(@"扬声器播放");
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        }
        
        NSLog(@" playVoiceMessage 开始播放AMR");
        [[ECDevice sharedInstance].messageManager playVoiceMessage:(ECVoiceMessageBody*)message.messageBody completion:^(ECError *error) {
            if (weakSelf) {
                objc_setAssociatedObject(weakSelf.playVoiceMessage, &KVoiceIsPlayKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                weakSelf.playVoiceMessage = nil;
                [weakSelf.tableView beginUpdates];
                [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.messageArray indexOfObject:self.playVoiceMessage] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                [weakSelf.tableView endUpdates];
            }
        }];
        
        [weakSelf.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.messageArray indexOfObject:self.playVoiceMessage] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [weakSelf.tableView endUpdates];
    }
}

-(void)voiceCellBubbleViewTap:(ECMessage*)message{
    
    ECVoiceMessageBody* mediaBody = (ECVoiceMessageBody*)message.messageBody;
    if (mediaBody.localPath.length>0 && [[NSFileManager defaultManager] fileExistsAtPath:mediaBody.localPath]) {
        
        NSLog(@"本地已存在ARM,播放就是了");
         [self playVoiceMessage:message];
    } else if (message.messageState == ECMessageState_Receive && mediaBody.remotePath.length>0){
        
        NSLog(@"本地不存在ARM,要下载");
        MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"正在获取文件";
        hud.margin = 10.f;
        hud.removeFromSuperViewOnHide = YES;
        
        __weak __typeof(self)weakSelf = self;
        [[DeviceChatHelper sharedInstance] downloadMediaMessage:message andCompletion:^(ECError *error, ECMessage *message) {
            
            if (weakSelf == nil) {
                return;
            }
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [MBProgressHUD hideHUDForView:strongSelf.view animated:YES];
            if (error.errorCode != ECErrorType_NoError) {
                MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"获取文件失败";
                hud.margin = 10.f;
                hud.removeFromSuperViewOnHide = YES;
                [hud hide:YES afterDelay:2];
            }
        }];
    }
}

-(void)imageCellBubbleViewTap:(ECMessage*)message{
        
    if (message.messageBody.messageBodyType >= MessageBodyType_Voice) {
        ECImageMessageBody *mediaBody = (ECImageMessageBody*)message.messageBody;
        
        if (mediaBody.localPath.length>0 && [[NSFileManager defaultManager] fileExistsAtPath:mediaBody.localPath]) {
            
            [self showPhotoBrowser:[self getImageMessageLocalPath] index:[self getImageMessageIndex:mediaBody]];
            
        } else if (message.messageState == ECMessageState_Receive && mediaBody.remotePath.length>0 && ([[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@",message.messageId]]==NO)) {
            
            MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.labelText = @"正在获取文件";
            hud.removeFromSuperViewOnHide = YES;
            
            __weak __typeof(self)weakSelf = self;
            
            [[DeviceChatHelper sharedInstance] downloadMediaMessage:message andCompletion:^(ECError *error, ECMessage *message) {
                
                if (weakSelf == nil) {
                    return ;
                }
                
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [MBProgressHUD hideHUDForView:strongSelf.view animated:YES];
                if (error.errorCode == ECErrorType_NoError) {
                    if ([mediaBody.localPath hasSuffix:@".jpg"] || [mediaBody.localPath hasSuffix:@".png"]) {
                        
                        [strongSelf showPhotoBrowser:[self getImageMessageLocalPath] index:[self getImageMessageIndex:mediaBody]];
                    }
                } else {
                    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
                    hud.mode = MBProgressHUDModeText;
                    hud.labelText = @"获取文件失败";
                    hud.margin = 10.f;
                    hud.removeFromSuperViewOnHide = YES;
                    [hud hide:YES afterDelay:2];
                }
            }];
        }
    }
}

#pragma mark - UIAlertViewDelegate

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == Alert_ResendMessage_Tag) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            ECMessage *message = objc_getAssociatedObject(alertView, &KAlertResendMessage);
            [self.messageArray removeObject:message];
            [[DeviceChatHelper sharedInstance] resendMessage:message];
            [self.messageArray addObject:message];
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Photo browser
-(void)showPhotoBrowser:(NSArray*)imageArray index:(NSInteger)currentIndex{
    if (imageArray && [imageArray count] > 0) {
        NSMutableArray *photoArray = [NSMutableArray array];
        for (id object in imageArray) {
            MWPhoto *photo;
            if ([object isKindOfClass:[UIImage class]]) {
                photo = [MWPhoto photoWithImage:object];
            } else if ([object isKindOfClass:[NSURL class]]) {
                photo = [MWPhoto photoWithURL:object];
            } else if ([object isKindOfClass:[NSString class]]) {
                photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:object]];
            }
            [photoArray addObject:photo];
        }
        
        self.photos = photoArray;
    }

    MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    photoBrowser.displayActionButton = YES;
    photoBrowser.displayNavArrows = NO;
    photoBrowser.displaySelectionButtons = NO;
    photoBrowser.alwaysShowControls = NO;
    photoBrowser.zoomPhotosToFill = YES;
    photoBrowser.enableGrid = NO;
    photoBrowser.startOnGrid = NO;
    photoBrowser.enableSwipeToDismiss = NO;
    [photoBrowser setCurrentPhotoIndex:currentIndex];

    [self.navigationController pushViewController:photoBrowser animated:YES];
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser{
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index{
    if (index < self.photos.count) {
        return self.photos[index];
    }
    return nil;
}

#pragma mark - 创建工具栏和布局变化操作

/**
 *@brief 生成工具栏
 */
-(void)createToolBarView {
    
    _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.tableView.frame.origin.y+self.tableView.frame.size.height, self.view.frame.size.width, ToolbarDefaultTotalHeigth)];
    _containerView.backgroundColor = [UIColor colorWithRed:225.0f/255.0f green:225.0f/255.0f blue:225.0f/255.0f alpha:1.0f];
    [self.view addSubview:_containerView];
    _oldInputHeight = ToolbarDefaultTotalHeigth;
    
    //聊天的基础功能
    _switchVoiceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _switchVoiceBtn.tag = ToolbarDisplay_Record;
    [_switchVoiceBtn addTarget:self action:@selector(switchToolbarDisplay:) forControlEvents:UIControlEventTouchUpInside];
    [_switchVoiceBtn setImage:[UIImage imageNamed:@"voice_icon"] forState:UIControlStateNormal];
    [_switchVoiceBtn setImage:[UIImage imageNamed:@"voice_icon_on"] forState:UIControlStateHighlighted];
    _switchVoiceBtn.frame = CGRectMake(5.0f, 5.0f, 31.0f, 31.0f);
    _switchVoiceBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _containerView.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1];
    [_containerView addSubview:_switchVoiceBtn];
    
    _inputTextView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(40.0f, 7.0f, 183.0f, 25.0f)];
    _inputTextView.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1];
    _inputTextView.contentInset = UIEdgeInsetsMake(5, 5, 3, 5);
    _inputTextView.minNumberOfLines = 1;
    _inputTextView.maxNumberOfLines = 4;
    _inputTextView.returnKeyType = UIReturnKeySend;
    _inputTextView.font = [UIFont systemFontOfSize:16.0f];
    _inputTextView.delegate = self;
    _inputTextView.placeholder = @"添加文本";
    _inputTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    _inputMaskImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"input_box"] stretchableImageWithLeftCapWidth:95.0f topCapHeight:16.0f]];
    _inputMaskImage.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _inputMaskImage.center = _inputTextView.center;
    
    _moreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_moreBtn addTarget:self action:@selector(switchToolbarDisplay:) forControlEvents:UIControlEventTouchUpInside];
    [_moreBtn setImage:[UIImage imageNamed:@"add_icon"] forState:UIControlStateNormal];
    [_moreBtn setImage:[UIImage imageNamed:@"add_icon_on"] forState:UIControlStateHighlighted];
    _moreBtn.frame = CGRectMake(_containerView.frame.size.width-36.0f, 5.0f, 31.0f, 31.0f);
    _moreBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _moreBtn.tag = ToolbarDisplay_More;
    [_containerView addSubview:_moreBtn];
    
    _emojiBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _emojiBtn.tag = ToolbarDisplay_Emoji;
    [_emojiBtn addTarget:self action:@selector(switchToolbarDisplay:) forControlEvents:UIControlEventTouchUpInside];
    [_emojiBtn setImage:[UIImage imageNamed:@"facial_expression_icon"] forState:UIControlStateNormal];
    [_emojiBtn setImage:[UIImage imageNamed:@"facial_expression_icon_on"] forState:UIControlStateHighlighted];
    _emojiBtn.frame = CGRectMake(_moreBtn.frame.origin.x-36.0f, 5.0f, 31.0f, 31.0f);
    _emojiBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [_containerView addSubview:_emojiBtn];
    
    CGFloat frame_x = _switchVoiceBtn.frame.origin.x+_switchVoiceBtn.frame.size.width+5.0f;
    _inputTextView.frame = CGRectMake(0, 7.0f, _emojiBtn.frame.origin.x-frame_x-5.0f, 25.0f);
    _inputMaskImage.frame = CGRectMake(0, 5.0f, _emojiBtn.frame.origin.x-frame_x-5.0f, 31.0f);
    _inputView = [[UIView alloc] initWithFrame:CGRectMake(frame_x, 0.0f, _emojiBtn.frame.origin.x-frame_x-5.0f, 43.0f)];
    _inputView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [_inputView addSubview:_inputTextView];
    [_inputView addSubview:_inputMaskImage];
    [_containerView addSubview:_inputView];
    
    _recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_recordBtn setBackgroundImage:[UIImage imageNamed:@"voice_record"] forState:UIControlStateNormal];
    [_recordBtn setTitle:@"按住 说话" forState:UIControlStateNormal];
    _recordBtn.frame = CGRectMake(frame_x, 5.0f, _emojiBtn.frame.origin.x-frame_x-5.0f, 31.0f);
    [_containerView addSubview:_recordBtn];
    [_recordBtn addTarget:self action:@selector(recordButtonTouchDown) forControlEvents:UIControlEventTouchDown];
    [_recordBtn addTarget:self action:@selector(recordButtonTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
    [_recordBtn addTarget:self action:@selector(recordButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [_recordBtn addTarget:self action:@selector(recordDragOutside) forControlEvents:UIControlEventTouchDragOutside];
    [_recordBtn addTarget:self action:@selector(recordDragInside) forControlEvents:UIControlEventTouchDragInside];
    _recordBtn.hidden = YES;
    
    
    //更多的附加功能
    [self createMoreView];
}

-(void)createMoreView{
    
    UIView *moreView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, ToolbarInputViewHeight, _containerView.frame.size.width, ToolbarMoreViewHeight1)];
    moreView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    moreView.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1];
    [_containerView addSubview:moreView];
    NSArray *imagesArr = [NSArray array];
    NSArray *textArr = [NSArray array];
    NSArray *selectorArr = [NSArray array];
    
    
    NSLog(@"\r\n\r\n------->:创建更多的发送按钮");

    
    if (![DemoGlobalClass sharedInstance].isSDKSupportVoIP) {
        
        imagesArr = @[@"dialogue_image_icon",@"dialogue_camera_icon",@"dialogue_snap_icon"];
        textArr = @[@"图片",@"拍摄",@"阅后即焚"];
        selectorArr = @[@"pictureBtnTap:",@"cameraBtnTap:",@"snapFireBtnTap:"];
        
    } else {
        
        if ([self.sessionId hasPrefix:@"g"]) {
            imagesArr = @[@"dialogue_image_icon",@"dialogue_camera_icon"];
            textArr = @[@"图片",@"拍摄"];
            selectorArr = @[@"pictureBtnTap:",@"cameraBtnTap:"];
            
        } else {
            if ( ![self.sessionId isEqualToString:[DemoGlobalClass sharedInstance].userName]) {
                
                imagesArr = @[@"dialogue_image_icon",@"dialogue_camera_icon",@"dialogue_phone_icon",@"dialogue_video_icon",@"dialogue_snap_icon"];
                textArr = @[@"图片",@"拍摄",@"音频",@"视频",@"阅后即焚"];
                selectorArr = @[@"pictureBtnTap:",@"cameraBtnTap:",@"voiceCallBtnTap:",@"videoCallBtnTap:",@"snapFireBtnTap:"];
            } else {
                imagesArr = @[@"dialogue_image_icon",@"dialogue_camera_icon",@"dialogue_snap_icon"];
                textArr = @[@"图片",@"拍摄",@"阅后即焚"];
                selectorArr = @[@"pictureBtnTap:",@"cameraBtnTap:",@"snapFireBtnTap:"];
            }
        }
    }
    
    for (NSInteger index = 0; index<imagesArr.count; index++) {
        
        NSString *imageLight = [NSString stringWithFormat:@"%@_on",imagesArr[index]];
        UIButton *extenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        SEL selector = NSSelectorFromString(selectorArr[index]);
        [extenBtn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
        [extenBtn setImage:[UIImage imageNamed:imagesArr[index]] forState:UIControlStateNormal];
        [extenBtn setImage:[UIImage imageNamed:imageLight] forState:UIControlStateHighlighted];
        if (index == 4 ) {
            extenBtn.frame = CGRectMake(25.0f, 80.0f, 50.0f, 50.0f);
        } else {
            extenBtn.frame = CGRectMake(25.0f+80.0f*index, 10.0f, 50.0f, 50.0f);
        }
        [moreView addSubview:extenBtn];
        
        UILabel *btnLabel = [[UILabel alloc] init];
        btnLabel.font = [UIFont systemFontOfSize:14.0f];
        btnLabel.textAlignment = NSTextAlignmentCenter;
        if (index == 4 || (index == 2 && [self.sessionId isEqualToString:[DemoGlobalClass sharedInstance].userName])) {
            CGFloat x = 0;
            if (index == 2) {
                x = index*80.0f;
            }
            btnLabel.frame = CGRectMake(15.0f+x, extenBtn.frame.origin.y+extenBtn.frame.size.height+5.0f, 70.0f, 15.0f);
        } else {
            btnLabel.frame = CGRectMake(extenBtn.frame.origin.x, extenBtn.frame.origin.y+extenBtn.frame.size.height+5.0f, extenBtn.frame.size.width, 15.0f);
        }
        [moreView addSubview:btnLabel];
        btnLabel.text = textArr[index];
    }
}

#pragma mark - CustomEmojiViewDelegate
-(void)emojiBtnInput:(NSInteger)emojiTag{
    _inputTextView.text =  [_inputTextView.text stringByAppendingString:
                            [CommonTools getExpressionStrById:emojiTag]];

}

-(void)backspaceText{
    if(_inputTextView.text.length > 0) {
        [_inputTextView deleteBackward];
    }
}

-(void)emojiSendBtn:(id)sender{
    [self sendTextMessage];
    _inputTextView.text = @"";
}
/**
 *@brief 改变toolbar显示的frame Y值
 */
-(void)toolbarDisplayChangedToFrameY:(CGFloat)frame_y andDuration:(NSTimeInterval)duration{
    
    __weak __typeof(self)weakSelf = self;
    if (toolbarDisplay == ToolbarDisplay_None) {
        [_emojiBtn setImage:[UIImage imageNamed:@"facial_expression_icon"] forState:UIControlStateNormal];
        [_emojiBtn setImage:[UIImage imageNamed:@"facial_expression_icon_on"] forState:UIControlStateHighlighted];
        CGRect frame = _emojiView.frame;
        frame.origin.y = self.view.frame.size.height;
        _emojiView.frame = frame;
    }
    
    //如果只显示的toolbar是输入框，表情页消失
    if (frame_y == self.view.frame.size.height-_containerView.frame.size.height+ToolbarMoreViewHeight) {
        CGRect frame = _emojiView.frame;
        frame.origin.y = self.view.frame.size.height;
        _emojiView.frame = frame;
    }
    
    void(^animations)() = ^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf && strongSelf.tableView) {
            CGRect frame = _containerView.frame;
            frame.origin.y = frame_y;
            _containerView.frame = frame;
            frame = strongSelf.tableView.frame;
            frame.size.height = _containerView.frame.origin.y-strongSelf.tableView.frame.origin.y;
            strongSelf.tableView.frame = frame;
        }
    };
    
    void(^completion)(BOOL) = nil;
    if (isScrollToButtom) {
        completion = ^(BOOL finished) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf && strongSelf.messageArray.count>0) {
                [strongSelf scrollViewToBottom:YES];
            }
        };
    } else {
        isScrollToButtom = YES;
    }
    
    [UIView animateWithDuration:duration delay:0.0f options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:completion];
}


/**
 *@brief 根据按钮改变工具栏的显示布局
 */
-(void)switchToolbarDisplay:(id)sender {
    
    UIButton*button = (UIButton*)sender;
    
    //如果上次显示内容为录音，更改显示
    if (toolbarDisplay == ToolbarDisplay_Record) {
        CGRect frame = _containerView.frame;
        frame.size.height = _oldInputHeight;
        _containerView.frame = frame;
        
        _inputView.hidden = NO;
        _recordBtn.hidden = YES;
    }
    
    //如果上次显示内容为表情
    if (toolbarDisplay == ToolbarDisplay_Emoji) {
        CGRect frame = _emojiView.frame;
        frame.origin.y = self.view.frame.size.height;
        _emojiView.frame=frame;
    }
    
    __weak __typeof(self)weakSelf = self;
    //如果两次按钮的相同触发输入文本
    if (button.tag == toolbarDisplay) {
        
        toolbarDisplay = ToolbarDisplay_None;
        [_inputTextView becomeFirstResponder];
    } else {
        
        CGFloat framey = self.view.frame.size.height-ToolbarInputViewHeight;
        if (button.tag == ToolbarDisplay_More) {
            //显示出附件功能页面
            framey = viewHeight-_containerView.frame.size.height-ToolbarInputViewHeight;
        } else if (button.tag == ToolbarDisplay_Emoji) {
            //显示表情页面
            framey = viewHeight-_containerView.frame.size.height-103.0f;
            _inputTextView.selectedRange = NSMakeRange(_inputTextView.text.length,0);
            void(^animations)() = ^{
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                if (strongSelf) {
                    CGRect frame = _emojiView.frame;
                    frame.origin.y = viewHeight-_emojiView.frame.size.height;
                    _emojiView.frame=frame;
                }
            };

            [UIView animateWithDuration:0.25 delay:0.1f options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:nil];
            
        } else if (button.tag == ToolbarDisplay_Record) {
            //显示录音按钮，并返回默认的布局
            CGRect frame = _containerView.frame;
            _oldInputHeight = frame.size.height;
            frame.size.height = ToolbarDefaultTotalHeigth;
            _containerView.frame = frame;
            _inputView.hidden = YES;
            _recordBtn.hidden = NO;
            framey = viewHeight-ToolbarInputViewHeight;
        }
        
        toolbarDisplay = (ToolbarDisplay)button.tag;
        
        if (_isDisplayKeyborad) {
            //如果显示键盘，在keyboardWillChangeFrame中更改显示
            [self.view endEditing:YES];
        } else {
            //如果未显示键盘，更改显示
            [self toolbarDisplayChangedToFrameY:framey andDuration:0.25];
        }
    }
    
    //更换按钮上显示的图片
    if (toolbarDisplay == ToolbarDisplay_Record) {
        [_switchVoiceBtn setImage:[UIImage imageNamed:@"keyboard_icon"] forState:UIControlStateNormal];
        [_switchVoiceBtn setImage:[UIImage imageNamed:@"keyboard_icon_on"] forState:UIControlStateHighlighted];
        [_emojiBtn setImage:[UIImage imageNamed:@"facial_expression_icon"] forState:UIControlStateNormal];
        [_emojiBtn setImage:[UIImage imageNamed:@"facial_expression_icon_on"] forState:UIControlStateHighlighted];
    } else if (toolbarDisplay == ToolbarDisplay_Emoji) {
        [_switchVoiceBtn setImage:[UIImage imageNamed:@"voice_icon"] forState:UIControlStateNormal];
        [_switchVoiceBtn setImage:[UIImage imageNamed:@"voice_icon_on"] forState:UIControlStateHighlighted];
        [_emojiBtn setImage:[UIImage imageNamed:@"keyboard_icon"] forState:UIControlStateNormal];
        [_emojiBtn setImage:[UIImage imageNamed:@"keyboard_icon_on"] forState:UIControlStateHighlighted];
    } else {
        [_switchVoiceBtn setImage:[UIImage imageNamed:@"voice_icon"] forState:UIControlStateNormal];
        [_switchVoiceBtn setImage:[UIImage imageNamed:@"voice_icon_on"] forState:UIControlStateHighlighted];
        [_emojiBtn setImage:[UIImage imageNamed:@"facial_expression_icon"] forState:UIControlStateNormal];
        [_emojiBtn setImage:[UIImage imageNamed:@"facial_expression_icon_on"] forState:UIControlStateHighlighted];
    }
}

#pragma mark - 录音操作

//按下操作
-(void)recordButtonTouchDown {
    
    if (self.playVoiceMessage) {
        //如果有播放停止播放语音
        objc_setAssociatedObject(self.playVoiceMessage, &KVoiceIsPlayKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [[ECDevice sharedInstance].messageManager stopPlayingVoiceMessage];
        [self.tableView reloadData];
        self.playVoiceMessage = nil;
    }
    
    static int seedNum = 0;
    if(seedNum >= 1000)
        seedNum = 0;
    seedNum++;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    NSString *file = [NSString stringWithFormat:@"tmp%@%03d.amr", currentDateStr, seedNum];

    ECVoiceMessageBody * messageBody = [[ECVoiceMessageBody alloc] initWithFile:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:file] displayName:file];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    __weak __typeof(self)weakSelf = self;
    [[ECDevice sharedInstance].messageManager startVoiceRecording:messageBody error:^(ECError *error, ECVoiceMessageBody *messageBody) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
//        [strongSelf.view sendSubviewToBack:strongSelf.amplitudeImageView];
        if (error.errorCode == ECErrorType_RecordTimeOut) {
            [strongSelf sendMediaMessage:messageBody];
        }
    }];
    
    _recordInfoLabel.text = @"手指上划,取消发送";
    [self.view bringSubviewToFront:_amplitudeImageView];
}

#pragma mark - 按钮外抬起操作,只是停止,并没有发送语音
-(void)recordButtonTouchUpOutside {
    NSLog(@"\r\n\r\n\t>>>>>>>>TouchUpOutside : 将要调用 stopVoiceRecording");
    
    
    __weak __typeof(self)weakSelf = self;
    [[ECDevice sharedInstance].messageManager stopVoiceRecording:^(ECError *error, ECVoiceMessageBody *messageBody) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        NSLog(@"\r\n\r\n\t>>>>>>>>TouchUpOutside :  进入回调 stopVoiceRecording");
        [strongSelf.view sendSubviewToBack:strongSelf.amplitudeImageView];
    }];
}

//按钮内抬起操作
-(void)recordButtonTouchUpInside {
    
    NSLog(@"\r\n\r\n\t>>>>>>>>TouchUp Inside : 将要调用 stopVoiceRecording");
    
    __weak __typeof(self)weakSelf = self;
    [[ECDevice sharedInstance].messageManager stopVoiceRecording:^(ECError *error, ECVoiceMessageBody *messageBody) {
        if (weakSelf == nil) {
            return ;
        }
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.view sendSubviewToBack:strongSelf.amplitudeImageView];
        if (error.errorCode == ECErrorType_NoError) {
            

            
            [strongSelf sendMediaMessage:messageBody];
        } else if  (error.errorCode == ECErrorType_RecordTimeTooShort) {
            MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:strongSelf.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.userInteractionEnabled = NO;
            hud.labelText = @"录音时间过短";
            hud.margin = 10.f;
            hud.removeFromSuperViewOnHide = YES;
            [hud hide:YES afterDelay:2];
        }
    }];
}

//手指划出按钮
-(void)recordDragOutside {
    _recordInfoLabel.text = @"松开手指,取消发送";
}

//手指划入按钮
-(void)recordDragInside {
    _recordInfoLabel.text = @"手指上划,取消发送";
}

-(void)recordingAmplitude:(NSNotification*)notification {
    
    double amplitude = ((NSNumber*)notification.object).doubleValue;
    if (amplitude<0.14) {
        _amplitudeImageView.image = [UIImage imageNamed:@"press_speak_icon_07"];
    } else if (0.14<= amplitude <0.28) {
        _amplitudeImageView.image = [UIImage imageNamed:@"press_speak_icon_06"];
    } else if (0.28<= amplitude <0.42) {
        _amplitudeImageView.image = [UIImage imageNamed:@"press_speak_icon_05"];
    } else if (0.42<= amplitude <0.57) {
        _amplitudeImageView.image = [UIImage imageNamed:@"press_speak_icon_04"];
    } else if (0.57<= amplitude <0.71) {
        _amplitudeImageView.image = [UIImage imageNamed:@"press_speak_icon_03"];
    } else if (0.71<= amplitude <0.85) {
        _amplitudeImageView.image = [UIImage imageNamed:@"press_speak_icon_02"];
    } else if (0.85<= amplitude) {
        _amplitudeImageView.image = [UIImage imageNamed:@"press_speak_icon_01"];
    }
}

#pragma mark - moreview 动作
/**
 *@brief 音频通话按钮
 */
- (void)voiceCallBtnTap:(id)sender {

    [self endOperation];
    
    // 弹出VoIP音频界面
    VoipCallController * VVC = [[VoipCallController alloc] initWithCallerName:_titleLabel.text andCallerNo:self.sessionId andVoipNo:self.sessionId andCallType:1];
    [self presentViewController:VVC animated:YES completion:nil];
}

/**
 *@brief 视频通话按钮
 */
-(void)videoCallBtnTap:(id)sender {
    
    [self endOperation];
    
   // 弹出视频界面
    [[ECDevice sharedInstance].VoIPManager enableLoudsSpeaker:YES];
    VideoViewController * vvc = [[VideoViewController alloc]initWithCallerName:_titleLabel.text andVoipNo:self.sessionId andCallstatus:0];
    [self presentViewController:vvc animated:YES completion:nil];
}

/**
 *@brief 视频按钮
 */
-(void)videoBtnTap:(id)sender {
    
    [self endOperation];
    // 弹出视频窗口
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypeCamera)]) {
        
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        UIAlertView *alterView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"设备不支持摄像头" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alterView show];
    }
    imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
    
    imagePicker.videoMaximumDuration = 30;
    
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

/**
 *@brief 图片按钮
 */
-(void)pictureBtnTap:(id)sender {
    _isReadDeleteMessage = NO;
    // 弹出照片选择
    [self popTypeOfImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)popTypeOfImagePicker:(UIImagePickerControllerSourceType)sourceType {
    
    [self endOperation];
    
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = sourceType;
    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

/**
 *@brief 照相按钮
 */
-(void)cameraBtnTap:(id)sender {
    _isReadDeleteMessage = NO;
    [self endOperation];
    
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;

#if 0
    //只照相
    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
#else
    //支持视频功能
    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage,(NSString *)kUTTypeMovie];
    imagePicker.videoMaximumDuration = 30;
#endif
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        //判断相机是否能够使用
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if(status == AVAuthorizationStatusAuthorized) {
            // authorized
             [self presentViewController:imagePicker animated:YES completion:NULL];
        } else if(status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied){
            // restricted
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在“设置-隐私-相机”选项中允许访问你的相机" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
            });
        } else if(status == AVAuthorizationStatusNotDetermined){
            // not determined
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if(granted){
                     [self presentViewController:imagePicker animated:YES completion:NULL];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在“设置-隐私-相机”选项中允许访问你的相机" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    }
}

-(void)snapFireBtnTap:(id)sender {
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照",@"从相册中选取", nil];
    sheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        _isReadDeleteMessage = YES;

        NSString* button = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([button isEqualToString:@"拍照"]) {
            [self popTypeOfImagePicker:UIImagePickerControllerSourceTypeCamera];
        } else if ([button isEqualToString:@"从相册中选取"]) {
            [self popTypeOfImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
        }
    }
}

#pragma mark - 发送消息操作

/**
 *@brief 发送媒体类型消息
 */
-(void)sendMediaMessage:(ECFileMessageBody*)mediaBody {
    NSLog(@"\r\n\r\n------->:sendMediaMessage");
    
    ECMessage *message = [[ECMessage alloc] init];
    
    
   
    
    
    // 是不是阅后即焚
    if (_isReadDeleteMessage) {
        message = [[DeviceChatHelper sharedInstance] sendMediaMessage:mediaBody to:self.sessionId withUserData:@"fireMessage"];
    } else {
        message = [[DeviceChatHelper sharedInstance] sendMediaMessage:mediaBody to:self.sessionId];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_onMesssageChanged object:message];
}

/**
 *@brief 发送文本消息
 */
-(void)sendTextMessage {

    NSString * textString = [_inputTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (textString.length == 0) {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:nil message:@"不能发送空白消息" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    ECMessage* message = [[DeviceChatHelper sharedInstance] sendTextMessage:textString to:self.sessionId];
    [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_onMesssageChanged object:message];
}

/**
 *@brief 发送成功，消息状态更新
 */
-(void)sendMessageCompletion:(NSNotification*)notification {
    
    ECMessage* message = notification.userInfo[KMessageKey];
    __weak  __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if ([strongSelf.sessionId isEqualToString:message.sessionId]) {
            for (int i=strongSelf.messageArray.count-1; i>=0 ; i--) {
                id content = [strongSelf.messageArray objectAtIndex:i];
                if ([content isKindOfClass:[NSNull class]]) {
                    continue;
                }
                ECMessage *currMsg = (ECMessage *)content;
                if ([message.messageId isEqualToString:currMsg.messageId]) {
                    currMsg.messageState = message.messageState;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf.tableView beginUpdates];
                        [strongSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                        [strongSelf.tableView endUpdates];
                    });
                    break;
                }
            }
        }
    });
}

//下载媒体消息附件完成，状态更新
-(void)downloadMediaAttachFileCompletion:(NSNotification*)notification {
    
    NSLog(@"\r\n\r\n------->:收到通知:KNOTIFICATION_DownloadMessageCompletion,刷新表格");
    ECError *error = notification.userInfo[KErrorKey];
    if (error.errorCode != ECErrorType_NoError) {
        return;
    }
    
    ECMessage* message = notification.userInfo[KMessageKey];
    __weak  __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        if ([strongSelf.sessionId isEqualToString:message.sessionId]) {
            for (NSInteger i=strongSelf.messageArray.count-1; i>=0; i--) {
                id content = [strongSelf.messageArray objectAtIndex:i];
                if ([content isKindOfClass:[NSNull class]]) {
                    continue;
                }
                ECMessage *currMsg = (ECMessage *)content;
                if ([message.messageId isEqualToString:currMsg.messageId]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf.tableView beginUpdates];
                        NSLog(@"\r\n\r\n------->:更新数据源数组:messageArray");
                        [strongSelf.messageArray replaceObjectAtIndex:i withObject:message];
                        [strongSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                        [strongSelf.tableView endUpdates];
                    });
                    break;
                }
            }
        }
    });
}

-(void)ReceiveMessageDelete:(NSNotification*)notification {
    
    NSString *msgId = notification.userInfo[@"msgid"];
    NSString *sessionId = notification.userInfo[@"sessionid"];
    
    __weak  __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if ([strongSelf.sessionId isEqualToString:sessionId]) {
            for (NSInteger i=strongSelf.messageArray.count-1; i>=0; i--) {
                id content = [strongSelf.messageArray objectAtIndex:i];
                if ([content isKindOfClass:[NSNull class]]) {
                    continue;
                }
                ECMessage *currMsg = (ECMessage *)content;
                if ([msgId isEqualToString:currMsg.messageId]) {
                    ECFileMessageBody* body = (ECFileMessageBody*)currMsg.messageBody;
                    body.localPath = nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf.tableView beginUpdates];
                        [strongSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                        [strongSelf.tableView endUpdates];
                    });
                    break;
                }
            }
        }
    });
}

#pragma mark - 保存音视频文件
- (NSURL *)convertToMp4:(NSURL *)movUrl {
    
    NSURL *mp4Url = nil;
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:movUrl options:nil];

    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    if ([compatiblePresets containsObject:AVAssetExportPreset640x480]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset
                                                                              presetName:AVAssetExportPreset640x480];
        
        NSDateFormatter* formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyyMMddHHmmssSSS"];
        NSString* fileName = [NSString stringWithFormat:@"%@.mp4", [formater stringFromDate:[NSDate date]]];
        NSString* path = [NSString stringWithFormat:@"file:///private%@",[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName]];
        mp4Url = [NSURL URLWithString:path];
        
        exportSession.outputURL = mp4Url;
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputFileType = AVFileTypeMPEG4;
        dispatch_semaphore_t wait = dispatch_semaphore_create(0l);
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed: {
                    NSLog(@"failed, error:%@.", exportSession.error);
                } break;
                case AVAssetExportSessionStatusCancelled: {
                    NSLog(@"cancelled.");
                } break;
                case AVAssetExportSessionStatusCompleted: {
                    NSLog(@"completed.");
                } break;
                default: {
                    NSLog(@"others.");
                } break;
            }
            dispatch_semaphore_signal(wait);
        }];
        
        long timeout = dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER);
        if (timeout) {
            NSLog(@"timeout.");
        }
        
        if (wait) {
            wait = nil;
        }
    }
    
    return mp4Url;
}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform     // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,CGImageGetBitsPerComponent(aImage.CGImage), 0,CGImageGetColorSpace(aImage.CGImage),CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
        default:              CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);              break;
    }       // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

#define DefaultThumImageHigth 90.0f
#define DefaultPressImageHigth 960.0f

-(void)saveGifToDocument:(NSURL *)srcUrl {
    
    ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *asset) {
        
        if (asset != nil) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            Byte *imageBuffer = (Byte*)malloc((unsigned long)rep.size);
            NSUInteger bufferSize = [rep getBytes:imageBuffer fromOffset:0.0 length:(unsigned long)rep.size error:nil];
            NSData *imageData = [NSData dataWithBytesNoCopy:imageBuffer length:bufferSize freeWhenDone:YES];
            
            NSDateFormatter* formater = [[NSDateFormatter alloc] init];
            [formater setDateFormat:@"yyyyMMddHHmmssSSS"];
            NSString* fileName =[NSString stringWithFormat:@"%@.gif", [formater stringFromDate:[NSDate date]]];
            NSString* filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];

            [imageData writeToFile:filePath atomically:YES];
            
            ECImageMessageBody *mediaBody = [[ECImageMessageBody alloc] initWithFile:filePath displayName:filePath.lastPathComponent];
            [self sendMediaMessage:mediaBody];
        } else {
        }
    };
    
    ALAssetsLibrary* assetLibrary = [[ALAssetsLibrary alloc] init];
    [assetLibrary assetForURL:srcUrl
                  resultBlock:resultBlock
                 failureBlock:^(NSError *error){
                 }];
}

-(NSString*)saveToDocument:(UIImage*)image {
    UIImage* fixImage = [self fixOrientation:image];
    
    NSDateFormatter* formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyyMMddHHmmssSSS"];
    NSString* fileName =[NSString stringWithFormat:@"%@.jpg", [formater stringFromDate:[NSDate date]]];
    
    NSString* filePath=[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];
    
    //图片按0.5的质量压缩－》转换为NSData
    CGSize pressSize = CGSizeMake((DefaultPressImageHigth/fixImage.size.height) * fixImage.size.width, DefaultPressImageHigth);
    UIImage * pressImage = [CommonTools compressImage:fixImage withSize:pressSize];
    NSData *imageData = UIImageJPEGRepresentation(pressImage, 0.5);
    [imageData writeToFile:filePath atomically:YES];
    
    CGSize thumsize = CGSizeMake((DefaultThumImageHigth/fixImage.size.height) * fixImage.size.width, DefaultThumImageHigth);
    UIImage * thumImage = [CommonTools compressImage:fixImage withSize:thumsize];
    NSData * photo = UIImageJPEGRepresentation(thumImage, 0.5);
    NSString * thumfilePath = [NSString stringWithFormat:@"%@.jpg_thum", filePath];
    [photo writeToFile:thumfilePath atomically:YES];

    return filePath;
    
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        [picker dismissViewControllerAnimated:YES completion:nil];

        // we will convert it to mp4 format
        NSURL *mp4 = [self convertToMp4:videoURL];
        NSFileManager *fileman = [NSFileManager defaultManager];
        if ([fileman fileExistsAtPath:videoURL.path]) {
            NSError *error = nil;
            [fileman removeItemAtURL:videoURL error:&error];
            if (error) {
                NSLog(@"failed to remove file, error:%@.", error);
            }
        }
        
        NSString *mp4Path = [mp4 relativePath];
        ECVideoMessageBody *mediaBody = [[ECVideoMessageBody alloc] initWithFile:mp4Path displayName:mp4Path.lastPathComponent];
        [self sendMediaMessage:mediaBody];
        
    } else {
        UIImage *orgImage = info[UIImagePickerControllerOriginalImage];
        [picker dismissViewControllerAnimated:YES completion:nil];
        
        NSURL *imageURL = [info valueForKey:UIImagePickerControllerReferenceURL];
        NSString* ext = imageURL.pathExtension.lowercaseString;

        if ([ext isEqualToString:@"gif"]) {
            [self saveGifToDocument:imageURL];
        } else {
            NSString *imagePath = [self saveToDocument:orgImage];
            ECImageMessageBody *mediaBody = [[ECImageMessageBody alloc] initWithFile:imagePath displayName:imagePath.lastPathComponent];
            [self sendMediaMessage:mediaBody];
        }
    }
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

}

#pragma mark - HPGrowingTextViewDelegate

//根据新的高度来改变当前的页面的的布局
- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height {
    
    __weak __typeof(self)weakSelf = self;
    float diff = (growingTextView.frame.size.height - height);
    void(^animations)() = ^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf) {
            CGRect r = _containerView.frame;
            r.size.height -= diff;
            r.origin.y += diff;
            _containerView.frame = r;
            CGRect tableFrame = strongSelf.tableView.frame;
            tableFrame.size.height += diff;
            strongSelf.tableView.frame = tableFrame;
        }
    };
    
    void(^completion)(BOOL) = ^(BOOL finished){
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf && strongSelf.messageArray.count>0){
            [strongSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:strongSelf.messageArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    };

    [UIView animateWithDuration:0.1 delay:0.0f options:(UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:completion];
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    
    if ([text isEqualToString:@"\n"]){ //判断输入的字是否是回车，即按下return
        //在这里做你响应return键的代码
        [self sendTextMessage];
        growingTextView.text = @"";
        return NO; //这里返回NO，就代表return键值失效，即页面上按下return，不会出现换行，如果为yes，则输入页面会换行
    }
    
    if ([self.sessionId hasPrefix:@"g"] && [text myContainsString:@"@"]) {
        isOpenMembersList = YES;
        GroupMembersViewController *membersList = [[GroupMembersViewController alloc] init];
        membersList.groupID = self.sessionId;
        arrowLocation = range.location+1;
        dispatch_after(0.1, dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:membersList animated:YES];
        });
    }
    
    if (range.length == 1) {
        return YES;
    }
    return YES;
}

//获取焦点
- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView {
    [_menuController setMenuItems:nil];
    _inputMaskImage.image = [[UIImage imageNamed:@"input_box_on"] stretchableImageWithLeftCapWidth:95.0f topCapHeight:16.0f];
    if ([self.sessionId hasPrefix:@"g"] && [_inputTextView.text myContainsString:@"@"] && isOpenMembersList && _GroupMemberNickName.length>0) {
        isOpenMembersList = NO;
        NSMutableString * string = [NSMutableString stringWithFormat:@"%@",_inputTextView.text];
        [string insertString:[NSString stringWithFormat:@"%@ ",_GroupMemberNickName] atIndex:arrowLocation];
        
        _inputTextView.text = [NSString stringWithFormat:@"%@",string];
        _GroupMemberNickName = nil;
    }

}

//失去焦点
- (void)growingTextViewDidEndEditing:(HPGrowingTextView *)growingTextView {
    _inputMaskImage.image = [[UIImage imageNamed:@"input_box"] stretchableImageWithLeftCapWidth:95.0f topCapHeight:16.0f];
}

@end
