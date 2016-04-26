//
//  EUExLocation.m
//  AppCan
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExLocation.h"
#import "EUtility.h"
#import "EUExBaseDefine.h"
#import "EBrowserView.h"
#import "SBJSON.h"
#import "JSON.h"

@interface EUExLocation ()

@property (nonatomic, strong) uexLocationObject *myLocation;

@end

@implementation EUExLocation {
    
    int flage;
}

- (id)initWithBrwView:(EBrowserView *) eInBrwView {
    
    if (self = [super initWithBrwView:eInBrwView]) {
        
    }
    
    return self;
    
}

- (void)openLocation:(NSMutableArray *)inArguments {

    
    
    
    if (![CLLocationManager locationServicesEnabled]) {
        [self jsSuccessWithName:@"uexLocation.cbOpenLocation" opId:0  dataType:UEX_CALLBACK_DATATYPE_INT intData:1];
        return;
    }
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:{
            [self.myLocation requestLocationPermission:inArguments];
            return;
        }
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied: {
            // 当前程序未打开定位服务
            [self jsSuccessWithName:@"uexLocation.cbOpenLocation" opId:0  dataType:UEX_CALLBACK_DATATYPE_INT intData:1];
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
        
        [self jsSuccessWithName:@"uexLocation.cbGetAddress" opId:1 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:UEX_LOCALIZEDSTRING(@"无网络连接,请检查你的网络")];
        
    } else {
        [self.myLocation getAddressWithLot:inLongitude Lat:inLatitude];
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
        

        NSString *jsStr = [NSString stringWithFormat:@"if(uexLocation.cbGetBaiduFromGoogle!=null){uexLocation.cbGetBaiduFromGoogle(%f,%f)}",newCoordinate2D.longitude,newCoordinate2D.latitude];
        [EUtility brwView:self.meBrwView evaluateScript:jsStr];
    }
    
}
-(NSString*)convertLocation:(NSMutableArray *)inArguments{
    if (inArguments.count < 1) {
        return nil;
    }
    id info = [inArguments[0] JSONValue];
    double latitude = [[info objectForKey:@"latitude"] doubleValue];
    double longitude = [[info objectForKey:@"longitude"] doubleValue];
    CLLocationCoordinate2D LocationCoordinate2D;
    LocationCoordinate2D.longitude =longitude;
    LocationCoordinate2D.latitude = latitude;
    NSString *from = [[info objectForKey:@"from"] lowercaseString];
    NSString *to = [[info objectForKey:@"to"] lowercaseString];
    if ([from isEqual:@"wgs84"] && [to isEqual:@"gcj02"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter wgs84ToGcj02:LocationCoordinate2D];
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} JSONFragment];
    }
    if ([from isEqual:@"gcj02"] && [to isEqual:@"wgs84"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter gcj02ToWgs84:LocationCoordinate2D];
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} JSONFragment];
    }
    if ([from isEqual:@"wgs84"] && [to isEqual:@"bd09"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter wgs84ToBd09:LocationCoordinate2D];
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} JSONFragment];
    }
    if ([from isEqual:@"bd09"] && [to isEqual:@"wgs84"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter bd09ToWgs84:LocationCoordinate2D];
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} JSONFragment];
    }
    if ([from isEqual:@"bd09"] && [to isEqual:@"gcj02"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter bd09ToGcj02:LocationCoordinate2D];
        NSLog(@"%@",@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)});
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} JSONFragment];
    }
    if ([from isEqual:@"gcj02"] && [to isEqual:@"bd09"]) {
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter gcj02ToBd09:LocationCoordinate2D];
        return [@{@"latitude":@(newCoordinate2D.latitude),@"longitude":@(newCoordinate2D.longitude)} JSONFragment];
    }
    return nil;
}

- (void)uexLocationWithLot:(double)inLog Lat:(double)inLat {
    
    NSString *jsStr = [NSString stringWithFormat:@"if(uexLocation.onChange!=null){uexLocation.onChange(%f,%f)}",inLat,inLog];
    [EUtility brwView:self.meBrwView evaluateScript:jsStr];

    
}

//地址回调
- (void)uexLocationWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData {
    
    if (inData) {
        
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
                
                NSMutableDictionary * valueDic =[[array objectAtIndex:i] JSONValue];
                [jsonDict setValue:valueDic forKey:key];
                
            }
            
        }
        
        if (flage==1) {
            
            NSString *json=[jsonDict JSONFragment];
            
            [self jsSuccessWithName:@"uexLocation.cbGetAddress" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:json];
            
        } else {
            
            NSString *adr=[jsonDict objectForKey:@"formatted_address"];
            NSString *adrStr = [NSString stringWithFormat:@"uexLocation.cbGetAddress(\"%d\",\"%d\",\"%@\")",inOpId,inDataType,adr];
            
            [self.meBrwView stringByEvaluatingJavaScriptFromString:adrStr];
            
        }
        
    }
    
}


- (void)clean {
 
}

- (BOOL)isConnectionAvailable {
    
    Reachability *reach = [Reachability reachabilityWithHostName:@"www.apple.com"];
    
    return [reach isReachable];
    
}

@end
