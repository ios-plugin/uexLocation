//
//  EUExLocation.m
//  AppCan
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExLocation.h"




@interface EUExLocation ()

@property(nonatomic,assign)BOOL isJudgeLct;//是否拥有定位权限

@property (nonatomic,strong) uexLocationObject *myLocation;
@property (nonatomic,strong) ACJSFunctionRef *getAddressCallback;
@end

@implementation EUExLocation {
    int flage;
}

#pragma mark - 定位权限判断
- (BOOL)judgeLocation
{
    self.isJudgeLct = NO;
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    switch (authStatus) {
        case kCLAuthorizationStatusNotDetermined://没有询问是否开启定位
        {
            //            __weak EUExImage *weakSelf = self;
            //            //第一次询问用户是否进行授权
            //            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            //                // CALL YOUR METHOD HERE - as this assumes being called only once from user interacting with permission alert!
            //                if (status == PHAuthorizationStatusAuthorized) {
            //                    // Photo enabled code
            //                    weakSelf.isJudgePic = YES;
            //                }
            //                else {
            //                    // Photo disabled code
            //                    weakSelf.isJudgePic = NO;
            //                }
            //            }];
            self.isJudgeLct = YES;
        }
            break;
        case kCLAuthorizationStatusRestricted:
            //未授权，家长限制
            self.isJudgeLct = NO;
            break;
        case kCLAuthorizationStatusDenied:
            //用户未授权
            self.isJudgeLct = NO;
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            //用户授权
            self.isJudgeLct = YES;
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            //用户授权
            self.isJudgeLct = YES;
        default:
            break;
    }
    
    return self.isJudgeLct;
}

- (void)openLocation:(NSMutableArray *)inArguments {
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.myLocation.func = func;
    //定位权限检测
    BOOL isLocationOK = [self judgeLocation];
    if (!isLocationOK) {
        NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"errCode",@"定位失败，请在 设置-隐私-定位服务 中开启权限",@"info", nil];
        NSString *dataStr = [dicResult ac_JSONFragment];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.onPermissionDenied" arguments:ACArgsPack(dataStr)];
        return;
    }
    
    if (![CLLocationManager locationServicesEnabled]) {
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbOpenLocation" arguments:ACArgsPack(@0,@2,@1)];
        [func executeWithArguments:ACArgsPack(@(-1))];
        return;
    }
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:{
            [self.myLocation requestPermissionThenOpenLocation:inArguments];
            return;
        }
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied: {
            // 当前程序未打开定位服务
            [self.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbOpenLocation" arguments:ACArgsPack(@0,@2,@1)];
            [func executeWithArguments:ACArgsPack(@(-1))];
            return;
        }
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            [self.myLocation openLocation:inArguments];
            break;
        }
    }
    
}



- (void)closeLocation:(NSMutableArray *)inArguments {

        [self.myLocation closeLocation];
    
}

- (uexLocationObject *)myLocation{
    if (!_myLocation) {
        _myLocation = [[uexLocationObject alloc] initWithEuexObj:self];
    }
    return _myLocation;
    
}

/** 已废弃,请用新接口getAddressByType**/
- (void)getAddress:(NSMutableArray *)inArguments {
    
    if (inArguments.count < 2) {
        return;
    }
    double inLatitude = [[inArguments objectAtIndex:0] doubleValue];
    double inLongitude = [[inArguments objectAtIndex:1] doubleValue];
    
    if ([inArguments count]>2) {
        flage=[[inArguments objectAtIndex:2]intValue];
    }
    
    
    if (![self isConnectionAvailable]){
        NSString *str = UEX_LOCALIZEDSTRING(@"无网络连接,请检查你的网络");
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbGetAddress" arguments:ACArgsPack(@1,@0,str)];
    } else {
        [self.myLocation getAddressWithLot:inLongitude Lat:inLatitude];
    }
    
    
    
}

- (void)getAddressByType:(NSMutableArray *)inArguments {
    ACArgsUnpack(NSDictionary *infoDic) = inArguments;
    ACJSFunctionRef *func = ac_JSFunctionArg(inArguments.lastObject);
    self.getAddressCallback = func;
    if (inArguments.count < 1) {
        return;
    }
    
    //定位权限检测
    BOOL isLocationOK = [self judgeLocation];
    if (!isLocationOK) {
        NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:@"1",@"errCode",@"定位失败，请在 设置-隐私-定位服务 中开启权限",@"info", nil];
        NSString *dataStr = [dicResult ac_JSONFragment];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.onPermissionDenied" arguments:ACArgsPack(dataStr)];
        return;
    }
    
    double inLatitude = [infoDic[@"latitude"] doubleValue];
    double inLongitude =[infoDic[@"longitude"] doubleValue];
    flage= [infoDic[@"flag"] intValue];
    NSString *type = infoDic[@"type"]? [infoDic[@"type"] lowercaseString]:nil;

    
    if (![self isConnectionAvailable]){
        
        //[self jsSuccessWithName:@"uexLocation.cbGetAddress" opId:1 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:UEX_LOCALIZEDSTRING(@"无网络连接,请检查你的网络")];
        NSString *str = UEX_LOCALIZEDSTRING(@"无网络连接,请检查你的网络");
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbGetAddress" arguments:ACArgsPack(@1,@0,str)];
        [func executeWithArguments:ACArgsPack(@(1),str)];
        
    } else {
        CLLocationCoordinate2D LocationCoordinate2D;
        LocationCoordinate2D.longitude = inLongitude;
        LocationCoordinate2D.latitude = inLatitude;
        
        CLLocationCoordinate2D newCoordinate2D = LocationCoordinate2D;
        //百度坐标系转为世界标准地理坐标======>百度坐标系转为高德坐标
        if ([type isEqualToString:@"bd09"]) {
            newCoordinate2D = [UexLocationJZLocationConverter bd09ToGcj02:LocationCoordinate2D];
        }
        //高德坐标系转为世界标准地理坐标======>高德坐标系不转换
//        if ([type isEqualToString:@"gcj02"]) {
//            newCoordinate2D = [UexLocationJZLocationConverter gcj02ToWgs84:LocationCoordinate2D];
//        }
        //世界标准地理坐标转为高德坐标系
        if ([type isEqualToString:@"wgs84"]) {
            newCoordinate2D = [UexLocationJZLocationConverter wgs84ToGcj02:LocationCoordinate2D];
        }
        
        [self.myLocation getAddressWithLot:newCoordinate2D.longitude Lat:newCoordinate2D.latitude];
    }
    
    
    
}
/**
 *	@brief	中国国测局地理坐标（GCJ-02）<火星坐标> 转换成 百度地理坐标（BD-09)
 *
 *	@param 	location 	中国国测局地理坐标（GCJ-02）<火星坐标>
 *
 *	@return	百度地理坐标（BD-09)
+ (CLLocationCoordinate2D)gcj02ToBd09:(CLLocationCoordinate2D)location;
  */

