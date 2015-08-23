//
//  LO_RootViewController.m
//  LO_BMKSample
//
//  Created by 侯志超 on 15/8/23.
//  Copyright (c) 2015年 河南蓝鸥科技有限公司. All rights reserved.
//

#import "LO_RootViewController.h"
#import <BaiduMapAPI/BMapKit.h>

@interface LO_RootViewController ()<BMKGeneralDelegate, BMKMapViewDelegate, BMKLocationServiceDelegate, BMKGeoCodeSearchDelegate, BMKRouteSearchDelegate>

@property (nonatomic, strong)UITextField *startCityTF;
@property (nonatomic, strong)UITextField *startAddressTF;


@property (nonatomic, strong)UITextField *endCityTF;
@property (nonatomic, strong)UITextField *endAddressTF;

@property (nonatomic, strong) BMKMapView *mapView;
//  声明定位服务对象属性（负责定位）
@property (nonatomic, strong) BMKLocationService *locationService;

//  声明地理位置搜索对象(负责地理编码)
@property (nonatomic, strong)BMKGeoCodeSearch * getCodeSearch;

//  声明路线搜索服务对象
@property (nonatomic, strong)BMKRouteSearch *routeSearch;

//  开始的路线检索节点
@property (nonatomic, strong)BMKPlanNode *startNode;
//  目标路线检索节点
@property (nonatomic, strong)BMKPlanNode *endNode;

@end

@implementation LO_RootViewController

- (void)dealloc
{
    self.mapView.delegate = nil;
    self.locationService.delegate = nil;
    self.getCodeSearch.delegate = nil;
    self.routeSearch.delegate = nil;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //  因为百度SDK的引擎使用C++代码写成，所以我们得保证我们工程中至少要有一个文件是.mm后缀
    //  创建百度地图主引擎类对象（使用百度地图功能之前必须启动引擎）
    BMKMapManager *manager = [[BMKMapManager alloc] init];
    //  启动引擎
    [manager start:@"pRXv4Rm4uK1kpZZ8Ue3SKGwR" generalDelegate:self];
    
    
    //
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0) {
        
        //  设置边距
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    
    //  搭建UI
    [self addSubviews];
    
    //  创建定位服务对象
    self.locationService = [[BMKLocationService alloc] init];
    //  设置定位服务对象代理
    self.locationService.delegate = self;
    //  设置再次定位的最小距离
    [BMKLocationService setLocationDistanceFilter:10];
    
    //  创建地理位置搜索对象
    self.getCodeSearch = [[BMKGeoCodeSearch alloc] init];
    //  设置代理
    self.getCodeSearch.delegate = self;
    
    //  创建route搜索服务对象
    self.routeSearch = [[BMKRouteSearch alloc] init];
    //  设置代理
    self.routeSearch.delegate = self;
    
}

/**
 *  搭建UI的方法
 */
