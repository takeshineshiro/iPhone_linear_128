//
//  ViewController.m
//  WirelessScan
//
//  Created by Gan Sweet on 14-10-20.
//  Copyright (c) 2014年 SweetGan. All rights reserved.
//

#import "ViewController.h"
#import "TransSocket.h"
//#import "WLBScanDesktopDlg.h"
#import <sqlite3.h>
#import "myView.h"
#import <QuartzCore/QuartzCore.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "CustomSlider.h"
#import "CustomImagePickerViewController.h"
#import "DSCor.h"
#import "RawImag.h"
#import <sys/utsname.h>


@interface ViewController (){
    
    NSString*   m_strSSID;      //  SSID字符串
    BOOL m_bSSIDValid;          //  获取的SSID为探头的SSID
    BOOL m_bConnected;          //  套接字是否连接（三个套接字均已连接时为YES）
    BOOL m_bLeftHand;           //  左右手状态
    BOOL m_bRunning;            //  探头是否在运行中
    int m_nSndRunning;          //  需要发送的运行状态 (-1: 无需要发送状态， 0：冻结状态， 1:运行状态）
    int m_nSndRunningCnt;       //  发送状态的等待计数
    
    BOOL m_bHaveImage;          //  图像区是否有图像
    BOOL m_bLoadedImage;        //  有图像的情况下也分为两种情况，一种是载入的图像，一种是重建的图像（回复或者在运行中）
    BOOL m_bInCineLoop;         //  是否处于回放状态中
    BOOL m_bInFullScreen;       //  是否处于全屏状态
    float m_fGama;              //  图像的gama校正
    BOOL m_bSRIEnable;          //  散斑抑制使能
    
    //
    //  探头相关信息
    //
    NSInteger   m_nProbeType;   //  探头类型信息
    unsigned char  m_ucGain;    //  探头当前的增益
    unsigned char  m_ucZoom;    //  探头当前的缩放
    unsigned char  m_ucSndGain; //  需要下发的增益
    unsigned char  m_ucSndZoom; //  需要下发的缩放
    int m_nWifiChannel;     //  探头当前使用的通道
    int m_nSalesCode;       //  探头的销售区域代码
    
    //  无线连接套接字
    AsyncSocket* asyncSocket;
    AsyncSocket* asyncSocketStateControl;
    AsyncSocket* asyncSocketReceiveState;
    BOOL m_bDataSocketConnected;
    BOOL m_bStatSocketConnected;
    BOOL m_bCtrlSocketConnected;
    
    //  回放图像数据列表
    NSMutableArray* m_imgArray;
    
    
    //
    //  自动锁屏定时器
    //
    //      软件 willAppear 时禁止自动锁屏，当连续15分钟没有操作后则允许
    //  自动锁屏。
    //
    NSTimer* autoLockTimer;     //  自动锁屏定时器
    
    //
    //  空白图像
    //
    RawImag* nullImage;
    NSTimer* nullImgTimer;
    
    //
    //  灰度条图像
    //
    UIImage* gradientImage;
    
    //
    //  提示信息
    //
    UILabel* labelNote;
    
    CTransSocket *ts;
    NSMutableData* imgData;
    //CWLBScanDesktopDlg *wbScan;
    NSUserDefaults* ud;
    
    
    
    
    
    NSInteger imagIndex;
    NSTimer* playTimer;
    sqlite3* db ;
    NSMutableArray* testArr;
    UILabel* labelProbe;
    UILabel* labelDepth;
    UILabel* labelGain;
    UILabel* labelFrozen;
    UILabel* labelTime;
    
    myView* mpView;
    UILabel* labelConnect;
    NSTimer* connectTimer;
    
    
    
    
    //BOOL isConnect;
    UISlider* bottomSlider;
    UISlider* sideSlider;
    //BOOL isCinelooping;
    //NSInteger probeType;
    CGRect normalFrame;
    
    UIButton* fullScrenButton;
    NSTimer*  fsbHiddenTimer;
    
    
    UIPickerView* pickerChannel;
    NSArray* channelList;
    
    NSInteger selectIndex;
    UIView* temView;
    NSString *newDateStr;
    
    
    UITextField* gamaTF;
}
@property (weak, nonatomic) IBOutlet UIImageView *imgLogo;
@property (weak, nonatomic) IBOutlet UIButton *btnSet;
@property (weak, nonatomic) IBOutlet UIImageView *lableLine;
@property (nonatomic) BOOL isFisrtInit;
//@property (nonatomic) BOOL bHaveImage;

@end

@implementation ViewController
@synthesize library;
@synthesize imagePicker;
@synthesize slider;
@synthesize playButton;
@synthesize btnPre;
@synthesize btnNext;
@synthesize isFisrtInit;

