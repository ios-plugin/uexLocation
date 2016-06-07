//
//  Location.m
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-14.
//  Copyright 2011 AppCan. All rights reserved.
//
#import "EUtility.h"
#import "uexLocationObject.h"
#import "EUExLocation.h"
#import "EUExBaseDefine.h"
#import "UexLocationJZLocationConverter.h"
#import "JSON.h"

@interface uexLocationObject()
@property (nonatomic,assign)BOOL requestedForPermission;
@property (nonatomic,strong)NSMutableArray *requestedArguments;
@end

@implementation uexLocationObject



- (id)initWithEuexObj:(EUExLocation *)euexObj_ {
    
    if (self = [super init]) {
        
        _euexObj = euexObj_;

    }
    
    return self;
    
}

- (CLLocationManager *)gps{
    if (!_gps) {
        _gps = [[CLLocationManager alloc] init];
        _gps.delegate = self;
    }
    return _gps;
}

- (void)requestPermissionThenOpenLocation:(NSMutableArray *)inArguments{
    CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion]floatValue];
    self.requestedForPermission = YES;
    if(systemVersion >= 8.0) {
        
        self.requestedArguments = inArguments;
        [self requestPermission];
    }else{
        [self openLocation:inArguments];
    }
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if (!self.requestedForPermission) {
        return;
    }
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            return;
        }
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied: {
            //[self.euexObj jsSuccessWithName:@"uexLocation.cbOpenLocation" opId:0  dataType:UEX_CALLBACK_DATATYPE_INT intData:1];
            [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbOpenLocation" arguments:ACArgsPack(@0,@2,@1)];
            [self.func executeWithArguments:ACArgsPack(@1)];
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion]floatValue];
            if(systemVersion >= 8.0){
                [self openLocation:self.requestedArguments];
            }else{
               // [self.euexObj jsSuccessWithName:@"uexLocation.cbOpenLocation" opId:0  dataType:UEX_CALLBACK_DATATYPE_INT intData:0];
                 [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbOpenLocation" arguments:ACArgsPack(@0,@2,@0)];
                [self.func executeWithArguments:ACArgsPack(@0)];
            }
            break;
        }
    }
    self.requestedForPermission = NO;
    self.requestedArguments = nil;
   
}



- (void)requestPermission{
    if ([self needBackgroundLocation]) {
        [self.gps requestAlwaysAuthorization];
    }else{
        [self.gps requestWhenInUseAuthorization];
    }
}

- (BOOL)needBackgroundLocation{
    BOOL backgroundLocation = NO;
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSArray *backgroundInfo = info[@"UIBackgroundModes"];
    if (backgroundInfo && [backgroundInfo containsObject:@"location"]) {
        backgroundLocation = YES;
    }
    return backgroundLocation;
}

- (void)openLocation:(NSMutableArray *)inArguments{
    

    CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion]floatValue];
    
    if(systemVersion >= 8.0) {
        [self requestPermission];
    }
    BOOL backgroundLocation = [self needBackgroundLocation];
    if (systemVersion >= 9.0 && backgroundLocation) {
        self.gps.allowsBackgroundLocationUpdates = YES;
    }
    
    if (inArguments.count == 2) {
        
        if ([inArguments[0] intValue] == 0) {
            
            self.gps.desiredAccuracy=kCLLocationAccuracyBest;
            
        }
        
        if ([inArguments[0] intValue] == 1) {
            
            self.gps.desiredAccuracy=kCLLocationAccuracyNearestTenMeters;
            
        }
        
        if ([inArguments[0] intValue]==2) {
            
            self.gps.desiredAccuracy=kCLLocationAccuracyHundredMeters;
            
        }
        
        if ([inArguments[0] intValue]==3) {
            
            self.gps.desiredAccuracy=kCLLocationAccuracyKilometer;
            
        }
        
        if ([inArguments[0] intValue]==4) {
            
            self.gps.desiredAccuracy=kCLLocationAccuracyThreeKilometers;
            
        }
        
        self.gps.distanceFilter=[inArguments[1] floatValue];
        
    } else {
        
        self.gps.desiredAccuracy = kCLLocationAccuracyBest;
        self.gps.distanceFilter = 3.0f;
        
    }
    
    
    
    
    [self.gps startUpdatingLocation];
    CLAuthorizationStatus newStatus =[CLLocationManager authorizationStatus];
    if (newStatus == kCLAuthorizationStatusAuthorizedAlways || newStatus ==kCLAuthorizationStatusAuthorizedWhenInUse) {
        //[self.euexObj jsSuccessWithName:@"uexLocation.cbOpenLocation" opId:0  dataType:UEX_CALLBACK_DATATYPE_INT intData:0];
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbOpenLocation" arguments:ACArgsPack(@0,@2,@0)];
        [self.func executeWithArguments:ACArgsPack(@0)];
    }
    
    
}

