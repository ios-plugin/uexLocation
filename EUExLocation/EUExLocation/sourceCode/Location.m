//
//  Location.m
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-14.
//  Copyright 2011 AppCan. All rights reserved.
//
#import "EUtility.h"
#import "Location.h"
//#import "SVGeocoder.h"
#import "EUExLocation.h"
#import "EUExBaseDefine.h"
#import "JZLocationConverter.h"
#import "JSON.h"

@implementation Location
@synthesize gps;
@synthesize euexObj;


- (id)initWithEuexObj:(EUExLocation *)euexObj_ {
    
    if (self = [super init]) {
        
        euexObj = euexObj_;

    }
    
    return self;
    
}

- (void)openLocation:(NSMutableArray *)inArguments {
    
    if (!gps) {
        
        gps = [[CLLocationManager alloc] init];
        
        CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion]floatValue];
        
        if(systemVersion >= 8.0) {
            
            //[gps requestWhenInUseAuthorization];
            [gps requestAlwaysAuthorization];
            
        }
        BOOL backgroundLocation = NO;
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSArray *backgroundInfo = info[@"UIBackgroundModes"];
        if (backgroundInfo && [backgroundInfo containsObject:@"location"]) {
            backgroundLocation = YES;
        }
        if (systemVersion >= 9.0 && backgroundLocation) {
            gps.allowsBackgroundLocationUpdates = YES;
        }
        
        

        if (inArguments.count == 2) {
            
            if ([inArguments[0] intValue] == 0) {
                
                gps.desiredAccuracy=kCLLocationAccuracyBest;
                
            }
            
            if ([inArguments[0] intValue] == 1) {
                
                gps.desiredAccuracy=kCLLocationAccuracyNearestTenMeters;
                
            }
            
            if ([inArguments[0] intValue]==2) {
                
                gps.desiredAccuracy=kCLLocationAccuracyHundredMeters;
                
            }
            
            if ([inArguments[0] intValue]==3) {
                
                gps.desiredAccuracy=kCLLocationAccuracyKilometer;
                
            }
            
            if ([inArguments[0] intValue]==4) {
                
                gps.desiredAccuracy=kCLLocationAccuracyThreeKilometers;
                
            }
            
            gps.distanceFilter=[inArguments[1] floatValue];
            
        } else {
            
            gps.desiredAccuracy = kCLLocationAccuracyBest;
            gps.distanceFilter = 3.0f;
            
        }
        
    }
    
    gps.delegate = self;
    
    [gps startUpdatingLocation];
    
    [euexObj jsSuccessWithName:@"uexLocation.cbOpenLocation" opId:0  dataType:UEX_CALLBACK_DATATYPE_INT intData:0];
    
}

//******************************获取经纬度************************
//ios6--
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    CLLocationCoordinate2D coordinate2D;
    coordinate2D.longitude = newLocation.coordinate.longitude;
    coordinate2D.latitude = newLocation.coordinate.latitude;
    
    //转成高德坐标系
    CLLocationCoordinate2D newCoordinate2D=[JZLocationConverter wgs84ToGcj02:coordinate2D];
    
    [euexObj uexLocationWithLot:newCoordinate2D.longitude Lat:newCoordinate2D.latitude ];
    
    NSMutableDictionary *locationDict=[NSMutableDictionary dictionary];
    
    [locationDict setObject:[NSString stringWithFormat:@"%f",newCoordinate2D.latitude] forKey:@"lat"];
    [locationDict setObject:[NSString stringWithFormat:@"%f",newCoordinate2D.longitude] forKey:@"lng"];
    
    self.locationStr = [locationDict JSONFragment];
    
}

//ios6++
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
        CLLocationCoordinate2D newCoordinate2D=[JZLocationConverter wgs84ToGcj02:LocationCoordinate2D];
        [euexObj uexLocationWithLot:newCoordinate2D.longitude Lat:newCoordinate2D.latitude ];
        
        NSMutableDictionary *locationDict=[NSMutableDictionary dictionary];
        
        [locationDict setObject:[NSString stringWithFormat:@"%f",newCoordinate2D.latitude] forKey:@"lat"];
        [locationDict setObject:[NSString stringWithFormat:@"%f",newCoordinate2D.longitude] forKey:@"lng"];
        
        self.locationStr = [locationDict JSONFragment];
        
    } else {
        
        [euexObj jsSuccessWithName:@"uexLocation.onChange" opId:1 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:UEX_LOCALIZEDSTRING(@"获取经纬度失败")];
        
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error {
    
}

//******************************由经纬度获取地址************************
//ios6++

- (void)getAddressWithLot:(NSString *)inLongitude Lat:(NSString *)inLatitude {
    
    double lon = [inLongitude doubleValue];
    double lat =[inLatitude doubleValue];
    
    //判断版本
    if([[[UIDevice currentDevice]systemVersion] floatValue]<6.0) {
        
        [self startedReverseGeoderWithLatitude:lat longitude:lon];
        
    } else {
        
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
                
                if(euexObj&&[euexObj respondsToSelector:@selector(uexLocationWithOpId:dataType:data:)]){
                    
                    [euexObj uexLocationWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:addressAll];
                    
                }
                
            }
            
        }];
        
    }
    
}

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
    
    if (gps) {
        
        [gps stopUpdatingLocation];
 
    }
}


@end
