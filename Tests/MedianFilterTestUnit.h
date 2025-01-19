//
//  MedianFilterTestUnit.h
//  RacingTach
//
//  Created by Gérald GUIONY on 27/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

//  Dependent unit tests mean unit test code depends on an application to be injected into.
//  Setting this to 0 means the unit test code is designed to be linked into an independent executable.

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>

//#import "application_headers" as required
#import "MedianFilter.h"

@interface MedianFilterTestUnit : SenTestCase 
{
}


@end
