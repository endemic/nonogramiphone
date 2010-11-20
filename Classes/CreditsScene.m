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
		// Check if running on iPad
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) iPad = YES;
		else iPad = NO;
		
		// Get window size
		CGSize winSize = [CCDirector sharedDirector].winSize;
		
		// Show credits background here
		CCSprite *background;
		if (iPad) background = [CCSprite spriteWithFile:@"creditsBackground-hd.png"];
		else background = [CCSprite spriteWithFile:@"creditsBackground.png"];
		[background setPosition:ccp(winSize.width / 2, winSize.height / 2)];
		[self addChild:background z:0];
		
		[self setIsTouchEnabled:YES];
		
		/**
		 Art, code & music by Nathan Demick
		 Special thanks to Andrew, Andy, Ben, Jason and Neven
		 */
		int fontSize = 16;
		if (iPad) fontSize *= 2;
		
		NSString *creditsText = @"Art, code & music\nNathan Demick\n\nSpecial thanks to\nAndrew\nAndy\nBen\nBrendan\nJason\nNeven";
		CCLabel *creditsLabel = [CCLabel labelWithString:creditsText dimensions:CGSizeMake(winSize.width, winSize.height) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:fontSize];
		if (iPad) [creditsLabel setPosition:ccp(384, 142)];		// Doubled, with 64px/32px guttahs
		else [creditsLabel setPosition:ccp(160, 55)];
		[self addChild:creditsLabel z:1];
		
		// Create "back" button that takes us back to the home screen
		CCMenuItem *backButton;
		if (iPad) backButton = [CCMenuItemImage itemFromNormalImage:@"backButton-hd.png" selectedImage:@"backButtonOn-hd.png" target:self selector:@selector(goToTitle:)];
		else backButton = [CCMenuItemImage itemFromNormalImage:@"backButton.png" selectedImage:@"backButtonOn.png" target:self selector:@selector(goToTitle:)];
		CCMenu *backMenu = [CCMenu menuWithItems:backButton, nil];
		if (iPad) [backMenu setPosition:ccp(384, 132)];		// Doubled, with 64px/32px guttahs
		else [backMenu setPosition:ccp(160, 50)];
		[self addChild:backMenu z:2];
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