- (void)getBaiduFromGoogle:(NSMutableArray *)inArguments {
    
    if(inArguments.count >1) {
        double longitude = [[inArguments objectAtIndex:0] doubleValue];
        double latitude = [[inArguments objectAtIndex:1] doubleValue];
        CLLocationCoordinate2D LocationCoordinate2D;
        LocationCoordinate2D.longitude =longitude;
        LocationCoordinate2D.latitude = latitude;
        //转成百度坐标系
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter gcj02ToBd09:LocationCoordinate2D];
        [self.webViewEngine callbackWithFunctionKeyPath:@"cbGetBaiduFromGoogle" arguments:ACArgsPack(@(newCoordinate2D.longitude),@(newCoordinate2D.latitude))];

    }
    
}
- (NSString *)convertLocation:(NSMutableArray *)inArguments{
    if (inArguments.count < 1) {
        return nil;
    }
    id info = [inArguments[0] ac_JSONValue];
    double latitude = [[info objectForKey:@"latitude"] doubleValue];
    double longitude = [[info objectForKey:@"longitude"] doubleValue];
    CLLocationCoordinate2D LocationCoordinate2D;
    LocationCoordinate2D.longitude =longitude;
    LocationCoordinate2D.latitude = latitude;
    NSString *from = [[info objectForKey:@"from"] lowercaseString];
    NSString *to = [[info objectForKey:@"to"] lowercaseString];
    if ([from isEqual:@"wgs84"] && [to isEqual:@"gcj02"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter wgs84ToGcj02:LocationCoordinate2D];
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} ac_JSONFragment];
    }
    if ([from isEqual:@"gcj02"] && [to isEqual:@"wgs84"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter gcj02ToWgs84:LocationCoordinate2D];
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} ac_JSONFragment];
    }
    if ([from isEqual:@"wgs84"] && [to isEqual:@"bd09"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter wgs84ToBd09:LocationCoordinate2D];
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)}  ac_JSONFragment];
    }
    if ([from isEqual:@"bd09"] && [to isEqual:@"wgs84"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter bd09ToWgs84:LocationCoordinate2D];
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} ac_JSONFragment];
    }
    if ([from isEqual:@"bd09"] && [to isEqual:@"gcj02"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter bd09ToGcj02:LocationCoordinate2D];
        NSLog(@"%@",@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)});
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} ac_JSONFragment];
    }
    if ([from isEqual:@"gcj02"] && [to isEqual:@"bd09"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter gcj02ToBd09:LocationCoordinate2D];
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} ac_JSONFragment];
    }
    return nil;
}

- (void)uexLocationWithLot:(double)inLog Lat:(double)inLat {
    
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.onChange" arguments:ACArgsPack(@(inLog),@(inLat))];
}

//地址回调
- (void)uexLocationWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData {
    if(!inData){
        return;
    }
    
    
    NSMutableArray *array=(NSMutableArray *)[inData componentsSeparatedByString:@";"];
    NSMutableDictionary *jsonDict=[NSMutableDictionary dictionary];
    NSArray *arrayKey=[NSArray arrayWithObjects:@"formatted_address",@"location",@"addressComponent",nil];
    
    NSString *key = nil;
    NSString *value = nil;
    
    for (int i=0;i<[array count] ; i++) {
        
        key=[NSString stringWithFormat:@"%@",[arrayKey objectAtIndex:i]];
        
        if (i==0) {
            
            value =[NSString stringWithFormat:@"%@",[array objectAtIndex:i]];
            [jsonDict setValue:value forKey:key];
            
        } else {
            
            NSMutableDictionary * valueDic =[[array objectAtIndex:i] ac_JSONValue];
            [jsonDict setValue:valueDic forKey:key];
            
        }
        
    }
    
    if (flage == 1) {
        NSString *json=[jsonDict ac_JSONFragment];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbGetAddress" arguments:ACArgsPack(@0,@1,json)];
        [self.getAddressCallback executeWithArguments:ACArgsPack(@(0),jsonDict)];
        
    } else {
         NSString *adr=[jsonDict objectForKey:@"formatted_address"];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbGetAddress" arguments:ACArgsPack(@(inOpId),@(inDataType),adr)];
        [self.getAddressCallback executeWithArguments:ACArgsPack(@(0),adr)];
    }
    
}


- (void)clean {
 
}

- (BOOL)isConnectionAvailable {
    
    Reachability *reach = [Reachability reachabilityWithHostName:@"www.apple.com"];
    
    return [reach isReachable];
    
}

@end
