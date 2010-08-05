//
//  TitleScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "TitleScene.h"
#import "OptionsScene.h"
#import "LevelSelectScene.h"
#import "TutorialScene.h"
#import "CreditsScene.h"
#import "GameDataManager.h"

#import "CocosDenshion.h"
#import "SimpleAudioEngine.h"

@implementation TitleScene

-(id) init
{
	if ((self = [super init]))
	{
		// Set up background
		CCSprite *background = [CCSprite spriteWithFile:@"titleBackground.png"];		// Create background sprite object
		[background setPosition:ccp(160, 240)];											// Move background to center of screen
		[self addChild:background z:0];													// Add background with lowest z-index
		
		// Add "scene" container
		[self addChild:[TitleLayer node] z:1];
	}
	return self;
}

@end


@implementation TitleLayer

-(id) init
{
	if ((self = [super init]))
	{		
		// Set up buttons
		CCMenuItem *playButton = [CCMenuItemImage itemFromNormalImage:@"playButton.png" selectedImage:@"playButtonOn.png" disabledImage:@"playButton.png" target:self selector:@selector(goToLevelSelect:)];
		CCMenuItem *tutorialButton = [CCMenuItemImage itemFromNormalImage:@"tutorialButton.png"	selectedImage:@"tutorialButtonOn.png" disabledImage:@"tutorialButton.png" target:self selector:@selector(goToTutorial:)];
		CCMenuItem *optionsButton = [CCMenuItemImage itemFromNormalImage:@"optionsButton.png" selectedImage:@"optionsButtonOn.png" disabledImage:@"optionsButton.png" target:self selector:@selector(goToOptions:)];
		
		// Determine if player has completed all levels
		NSArray *levelTimes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"];
		BOOL showCredits = TRUE;
		for (int i = 0; i < 100; i++) 
		{
			if ([[[levelTimes objectAtIndex:i] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				showCredits = FALSE;
				break;
			}
		}
		
		// Show "credits" button if all levels have been completed
		CCMenu *menu;
		if (showCredits)
		{
			CCMenuItem *creditsButton = [CCMenuItemImage itemFromNormalImage:@"optionsButton.png" selectedImage:@"optionsButtonOn.png" disabledImage:@"optionsButton.png" target:self selector:@selector(goToCredits:)];
			menu = [CCMenu menuWithItems:playButton, tutorialButton, optionsButton, creditsButton, nil];		// Create container menu object
		}
		else 
		{
			menu = [CCMenu menuWithItems:playButton, tutorialButton, optionsButton, nil];		// Create container menu object
		}

			
		[menu alignItemsVertically];
		[menu setPosition:ccp(160, 100)];
		[self addChild:menu	z:1];
		
		// Preload the rest of the required SFX/music resources
		if (![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying]) 
		{
			[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"levelSelect.mp3"];
			[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"play.mp3"];
			[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"winJingle.mp3"];
			[[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"loseJingle.mp3"];
			[[SimpleAudioEngine sharedEngine] preloadEffect:@"cursorMove.wav"];
			[[SimpleAudioEngine sharedEngine] preloadEffect:@"dud.wav"];
			[[SimpleAudioEngine sharedEngine] preloadEffect:@"miss.wav"];
			[[SimpleAudioEngine sharedEngine] preloadEffect:@"hit.wav"];
			[[SimpleAudioEngine sharedEngine] preloadEffect:@"mark.wav"];
		}

		// Play SFX if allowed
		if ([GameDataManager sharedManager].playMusic && ![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying])
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"titleScreen.mp3"];
	}
	return self;
}

-(void) goToLevelSelect: (id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[LevelSelectScene node]]];
}

-(void) goToTutorial: (id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TutorialScene node]]];
}

-(void) goToOptions: (id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[OptionsScene node]]];
}

- (void)goToCredits: (id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[CreditsScene node]]];
}

@end