@synthesize belowImageView;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"deviceVersion=%@",[self getDeviceVersion]);
    
    //  配置参数
    ud = [NSUserDefaults standardUserDefaults];
    
    //  全局状态初始化
    m_strSSID = @"";
    m_bSSIDValid = NO;
    m_bConnected = NO;
    m_bLeftHand = NO;
    m_bRunning = NO;
    m_nSndRunning = -1; //  无需发送状态
    m_bHaveImage = NO;
    m_bLoadedImage = NO;
    m_bInCineLoop = NO;
    m_bInFullScreen = NO;
    m_bLeftHand = [ud boolForKey:@"leftHand"];
    m_fGama = 1.3;
    m_bSRIEnable = false;
    NSString* devstr = [self getDeviceVersion];
    if ( [devstr hasPrefix:@"iPad5,"]) {
        m_bSRIEnable = true;
    }
    
    
    //  探头状态初始化
    m_nProbeType = [ud integerForKey:@"probeType"];
    m_ucSndGain = [ud integerForKey:@"Gain"];
    if (m_ucSndGain > 127)
        m_ucSndGain = 127;
    m_ucSndZoom = [ud integerForKey:@"Zoom"];
    if (m_ucSndZoom > 3)
        m_ucSndZoom = 3;
    m_ucGain = m_ucSndGain;
    m_ucZoom = m_ucSndZoom;
    
    //  初始化空白图像
    nullImage = [[RawImag alloc]init];
    nullImage.probeType = m_nProbeType;
    nullImage.zoom = m_ucSndZoom;
    nullImage.gain = m_ucSndGain;
    nullImage.rawData = nil;
    //nullImage.time = newDateStr;
    
    
    //  无线连接状态
    m_bDataSocketConnected = NO;
    m_bCtrlSocketConnected = NO;
    m_bStatSocketConnected = NO;
    
    //  初始化渐变条
    gradientImage = [self InitGradientImage];
    
    
    //初始化回放数据
    imgData = [[NSMutableData alloc]init];
    
    ts = new CTransSocket();
    
    //  创建Wifi SSID
    {
        labelConnect = [[UILabel alloc]initWithFrame:CGRectMake(28, 5, 180, 15)];
        labelConnect.backgroundColor = [UIColor clearColor];
        labelConnect.textColor = [UIColor whiteColor];
        labelConnect.text = m_strSSID;
        labelConnect.font = [UIFont systemFontOfSize:12];
        [self.view addSubview:labelConnect];
    }
    
    //
    // 创建图像区
    //
    {
        self.scanImg.frame = CGRectMake(self.scanImg.frame.origin.x, self.scanImg.frame.origin.y, 700,400);
        // 创建黑色背景底图
        CGSize  size = self.scanImg.frame.size;
        UIGraphicsBeginImageContextWithOptions(size,YES,0);
        UIImage *resultImage=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        belowImageView = [[UIImageView alloc]initWithImage:resultImage];
        belowImageView.tag = 1000;
        belowImageView.frame = CGRectMake(0,0,self.scanImg.frame.size.width,self.scanImg.frame.size.height);
        //增加边框
        belowImageView.layer.borderWidth = 1 ;
        belowImageView.layer.borderColor = [UIColor grayColor].CGColor;
        
        //  创建元素
        labelTime = [[UILabel alloc]initWithFrame:CGRectMake(10, 1, 160 , 20)];
        labelTime.text = newDateStr;
        labelTime.backgroundColor = [UIColor clearColor];
        labelTime.textColor = [UIColor whiteColor];
        labelTime.font = [UIFont systemFontOfSize:12];
        [belowImageView addSubview:labelTime];
        
        NSInteger labelW = self.scanImg.frame.size.width/2;
        
        labelDepth = [[UILabel alloc]initWithFrame:CGRectMake(10, 18, labelW, 20)];
        labelDepth.backgroundColor = [UIColor clearColor];
        labelDepth.textColor = [UIColor whiteColor];
        labelDepth.font = [UIFont systemFontOfSize:12];
        [belowImageView addSubview:labelDepth];
        
        labelGain = [[UILabel alloc]initWithFrame:CGRectMake(10, 35, labelW, 20)];
        labelGain.backgroundColor = [UIColor clearColor];
        labelGain.textColor = [UIColor whiteColor];
        labelGain.font = [UIFont systemFontOfSize:12];
        [belowImageView addSubview:labelGain];
        
        labelFrozen = [[UILabel alloc]initWithFrame:CGRectMake(16, self.scanImg.frame.size.height-40, labelW, 20)];
        labelFrozen.backgroundColor = [UIColor clearColor];
        labelFrozen.textColor = [UIColor whiteColor];
        labelFrozen.font = [UIFont systemFontOfSize:12];
        [belowImageView addSubview:labelFrozen];
        
        fullScrenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        fullScrenButton.frame = CGRectMake(self.scanImg.frame.size.width-70, self.scanImg.frame.size.height-60, 60, 60);
        [fullScrenButton setImage:[UIImage imageNamed:@"放大按钮.png"] forState:UIControlStateNormal];
        [fullScrenButton addTarget:self action:@selector(clickFullScreen:) forControlEvents:UIControlEventTouchUpInside];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapInImageV:)];
        [self.scanImg addGestureRecognizer:tap];
        [self.scanImg addSubview:fullScrenButton];
        
        //  提示信息条
        labelNote = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
        
        //labelNote.center = //self.scanImg.center;
        
        labelNote.center = CGPointMake(self.scanImg.center.x, self.scanImg.center.y/2);
        
        labelNote.font = [UIFont systemFontOfSize:25];
        labelNote.textColor = [UIColor blueColor];
        [self.scanImg addSubview:labelNote];
        
        /*
         UILabel* label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
         label.center = self.scanImg.center;
         label.text = errMsg;
         [self.scanImg addSubview:label];
         label.textColor = [UIColor blueColor];
         label.font = [UIFont systemFontOfSize:25];
         [UIView animateWithDuration:1 animations:^{
         label.alpha = 0;
         }];
         */
        
        //上下扫手势
        
        UISwipeGestureRecognizer* swipe1 = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeTheImageView:)];
        [swipe1 setDirection:UISwipeGestureRecognizerDirectionDown];
        [self.scanImg addGestureRecognizer:swipe1];
        UISwipeGestureRecognizer* swipe2 = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeTheImageView:)];
        [swipe2 setDirection:UISwipeGestureRecognizerDirectionUp];
        [self.scanImg addGestureRecognizer:swipe2];
        
        //左右扫手势
        UISwipeGestureRecognizer* swipe3 = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeTheImageView:)];
        [swipe3 setDirection:UISwipeGestureRecognizerDirectionLeft];
        [self.scanImg addGestureRecognizer:swipe3];
        
        UISwipeGestureRecognizer* swipe4 = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeTheImageView:)];
        [swipe4 setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.scanImg addGestureRecognizer:swipe4];
    }
    
    //
    //  创建 Sliders
    //
    //  回放进度条
    {
        self.slider.hidden = YES;
        bottomSlider = [[UISlider alloc]initWithFrame:slider.frame];
        [bottomSlider setThumbImage:[UIImage imageNamed:@"底部滑块_滑块.png"] forState:UIControlStateNormal];
        [bottomSlider setMinimumTrackImage:[UIImage imageNamed:@"底部滑块_进度条.png"] forState:UIControlStateNormal];
        bottomSlider.enabled = NO;
        [bottomSlider  setMaximumTrackImage:[UIImage imageNamed:@"底部滑块_凹槽.png" ] forState:UIControlStateNormal];
        [bottomSlider addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:bottomSlider];
    }
    //  增益进度条
    {
        sideSlider = [[CustomSlider alloc]initWithFrame:CGRectMake(770, self.view.frame.size.height/2+100, 379, 20)];
        [sideSlider setMinimumTrackImage:[UIImage imageNamed:@"右侧滑块_进度条.png"] forState:UIControlStateNormal];
        [sideSlider  setMaximumTrackImage:[UIImage imageNamed:@"底部滑块_凹槽.png" ] forState:UIControlStateNormal];
        [sideSlider setThumbImage:[UIImage imageNamed:@"右侧滑块_滑块.png"] forState:UIControlStateNormal];
        sideSlider.enabled = NO;
        float degree = -90 * M_PI / 180.0;
        sideSlider.transform = CGAffineTransformMakeRotation(CGFloat(degree));
        [sideSlider addTarget:self action:@selector(slidingSideBoard:) forControlEvents:UIControlEventValueChanged];
        sideSlider.maximumValue = 127;
        sideSlider.value = [ud integerForKey:@"Gain"];
        [self.view addSubview:sideSlider];
    }
    
    
    //  创建 通道picker
    m_nWifiChannel = -2;
    channelList = @[@"CHANNEL  1",@"CHANNEL  2",@"CHANNEL  3",@"CHANNEL  4",@"CHANNEL  5",@"CHANNEL  6",@"CHANNEL  7",@"CHANNEL  8",@"CHANNEL  9",@"CHANNEL  10",@"CHANNEL  11",@"CHANNEL  12",@"CHANNEL  13"];
    
    
    
    //
    //  去除界面的上边缘
    //
    //self.edgesForExtendedLayout = UIRectEdgeNone;
    
    
    // Do any additional setup after loading the view, typically from a nib.
    testArr = [NSMutableArray array];
    
    
    
    //
    //  创建相册的Picker
    //
    library = [[ALAssetsLibrary alloc]init];
    imagePicker = [[CustomImagePickerViewController alloc]init];
    
    
    //
    //  创建回放图像列表
    //
    m_imgArray = [NSMutableArray array];
    
    //
    //  监听冻结事件
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEnterBackground) name:@"didEnterBackground" object:nil];
    
    
    //  初始化按钮状态
    [self adjustItemStatus];
    
    //  初始化增益slider
    sideSlider.value = m_ucSndGain;
    
    //[UIApplication sharedApplication].idleTimerDisabled = false;
    
    NSLog(@"model=%@",[[UIDevice currentDevice]model]);
    NSString *strLocModel = [[UIDevice currentDevice] localizedModel];
    NSLog(@"本地设备模式：%@", strLocModel);// localized version of model
}




-(IBAction)tapWifi{
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    if (m_bInCineLoop) {
        m_bInCineLoop = NO;
        [playTimer invalidate];
        [playButton setImage:[UIImage imageNamed:@"btn_播放_nor.png"] forState:UIControlStateNormal];
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (id)fetchSSIDInfo {
    
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    
    NSString* ssid = @"";
    for (NSString *ifnam in ifs) {
        id  info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        
        ssid = [info objectForKey:@"SSID"];
        
        if (ssid) { break; }
        
    }
    return ssid;
}


-(void)fullScreenHiden{
    
    [fsbHiddenTimer invalidate];
    fullScrenButton.hidden = YES;
}

//数据库操作
-(void)dataBaseHandle{
    
    // NSString* path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"modelData.db"];
    NSString * srcPath = [[NSBundle mainBundle] pathForResource:@"modelData" ofType:@"db"];
    NSLog(@"%@",srcPath);
    if (sqlite3_open([srcPath UTF8String], &db)!=SQLITE_OK) {
        sqlite3_close(db);
        
        NSLog(@"打开数据库失败！");
        
    }else{
        //        //创建表
        //        NSString *sqlCreateTable =@"CREATE TABLE IF NOT EXISTS modelData (ID INTEGER PRIMARY KEY AUTOINCREMENT, data BLOB)";
        //        [self execSql:sqlCreateTable];
        //
        //        //插入数据
        //        for (NSData* data in m_imgArray) {
        //            NSString *insertSql1= [NSString stringWithFormat:
        //                                   @"INSERT INTO 'modelData' ('data') VALUES ('%@')",data];
        //            [self execSql:insertSql1];
        //
        //        }
        //查询数据
        NSString *sqlQuery = @"SELECT data FROM modelData";
        
        sqlite3_stmt * statement;
        
        if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            
            while (sqlite3_step(statement) == SQLITE_ROW) {
                
                int ss = sqlite3_column_bytes(statement, 0);
                
                Byte *bt = (Byte*)sqlite3_column_blob(statement, 0);
                
                NSData* dt = [NSData dataWithBytes:bt length:ss];
                [testArr addObject:dt];
                // NSLog(@"data=%lu",(unsigned long)dt.length);
                
            }
            
        }else{
            
            NSLog(@"查询失败！");
            
            
        }
        sqlite3_finalize(statement);
        
    }
    if (testArr) {
        m_imgArray = testArr;
        
    }
    sqlite3_close(db);
}

//执行语句
-(void)execSql:(NSString *)sql
{
    
    char *err;
    if (sqlite3_exec(db, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        
        sqlite3_close(db);
        NSLog(@"数据库操作数据失败!,%s",err);
    }else{
        NSLog(@"数据库操作数据成功!");
        
    }
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    NSLog(@"IN viewWillAppear");
    
    if (!m_bHaveImage) {
        [self nullImageRefresh];
        //  启动定时器
        nullImgTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(nullImageRefresh) userInfo:nil repeats:YES];
    }
    
    //发送链接服务器的命令
    connectTimer =  [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendConnectCommand) userInfo:nil repeats:YES];
    
    //
    //  全屏按钮隐藏定时器
    //
    fsbHiddenTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(fullScreenHiden) userInfo:nil repeats:NO];
    
    //  切换左右手的显示
    [self repositionByHand];
    
    //
    //  禁止自动锁屏的启始时间
    //
    autoLockTimer = nil;
    [self disableAutoLock];
    
    //  调节界面显示状态
    [self adjustItemStatus];
    
}