//******************************获取经纬度************************

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    NSString *locationStr0=[NSString stringWithFormat:@"%@",locations[0]];
    
    if ([locationStr0 length]>0) {
        
        NSArray  *locationAry0=[locationStr0 componentsSeparatedByString:@">"];
        NSString *locationStr1=[NSString stringWithFormat:@"%@",locationAry0[0]];
        NSString *locationStr2=[locationStr1 substringFromIndex:1];
        NSArray *locationAry1=[locationStr2 componentsSeparatedByString:@","];
        
        double lat=[[locationAry1 objectAtIndex:0] doubleValue];
        double log=[[locationAry1 objectAtIndex:1] doubleValue];
        
        CLLocationCoordinate2D LocationCoordinate2D;
        LocationCoordinate2D.longitude =log;
        LocationCoordinate2D.latitude = lat;
        
        //转成高德坐标系
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter wgs84ToGcj02:LocationCoordinate2D];
        [self.euexObj uexLocationWithLot:newCoordinate2D.longitude Lat:newCoordinate2D.latitude ];
        
        NSMutableDictionary *locationDict=[NSMutableDictionary dictionary];
        
        [locationDict setObject:[NSString stringWithFormat:@"%f",newCoordinate2D.latitude] forKey:@"lat"];
        [locationDict setObject:[NSString stringWithFormat:@"%f",newCoordinate2D.longitude] forKey:@"lng"];
        
        self.locationStr = [locationDict JSONFragment];
        
    } else {
        
        //[self.euexObj jsSuccessWithName:@"uexLocation.onChange" opId:1 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:UEX_LOCALIZEDSTRING(@"获取经纬度失败")];
        NSString *failedStr = UEX_LOCALIZEDSTRING(@"获取经纬度失败");
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbOpenLocation" arguments:ACArgsPack(@1,@0,failedStr)];
        [self.func executeWithArguments:ACArgsPack(failedStr)];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}


//******************************由经纬度获取地址************************
//ios6++

