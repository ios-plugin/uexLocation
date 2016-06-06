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
#define KUEX_IS_NSString(x) ([x isKindOfClass:[NSString class]] && x.length>0&&(![x isEqualToString:@"(null)"]))

@class EUExLocation;

@interface uexLocationObject : NSObject <CLLocationManagerDelegate>


@property(nonatomic, weak) EUExLocation *euexObj;

@property(nonatomic, strong) CLLocationManager *gps;

@property(nonatomic, strong) NSString *locationStr;

@property(nonatomic,strong)ACJSFunctionRef *func;

-(id)initWithEuexObj:(EUExLocation *)euexObj_;

-(void)getAddressWithLot:(double)inLongitude Lat:(double)inLatitude;

-(void)openLocation:(NSMutableArray *)inArguments;

-(void)closeLocation;

- (void)requestPermissionThenOpenLocation:(NSMutableArray *)inArguments;

@end

