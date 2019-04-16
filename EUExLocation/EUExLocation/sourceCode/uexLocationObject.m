//
//  Location.m
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-14.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "uexLocationObject.h"
#import "EUExLocation.h"
#import "UexLocationJZLocationConverter.h"


@interface uexLocationObject()
@property (nonatomic,assign)BOOL requestedForPermission;
@property (nonatomic,strong)NSMutableArray *requestedArguments;
@property (nonatomic,strong)NSString *type;
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
            [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbOpenLocation" arguments:ACArgsPack(@0,@2,@1)];
            [self.func executeWithArguments:ACArgsPack(@(-1))];
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion]floatValue];
            if(systemVersion >= 8.0){
                [self openLocation:self.requestedArguments];
            }else{
                [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.cbOpenLocation" arguments:ACArgsPack(@0,@2,@0)];
                [self.func executeWithArguments:ACArgsPack(@(0))];
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
    ACArgsUnpack(NSString *type) = inArguments;
    self.type = type?[type lowercaseString]:nil;
    
    CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion]floatValue];
    
    if(systemVersion >= 8.0) {
        [self requestPermission];
    }
    BOOL backgroundLocation = [self needBackgroundLocation];
    if (systemVersion >= 9.0 && backgroundLocation) {
        self.gps.allowsBackgroundLocationUpdates = YES;
    }
    
    self.gps.desiredAccuracy = kCLLocationAccuracyBest;
    self.gps.distanceFilter = 3.0f;//更新距离
    
    [self.gps startUpdatingLocation];
    CLAuthorizationStatus newStatus = [CLLocationManager authorizationStatus];
    if (newStatus == kCLAuthorizationStatusAuthorizedAlways || newStatus ==kCLAuthorizationStatusAuthorizedWhenInUse) {
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
        //世界标准地理坐标转成高德坐标系
        CLLocationCoordinate2D newCoordinate2D=[UexLocationJZLocationConverter wgs84ToGcj02:LocationCoordinate2D];
        //世界标准地理坐标转化为百度坐标系
        if ([self.type isEqualToString:@"bd09"]) {
            newCoordinate2D = [UexLocationJZLocationConverter wgs84ToBd09:LocationCoordinate2D];
        }
        //世界标准地理坐标
        if ([self.type isEqualToString:@"wgs84"]) {
            newCoordinate2D = LocationCoordinate2D;
        }
        [self.euexObj uexLocationWithLot:newCoordinate2D.longitude Lat:newCoordinate2D.latitude ];
        NSMutableDictionary *locationDict=[NSMutableDictionary dictionary];
        [locationDict setObject:[NSString stringWithFormat:@"%f",newCoordinate2D.latitude] forKey:@"lat"];
        [locationDict setObject:[NSString stringWithFormat:@"%f",newCoordinate2D.longitude] forKey:@"lng"];
        self.locationStr = [locationDict ac_JSONFragment];
        
    } else {
        NSString *failedStr = UEX_LOCALIZEDSTRING(@"获取经纬度失败");
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexLocation.onChange" arguments:ACArgsPack(@1,@0,failedStr)];
        
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}



- (void)getAddressWithLot:(double)inLongitude Lat:(double)inLatitude {
    
    double lon = inLongitude;
    double lat = inLatitude;

    CLLocationCoordinate2D myCoOrdinate;
    myCoOrdinate.latitude = lat;
    myCoOrdinate.longitude = lon;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:myCoOrdinate.latitude longitude:myCoOrdinate.longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *array,NSError *error) {
        NSLog(@"array:%@",array);
        if (array.count > 0) {
            
            CLPlacemark *placemark = [array objectAtIndex:0];
            NSString *city = placemark.locality;
            if([self isBeiJingCity:placemark.administrativeArea]){
                city = placemark.administrativeArea;
            }
            NSMutableString *resultAddress = [NSMutableString string];
            [resultAddress appendString:placemark.country];
            [resultAddress appendString:placemark.administrativeArea];
            [resultAddress appendString:placemark.subAdministrativeArea];
            [resultAddress appendString:placemark.locality];
            [resultAddress appendString:placemark.subLocality];
            [resultAddress appendString:placemark.thoroughfare];
            [resultAddress appendString:placemark.subThoroughfare];
            NSMutableDictionary *addressDict=[NSMutableDictionary dictionary];
            [addressDict setValue:placemark.administrativeArea forKey:@"province"];
            [addressDict setValue:placemark.subThoroughfare forKey:@"street_number"];
            [addressDict setValue:placemark.thoroughfare forKey:@"street"];
            [addressDict setValue:city forKey:@"city"];
            NSString *address = [addressDict ac_JSONFragment];
            NSString *addressAll = [NSString stringWithFormat:@"%@;%@;%@",resultAddress,_locationStr,address];
            
            if([self.euexObj respondsToSelector:@selector(uexLocationWithOpId:dataType:data:)]){
                [self.euexObj uexLocationWithOpId:0 dataType:2 data:addressAll];
            }
            
        }
        
    }];
}
- (BOOL)isBeiJingCity:(NSString *)city {
    for (NSString *aCity in @[@"北京",@"上海",@"重庆",@"天津"]){
        if ([city hasPrefix:UEX_LOCALIZEDSTRING(aCity)]) {
            return YES;
        }
    }
    return NO;
    
}

- (void)closeLocation {
    [self.gps stopUpdatingLocation];
    
}


@end