//扫屏手势响应
-(void)swipeTheImageView:(UISwipeGestureRecognizer*)swipe{
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    if (m_bRunning) {   //  运行中，上下扫手势调节ZOOM
        if ( UISwipeGestureRecognizerDirectionDown == swipe.direction) {
            if (m_ucSndZoom > 0) {
                m_ucSndZoom--;
            }
        }else if ( UISwipeGestureRecognizerDirectionUp == swipe.direction){
            m_ucSndZoom++;
        }
        
        if (m_ucSndZoom<0) {
            m_ucSndZoom = 0;
        }else if (m_ucSndZoom>3){
            m_ucSndZoom = 3;
        }
        
        [self sendParamZoom:m_ucSndZoom Gain:m_ucSndGain Runing:YES];
        [ud setInteger:m_ucSndZoom forKey:@"Zoom"];
    }
    else if (!m_bLoadedImage){  //  冻结后，左右扫手势回放图像
        
        if (m_imgArray.count >0) {
            if (UISwipeGestureRecognizerDirectionLeft == swipe.direction) {
                [self pre: btnPre];
            } else if (UISwipeGestureRecognizerDirectionRight == swipe.direction) {
                [self next:btnNext];
            }
        }
        
    }
}


-(void)tapInImageV:(UITapGestureRecognizer*)tap{
    
    if (fullScrenButton.hidden == YES) {
        fullScrenButton.hidden = NO;
    } else {
        if (fsbHiddenTimer != nil) {
            [fsbHiddenTimer invalidate];
        }
    }
    //  全屏按钮隐藏定时器
    fsbHiddenTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(fullScreenHiden) userInfo:nil repeats:NO];
}

-(void)clickFullScreen:(UIButton*)btn{
    
    if (fsbHiddenTimer != nil) {
        [fsbHiddenTimer invalidate];
        fsbHiddenTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(fullScreenHiden) userInfo:nil repeats:NO];
    }
    
    NSInteger labelW = self.scanImg.frame.size.width/2;
    if (btn.tag == 0) {
        btn.tag = 1;
        normalFrame = self.scanImg.frame;
        self.scanImg.frame = self.view.frame;
        belowImageView.frame = CGRectMake(0,0,self.scanImg.frame.size.width,self.scanImg.frame.size.height);
        self.scanImg.backgroundColor = [UIColor blackColor];
        [btn setImage:[UIImage imageNamed:@"缩小按钮.png"] forState:UIControlStateNormal];
        fullScrenButton.frame = CGRectMake(self.scanImg.frame.size.width-70, self.scanImg.frame.size.height-60, 60, 60);
        labelConnect.hidden = YES;
        sideSlider.hidden = YES;
        bottomSlider.hidden = YES;
        labelFrozen.frame = CGRectMake(26, self.scanImg.frame.size.height-40, labelW, 20);
    }else{
        
        btn.tag = 0;
        self.scanImg.frame = normalFrame;
        //belowImageView.frame = normalFrame;
        belowImageView.frame = CGRectMake(0,0,self.scanImg.frame.size.width,self.scanImg.frame.size.height);
        
        self.scanImg.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"放大按钮.png"] forState:UIControlStateNormal];
        fullScrenButton.frame = CGRectMake(self.scanImg.frame.size.width-70, self.scanImg.frame.size.height-60, 60, 60);
        bottomSlider.hidden = NO;
        sideSlider.hidden = NO;
        labelConnect.hidden = NO;
        labelFrozen.frame = CGRectMake(26, self.scanImg.frame.size.height-40, labelW, 20);
        
    }
    
    
}


-(void)slidingSideBoard:(UISlider*)sli{
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    m_ucSndGain = sli.value;
    
    if (m_ucSndGain > 127){
        m_ucSndGain = 127;
    }
    else if (m_ucSndGain<0){
        m_ucSndGain = 0;
    }
    [self sendParamZoom:m_ucSndZoom Gain:m_ucSndGain Runing:m_bRunning];
    
    
    [ud setInteger:m_ucSndGain forKey:@"Gain"];
    [ud synchronize];
    
}

-(void)onEnterBackground{
    
    //
    //  如果在运行状态中推到后台，则发送冻结命令
    //
    if (m_bRunning) {
        [self clickFreezing:self.btnFrozen];
    }
    
    //
    //  如果在回放中退到后台，则停止回放
    //
    if (m_bInCineLoop) {
        [self playControl:self.playButton];
    }
}


//划块响应事件
-(void)sliderValueChange:(UISlider*)sli{
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    if (m_bInCineLoop) {
        [self playControl:self.playButton];
    }
    
    imagIndex = sli.value ;
    self.labelCount.text  = [NSString stringWithFormat:@"%ld/%ld",imagIndex+1,m_imgArray.count];
    
    if (imagIndex < m_imgArray.count) {
        RawImag* raw = [m_imgArray objectAtIndex:imagIndex];
        [self drawImage:raw runing:NO];
    }
}
//图片播放功能
-(IBAction)playControl:(UIButton*)btn{
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    if (m_bInCineLoop) {
        m_bInCineLoop = NO;
        [playTimer invalidate];
    }else {
        if (imagIndex>=m_imgArray.count-1) {
            imagIndex = 0;
        }
        m_bInCineLoop = YES;
        playTimer = [NSTimer scheduledTimerWithTimeInterval:0.1250 target:self selector:@selector(playImage) userInfo:nil repeats:YES];
    }
    [self adjustItemStatus];
}

//播放图片
-(void)playImage{
    if (m_imgArray.count>0) {
        RawImag* raw = [m_imgArray objectAtIndex:imagIndex];
        [self drawImage:raw runing:NO];
        imagIndex++;
    }
    
    if (imagIndex>=m_imgArray.count) {
        [self playControl:self.playButton]; //  停止回放
        
        imagIndex = 0;
        RawImag* raw = [m_imgArray objectAtIndex:imagIndex];
        [self drawImage:raw runing:NO];
        bottomSlider.value = 0;
    }
    self.labelCount.text = [NSString stringWithFormat:@"%ld/%ld",imagIndex,m_imgArray.count];
    bottomSlider.value = imagIndex;
    [self adjustItemStatus];
}

//下一张
-(IBAction)next:(UIButton*)btn{
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    if (m_bInCineLoop) {
        [self playControl:self.playButton]; //  停止回放
    }
    
    imagIndex++;
    if (imagIndex>=m_imgArray.count) {
        imagIndex = 0;
    }
    RawImag* raw = [m_imgArray objectAtIndex:imagIndex];
    [self drawImage:raw runing:NO];
    self.labelCount.text = [NSString stringWithFormat:@"%ld/%ld",imagIndex+1,m_imgArray.count];
    bottomSlider.value = imagIndex;
    
}
//上一张
-(IBAction)pre:(UIButton*)btn{
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    if (m_bInCineLoop) {
        [self playControl:self.playButton]; //  停止回放
    }
    
    if (imagIndex>0) {
        imagIndex--;
    }
    else {
        imagIndex = m_imgArray.count-1;
    }
    RawImag* raw = [m_imgArray objectAtIndex:imagIndex];
    [self drawImage:raw runing:NO];
    self.labelCount.text = [NSString stringWithFormat:@"%ld/%ld",imagIndex+1,m_imgArray.count];
    bottomSlider.value = imagIndex;
}


- (IBAction)clickFreezing:(UIButton*)btn {
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    if (m_bInCineLoop) {
        [self playControl:self.playButton]; //  停止回放
    }
    if (!m_bRunning) {
        // 复位到0
        imagIndex = 0;
        self.labelCount.text = [NSString stringWithFormat:@"0/%ld",m_imgArray.count];
        bottomSlider.value = imagIndex;
    }
    
    if (m_bRunning) {
        m_nSndRunning = 0;
        m_nSndRunningCnt = 0;
        [self sendParamZoom:m_ucSndZoom Gain:m_ucSndGain Runing:NO];
    } else {
        m_nSndRunning = 1;
        m_nSndRunningCnt = 0;
        [self sendParamZoom:m_ucSndZoom Gain:m_ucSndGain Runing:YES];
    }
    
}



