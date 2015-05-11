//
//  Location.h
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-14.
//  Copyright 2011 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class EUExLocation;

@interface Location : NSObject <CLLocationManagerDelegate,MKReverseGeocoderDelegate,MKMapViewDelegate>{
	EUExLocation *euexObj;
    CLLocationManager *gps;
}

@property(nonatomic,assign) EUExLocation *euexObj;
@property(nonatomic,retain) CLLocationManager *gps;
@property(nonatomic,retain) NSString *locationStr;

-(id)initWithEuexObj:(EUExLocation *)euexObj_;
-(void)getAddressWithLot:(NSString *)inLongitude Lat:(NSString *)inLatitude;
-(void)openLocation:(NSMutableArray *)inArguments;
-(void)closeLocation;
@end

