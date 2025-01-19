//
//  RacingTachAppDelegate.h
//  RacingTach
//
//  Created by Gérald GUIONY on 25/01/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GLView;
@class GLViewControllerAnimated;
@class SetupViewController;
@class TachometerAudioSignal;

// ------------------------------------------------------------------------------------------------------------------------------------
// L'application delegate 
// ------------------------------------------------------------------------------------------------------------------------------------
@interface RacingTachAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> 
{
    UIWindow * 					_window;
    UITabBarController *		_tabBarController;
	
	// La vue OpenGL
	GLView *					_glView;
	
	// Les controlleurs associés au TabBar
	GLViewControllerAnimated *	_tachoViewController;
	GLViewControllerAnimated *	_curveViewController;
	SetupViewController *		_setupViewController;
	
	// Le compte-tours audio
	TachometerAudioSignal *		_tachoAudioSignal;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Accesseurs
// ------------------------------------------------------------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UIWindow *	window;
@property (nonatomic, retain) UITabBarController *	tabBarController;

@end