- (IBAction)clickZoomLeft:(id)sender {
    
    if (m_ucZoom == 0){
        m_ucZoom = 0;
    }else
        m_ucZoom--;
    
    Byte* frozen = new Byte[4];
    frozen[0] = 0x5a;
    frozen[1] = 0xa5;
    frozen[2] = 0x00;
    if (m_bRunning) {
        frozen[2] |= 0x80;
    }
    frozen[2] |= m_ucZoom & 0x03;
    frozen[3] = 0x00;
    frozen[3] |= m_ucGain & 0x7F;
    NSData* data = [NSData dataWithBytes:frozen length:4];
    [asyncSocketStateControl writeData:data withTimeout:-1 tag:1];
    labelDepth.text = [NSString stringWithFormat:@"Depth: %dmm",90+m_ucZoom*30];
    
    
}
- (IBAction)clickZoomRight:(id)sender {
    
    
    m_ucZoom++;
    if (m_ucZoom > 3)
        m_ucZoom = 3;
    Byte* frozen = new Byte[4];
    frozen[0] = 0x5a;
    frozen[1] = 0xa5;
    frozen[2] = 0x00;
    if (m_bRunning) {
        frozen[2] |= 0x80;
    }
    frozen[2] |= m_ucZoom & 0x03;
    frozen[3] = 0x00;
    frozen[3] |= m_ucGain & 0x7F;
    NSData* data = [NSData dataWithBytes:frozen length:4];
    [asyncSocketStateControl writeData:data withTimeout:-1 tag:1];
    
    labelDepth.text = [NSString stringWithFormat:@"Depth: %dmm",90+m_ucZoom*30];
    
    
}

-(void) sendParamZoom:(unsigned char)zoom Gain:(unsigned char)gain Runing:(BOOL)running{
    
    
    Byte* frozen = new Byte[4];
    frozen[0] = 0x5a;
    frozen[1] = 0xa5;
    frozen[2] = 0x00;
    if (running) {
        frozen[2] |= 0x80;
    }
    frozen[2] |= zoom & 0x03;
    frozen[3] = 0x00;
    frozen[3] |= gain & 0x7F;
    NSData* data = [NSData dataWithBytes:frozen length:4];
    [asyncSocketStateControl writeData:data withTimeout:-1 tag:1];
    
}
-(void)selectChannel:(NSInteger)channel{
    
    if (channel>0&&channel<=13) {
        
        Byte* frozen = new Byte[4];
        frozen[0] = 0x5c;
        frozen[1] = 0xc5;
        frozen[2] = channel;
        frozen[3] = channel;
        NSData* data = [NSData dataWithBytes:frozen length:4];
        [asyncSocketStateControl writeData:data withTimeout:-1 tag:1];
    }
}
-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
    //NSLog(@"didwrite");
    
}

#pragma asyncsocketdelegate

-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    
    NSLog(@" did Connected port %ld",port);
    
    /*
     //  三个链接均成功时判断为探头链接有效。
     if (port == 5001) {
     m_bDataSocketConnected = YES;
     }
     if (port == 5002) {
     m_bStatSocketConnected = YES;
     }
     if (port == 5003) {
     m_bCtrlSocketConnected = YES;
     }
     
     if (!m_bDataSocketConnected || !m_bStatSocketConnected || !m_bCtrlSocketConnected) {
     return;
     }
     */
    
    
    
    m_bConnected = YES;
    [self adjustItemStatus];
    [self sendParamZoom:m_ucSndZoom Gain:m_ucSndGain Runing:m_bRunning];
    
    NSLog(@"syncSocket=%@,%d",host,port);
    
    if (port == 5002) {
        [sock readDataWithTimeout:-1 tag:2];
    }else if (port==5003){
        [sock readDataWithTimeout:-1 tag:3];
    }else {
        [sock readDataWithTimeout:-1 tag:0];
    }
}
-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    switch (tag) {
        case 2:
        {
            //  原始数据通道
            [imgData appendData:data];
            if (imgData.length > 512) {
                Byte* pStream = (Byte*)[data bytes];
                bool bSuc = ts->Package(pStream,data.length);   //  原始数据流打包操作
                if (bSuc && m_bRunning) {
                    NSData *pData = [NSData dataWithBytes: ts->m_pRawImg length: 256*512];
                    
                    if (m_nSndRunning == 0 ) {
                        m_nSndRunningCnt++;
                        if (m_nSndRunningCnt > 4) {
                            m_nSndRunning = -1;
                        }
                    }
                    
                    if( m_nSndRunning != 0) {
                        [self ShowImageToWindow: pData];    //  准备修改
                    }
                    
                    imgData = nil;
                    imgData = [NSMutableData data];
                }
            }
            [sock readDataWithTimeout:-1 tag:2];
        }
            break;
        case 3:
        {
            //  状态通道
            Byte* comond = (Byte*)[data bytes];
            if (comond[0]==0x5a&&
                comond[1]==0xa5) {
                unsigned char ucRunning = comond[2] & 0x80;
                unsigned char ucZoom = comond[2] & 0x03;
                unsigned char ucGain = comond[3] & 0x7F;
                
                if (m_nSndRunning>=0) {
                    if ( (ucRunning==0x80) && m_nSndRunning ) {
                        m_nSndRunning = -1;
                    }
                    else if ( (ucRunning != 0x80) && !m_nSndRunning) {
                        m_nSndRunning = -1;
                    }
                }
                
                
                if ( (ucRunning==0x80) != m_bRunning ) {
                    m_bRunning = !m_bRunning;
                    if (m_bRunning) {
                        if (m_bInCineLoop) {
                            [self playControl:self.playButton]; //  停止回放
                        }
                    }
                    else {
                        imagIndex = m_imgArray.count-1;
                        
                        self.labelCount.text = [NSString stringWithFormat:@"%ld/%ld",imagIndex+1,m_imgArray.count];
                        bottomSlider.maximumValue = imagIndex;
                        bottomSlider.value = imagIndex;
                        
                        
                        /*
                         imagIndex++;
                         if (imagIndex>=m_imgArray.count) {
                         imagIndex = 0;
                         }
                         RawImag* raw = [m_imgArray objectAtIndex:imagIndex];
                         [self drawImage:raw runing:NO];
                         self.labelCount.text = [NSString stringWithFormat:@"%ld/%ld",imagIndex+1,m_imgArray.count];
                         bottomSlider.value = imagIndex;
                         */
                    }
                    
                    [self disableAutoLock];
                    [self drawRunning:m_bRunning];
                    [self adjustItemStatus];
                    if (m_bRunning) {
                        bottomSlider.maximumValue = m_imgArray.count-1;
                    }
                }
                if (ucGain>127)
                    ucGain = 127;
                if (ucZoom>3)
                    ucZoom = 3;
                m_ucGain = ucGain;
                m_ucZoom = ucZoom;
            }
            [sock readDataWithTimeout:-1 tag:3];
        }
            break;
    }
    
}

