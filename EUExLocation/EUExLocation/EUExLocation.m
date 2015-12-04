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

@property (nonatomic, strong) Location *myLocation;

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

    if ([CLLocationManager locationServicesEnabled]) {
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            
            // 当前程序未打开定位服务
            [self jsSuccessWithName:@"uexLocation.cbOpenLocation" opId:0  dataType:UEX_CALLBACK_DATATYPE_INT intData:1];
            
            return;
            
        }
        
    }
    
    _myLocation = [[Location alloc] initWithEuexObj:self];
    
    [_myLocation openLocation:inArguments];
    
}

- (void)closeLocation:(NSMutableArray *)inArguments {
    
    if (_myLocation) {
        
        [_myLocation closeLocation];
        
    }
    
}

- (void)getAddress:(NSMutableArray *)inArguments {
    
    NSString *inLatitude = [inArguments objectAtIndex:0];
    NSString *inLongitude = [inArguments objectAtIndex:1];
    
    if ([inArguments count]>2) {
        
        flage=[[inArguments objectAtIndex:2]intValue];
        
    }
    
    if (-90<[inLatitude intValue]<90||-180<[inLongitude intValue]<180) {
        
        if (![self isConnectionAvailable]){
            
            [self jsSuccessWithName:@"uexLocation.cbGetAddress" opId:1 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:UEX_LOCALIZEDSTRING(@"无网络连接,请检查你的网络")];
            
        } else {
            
            [_myLocation getAddressWithLot:inLongitude Lat:inLatitude];
            
        }
        
    } else {
        
        [self jsFailedWithOpId:0 errorCode:1120201 errorDes:UEX_ERROR_DESCRIBE_ARGS];
        
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
        CLLocationCoordinate2D newCoordinate2D=[JZLocationConverter gcj02ToBd09:LocationCoordinate2D];
        
        NSString *jsStr = [NSString stringWithFormat:@"if(uexLocation.cbGetBaiduFromGoogle!=null){uexLocation.cbGetBaiduFromGoogle(%f,%f)}",newCoordinate2D.longitude,newCoordinate2D.latitude];
        
        [self.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
        
    }
    
}

- (void)uexLocationWithLot:(double)inLog Lat:(double)inLat {
    
    NSString *jsStr = [NSString stringWithFormat:@"if(uexLocation.onChange!=null){uexLocation.onChange(%f,%f)}",inLat,inLog];
    
    [self.meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
    
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
