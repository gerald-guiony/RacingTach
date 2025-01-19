//
//  RacingTachAppDelegate.m
//  RacingTach
//
//  Created by Gérald GUIONY on 25/01/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RacingTachAppDelegate.h"

#import "TachometerAudioSignal.h"
#import "SetupViewController.h"
#import "GLViewControllerAnimated.h"
#import "GLViewControllerFrequenceAudioCurve.h"
#import "GLViewControllerTachometerAudioSignal.h"


#define kFirstRunKey			@"FirstRunKey"
#define kSparksPerRevKey		@"SparksPerRevKey"
#define kLowRPMKey				@"LowRPMKey"
#define kHighRPMKey				@"HighRPMKey"
#define kFundVsHarmonicPercent	@"FundVsHarmonicPercent"
#define kShiftLightRPMKey		@"ShiftLightRPMKey"
#define kShiftLightSoundKey		@"ShiftLightSoundKey"



@implementation RacingTachAppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

// ------------------------------------------------------------------------------------------------------------------------------------
// Lorsque l'application a finie de se charger cette méthode est appelée
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) applicationDidFinishLaunching: (UIApplication *)application
{
	// -------------------------------------------------------------------------
	// Restauration des préférences utilisateur
	// -------------------------------------------------------------------------

	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];

	// -------------------------------------------------------------------------
	// Création du compte tours audio
	// -------------------------------------------------------------------------

	// NO is returned if no value is associated (first time) ...
	if ([prefs boolForKey: kFirstRunKey] == NO)
	{
		// First run
		_tachoAudioSignal = [[TachometerAudioSignal alloc] init];
	}
	else
	{
		// Second run and others ...
		_tachoAudioSignal = [[TachometerAudioSignal alloc] initWithSparksPerRev: [prefs floatForKey: kSparksPerRevKey]
																	  andLowRPM: [prefs integerForKey: kLowRPMKey]
																	 andHighRPM: [prefs integerForKey: kHighRPMKey]
													   andFundVsHarmonicPercent: [prefs integerForKey: kFundVsHarmonicPercent]
															   andShiftLightRPM: [prefs integerForKey: kShiftLightRPMKey]
															 andShiftLightSound: [prefs boolForKey: kShiftLightSoundKey]];
	}

	// -------------------------------------------------------------------------
	// Les vues et contolleurs
	// -------------------------------------------------------------------------

	// http://sens2.noblogs.org/gallery/5715/15906482-Manning-iPhone-in-Action-Introduction-to-Web-and-SDK-Development-2008.pdf

	// Taille de l'écran
	CGRect rect = [[UIScreen mainScreen] bounds];

	// La vue OpenGL
	_glView = [[GLView alloc] initWithFrame: rect];
	_glView.animationInterval = 1.0 / kRenderingFrequency;

	// Les controlleurs OpenGL
	//_curveViewController = [[[GLViewControllerAutoCorrelationSampleCurve alloc] initWithTachAudio: tachoAudioSignal] autorelease];
	_tachoViewController = [[[GLViewControllerTachometerAudioSignal alloc] initWithTachAudio: _tachoAudioSignal] autorelease];
	_curveViewController = [[[GLViewControllerFrequenceAudioCurve alloc] initWithTachAudio: _tachoAudioSignal] autorelease];

	// Le controlleur de la vue 'setupView' avec chargement du fichier Nib 'setupView.xib' (Interface Builder) :
	_setupViewController = [[[SetupViewController alloc] initWithNibName: @"SetupView"
																  bundle: nil
															   tachAudio: _tachoAudioSignal] autorelease];
	_setupViewController.allowRotation = YES;

	// Les titres des tabBarItem des controlleurs
	_tachoViewController.tabBarItem.title = @"RPM";
	_curveViewController.tabBarItem.title = @"Signal";
	_setupViewController.tabBarItem.title = @"Settings";

	// Les images des tabBarItem
	_tachoViewController.tabBarItem.image = [UIImage imageNamed: @"IcoTacho.png"];
	_curveViewController.tabBarItem.image = [UIImage imageNamed: @"IcoSignal.png"];
	_setupViewController.tabBarItem.image = [UIImage imageNamed: @"IcoSettings.png"];

	// Affectation du controlleur de la vue
	_glView.controller = _tachoViewController;

	// Affectation de la vue openGL aux controlleurs
	_tachoViewController.view = _glView;
	_curveViewController.view = _glView;

	// -------------------------------------------------------------------------
	// Le tab bar controlleur
	// -------------------------------------------------------------------------

	// Création du tabBar en 'manuel' (sans utiliser Interface Builder) car sinon impossible d'affecter des controller 'GLViewController'
	// sur les vues openGL du tabBar
	_tabBarController = [[RotatingTabBarController alloc] init];
	_tabBarController.customizableViewControllers = nil;
	// Assign the tab bar controller’s delegate object.
	[_tabBarController setDelegate: self];

	// The array of the root view controllers displayed by the tab bar interface
	_tabBarController.viewControllers = [NSArray arrayWithObjects: _tachoViewController, _curveViewController, _setupViewController, nil];

	// Sélection du premier Tab
	_tabBarController.selectedViewController = _tachoViewController;

	// -------------------------------------------------------------------------
	// Affichage de la fenêtre principale
	// -------------------------------------------------------------------------

	// adds the tab bar's view property to the window
	[_window addSubview: _tabBarController.view];

	// Override point for customization after application launch
    [_window makeKeyAndVisible];	// makes the window visible
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Fuck JailBreak
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) byeBye
{
	// Bousillage des préférences utilisateur ...
	// [[NSUserDefaults standardUserDefaults] removeObjectForKey: kSparksPerRevKey];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Tells the delegate when the application is about to terminate.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) applicationWillTerminate: (UIApplication *)application
{
	if ([_tabBarController.selectedViewController isKindOfClass: [GLViewControllerAnimated class]])
	{
		// Arrete le timer d'affichage ...
		[(GLViewControllerAnimated *)_tabBarController.selectedViewController stopAnimation];
	}

	// Mise en veille ON de l'iphone (par défaut ?)
	[UIApplication sharedApplication].idleTimerDisabled = NO;

	// Sauvegarde des préférences utilisateur
	NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];

	[prefs setBool: YES forKey: kFirstRunKey];
	[prefs setFloat: _tachoAudioSignal.sparksPerRev forKey: kSparksPerRevKey];
	[prefs setInteger: _tachoAudioSignal.lowRPM forKey: kLowRPMKey];
	[prefs setInteger: _tachoAudioSignal.highRPM forKey: kHighRPMKey];
	[prefs setInteger: _tachoAudioSignal.fundVsHarmonicPercent forKey: kFundVsHarmonicPercent];
	[prefs setInteger: _tachoAudioSignal.shiftLightRPM forKey: kShiftLightRPMKey];
	[prefs setBool: _tachoAudioSignal.shiftLightSound forKey: kShiftLightSoundKey];

	[prefs synchronize];

	// -------------------------------------------------------------------------
	// Protection contre le piratage
	// -------------------------------------------------------------------------
	NSBundle * bundle = [NSBundle mainBundle];
	NSDictionary * info = [bundle infoDictionary];
	if ([info objectForKey: @"SignerIdentity"] == nil)
	{
		/*
		UIAlertView * alert = [[UIAlertView alloc] init];
		alert.delegate = self;
		[alert setTitle: @"Attention !"];
		[alert setMessage: @"Vous utilisez un iphone jailbreaké. L'application, pour des raisons de sécurité, ne se lancera plus !"];
		[alert addButtonWithTitle: @"Ok"];
		[alert show];
		[alert release];
		*/
		[self byeBye];
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions
// (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background
// state. Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method
// to pause the game.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) applicationWillResignActive: (UIApplication *)application
{
	if ([_tabBarController.selectedViewController isKindOfClass: [GLViewControllerAnimated class]])
	{
		// Arrete le timer d'affichage ...
		[(GLViewControllerAnimated *)_tabBarController.selectedViewController stopAnimation];
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to
// restore your application to its current state in case it is terminated later.
// If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) applicationDidEnterBackground: (UIApplication *)application
{
	[self applicationWillTerminate: application];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Called as part of transition from the background to the inactive state: here you can undo many of the changes made on entering the
// background.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) applicationWillEnterForeground: (UIApplication *)application
{
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the
// background, optionally refresh the user interface.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) applicationDidBecomeActive: (UIApplication *)application
{
	if ([_tabBarController.selectedViewController isKindOfClass: [GLViewControllerAnimated class]])
	{
		// Redemarre le timer d'affichage ...
		[(GLViewControllerAnimated *)_tabBarController.selectedViewController startAnimation];
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Optional UITabBarControllerDelegate method
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) tabBarController: (UITabBarController *)tabBarController didSelectViewController: (UIViewController *)viewController
{
	/*
	if ([_lastViewController isKindOfClass: [GLViewControllerAnimated class]])
	{
		// Arrete le timer d'affichage ...
		[(GLViewControllerAnimated *)_lastViewController stopAnimation];
	}
	else if (_lastViewController == _setupViewController)
	{
		[_setupViewController updateTachometerWithFields];
	}

	if ([viewController isKindOfClass: [GLViewControllerAnimated class]])
	{
		// Affectation du controlleur à la vue
		_glView.controller = (GLViewControllerAnimated *)viewController;

		// Réinitialise les dimentions du viewport par rapport à l'éventuelle rotation précédente de la fenetre
		[(GLViewControllerAnimated *)viewController setupView: nil];

		// Démarre le timer d'affichage
		[(GLViewControllerAnimated *)viewController startAnimation];
	}
	// Pour les autres controlleurs
	else if (viewController == _setupViewController)
	{
		[_setupViewController updateFieldsWithTachometer];
	}

	_lastViewController = viewController;
	*/
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Optional UITabBarControllerDelegate method
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) tabBarController: (UITabBarController *)tabBarController didEndCustomizingViewControllers: (NSArray *)viewControllers changed: (BOOL)changed
{
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Désallocation
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) dealloc
{
	//[_glView release];
	[_tachoAudioSignal release];
    [_tabBarController release];
    [_window release];

    [super dealloc];
}

@end