-(void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err{
    
    NSLog(@"will disconnect %ld",sock.connectedPort);
    
    
    if (sock.connectedPort == 5001) {
        m_bCtrlSocketConnected = NO;
    }
    if (sock.connectedPort == 5002) {
        m_bDataSocketConnected = NO;
    }
    if (sock.connectedPort == 5003) {
        m_bStatSocketConnected = NO;
    }
    
    
    
}
-(void)onSocketDidDisconnect:(AsyncSocket *)sock{
    
    if (m_bConnected) {
        m_bConnected = NO;
        m_bRunning = NO;
        
        [self adjustItemStatus];
    }
}

-(void)sendConnectCommand{
    NSString* oldSSID = m_strSSID;
    m_strSSID = [self fetchSSIDInfo];
    /*
     if ([oldSSID isEqualToString:m_strSSID]) {
     return;
     }
     */
    
    //  SS-1 only, for SonoStar human version.
    if ([m_strSSID hasPrefix:@"SS-1 "]) {
        //
        //  无线阵列探头
        //
        m_nProbeType = CDSCor::PROBE_SECTORARRAY;
        char  str = [m_strSSID characterAtIndex:5];
        if (str=='G'){
            m_nSalesCode = 0x7f;
        }else{
            m_nSalesCode = 1;
        }
        char next = [m_strSSID characterAtIndex:6];
        m_nWifiChannel = next - 'A' + 1;
        m_bSSIDValid = YES;
    } else {
        m_strSSID = @"";
        m_bSSIDValid = NO;
        m_nWifiChannel = -2;
    }
    
    //  保持探头类型
    if (m_bSSIDValid) {
        [ud setInteger:m_nProbeType forKey:@"probeType"];
    }
    
    //  更新界面元素
    labelConnect.text = m_strSSID;
    [self adjustItemStatus];
    
    //
    //  开始连接探头
    //
    if (m_bSSIDValid && !m_bConnected) {
        //
        //  探头销售区域监测
        //
        BOOL bSalesCodeCheckPassed = NO;
        if (m_nSalesCode == 1) {    //  中国大陆地区销售代码
            NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
            NSArray * allLanguages = [defaults objectForKey:@"AppleLanguages"];
            NSString * preferredLang = [allLanguages objectAtIndex:0];
            NSLog(@"当前语言:%@", preferredLang);
            if ([preferredLang isEqualToString:@"zh-Hans"]) {
                bSalesCodeCheckPassed = YES;
            }
        } else {   //   0x7F    全球无限制销售代码
            bSalesCodeCheckPassed = YES;
        }
        
        //
        //  开始连接探头
        //
        if (bSalesCodeCheckPassed) {
            NSLog(@"Starting socket connecting");
            asyncSocket = nil;
            asyncSocketStateControl = nil;
            asyncSocketReceiveState = nil;
            //创建套节字链接
            UInt16 port = 5002;
            NSError* error;
            NSString* host = @"192.168.1.1";
            asyncSocket = [[AsyncSocket alloc]initWithDelegate:self];
            [asyncSocket connectToHost:host  onPort:port  error:&error];
            //状态控制端口链接
            port = 5001;
            asyncSocketStateControl = [[AsyncSocket alloc]initWithDelegate:self];
            [asyncSocketStateControl connectToHost:host onPort:port error:&error];
            //状态接收端口
            port = 5003;
            asyncSocketReceiveState = [[AsyncSocket alloc]initWithDelegate:self];
            [asyncSocketReceiveState connectToHost:host onPort:port error:&error];
        }
    }
}

//显示图像到视图
-(void)ShowImageToWindow: (NSData*) pData
{
    belowImageView.hidden = NO;
    if (!m_bHaveImage) {
        m_bHaveImage = YES;
        m_bLoadedImage = NO;
    }
    
    NSDate *date=[NSDate date];
    NSTimeInterval  timeZoneOffset=[[NSTimeZone systemTimeZone] secondsFromGMT];
    NSDate *newDate=[date dateByAddingTimeInterval:timeZoneOffset];
    newDateStr =[NSString stringWithFormat:@"%@",newDate];
    newDateStr = [newDateStr substringToIndex:newDateStr.length-6];
    
    RawImag* newgotimg = [[RawImag alloc] init];
    newgotimg.rawData = pData;
    newgotimg.zoom = m_ucZoom;
    newgotimg.gain = m_ucGain;
    newgotimg.probeType = m_nProbeType;
    newgotimg.time = newDateStr;
    
    [self drawImage:newgotimg runing:m_bRunning];
    
    [m_imgArray addObject:newgotimg];
    if (m_imgArray.count > 100) {
        [m_imgArray removeObjectAtIndex:0];
        self.labelCount.text = @"100/100";
    } else {
        self.labelCount.text = [NSString stringWithFormat:@"%ld/%ld",m_imgArray.count,m_imgArray.count];
    }
    bottomSlider.maximumValue = m_imgArray.count-1;
    bottomSlider.value = m_imgArray.count-1;
    
    
    /*
     RawImag* raw = [[RawImag alloc]init];
     raw.rawData =  pData;
     raw.gain = m_ucGain;
     raw.zoom = m_ucZoom;
     raw.time = newDateStr;
     raw.probeType = probeType;
     [m_imgArray addObject: raw];
     
     if (m_imgArray.count > 100) {
     [m_imgArray removeObjectAtIndex: 0 ];
     }else{
     
     self.labelCount.text = [NSString stringWithFormat:@"0/%ld",m_imgArray.count];
     
     }
     */
    /*
     Byte* drawImg =new Byte[640*480*4];
     
     Byte* rawImg = (Byte*)[pData bytes];
     
     pDscor->InitDSC(probeType,m_ucZoom);
     memcpy(drawImg, pDscor->DSCImage(rawImg), 640*480*4);
     
     NSInteger w = 640 ;
     NSInteger h = 480 ;
     NSUInteger bytesPerPixel = 4;
     NSUInteger bytesPerRow = bytesPerPixel * w;
     NSUInteger bitsPerComponent = 8;
     
     CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
     CGContextRef bitmapContext = CGBitmapContextCreate(drawImg,w,h,bitsPerComponent,bytesPerRow,
     colorSpace,
     kCGImageAlphaPremultipliedLast);
     
     CGImageRef cgRef;
     UIImage* img;
     
     if (!bitmapContext) {
     CGContextRelease(bitmapContext);
     CGColorSpaceRelease( colorSpace );
     NSLog(@"位图上下文为空！");
     return ;
     }
     cgRef = CGBitmapContextCreateImage(bitmapContext);
     
     img = [UIImage imageWithCGImage: cgRef];
     self.scanImg.image = img;
     CGImageRelease(cgRef);
     CGContextRelease(bitmapContext);
     CGColorSpaceRelease(colorSpace);
     delete[]drawImg;
     
     static int nPrevZoom = -1;
     if (m_ucZoom != nPrevZoom) {
     nPrevZoom = m_ucZoom;
     double scale = CDSCor::GetScale(probeType, m_ucZoom);
     [self ChangeBelowView:scale];
     }
     */
}


-(void)ChangeBelowView:(double)scale{
    
    if ([UIScreen mainScreen].bounds.size.width==480) {
        self.scanImg.frame = CGRectMake(self.scanImg.frame.origin.x, self.scanImg.frame.origin.y, self.scanImg.frame.size.width+20, self.scanImg.frame.size.height+15);
    }
    
    //移除底图
    for (UIView* v in self.scanImg.subviews) {
        if (v.tag==1000) {
            [v removeFromSuperview];
        }
    }
    
    //改变刻度尺量程
    CGSize  size = self.scanImg.frame.size;
    mpView = [[myView alloc]initWithFrame:CGRectMake(self.scanImg.frame.size.width, 0, 10, self.scanImg.frame.size.height)];
    mpView.backgroundColor = [UIColor whiteColor];
    mpView.scale = scale;
    
    UIGraphicsBeginImageContext(size);
    [mpView drawRect:self.scanImg.frame];
    
    //  绘制渐变图
    //UIImage* imgJianBian = [self drawImageForGradient:nil];
    
    [gradientImage drawInRect:CGRectMake(3, 0, 8,  self.scanImg.frame.size.height)];
    
    /*
     unsigned char gnd[256];
     for (int i=0;i<256;i++) {
     gnd[i] = 255-i;
     }
     NSData* gradient = [[NSData alloc] initWithBytes:gnd length:256];
     UIImage* gndImg = [[UIImage alloc] initWithData:gradient];
     //[gndImg drawInRect:CGRectMake(3, 0, 8,  self.scanImg.frame.size.height)];
     [gndImg drawInRect:CGRectMake(3, 0, 1,  256)];
     */
    
    
    
    UIImage *resultImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    belowImageView = [[UIImageView alloc]initWithImage:resultImage];
    belowImageView.tag = 1000;
    belowImageView.frame = CGRectMake(0,0,self.scanImg.frame.size.width,self.scanImg.frame.size.height);
    
    //增加边框
    belowImageView.layer.borderWidth = 1 ;
    belowImageView.layer.borderColor = [UIColor grayColor].CGColor;
    
    [belowImageView addSubview:labelDepth];
    [belowImageView addSubview:labelGain];
    [belowImageView addSubview:labelProbe];
    [belowImageView addSubview:labelTime];
    [belowImageView addSubview:labelFrozen];
    
    
    [self.scanImg addSubview:belowImageView];
    
    
    
    
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}

//单击保存当前扫描图片
- (IBAction)clickSaveCurrentScanImg:(id)sender {
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    if (m_bInCineLoop) {
        [self playControl:self.playButton];
    }
    
    
    NSInteger labelW = self.scanImg.frame.size.width/2;
    
    //UIImage* imgJianBian = [UIImage imageNamed:@"渐变.png"];
    
    UIImage* imgSaoMiao = self.scanImg.image;
    CGSize  size = self.scanImg.frame.size;
    UIGraphicsBeginImageContextWithOptions(size,YES,0);
    
    //Draw image2
    [gradientImage drawInRect:CGRectMake(3, 0, 8,  self.scanImg.frame.size.height)];
    
    
    //Draw image1
    [imgSaoMiao drawInRect:CGRectMake(15, 0, self.scanImg.frame.size.width-20, (self.scanImg.frame.size.width-20)*0.75)];
    NSMutableParagraphStyle *paragraphStyle= [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    NSDictionary* textAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor],NSStrokeColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont systemFontOfSize:15]};
    
    
    //labelDepth.text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Depth", nil),tmpdepth ];
    
    
    [labelDepth.text drawInRect:CGRectMake(26, 43, labelW+50, 20) withAttributes:textAttributes];
    [labelGain.text drawInRect:CGRectMake(26, 68, labelW, 20) withAttributes:textAttributes];
    [labelTime.text drawInRect:CGRectMake(26, 18,160 , 20) withAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],NSStrokeColorAttributeName:[UIColor whiteColor],NSStrokeColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont systemFontOfSize:15],NSParagraphStyleAttributeName:paragraphStyle}];
    [mpView drawRect:self.scanImg.frame];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [library saveImage:resultImage toAlbum: NSLocalizedString(@"WirelessScan", nil)  withCompletionBlock:^(NSError* error){
        
        NSString* errMsg;
        if(error==nil){
            errMsg = NSLocalizedString(@"Saved Success",nil);
        }else{
            errMsg = NSLocalizedString(@"Saved Failure", nil);
        }
        
        labelNote.text = errMsg;
        labelNote.alpha = 1;
        [UIView animateWithDuration:1 animations:^{labelNote.alpha=0;}];
        
        /*
         UILabel* label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 30)];
         label.center = self.scanImg.center;
         label.text = errMsg;
         [self.scanImg addSubview:label];
         label.textColor = [UIColor blueColor];
         label.font = [UIFont systemFontOfSize:25];
         [UIView animateWithDuration:1 animations:^{
         label.alpha = 0;
         }];
         */
        
        
    }];
}

