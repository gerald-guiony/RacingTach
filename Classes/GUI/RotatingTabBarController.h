//
//  RotatingTabBarController.h
//  RacingTach
//
//  Created by Gérald GUIONY on 29/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// ------------------------------------------------------------------------------------------------------------------------------------
// Définition d'un controlleur de TabBar permettant aux controlleurs des vues d'autoriser ou pas la rotation des vues
// ------------------------------------------------------------------------------------------------------------------------------------
@interface RotatingTabBarController : UITabBarController
{
}

@end

// ------------------------------------------------------------------------------------------------------------------------------------
// Définition d'un controlleur de vue autorisant ou pas la rotation de la vue associée
// ------------------------------------------------------------------------------------------------------------------------------------
@interface RotatingViewController : UIViewController
{
	BOOL _allowRotation;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Accesseurs
// ------------------------------------------------------------------------------------------------------------------------------------
@property (nonatomic, assign) BOOL allowRotation;

@end