- (void)getAddressWithLot:(double)inLongitude Lat:(double)inLatitude {
    
    double lon = inLongitude;
    double lat = inLatitude;
    
    //判断版本
    /*
    if([[[UIDevice currentDevice]systemVersion] floatValue]<6.0) {
        
        [self startedReverseGeoderWithLatitude:lat longitude:lon];
        
    } else {
    */
    CLLocationCoordinate2D myCoOrdinate;
    myCoOrdinate.latitude = lat;
    myCoOrdinate.longitude = lon;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:myCoOrdinate.latitude longitude:myCoOrdinate.longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *array,NSError *error) {
        
        if (array.count > 0) {
            
            CLPlacemark *placemark = [array objectAtIndex:0];
            
            NSString *address =	@"";
            NSString *addressAll = @"";
            NSString *city = @"";
            NSString *getAddress=[NSString stringWithFormat:@"%@",placemark.country];
            
            if (KUEX_IS_NSString(placemark.administrativeArea)) {
                
                getAddress=[getAddress stringByAppendingString:placemark.administrativeArea];
                
            }
            
            if (KUEX_IS_NSString(placemark.subAdministrativeArea)) {
                
                getAddress=[getAddress stringByAppendingString:placemark.subAdministrativeArea];
                
            }
            
            if (KUEX_IS_NSString(placemark.locality)) {
                
                getAddress=[getAddress stringByAppendingString: placemark.locality];
                
            }
            
            if (KUEX_IS_NSString(placemark.subLocality)) {
                
                getAddress=[getAddress stringByAppendingString:placemark.subLocality];
                
            }
            
            if (KUEX_IS_NSString(placemark.thoroughfare)) {
                
                getAddress=[getAddress stringByAppendingString:placemark.thoroughfare];
                
            }
            
            if (KUEX_IS_NSString(placemark.subThoroughfare)) {
                
                getAddress=[getAddress stringByAppendingString:placemark.subThoroughfare];
                
            }
            
            if (KUEX_IS_NSString(placemark.locality)) {
                
                city = [NSString stringWithFormat:@"%@",placemark.locality];
                
            }
            
            if([self isBeiJingCity:placemark.administrativeArea]) {
                
                if (KUEX_IS_NSString(placemark.administrativeArea)) {
                    
                    city = [NSString stringWithFormat:@"%@",placemark.administrativeArea];
                    
                }
                
            }
            
            NSMutableDictionary *addressDict=[NSMutableDictionary dictionary];
            
            if(placemark.administrativeArea){
                
                [addressDict setObject:placemark.administrativeArea forKey:@"province"];
                
            }
            
            if (placemark.subThoroughfare) {
                
                [addressDict setObject:placemark.subThoroughfare forKey:@"street_number"];
                
            } else {
                
                [addressDict setObject:@"(null)" forKey:@"street_number"];
                
            }
            
            if (placemark.subLocality) {
                
                [addressDict setObject:placemark.subLocality forKey:@"district"];
                
            }
            
            if (placemark.thoroughfare) {
                
                [addressDict setObject:placemark.thoroughfare forKey:@"street"];
                
            }
            if (city) {
                
                [addressDict setObject:city forKey:@"city"];
                
            }
            
            address = [addressDict JSONFragment];
            addressAll = [NSString stringWithFormat:@"%@;%@;%@",getAddress,_locationStr,address];
            
            //对象是否实现了某个方法
            
            if(self.euexObj&&[self.euexObj respondsToSelector:@selector(uexLocationWithOpId:dataType:data:)]){
                
                [self.euexObj uexLocationWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:addressAll];

                
            }
            
        }
        
    }];
    
    //}
    
}
/*
- (void)startedReverseGeoderWithLatitude:(double)latitude longitude:(double)longitude {
 
    CLLocationCoordinate2D coordinate2D;
    coordinate2D.longitude = longitude;
    coordinate2D.latitude = latitude;
 
    MKReverseGeocoder *geoCoder = [[MKReverseGeocoder alloc] initWithCoordinate:coordinate2D];
 
    geoCoder.delegate = self;
 
    [geoCoder start];
 
}

//ios6--
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark {
    
    NSString *address =	@"";
    NSString *addressAll = @"";
    NSString *city = @"";
    
    NSString *getAddress=[NSString stringWithFormat:@"%@",placemark.country];
    
    if (KUEX_IS_NSString(placemark.administrativeArea)) {
        
        getAddress=[getAddress stringByAppendingString:placemark.administrativeArea];
        
    }
    
    if (KUEX_IS_NSString(placemark.subAdministrativeArea)) {
        
        getAddress=[getAddress stringByAppendingString:placemark.subAdministrativeArea];
        
    }
    
    if (KUEX_IS_NSString(placemark.locality)) {
        
        getAddress=[getAddress stringByAppendingString: placemark.locality];
        
    }
    
    if (KUEX_IS_NSString(placemark.subLocality)) {
        
        getAddress=[getAddress stringByAppendingString:placemark.subLocality];
        
    }
    
    if (KUEX_IS_NSString(placemark.thoroughfare)) {
        
        getAddress=[getAddress stringByAppendingString:placemark.thoroughfare];
        
    }
    
    if (KUEX_IS_NSString(placemark.subThoroughfare)) {
        
        getAddress=[getAddress stringByAppendingString:placemark.subThoroughfare];
        
    }
    
    if (KUEX_IS_NSString(placemark.locality)) {
        
        city = [NSString stringWithFormat:@"%@",placemark.locality];
        
    }
    
    if([self isBeiJingCity:placemark.administrativeArea]) {
        
        if (KUEX_IS_NSString(placemark.administrativeArea)) {
            
            city = [NSString stringWithFormat:@"%@",placemark.administrativeArea];
            
        }
        
    }
    
    NSMutableDictionary *addressDict=[NSMutableDictionary dictionary];
    
    if(placemark.administrativeArea){
        
        [addressDict setObject:placemark.administrativeArea forKey:@"province"];
        
    }
    
    if (placemark.subThoroughfare) {
        
        [addressDict setObject:placemark.subThoroughfare forKey:@"street_number"];
        
    } else {
        
        [addressDict setObject:@"(null)" forKey:@"street_number"];
        
    }
    
    if (placemark.subLocality) {
        
        [addressDict setObject:placemark.subLocality forKey:@"district"];
        
    }
    
    if (placemark.thoroughfare) {
        
        [addressDict setObject:placemark.thoroughfare forKey:@"street"];
        
    }
    
    if (city) {
        
        [addressDict setObject:city forKey:@"city"];
        
    }
    
    address = [addressDict JSONFragment];
    
    addressAll = [NSString stringWithFormat:@"%@;%@;%@",getAddress,_locationStr,address];
    
    if (euexObj&&[euexObj respondsToSelector:@selector(uexLocationWithOpId:dataType:data:)]) {
        
        [euexObj uexLocationWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:addressAll];
        
    }
    
}
*/
- (BOOL)isBeiJingCity:(NSString *)city {
    
    if ([city hasPrefix:UEX_LOCALIZEDSTRING(@"北京")]) {
        return YES;
    }
    if ([city hasPrefix:UEX_LOCALIZEDSTRING(@"上海")]) {
        return YES;
    }
    if ([city hasPrefix:UEX_LOCALIZEDSTRING(@"重庆")]) {
        return YES;
    }
    if ([city hasPrefix:UEX_LOCALIZEDSTRING(@"天津")]) {
        return YES;
    }
    
    return NO;
    
}

- (void)closeLocation {
    //NSLog(@"hui-->uexLocation-->Location-->closeLocation");
    [self.gps stopUpdatingLocation];

}


@end
