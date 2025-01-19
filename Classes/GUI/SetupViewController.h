//
//  SetupViewController.h
//  RacingTach
//
//  Created by Gérald GUIONY on 13/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#import "RotatingTabBarController.h"

@class TachometerAudioSignal;

// ------------------------------------------------------------------------------------------------------------------------------------
// Définition du controlleur de la vue 'SetupView'
// ------------------------------------------------------------------------------------------------------------------------------------
@interface SetupViewController : RotatingViewController <MFMailComposeViewControllerDelegate>
{
	TachometerAudioSignal * _tachoAudioSignal;

	// Le mot clé IBOutlet spécifie au compilateur de rendre ces objets disponibles pour Interface Builder.
	IBOutlet UIScrollView * scrollView;

	IBOutlet UITextField * textFieldSparkPerRev;

	IBOutlet UILabel * labelMinRPM;
	IBOutlet UISlider * sliderMinRPM;

	IBOutlet UILabel * labelMaxRPM;
	IBOutlet UISlider * sliderMaxRPM;

	IBOutlet UILabel * labelThresholdSpectrumSearch;
	IBOutlet UISlider * sliderThresholdSpectrumSearch;

	IBOutlet UILabel * labelShiftLight;
	IBOutlet UISlider * sliderShiftLight;

	IBOutlet UISwitch * switchShiftLightSound;

	IBOutlet UILabel * labelVersionApp;
	IBOutlet UIButton * buttonVisitWebSite;
	IBOutlet UIButton * buttonContactAuthor;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Accesseurs
// ------------------------------------------------------------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UIScrollView * scrollView;

@property (nonatomic, retain) IBOutlet UITextField * textFieldSparkPerRev;

@property (nonatomic, retain) IBOutlet UILabel * labelMinRPM;
@property (nonatomic, retain) IBOutlet UISlider * sliderMinRPM;

@property (nonatomic, retain) IBOutlet UILabel * labelMaxRPM;
@property (nonatomic, retain) IBOutlet UISlider * sliderMaxRPM;

@property (nonatomic, retain) IBOutlet UILabel * labelThresholdSpectrumSearch;
@property (nonatomic, retain) IBOutlet UISlider * sliderThresholdSpectrumSearch;

@property (nonatomic, retain) IBOutlet UILabel * labelShiftLight;
@property (nonatomic, retain) IBOutlet UISlider * sliderShiftLight;

@property (nonatomic, retain) IBOutlet UISwitch * switchShiftLightSound;

@property (nonatomic, retain) IBOutlet UILabel * labelVersionApp;
@property (nonatomic, retain) IBOutlet UIButton * buttonVisitWebSite;
@property (nonatomic, retain) IBOutlet UIButton * buttonContactAuthor;

// ------------------------------------------------------------------------------------------------------------------------------------
// Methods
// ------------------------------------------------------------------------------------------------------------------------------------

// Constructeur
-(id) initWithNibName: (NSString *)nibNameOrNil bundle: (NSBundle *)nibBundleOrNil tachAudio: (TachometerAudioSignal *)tachoAudio;

// Cette méthode est déclarée à l’aide du mot-clé IBAction qui spécifiera au compilateur de rendre cette méthode disponible pour
// Interface Builder. Elle prend également un paramètre de type id (qui est générique)
-(IBAction) sliderMinRPMUpdate: (id)sender;
-(IBAction) sliderMaxRPMUpdate: (id)sender;
-(IBAction) sliderThresholdSpectrumSearchUpdate: (id)sender;
-(IBAction) sliderShiftLightUpdate: (id)sender;

-(void) updateFieldsWithTachometer;
-(void) updateTachometerWithFields;

-(IBAction) visitWebSite;
-(IBAction) sendMailToAuthor;

@end