- (void)addSubviews
{
    //  设置BarButtonItem
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:@"开始定位" style:UIBarButtonItemStylePlain target:self action:@selector(leftAction)];
    self.navigationItem.leftBarButtonItem = left;
    
    //
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"关闭定位" style:UIBarButtonItemStylePlain target:self action:@selector(rightAction)];
    self.navigationItem.rightBarButtonItem = right;
    
    self.startCityTF = [[UITextField alloc] initWithFrame:CGRectMake(20, 30, 100, 30)];
    self.startCityTF.text = @"开始城市";
    [self.view addSubview:_startCityTF];
    
    self.startAddressTF = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_startCityTF.frame) + 30, CGRectGetMinY(_startCityTF.frame), CGRectGetWidth(_startCityTF.frame), CGRectGetHeight(_startCityTF.frame))];
    self.startAddressTF.text = @"开始地址";
    [self.view addSubview:_startAddressTF];
    
    self.endCityTF = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMinX(_startCityTF.frame), CGRectGetMaxY(_startCityTF.frame) + 10, CGRectGetWidth(_startCityTF.frame), CGRectGetHeight(_startCityTF.frame))];
    self.endCityTF.text = @"目的城市";
    [self.view addSubview:_endCityTF];
    
    //  目的地址
    self.endAddressTF = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_endCityTF.frame) + 30, CGRectGetMaxY(_startCityTF.frame) + 10, CGRectGetWidth(_startCityTF.frame), CGRectGetHeight(_startCityTF.frame))];
    self.endAddressTF.text = @"目的地址";
    [self.view addSubview:_endAddressTF];
    
    //  添加路线规划按钮
    UIButton *routeSearch = [UIButton buttonWithType:UIButtonTypeSystem];
    [routeSearch setTitle:@"路线规划" forState:UIControlStateNormal];
    routeSearch.frame = CGRectMake(CGRectGetMaxX(_startAddressTF.frame) + 10, CGRectGetMaxY(_startAddressTF.frame), 100, 30);
    [routeSearch setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //  设置点击事件
    [routeSearch addTarget:self action:@selector(routeSearchAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:routeSearch];
    
    
    //  添加地图
    self.mapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_endAddressTF.frame) + 5, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - CGRectGetMaxY(_endAddressTF.frame) - 5)];
    
    //  设置当前类为mapView的代理对象
    self.mapView.delegate = self;
    
    //  添加到父视图上
    [self.view addSubview:_mapView];
}
/**
 *  开始定位的方法
 */
- (void)leftAction
{
    //  1.开启定位服务
    [self.locationService startUserLocationService];
    //  2.在地图上显示用户的位置
    self.mapView.showsUserLocation = YES;
    
}

/**
 *  关闭定位
 */
- (void)rightAction
{
    //  1.关闭定位服务
    [self.locationService stopUserLocationService];
    //  2.设置地图不显示用户的位置
    self.mapView.showsUserLocation = NO;
    
    //  3.删除我们添加的标注对象
    [self.mapView removeAnnotation:[self.mapView.annotations lastObject]];
    
}

/**
 *  路线规划的点击事件
 */
- (void)routeSearchAction:(UIButton *)sender
{
    //  完成准确的说是正向地理编码
    //  1.创建正向地理编码选项对象
    BMKGeoCodeSearchOption *geoSearchOption = [[BMKGeoCodeSearchOption alloc] init];
    //  2.给想进行正向地理位置编码的位置赋值
    geoSearchOption.city = self.startCityTF.text;
    geoSearchOption.address = self.startAddressTF.text;
    
    //  执行地理位置编码
    [self.getCodeSearch geoCode:geoSearchOption];
}

#pragma mark - BMKlocationService的代理方法
- (void)willStartLocatingUser
{
    NSLog(@"开始定位");
}

- (void)didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"定位失败error:%@", error);
}

/**
 *  定位成功，再次定位的方法
 */

- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    
    //  完成地理反编码
    //  1.创建反向地理编码选项对象
    BMKReverseGeoCodeOption *reverseOption = [[BMKReverseGeoCodeOption alloc] init];
    //  2.给反向地理编码选项对象的坐标点赋值
    reverseOption.reverseGeoPoint = userLocation.location.coordinate;
    
    //  3.执行反向地理编码操作
    [self.getCodeSearch reverseGeoCode:reverseOption];
    
}


#pragma mark BMKGeoCodeSearch的代理方法
/**
 *  
 *
 *     反向编码的回调方法
 *  
 *
 */
- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    
    //  定义大头针标注
    BMKPointAnnotation *annotation = [[BMKPointAnnotation alloc] init];
    
    //  设置标注的位置坐标
    annotation.coordinate = result.location;
    //
    annotation.title = result.address;
    //  添加到地图中
    [self.mapView addAnnotation:annotation];
    
    //  使地图显示该位置
    [self.mapView setCenterCoordinate:result.location animated:YES];
    
    

}
/**
 *  正向地理编码的回调方法
 */

- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    //
    if ([result.address isEqualToString:self.startAddressTF.text]) {
        //  说明当前编码的对象是开始节点
        self.startNode = [[BMKPlanNode alloc] init];
        //  给节点的坐标位置赋值
        _startNode.pt = result.location;
        
        //  发起对目标节点的地理编码
        //  1.创建正向地理编码选项对象
        BMKGeoCodeSearchOption *geoOption = [[BMKGeoCodeSearchOption alloc] init];
        geoOption.city = self.endCityTF.text;
        geoOption.address = self.endAddressTF.text;
        
        //  执行正向编码
        [self.getCodeSearch geoCode:geoOption];
        
        //
        
        self.endNode = nil;
        
        
        
    }else{
        self.endNode = [[BMKPlanNode alloc] init];
        _endNode.pt = result.location;
    }
    
    if (_startNode != nil && _endNode != nil) {
        //  开始进行路线规划
        //  1.创建驾车路线规划
        BMKDrivingRoutePlanOption *drivingRoutOption = [[BMKDrivingRoutePlanOption alloc] init];
        //  2.指定开始节点和目标节点
        drivingRoutOption.from = _startNode;
        drivingRoutOption.to = _endNode;
        //  3.让路线搜索服务对象搜索路线
        [self.routeSearch drivingSearch:drivingRoutOption];
        
        
    }
}

//  获取到自驾路线的回调
- (void)onGetDrivingRouteResult:(BMKRouteSearch *)searcher result:(BMKDrivingRouteResult *)result errorCode:(BMKSearchErrorCode)error
{
    //  删除原来的覆盖物
    NSArray *array = [NSArray arrayWithArray:_mapView.annotations];
    [_mapView removeAnnotations:array];
    
    //  删除overlays(原来的轨迹)
    array = [NSArray arrayWithArray:_mapView.overlays];
    [_mapView removeOverlays:array];
    if (error == BMK_SEARCH_NO_ERROR) {
        //  选取获取到所有路线中的一条路线
        BMKDrivingRouteLine *plan = [result.routes objectAtIndex:0];
        //  计算路线方案中路段的数目
        NSUInteger size = [plan.steps count];
        
        //  声明一个整型变量用来计算所有轨迹点的总数
        int planPointCounts = 0;
        for (int i = 0; i < size; i ++) {
            //  获取路线中的路段
            BMKDrivingStep *step = plan.steps[i];
            if (i == 0) {
                //  地图显示经纬区域
                [self.mapView setRegion:BMKCoordinateRegionMake(step.entrace.location, BMKCoordinateSpanMake(0.001, 0.001))];
            }
            //  累计轨迹点
            planPointCounts += step.pointsCount;
            
            
            
        }
        
        //  声明一个结构体数组用来保存所有的轨迹点（每一个轨迹点都是一个结构体）
        //  轨迹点结构体的名字为BMKMapPoint
        BMKMapPoint *temppoints = new BMKMapPoint[planPointCounts];
        
        int i = 0;
        for (int j = 0; j < size; j ++) {
            BMKDrivingStep *transitStep = [plan.steps objectAtIndex:j];
            int k = 0;
            for (k = 0; k < transitStep.pointsCount; k ++) {
                //  获取每个轨迹点的x，y放入数组中
                temppoints[i].x = transitStep.points[k].x;
                temppoints[i].y = transitStep.points[k].y;
                i ++;
            }
        }
        
        //  通过轨迹点构造BMKPolyline（折线）
        
        BMKPolyline *polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
        //  添加到mapView上
        //  我们想要在地图上显示轨迹呢，只能先添加overlay对象（类比大头针的标注）,添加好之后，地图就会根据你设置的overlay显示出轨迹
        [self.mapView addOverlay:polyLine];
        
        
        
        
    }
    
    
    
    
}

#pragma mark -mapview的代理方法
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        //  创建要显示的折线
        BMKPolylineView *polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        //  设置该线条的填充颜色
        polylineView.fillColor = [UIColor redColor];
        //  设置线条的颜色
        polylineView.strokeColor = [UIColor redColor];
        //  设置折线的宽度
        polylineView.lineWidth = 3.0;
        return polylineView;
        
    }
    return nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