//单击浏览按钮
- (IBAction)clickScanSavedImg:(id)sender {
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    if (m_bInCineLoop) {
        [self playControl:self.playButton];
    }
    
    
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = YES;
    imagePicker.delegate = self;
    
    if ([[UIDevice currentDevice].model hasPrefix:@"iPhone"]) {
        
        [self presentViewController:imagePicker animated:YES completion:nil];
        
    }else if ([[UIDevice currentDevice].model hasPrefix:@"iPad"]){
        UIPopoverController *popC = [[UIPopoverController alloc]initWithContentViewController:imagePicker];
        popC.delegate = self;
        
        [popC presentPopoverFromRect:CGRectMake(0, 0, 300, 300) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    }
    
    //调用相册过后隐藏得状态栏会出现，需要在plist设置viewControllerBasedStateBarApperance为yes，再调用 setStatusBarHidden：设置为 yes 。
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
}

#pragma UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    m_bHaveImage = YES;
    m_bLoadedImage = YES;
    [self adjustItemStatus];
    
    belowImageView.hidden = YES;
    UIImage* image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    self.scanImg.image = image;
    
    
    
    //    UIImageView *imgView = [[UIImageView alloc]initWithImage:image];
    //    imgView.frame = CGRectMake(0, 0, 888, 666);
    //    imgView.tag = 101;
    //    imgView.layer.borderColor = [UIColor grayColor].CGColor;
    //    imgView.layer.borderWidth = 1;
    //    [self.scanImg addSubview:imgView];
    [picker dismissViewControllerAnimated:YES completion:^{
        
        [[UIApplication sharedApplication] setStatusBarHidden:true withAnimation:UIStatusBarAnimationNone];
        
    }];
    bottomSlider.value = 0;
    _labelCount.text = [NSString stringWithFormat:@"0/%ld",m_imgArray.count];
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
}



- (IBAction)clickSettingButton:(id)sender {
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    if (m_bInCineLoop) {
        [self playControl:self.playButton];
    }
    
    temView = [[UIView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:temView];
    
    //self.settingView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 400, 440+120)];
    self.settingView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 400, 440)];
    self.settingView.center = CGPointMake(self.view.center.x, self.view.center.y-50);
    self.settingView.backgroundColor = [UIColor whiteColor];
    self.settingView.layer.cornerRadius = 10;
    self.settingView.layer.borderWidth = 1;
    [temView addSubview:self.settingView];
    
    //标题
    UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(150, 10, 100, 20)];
    titleLabel.text = NSLocalizedString(@"Settings", nil);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.settingView addSubview:titleLabel];
    
    //操作
    UILabel* handleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 40, self.settingView.frame.size.width, 50)];
    handleLabel.backgroundColor = [UIColor groupTableViewBackgroundColor];
    handleLabel.text = NSLocalizedString(@"    Operation", nil);
    handleLabel.font = [UIFont systemFontOfSize:12];
    handleLabel.layer.borderWidth = 0.3;
    [self.settingView addSubview:handleLabel];
    
    //左右手Label
    UILabel* labelHand = [[UILabel alloc]initWithFrame:CGRectMake(30, 100, 200, 20)];
    labelHand.text = NSLocalizedString(@"Left Hand Operration:", nil);
    [self.settingView addSubview:labelHand];
    //左右手转换器
    UISwitch* switchHand = [[UISwitch alloc] initWithFrame:CGRectMake(310, 94, 100, 40)];
    switchHand.on = m_bLeftHand;
    [self.settingView addSubview:switchHand];
    [switchHand addTarget:self action:@selector(swicthTheHand:) forControlEvents:UIControlEventValueChanged];
    
    //通道选项
    UILabel* advanceSetting = [[UILabel alloc]initWithFrame:CGRectMake(30, 190, 150, 20)];
    advanceSetting.text = NSLocalizedString(@"Channel Selection:", nil);
    [self.settingView addSubview:advanceSetting];
    
    //选择器
    pickerChannel = [[UIPickerView alloc ]initWithFrame:CGRectMake(0, 210, self.settingView.frame.size.width, 200)];
    pickerChannel.delegate = self;
    pickerChannel.dataSource = self;
    [self.settingView addSubview:pickerChannel];
    
    //选择按钮
    UIButton* selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    selectButton.frame = CGRectMake(self.settingView.frame.size.width/2 -40, 390, 80, 30);
    [selectButton setTitle:NSLocalizedString(@"Select", nil) forState:UIControlStateNormal];
    [selectButton setTitleColor:[UIColor colorWithRed:8/255.0 green:120/255.0 blue:200/255.0 alpha:1] forState:UIControlStateNormal];
    [self.settingView addSubview:selectButton];
    [selectButton addTarget:self action:@selector(clickSelectButton:) forControlEvents:UIControlEventTouchUpInside];
    
    //完成按钮
    UIButton* close = [UIButton buttonWithType:UIButtonTypeCustom];
    
    close.frame = CGRectMake(self.settingView.frame.size.width -70, 5, 60, 30);
    [close setTitle:NSLocalizedString(@"Close", nil) forState:UIControlStateNormal];
    [close setTitleColor:[UIColor colorWithRed:8/255.0 green:120/255.0 blue:200/255.0 alpha:1] forState:UIControlStateNormal];
    [self.settingView addSubview:close];
    [close addTarget:self action:@selector(clickcloseButton:) forControlEvents:UIControlEventTouchUpInside];
    
    //中部浅灰
    UILabel* btweenLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 130, self.settingView.frame.size.width, 50)];
    btweenLabel.backgroundColor = [UIColor groupTableViewBackgroundColor];
    btweenLabel.font = [UIFont systemFontOfSize:12];
    btweenLabel.layer.borderWidth = 0.3;
    btweenLabel.text =NSLocalizedString(@"    Wireless Channel",nil);
    [self.settingView addSubview:btweenLabel];
    
    
    /*
     //  gama设置编辑器
     gamaTF = [[UITextField alloc] initWithFrame:CGRectMake(40, 50, 160, 30)];
     [gamaTF setBorderStyle:UITextBorderStyleLine];
     [self.settingView addSubview:gamaTF];
     
     
     //  gama设置按钮
     UIButton* setgamaButton = [UIButton buttonWithType:UIButtonTypeCustom];
     setgamaButton.frame = CGRectMake(210, 50, 100,30);
     [setgamaButton setTitle: @"Set Gama" forState:UIControlStateNormal];
     [setgamaButton setTitleColor:[UIColor colorWithRed:8/255.0 green:120/255.0 blue:200/255.0 alpha:1] forState:UIControlStateNormal];
     [self.settingView addSubview:setgamaButton];
     [setgamaButton addTarget:self action:@selector(clickSetGama:) forControlEvents:UIControlEventTouchUpInside];
     */
}


-(void)repositionByHand
{
    if (m_bLeftHand) {
        //  左手操作界面布置
        self.scanImg.frame = CGRectMake(128, 32, 888, 666);
        self.imgLogo.frame = CGRectMake(7, 62, 115, 42);
        sideSlider.frame = CGRectMake(55,302,20, 379);
        self.btnFrozen.frame = CGRectMake(18, 179, 93, 93);
        self.lableLine.frame = CGRectMake(8, 142, 112, 2);
    } else {
        //  右手操作界面布置
        self.scanImg.frame = CGRectMake(8, 32, 888, 666);
        self.imgLogo.frame = CGRectMake(902, 62, 115, 42);
        sideSlider.frame = CGRectMake(949,304,20, 379);
        self.btnFrozen.frame = CGRectMake(913, 179, 93, 93);
        self.lableLine.frame = CGRectMake(904, 142, 112, 2);
    }
}

