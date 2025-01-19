//
//  RotatingTabBarController.m
//  RacingTach
//
//  Created by Gérald GUIONY on 29/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RotatingTabBarController.h"

// ====================================================================================================================================
//
//	RotatingTabBarController implementation
//
// ====================================================================================================================================

@implementation RotatingTabBarController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

// ------------------------------------------------------------------------------------------------------------------------------------
// La vue peut elle se tourner ?
// Here's an extension to UITabBarController that delegates calls to shouldAutorotateToInterfaceOrientation to the currently selected
// child controller.
// ------------------------------------------------------------------------------------------------------------------------------------
-(BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	if ([self.selectedViewController isKindOfClass: [UINavigationController class]])
	{
		return [[(UINavigationController*) self.selectedViewController visibleViewController] shouldAutorotateToInterfaceOrientation: interfaceOrientation];
	}
	else
	{
		return [self.selectedViewController shouldAutorotateToInterfaceOrientation: interfaceOrientation];
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Surcharge
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Surcharge
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Désallocation
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) dealloc
{
    [super dealloc];
}

@end

// ====================================================================================================================================
//
//	RotatingViewController implementation
//
// ====================================================================================================================================

@implementation RotatingViewController

@synthesize allowRotation	= _allowRotation;

// ------------------------------------------------------------------------------------------------------------------------------------
// Surcharge
// ------------------------------------------------------------------------------------------------------------------------------------
-(BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
    return _allowRotation;
}

@end
