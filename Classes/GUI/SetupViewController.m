//
//  SetupViewController.m
//  RacingTach
//
//  Created by Gérald GUIONY on 13/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SetupViewController.h"
#import "TachometerAudioSignal.h"

#define RPM_SLIDER_STEP_PRECISION		 100
#define RPM_SLIDER_STEP_MINMAX 			 1000
#define RPM_SLIDER_RANGE				 10000

#define HEIGHT_VIEW_ORIENTATION_PORTRAIT 600


// ------------------------------------------------------------------------------------------------------------------------------------
// Les méthodes privées de cette classe ...
// ------------------------------------------------------------------------------------------------------------------------------------
@interface SetupViewController (private)

+(BOOL) isInteger: (NSString *)text;
+(BOOL) isDecimal: (NSString *)text;

+(UInt32) sliderStepValue: (UISlider *)slider andStep: (UInt16)step;
+(void) sliderMinMaxUpdate: (UISlider *)slider andStep: (UInt16)step andRange: (UInt32)range;

@end



@implementation SetupViewController

@synthesize scrollView;

@synthesize textFieldSparkPerRev;

@synthesize labelMinRPM;
@synthesize sliderMinRPM;

@synthesize labelMaxRPM;
@synthesize sliderMaxRPM;

@synthesize labelThresholdSpectrumSearch;
@synthesize sliderThresholdSpectrumSearch;

@synthesize labelShiftLight;
@synthesize sliderShiftLight;

@synthesize switchShiftLightSound;

@synthesize labelVersionApp;
@synthesize buttonVisitWebSite;
@synthesize buttonContactAuthor;