-(void)swicthTheHand:(UISwitch*)sw{
    
    if (sw.isOn) {
        if (m_bLeftHand)
            return;
        m_bLeftHand = YES;
        [self repositionByHand];
    } else {
        if (!m_bLeftHand)
            return;
        m_bLeftHand = NO;
        [self repositionByHand];
    }
    [ud setBool:m_bLeftHand forKey:@"leftHand"];
    [ud synchronize];
    
    /*
     if (sw.isOn) {
     if (m_bLeftHand)
     return;
     m_bLeftHand = YES;
     
     NSLog(@"Left Hand On\r\n");
     
     
     //self.belowImageView.frame = CGRectMake(belowImageView.frame.origin.x + 120, belowImageView.frame.origin.y ,belowImageView.frame.size.width, belowImageView.frame.size.height);
     
     self.scanImg.frame = CGRectMake(self.scanImg.frame.origin.x+120, self.scanImg.frame.origin.y, self.scanImg.frame.size.width, self.scanImg.frame.size.height);
     self.imgLogo.frame = CGRectMake(self.imgLogo.frame.origin.x -900, self.imgLogo.frame.origin.y, self.imgLogo.frame.size.width, self.imgLogo.frame.size.height);
     sideSlider.frame = CGRectMake(sideSlider.frame.origin.x-900, sideSlider.frame.origin.y, sideSlider.frame.size.width, sideSlider.frame.size.height);
     self.btnFrozen.frame = CGRectMake(self.btnFrozen.frame.origin.x-900, self.btnFrozen.frame.origin.y, self.btnFrozen.frame.size.width, self.btnFrozen.frame.size.height);
     self.lableLine.frame = CGRectMake(self.lableLine.frame.origin.x-900, self.lableLine.frame.origin.y, self.lableLine.frame.size.width, self.lableLine.frame.size.height);
     
     [ud setBool:true forKey:@"leftHand"];
     }else{
     if (!m_bLeftHand)
     return;
     m_bLeftHand = NO;
     
     NSLog(@"Left Hand Off\r\n");
     
     //self.belowImageView.frame = CGRectMake(belowImageView.frame.origin.x - 120, belowImageView.frame.origin.y ,belowImageView.frame.size.width, belowImageView.frame.size.height);
     
     self.scanImg.frame = CGRectMake(self.scanImg.frame.origin.x-120, self.scanImg.frame.origin.y, self.scanImg.frame.size.width, self.scanImg.frame.size.height);
     self.imgLogo.frame = CGRectMake(self.imgLogo.frame.origin.x +900, self.imgLogo.frame.origin.y, self.imgLogo.frame.size.width, self.imgLogo.frame.size.height);
     sideSlider.frame = CGRectMake(sideSlider.frame.origin.x+900, sideSlider.frame.origin.y, sideSlider.frame.size.width, sideSlider.frame.size.height);
     self.btnFrozen.frame = CGRectMake(self.btnFrozen.frame.origin.x+900, self.btnFrozen.frame.origin.y, self.btnFrozen.frame.size.width, self.btnFrozen.frame.size.height);
     self.lableLine.frame = CGRectMake(self.lableLine.frame.origin.x+900, self.lableLine.frame.origin.y, self.lableLine.frame.size.width, self.lableLine.frame.size.height);
     [ud setBool:false forKey:@"leftHand"];
     
     }
     */
}

-(void)swicthTheAdvance:(UISwitch*)sw{
    
    if (sw.isOn) {
        pickerChannel.hidden = NO;
    }else{
        pickerChannel.hidden = YES;
    }
    
}

// Mark pickerViewDelegate

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return 13;
}
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [channelList objectAtIndex:row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    selectIndex = row;
    //[pickerView viewForRow:row forComponent:component].backgroundColor = [UIColor greenColor];
    [pickerView reloadComponent:0];
}

-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    UILabel* label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 320, 30)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [channelList objectAtIndex:row];
    label.backgroundColor = [UIColor greenColor];
    
    if (m_nWifiChannel==row+1) {
        label.backgroundColor = [UIColor redColor];
    }else if (m_nWifiChannel==row+2){
        label.backgroundColor = [UIColor orangeColor];
    }else if (m_nWifiChannel==row){
        label.backgroundColor = [UIColor orangeColor];
    }
    
    return label;
    
}



