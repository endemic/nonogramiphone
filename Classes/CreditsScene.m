//
//  CreditsScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "CreditsScene.h"
#import "TitleScene.h"
#import "GameDataManager.h"

@implementation CreditsScene

-(id) init
{
	if ((self = [super init]))
	{
		[self addChild:[CreditsLayer node] z:0];
	}
	return self;
}

@end

@implementation CreditsLayer

- (id)init
{
	if ((self = [super init]))
	{
		// Show credits background here
		CCSprite *background = [CCSprite spriteWithFile:@"creditsBackground.png"];
		[background setPosition:ccp(160, 240)];
		[self addChild:background z:0];
		
		[self setIsTouchEnabled:YES];
		
		/**
		 Art, code & music by Nathan Demick
		 Special thanks to Andrew, Andy, Ben, Jason and Neven
		 */
		
		NSString *creditsText = @"Art, code & music\nNathan Demick\n\nSpecial thanks to\nAndrew\nAndy\nBen\nJason\nNeven";
		CCLabel *creditsLabel = [CCLabel labelWithString:creditsText dimensions:CGSizeMake(320, 400) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:24];
		[creditsLabel setPosition:ccp(160, 140)];
		[self addChild:creditsLabel z:1];
		
		// Create "back" button that takes us back to the home screen
		CCMenuItem *backButton = [CCMenuItemImage itemFromNormalImage:@"backButton.png" selectedImage:@"backButtonOn.png" target:self selector:@selector(goToTitle:)];
		CCMenu *backMenu = [CCMenu menuWithItems:backButton, nil];
		[backMenu setPosition:ccp(160, 63)];
		[self addChild:backMenu z:1];
	}
	return self;
}

- (void)goToTitle:(id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TitleScene node]]];
}

@end
