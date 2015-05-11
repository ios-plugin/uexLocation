//
//  Location.m
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-14.
//  Copyright 2011 AppCan. All rights reserved.
//
#import "EUtility.h"
#import "Location.h"
#import "SVGeocoder.h"
#import "EUExLocation.h"
#import "EUExBaseDefine.h"
#import "JZLocationConverter.h"
#import "JSON.h"
@implementation Location
@synthesize gps;
@synthesize euexObj;


-(id)initWithEuexObj:(EUExLocation *)euexObj_{
    euexObj = euexObj_;
    return self;
}
-(void)openLocation:(NSMutableArray *)inArguments{
    if (!gps) {
        gps = [[CLLocationManager alloc] init];
#ifdef __IPHONE_8_0
        if([[[UIDevice currentDevice] systemVersion]floatValue]>=8.0){
            [gps requestWhenInUseAuthorization];
            
        }
#endif
        if (inArguments.count==2) {
            if ([inArguments[0] intValue]==0) {
                gps.desiredAccuracy=kCLLocationAccuracyBest;
            }
            
            if ([inArguments[0] intValue]==1) {
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
        }
        else{
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
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
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
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations{
    
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
        
    }
    else{
        [euexObj jsSuccessWithName:@"uexLocation.onChange" opId:1 dataType:UEX_CALLBACK_DATATYPE_TEXT strData:@"获取经纬度失败"];
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    
}
-(void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error{
    
}
//******************************由经纬度获取地址************************
//ios6++

-(void)getAddressWithLot:(NSString *)inLongitude Lat:(NSString *)inLatitude
{
    double lon = [inLongitude doubleValue];
    double lat =[inLatitude doubleValue];
    //判断版本
    if([[[UIDevice currentDevice]systemVersion] floatValue]<6.0)
    {
        [self startedReverseGeoderWithLatitude:lat longitude:lon];
    }else{
        CLLocationCoordinate2D myCoOrdinate;
        myCoOrdinate.latitude = lat;
        myCoOrdinate.longitude = lon;
        CLLocation *location = [[CLLocation alloc] initWithLatitude:myCoOrdinate.latitude longitude:myCoOrdinate.longitude];
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *array,NSError *error) {
            
            if (array.count > 0) {
                
                CLPlacemark *placemark = [array objectAtIndex:0];
                NSString *address =	nil;
                NSString *formattedAddress = nil;
                NSString *addressAll = nil;
                NSString *city = nil;
                formattedAddress = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@",
                                    placemark.country,
                                    placemark.ISOcountryCode,
                                    placemark.administrativeArea,
                                    placemark.subAdministrativeArea,
                                    placemark.locality,
                                    placemark.subLocality,
                                    placemark.thoroughfare,
                                    placemark.subThoroughfare,
                                    placemark.name];
               
                formattedAddress = [self getFormattedAddress:formattedAddress];
                
//                city = [NSString stringWithFormat:@"%@",placemark.subAdministrativeArea];
                city = [NSString stringWithFormat:@"%@",placemark.locality];
                
                 if([self isBeiJingCity:placemark.administrativeArea]) {
                    city = [NSString stringWithFormat:@"%@",placemark.administrativeArea];
                 }
                
                 NSMutableDictionary *addressDict=[NSMutableDictionary dictionary];
                if(placemark.administrativeArea){
                    [addressDict setObject:placemark.administrativeArea forKey:@"province"];
                }
                if (placemark.subThoroughfare) {
                    [addressDict setObject:placemark.subThoroughfare forKey:@"street_number"];
                }
                else{
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
                
                addressAll = [NSString stringWithFormat:@"%@;%@;%@",formattedAddress,_locationStr,address];
                [euexObj uexLocationWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:addressAll];
            }
        }];
        [geocoder release];
        [location release];
    }
}
-(void) startedReverseGeoderWithLatitude:(double)latitude longitude:(double)longitude{
    
    CLLocationCoordinate2D coordinate2D;
    coordinate2D.longitude = longitude;
    coordinate2D.latitude = latitude;
    MKReverseGeocoder *geoCoder = [[MKReverseGeocoder alloc] initWithCoordinate:coordinate2D];
    geoCoder.delegate = self;
    [geoCoder start];
    
}

//ios6--
-(void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark
{
    NSString *address =	nil;
    NSString *formattedAddress = nil;
    NSString *addressAll = nil;
    NSString *city = nil;
    
    formattedAddress = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@",
               placemark.country,
               placemark.countryCode,
               placemark.administrativeArea,
               placemark.subAdministrativeArea,
               placemark.locality,
               placemark.subLocality,
               placemark.thoroughfare,
               placemark.subThoroughfare];
    formattedAddress = [self getFormattedAddress:formattedAddress];
    
    city = [NSString stringWithFormat:@"%@",placemark.subAdministrativeArea];
    if ([city isEqualToString:@"(null)"]) {
        
        city = [NSString stringWithFormat:@"%@",placemark.administrativeArea];
    }
    NSMutableDictionary *addressDict=[NSMutableDictionary dictionary];
    if(placemark.administrativeArea){
        [addressDict setObject:placemark.administrativeArea forKey:@"province"];
    }
    if (placemark.subThoroughfare) {
        [addressDict setObject:placemark.subThoroughfare forKey:@"street_number"];
    }
    else{
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
    
    addressAll = [NSString stringWithFormat:@"%@;%@;%@",formattedAddress,_locationStr,address];
    [euexObj uexLocationWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:addressAll];
}

-(NSString *)getFormattedAddress:(NSString *)str {
    
    NSString *getAddress=nil;
    if (str) {
        NSMutableArray *array=(NSMutableArray *)[str componentsSeparatedByString:@","];
        NSMutableDictionary *jsonDict=[NSMutableDictionary dictionary];
        NSArray *arrayKey=[NSArray arrayWithObjects:@"country",@"countryCode",@"administrativeArea",@"subAdministrativeArea",@"locality",@"subLocality",@"thoroughfare",@"subThoroughfare",@"name" ,nil];
        for (int i=0;i<[array count] ; i++) {
            NSString *value=[NSString stringWithFormat:@"%@",[array objectAtIndex:i]];
            NSString *key=[NSString stringWithFormat:@"%@",[arrayKey objectAtIndex:i]];
            [jsonDict setValue:value forKey:key];
        }
            NSString *country=[jsonDict objectForKey:@"country"];
            NSString *administrativeArea=[jsonDict objectForKey:@"administrativeArea"];
            NSString *subAdministrativeArea=[jsonDict objectForKey:@"subAdministrativeArea"];
            NSString *locality=[jsonDict objectForKey:@"locality"];
            NSString *subLocality=[jsonDict objectForKey:@"subLocality"];
            NSString *thoroughfare=[jsonDict objectForKey:@"thoroughfare"];
            NSString *subThoroughfare=[jsonDict objectForKey:@"subThoroughfare"];
            
            getAddress=[NSString stringWithFormat:@"%@",country];
            
            if (![administrativeArea isEqualToString:@"(null)"]) {
                getAddress=[getAddress stringByAppendingString:administrativeArea];
            }
            if (![subAdministrativeArea isEqualToString:@"(null)"]) {
                getAddress=[getAddress stringByAppendingString:subAdministrativeArea];
            }
            if (![locality isEqualToString:@"(null)"]) {
                getAddress=[getAddress stringByAppendingString:locality];
            }
            if (![subLocality isEqualToString:@"(null)"]) {
                getAddress=[getAddress stringByAppendingString:subLocality];
            }
            if (![thoroughfare isEqualToString:@"(null)"]) {
                getAddress=[getAddress stringByAppendingString:thoroughfare];
            }
            if (![subThoroughfare isEqualToString:@"(null)"]) {
                getAddress=[getAddress stringByAppendingString:subThoroughfare];
            }
        }
    
    return getAddress;
}
- (BOOL)isBeiJingCity:(NSString *)city {
    
    if ([city hasPrefix:@"北京"]) {
        return YES;
    }
    if ([city hasPrefix:@"上海"]) {
        return YES;
    }
    if ([city hasPrefix:@"重庆"]) {
        return YES;
    }
    if ([city hasPrefix:@"天津"]) {
        return YES;
    }
    return NO;
    
}
-(void)closeLocation{
    NSLog(@"hui-->uexLocation-->Location-->closeLocation");
    if (gps) {
        [gps stopUpdatingLocation];
        [gps release];
        gps = nil;
    }
}
-(void)delloc{
    NSLog(@"hui-->uexLocation-->Location-->delloc");
    if (gps) {
        [gps stopUpdatingLocation];
        [gps release];
        gps = nil;
    }
    [_locationStr release];
    _locationStr = nil;
    
    [super dealloc];
}
@end