-(void)clickSelectButton:(UIButton*)btn{
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
    NSString* message = nil;
    
    if (m_bConnected) {
        if (m_nWifiChannel == selectIndex+1) {
            // Tips： "The Channel is Currently Using."
            message = NSLocalizedString(@"The Channel is Currently Using.", nil);
        }
        else {
            [btn.superview removeFromSuperview];
            [self selectChannel:selectIndex+1];
            // Tips: Please Restart the Probe, then Connect to it Again."
            message = NSLocalizedString(@"Please Restart the Probe, then Connect to it Again.", nil);
        }
    }
    else {
        // Tip: " Probe is NOT connected."
        message = NSLocalizedString(@"Probe is NOT connected.", nil);
    }
    
    if (message) {
        
        UIAlertView* alert = [[UIAlertView alloc ]initWithTitle: NSLocalizedString(@"Tips", nil) message:message delegate:nil cancelButtonTitle: NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
        
    }
    
    [temView removeFromSuperview];
}



-(void)clickcloseButton:(UIButton*)btn{
    [temView removeFromSuperview];
    
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
}

-(void)drawRunning:(BOOL)running {
    if (running) {
        labelFrozen.text = NSLocalizedString(@"LIVE",nil);
    }else{
        labelFrozen.text = NSLocalizedString(@"FREEZE",nil);
    }
}

-(void)drawImage:(RawImag*)raw runing:(BOOL)running{
    //  调节状态
    if (raw.rawData  == nil) {
        m_bHaveImage = NO;
        m_bLoadedImage = NO;
        [self adjustItemStatus];
    } else {
        m_bHaveImage = YES;
        m_bLoadedImage = NO;
        [self adjustItemStatus];
    }
    
    
    Byte* drawImg = new Byte[640*480*4];
    if (raw.rawData == nil) {
        memset(drawImg,0,640*480*4);
        for (int i=0;i<640*480;i++) {
            drawImg[i*4+3] = 0xFF;
        }
    }else{
        Byte* rawImg = (Byte*)[raw.rawData bytes];
        
        unsigned char* rawdata = new unsigned char[256*512];
        memcpy(rawdata,rawImg,256*512);
        
        CDSCor* pDscor = CDSCor::GetInstance();
        pDscor->InitDSC(raw.probeType, raw.zoom);
        pDscor->InitGama(m_fGama);
        memcpy(drawImg,pDscor->DSCImage(rawdata),640*480*4);
        
        delete[]rawdata;
    }
    
    //画位图
    NSInteger w = 640 ;
    NSInteger h = 480 ;
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * w;
    NSUInteger bitsPerComponent = 8;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(drawImg,w,h,bitsPerComponent,bytesPerRow,
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast);
    
    CGImageRef cgRef;
    UIImage* img;
    
    if (!bitmapContext) {
        CGContextRelease(bitmapContext);
        CGColorSpaceRelease( colorSpace );
        NSLog(@"位图上下文为空！");
        return ;
    }
    cgRef = CGBitmapContextCreateImage(bitmapContext);
    
    img = [UIImage imageWithCGImage: cgRef];
    self.scanImg.image = img;
    CGImageRelease(cgRef);
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(colorSpace);
    delete[]drawImg;
    
    
    //画比例尺
    //static int nPrevZoom = -1;
    //if (raw.zoom != nPrevZoom)
    {
        //nPrevZoom = raw.zoom;
        double scale = CDSCor::GetScale(raw.probeType, raw.zoom);
        [self ChangeBelowView:scale];
    }
    
    
    //  更新ProbeType
    NSString* tmpdepth = nil;
    if (raw.probeType == CDSCor::PROBE_SECTORSCAN) {
        switch (raw.zoom) {
            case 0:
                tmpdepth = @"100mm";
                break;
            case 1:
                tmpdepth = @"140mm";
                break;
            case 2:
                tmpdepth = @"160mm";
                break;
            case 3:
                tmpdepth = @"180mm";
                break;
            default:
                tmpdepth = @"___mm";
                break;
        }
    } else if (raw.probeType == CDSCor::PROBE_SECTORARRAY) {
        switch (raw.zoom) {
            case 0:
                tmpdepth = @"90mm";
                break;
            case 1:
                tmpdepth = @"120mm";
                break;
            case 2:
                tmpdepth = @"160mm";
                break;
            case 3:
                tmpdepth = @"200mm";
                break;
            default:
                tmpdepth = @"___mm";
                break;
        }
    } else {
        labelDepth.text = @" ___mm";
    }
    labelDepth.text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Depth", nil),tmpdepth ];
    
    
    //  更新Gain
    int nshowgain = (int)((float)raw.gain * (105.0-30.0)/127.0 + 30.0);
    if (raw.gain==127)
        nshowgain = 105;
    if (raw.gain==0)
        nshowgain = 30;
    NSString* newgain = [NSString stringWithFormat:@"%@: %ddB",NSLocalizedString(@"Gain", nil),nshowgain];
    if (![newgain isEqualToString:labelGain.text])
        labelGain.text = newgain;
    
    labelTime.text = raw.time;
    if (running) {
        labelFrozen.text = NSLocalizedString(@"LIVE",nil);
    }else{
        labelFrozen.text = NSLocalizedString(@"FREEZE",nil);
    }
    
}

//
//  界面元素状态调节函数
//
-(void) adjustItemStatus
{
    //
    //  状态的一致性检测
    //
    if (!m_bSSIDValid) {
        m_bConnected = NO;
    }
    if (!m_bConnected) {
        m_bRunning = NO;
    }
    if (m_bRunning) {
        m_bInCineLoop = NO;
    }
    if (!m_bHaveImage) {
        m_bLoadedImage = NO;
    }
    
    //
    //  各个按钮的状态调整
    //
    if (m_bConnected) {
        self.btnFrozen.enabled = YES;
    } else {
        self.btnFrozen.enabled = NO;
    }
    
    if (m_bConnected && m_bRunning) {
        sideSlider.enabled = YES;
    } else {
        sideSlider.enabled = NO;
    }
    
    if (m_bRunning) {
        self.btnWifi.enabled = NO;
    } else {
        self.btnWifi.enabled = YES;
    }
    
    if (m_bRunning || m_imgArray==nil || m_imgArray.count<=0) {
        bottomSlider.enabled = NO;
    } else {
        bottomSlider.enabled = YES;
    }
    
    if (m_imgArray==nil || m_imgArray.count<=0 || m_bRunning) {
        btnPre.enabled = NO;
        btnNext.enabled = NO;
        playButton.enabled = NO;
    } else {
        btnPre.enabled = YES;
        btnNext.enabled = YES;
        playButton.enabled = YES;
    }
    
    if (!m_bRunning && m_bHaveImage && !m_bLoadedImage) {
        self.btnSave.enabled = YES;
    } else {
        self.btnSave.enabled = NO;
    }
    
    if (!m_bRunning && !m_bInCineLoop) {
        self.btnScan.enabled = YES;
    } else {
        self.btnScan.enabled = NO;
    }
    
    if (!m_bRunning && !m_bInCineLoop) {
        self.btnSet.enabled = YES;
    } else {
        self.btnSet.enabled = NO;
    }
    
    //  更新Frozen标签
    if (m_bRunning) {
        labelFrozen.text = NSLocalizedString(@"LIVE", nil);
    } else {
        labelFrozen.text = NSLocalizedString(@"FREEZE",nil);
    }
    
    //  更新播放按钮的图标
    if (m_bInCineLoop) {
        [self.playButton setImage:[UIImage imageNamed:@"btn_暂停_nor.png"] forState:UIControlStateNormal];
    } else {
        [self.playButton setImage:[UIImage imageNamed:@"btn_播放_nor.png"] forState:UIControlStateNormal];
    }
}

-(void) disableAutoLock
{
    if (autoLockTimer != nil) {
        [autoLockTimer invalidate];
    }
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    autoLockTimer = [NSTimer scheduledTimerWithTimeInterval:60*15 target:self selector:@selector(checkEnableAutoLock) userInfo:nil repeats:NO];
}

-(void) checkEnableAutoLock
{
    if (autoLockTimer != nil) {
        [autoLockTimer invalidate];
    }
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

-(void) nullImageRefresh
{
    if (!m_bHaveImage) {
        NSDate *date=[NSDate date];
        NSTimeInterval  timeZoneOffset=[[NSTimeZone systemTimeZone] secondsFromGMT];
        NSDate *newDate=[date dateByAddingTimeInterval:timeZoneOffset];
        newDateStr =[NSString stringWithFormat:@"%@",newDate];
        newDateStr = [newDateStr substringToIndex:newDateStr.length-6];
        nullImage.time = newDateStr;
        [self drawImage:nullImage runing:NO];
    } else {
        [nullImgTimer invalidate];
    }
}

-(void)clickSetGama:(UIButton*)btn{
    NSString* strgama = gamaTF.text;
    float gama = [strgama floatValue];
    if (gama > 0.1 && gama < 10) {
        [ud setFloat:gama forKey:@"Gama"];
        m_fGama = gama;
        
        //  更新渐变图
        CDSCor* pDscor = CDSCor::GetInstance();
        pDscor->InitGama(m_fGama);
        gradientImage = [self InitGradientImage];
    }
    
    [temView removeFromSuperview];
    //  关闭自动锁屏功能
    [self disableAutoLock];
    
}

-(UIImage*)InitGradientImage {
    
    CDSCor* pDscor = CDSCor::GetInstance();
    pDscor->InitGama(m_fGama);
    unsigned int* unGama = pDscor->GetGama();
    
    Byte* drawImg = new Byte[256*1*4];
    memset(drawImg,0,256*1*4);
    for (int i=0;i<256*1;i++) {
        drawImg[i*4] = (unsigned char)(unGama[255-i]/256);
        drawImg[i*4+1] = (unsigned char)(unGama[255-i]/256);
        drawImg[i*4+2] = (unsigned char)(unGama[255-i]/256);
        drawImg[i*4+3] = 255;
    }
    
    
    //画位图
    NSInteger w = 1 ;
    NSInteger h = 256 ;
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * w;
    NSUInteger bitsPerComponent = 8;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(drawImg,w,h,bitsPerComponent,bytesPerRow,
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast);
    
    CGImageRef cgRef;
    UIImage* img;
    
    if (!bitmapContext) {
        CGContextRelease(bitmapContext);
        CGColorSpaceRelease( colorSpace );
        NSLog(@"位图上下文为空！");
        return  nil;
    }
    cgRef = CGBitmapContextCreateImage(bitmapContext);
    
    img = [UIImage imageWithCGImage: cgRef];
    CGImageRelease(cgRef);
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(colorSpace);
    delete[]drawImg;
    
    return img;
}

-(NSString*)getDeviceVersion{
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSLog(@"----设备类型---%@",deviceString);
    
    NSArray *modelArray = @[
                            
                            @"i386", @"x86_64",
                            
                            @"iPhone1,1",
                            @"iPhone1,2",
                            @"iPhone2,1",
                            @"iPhone3,1",
                            @"iPhone3,2",
                            @"iPhone3,3",
                            @"iPhone4,1",
                            @"iPhone5,1",
                            @"iPhone5,2",
                            @"iPhone5,3",
                            @"iPhone5,4",
                            @"iPhone6,1",
                            @"iPhone6,2",
                            
                            @"iPod1,1",
                            @"iPod2,1",
                            @"iPod3,1",
                            @"iPod4,1",
                            @"iPod5,1",
                            
                            @"iPad1,1",
                            @"iPad2,1",
                            @"iPad2,2",
                            @"iPad2,3",
                            @"iPad2,4",
                            @"iPad3,1",
                            @"iPad3,2",
                            @"iPad3,3",
                            @"iPad3,4",
                            @"iPad3,5",
                            @"iPad3,6",
                            
                            @"iPad4,7",
                            
                            @"iPad5,3",
                            
                            @"iPad2,5",
                            @"iPad2,6",
                            @"iPad2,7",
                            ];
    NSArray *modelNameArray = @[
                                
                                @"iPhone Simulator", @"iPhone Simulator",
                                
                                @"iPhone 2G",
                                @"iPhone 3G",
                                @"iPhone 3GS",
                                @"iPhone 4(GSM)",
                                @"iPhone 4(GSM Rev A)",
                                @"iPhone 4(CDMA)",
                                @"iPhone 4S",
                                @"iPhone 5(GSM)",
                                @"iPhone 5(GSM+CDMA)",
                                @"iPhone 5c(GSM)",
                                @"iPhone 5c(Global)",
                                @"iphone 5s(GSM)",
                                @"iphone 5s(Global)",
                                
                                @"iPod Touch 1G",
                                @"iPod Touch 2G",
                                @"iPod Touch 3G",
                                @"iPod Touch 4G",
                                @"iPod Touch 5G",
                                
                                @"iPad",
                                @"iPad 2(WiFi)",
                                @"iPad 2(GSM)",
                                @"iPad 2(CDMA)",
                                @"iPad 2(WiFi + New Chip)",
                                @"iPad 3(WiFi)",
                                @"iPad 3(GSM+CDMA)",
                                @"iPad 3(GSM)",
                                @"iPad 4(WiFi)",
                                @"iPad 4(GSM)",
                                @"iPad 4(GSM+CDMA)",
                                
                                @"iPad mini (WiFi)",
                                @"iPad mini (GSM)",
                                @"ipad mini (GSM+CDMA)"
                                
                                ];
    NSInteger modelIndex = - 1;
    NSString *modelNameString = nil;
    modelIndex = [modelArray indexOfObject:deviceString];
    if (modelIndex >= 0 && modelIndex < [modelNameArray count]) {
        modelNameString = [modelNameArray objectAtIndex:modelIndex];
    }
    
    NSLog(@"----设备类型---%@",deviceString);
    return deviceString;
}

@end