// ------------------------------------------------------------------------------------------------------------------------------------
// Constructeur a partir d'un fichier Nib
// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not
// appropriate for viewDidLoad.
// ------------------------------------------------------------------------------------------------------------------------------------
-(id) initWithNibName: (NSString *)nibNameOrNil bundle: (NSBundle *)nibBundleOrNil tachAudio: (TachometerAudioSignal *)tachoAudio
{
    if (self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil])
	{
        // Custom initialization
		_tachoAudioSignal = [tachoAudio retain];
    }
    return self;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Mise à jour des champs grace au compte-tour
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) updateFieldsWithTachometer
{
	// Affectation des controles de la form
	textFieldSparkPerRev.text = [NSString stringWithFormat: @"%01.01f", _tachoAudioSignal.sparksPerRev]; // convertit le short résultat en NSString et l'affiche dans le label

	double minRpm = _tachoAudioSignal.lowRPM;
	double maxRpm = _tachoAudioSignal.highRPM;
	double shiftLightRpm = _tachoAudioSignal.shiftLightRPM;

	sliderMinRPM.minimumValue = minRpm;
	sliderMaxRPM.minimumValue = maxRpm - RPM_SLIDER_RANGE;
	sliderShiftLight.minimumValue = shiftLightRpm - RPM_SLIDER_RANGE;

	sliderMinRPM.maximumValue = minRpm + RPM_SLIDER_RANGE;
	sliderMaxRPM.maximumValue = maxRpm;
	sliderShiftLight.maximumValue = shiftLightRpm;

	// Mise à jour des valeurs
	sliderMinRPM.value = minRpm;
	sliderMaxRPM.value = maxRpm;

	sliderThresholdSpectrumSearch.value = _tachoAudioSignal.fundVsHarmonicPercent;

	sliderShiftLight.value = shiftLightRpm;
	switchShiftLightSound.on = _tachoAudioSignal.shiftLightSound;

	// Force la mise à jour des labels correspondant aux sliders
	[self sliderMinRPMUpdate: nil];
	[self sliderMaxRPMUpdate: nil];
	[self sliderShiftLightUpdate: nil];
	[self sliderThresholdSpectrumSearchUpdate: nil];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Mise à jour du compte-tours à partir des champs
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) updateTachometerWithFields
{
	// Prise en compte des contrôles de la form

	_tachoAudioSignal.sparksPerRev = [textFieldSparkPerRev.text floatValue];

	_tachoAudioSignal.lowRPM = sliderMinRPM.value;
	_tachoAudioSignal.highRPM = sliderMaxRPM.value;
	_tachoAudioSignal.fundVsHarmonicPercent = sliderThresholdSpectrumSearch.value;

	_tachoAudioSignal.shiftLightRPM = sliderShiftLight.value;
	_tachoAudioSignal.shiftLightSound = switchShiftLightSound.on;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Le texte est il un entier ?
// ------------------------------------------------------------------------------------------------------------------------------------
+(BOOL) isInteger: (NSString *)text
{
	NSCharacterSet * nonNumberSet = [[NSCharacterSet characterSetWithRange:NSMakeRange('0', 10)] invertedSet]; 	// Les charactères qui ne sont pas des chiffres
	NSString * trimmed = [text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]; 		// Suppression des blancs
	BOOL isNumeric = ((trimmed.length > 0) && ([trimmed rangeOfCharacterFromSet: nonNumberSet].location == NSNotFound));
	return isNumeric;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Le texte est il un nombre décimal ?
// ------------------------------------------------------------------------------------------------------------------------------------
+(BOOL) isDecimal: (NSString *)text
{
	NSCharacterSet * nonNumberSet = [[NSCharacterSet characterSetWithCharactersInString: @"0123456789."] invertedSet];	// Les charactères qui ne sont pas des chiffres
	NSString * trimmed = [text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]; 				// Suppression des blancs
	BOOL isNumeric = ((trimmed.length > 0) && ([trimmed rangeOfCharacterFromSet: nonNumberSet].location == NSNotFound));
	return isNumeric;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Permet de fermer correctement le Text Field après la saisie.
//
// Le delegate de chaque text field de la vue est le controlleur (self) de cette vue => cette méthode est donc appelée après chaque
// saisie dans les text fields
// ------------------------------------------------------------------------------------------------------------------------------------
-(BOOL) textFieldShouldReturn: (UITextField *)theTextField
{
	/*
	if (theTextField == textFieldClPercent)
	{
		NSUInteger clPercent = [textFieldClPercent.text intValue];
		if ((0 <= clPercent) && (clPercent <= 100))
		{
			[theTextField resignFirstResponder];
		}
		else
		{
			UIAlertView *alert = [[UIAlertView alloc]  initWithTitle: @"Too Big"
															 message: @"Please Shorten Name"
															delegate: nil
									    		   cancelButtonTitle: @"Cancel"
												   otherButtonTitles: nil];
			[alert show];
			[alert release];
			return NO;
		}
	}
	*/

	if (theTextField == textFieldSparkPerRev)
	{
		if (([textFieldSparkPerRev.text floatValue] > 0) && ([textFieldSparkPerRev.text floatValue] < 10))
		{
			[theTextField resignFirstResponder];
		}
	}

	return YES;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Before the text field changes, the UITextField asks the delegate if the specified text should be changed.
// range : The range of characters to be replaced  (représente le texte sélectionné (éventuellement))
// str   : The replacement string.
// Return Value : YES if the specified text range should be replaced; otherwise, NO to keep the old text.
//
// Le delegate de chaque text field de la vue est le controlleur (self) de cette vue => cette méthode est donc appelée pour chaque
// changement dans les text fields
// ------------------------------------------------------------------------------------------------------------------------------------
-(BOOL) textField: (UITextField *)theTextField shouldChangeCharactersInRange: (NSRange)range replacementString: (NSString *)str
{
	// The text field has not changed at this point, so we grab it's current length and the string length we're inserting, minus the
	// range length. If this value is too long (more than XX characters in this example), return NO to prohibit the change.

	// When typing in a single character at the end of a text field, the range.location will be the current field's length, and
	// range.length will be 0 because we're not replacing/deleting anything. Inserting into the middle of a text field just means a
	// different range.location, and pasting multiple characters just means 'str' has more than one character in it.

	// Deleting single characters or cutting multiple characters is specified by a range with a non-zero length, and an empty string.
	// Replacement is just a range deletion with a non-empty string.

	// Vérifier que c'est une saisie de caractère et pas un backspace (par exemple)
	if (str && [str length])
	{
		NSUInteger newLength = [theTextField.text length] + [str length] - range.length;

		if (theTextField == textFieldSparkPerRev)
		{
			return ((newLength <= 3) && ([SetupViewController isDecimal: str]));
		}
	}

    return YES;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Valeur approchée d'un slider en fonction d'un pas
// ------------------------------------------------------------------------------------------------------------------------------------
+(UInt32) sliderStepValue: (UISlider *)slider andStep: (UInt16)step
{
	//int value = (step * (((int)slider.value) / step));
	UInt32 value = step * nearbyint(slider.value / step);
	if (slider.value != value)
	{
		slider.value = value;
	}
	return value;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Mise à jour du Min et Max du slider en fonction de sa valeur
// ------------------------------------------------------------------------------------------------------------------------------------
+(void) sliderMinMaxUpdate: (UISlider *)slider andStep: (UInt16)step andRange: (UInt32)range
{
	float min = slider.minimumValue;
	float max = slider.maximumValue;

	// Retourne le max des limites des types de compteurs
	UInt32 limitMax = [TachometerAudioSignal getRpmLimitWithRpm: -1.0];

	if (slider.value - step <= MAX (min, 0))
	{
		min = MAX (slider.value - step, 0);
		max = min + range;
	}
	else if (slider.value + step >= MIN (max, limitMax))
	{
		max = MIN (slider.value + step, limitMax);
		min = max - range;
	}

	slider.minimumValue = min;
	slider.maximumValue = max;

	// Force la mise à jour du curseur
	slider.value -= 0.1;
	slider.value += 0.1;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Mise à jour du slider pour le RPM min
// ------------------------------------------------------------------------------------------------------------------------------------
-(IBAction) sliderMinRPMUpdate: (id)sender
{
	// Mise à jour des maximums du slider
	[SetupViewController sliderMinMaxUpdate: sliderMinRPM andStep: RPM_SLIDER_STEP_MINMAX andRange: RPM_SLIDER_RANGE];

	if (sliderMinRPM.value > sliderMaxRPM.value)
	{
		sliderMaxRPM.value = sliderMinRPM.value;
		[self sliderMaxRPMUpdate: sender];
	}

	// Step de la valeur correspondant au slide
	labelMinRPM.text = [NSString stringWithFormat: @"%d", [SetupViewController sliderStepValue: sliderMinRPM andStep: RPM_SLIDER_STEP_PRECISION]];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Mise à jour du slider pour le RPM max
// ------------------------------------------------------------------------------------------------------------------------------------
-(IBAction) sliderMaxRPMUpdate: (id)sender
{
	// Mise à jour des maximums du slider
	[SetupViewController sliderMinMaxUpdate: sliderMaxRPM andStep: RPM_SLIDER_STEP_MINMAX andRange: RPM_SLIDER_RANGE];

	if (sliderMaxRPM.value < sliderMinRPM.value)
	{
		sliderMinRPM.value = sliderMaxRPM.value;
		[self sliderMinRPMUpdate: sender];
	}

	// Step de la valeur correspondant au slide
	labelMaxRPM.text = [NSString stringWithFormat: @"%d", [SetupViewController sliderStepValue: sliderMaxRPM andStep: RPM_SLIDER_STEP_PRECISION]];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Mise à jour du slider pour le filtre
// ------------------------------------------------------------------------------------------------------------------------------------
-(IBAction) sliderThresholdSpectrumSearchUpdate: (id)sender
{
	labelThresholdSpectrumSearch.text = [NSString stringWithFormat: @"%d", (int)sliderThresholdSpectrumSearch.value];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Mise à jour du slider shift light
// ------------------------------------------------------------------------------------------------------------------------------------
-(IBAction) sliderShiftLightUpdate: (id)sender
{
	// Mise à jour des maximums du slider
	[SetupViewController sliderMinMaxUpdate: sliderShiftLight andStep: RPM_SLIDER_STEP_MINMAX andRange: RPM_SLIDER_RANGE];

	// Step de la valeur correspondant au slide
	labelShiftLight.text = [NSString stringWithFormat: @"%d", [SetupViewController sliderStepValue: sliderShiftLight andStep: RPM_SLIDER_STEP_PRECISION]];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Lien vers le site Web
// ------------------------------------------------------------------------------------------------------------------------------------
-(IBAction) visitWebSite
{
	[[UIApplication sharedApplication] openURL: [NSURL URLWithString: @"http://wpsm.free.fr/en/racingtach.html"]];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Envoi d'un mail à l'auteur
// ------------------------------------------------------------------------------------------------------------------------------------
-(IBAction) sendMailToAuthor
{
	// Création du mail
    MFMailComposeViewController * picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

	// Nom de l'application
	NSString * appName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleDisplayName"];
	// Version de l'application
	NSString * appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"];

    [picker setSubject: [NSString stringWithFormat: @"%@ %@", appName, appVersion]];
	[picker setToRecipients: [NSArray arrayWithObject: @"racingtach@yahoo.fr"]];

    [self presentModalViewController: picker animated: YES];
	[picker release];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Méthode delegate du MFMailComposeViewController
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) mailComposeController: (MFMailComposeViewController*)controller didFinishWithResult: (MFMailComposeResult)result error: (NSError*)error
{
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			break;
		case MFMailComposeResultSaved:
			break;
		case MFMailComposeResultSent:
			break;
		case MFMailComposeResultFailed:
			break;
		default:
			break;
	}

	// Notifies the receiver that it is about to become first responder in its window.
	// Reprend le focus
	[self becomeFirstResponder];
	// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
	[self dismissModalViewControllerAnimated: YES];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Sent to the view controller after the user interface rotates.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) didRotateFromInterfaceOrientation: (UIInterfaceOrientation)fromInterfaceOrientation
{
	if ((fromInterfaceOrientation == UIInterfaceOrientationPortrait) ||
	    (fromInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown))
	{
		[scrollView setContentSize: CGSizeMake (self.view.bounds.size.width, HEIGHT_VIEW_ORIENTATION_PORTRAIT)];
	}
	else
	{
		[scrollView setContentSize: CGSizeMake (self.view.bounds.size.width, self.view.bounds.size.height)];
	}
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Notifies the view controller that its view is about to be become visible.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) viewWillAppear: (BOOL)animated
{
	if (self.view.bounds.size.width > self.view.bounds.size.height)
	{
		[scrollView setContentSize: CGSizeMake (self.view.bounds.size.width, HEIGHT_VIEW_ORIENTATION_PORTRAIT)];
	}
	else
	{
		[scrollView setContentSize: CGSizeMake (self.view.bounds.size.width, self.view.bounds.size.height)];
	}

	labelVersionApp.text = [NSString stringWithFormat: @"Version %@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]];

	[self updateFieldsWithTachometer];
    [super viewWillAppear: animated];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Notifies the view controller that its view is about to be dismissed, covered, or otherwise hidden from view.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) viewWillDisappear: (BOOL)animated
{
	[self updateTachometerWithFields];
    [super viewWillDisappear: animated];
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) viewDidLoad
{
	// Enable mail only if the iPhone or iPod touch the app is running on has been configured to send mail.
	buttonContactAuthor.enabled = [MFMailComposeViewController canSendMail];

	[super viewDidLoad];
}

// ------------------------------------------------------------------------------------------------------------------------------------
//
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

// ------------------------------------------------------------------------------------------------------------------------------------
//
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Désallocation
// ------------------------------------------------------------------------------------------------------------------------------------
-(void) dealloc
{
	[_tachoAudioSignal release];

	[scrollView release];

	[textFieldSparkPerRev release];

	[labelMinRPM release];
	[sliderMinRPM release];

	[labelMaxRPM release];
	[sliderMaxRPM release];

	[labelShiftLight release];
	[sliderShiftLight release];

	[switchShiftLightSound release];

	[labelThresholdSpectrumSearch release];
	[sliderThresholdSpectrumSearch release];

	[buttonContactAuthor release];

    [super dealloc];
}


@end
