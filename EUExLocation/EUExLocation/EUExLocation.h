//
//  EUExLocation.h
//  AppCan
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "uexLocationObject.h"
#import "Reachability.h"
#import "UexLocationJZLocationConverter.h"

@interface EUExLocation : EUExBase

-(void)uexLocationWithLot:(double)inLog Lat:(double)inLat ;

-(void)uexLocationWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData;




@end
