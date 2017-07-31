//
//  EUExLocation.h
//  AppCan
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//
#import "EUExBase.h"
#import "uexLocationObject.h"
#import "Reachability.h"
#import "UexLocationJZLocationConverter.h"

@interface EUExLocation : EUExBase {
    
	double log;//经度
	double lat;//纬度
    
}

@property(nonatomic,assign)BOOL isJudgeLct;//是否拥有定位权限

-(void)uexLocationWithLot:(double)inLog Lat:(double)inLat ;

-(void)uexLocationWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData;




@end
