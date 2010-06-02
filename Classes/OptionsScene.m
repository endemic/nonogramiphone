//
//  OptionsScene.m
//  Nonograms
//
//  Created by Nathan Demick on 4/2/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "OptionsScene.h"
#import "TitleScene.h"
#import "GameDataManager.h"

@implementation OptionsScene

-(id) init
{
	if ((self = [super init]))
	{
		CCSprite *background = [CCSprite spriteWithFile:@"optionsBackground.png"];
		[background setPosition:ccp(160,240)];
		[self addChild:background z:0];
		[self addChild:[OptionsLayer node] z:1];
	}
	return self;
}

@end

@implementation OptionsLayer

-(id) init
{
	if ((self = [super init]))
	{
		// Create buttons, etc. for optionz!
		CCMenuItem *sfxOnButton = [CCMenuItemImage itemFromNormalImage:@"onButton.png" selectedImage:@"onButtonSelected.png" target:self selector:@selector(sfxOn:)];
		CCMenuItem *sfxOffButton = [CCMenuItemImage itemFromNormalImage:@"offButton.png" selectedImage:@"offButtonSelected.png" target:self selector:@selector(sfxOff:)];
		CCRadioMenu *sfxMenu = [CCRadioMenu menuWithItems:sfxOnButton, sfxOffButton, nil];
		
		[sfxMenu alignItemsHorizontally];
		[sfxMenu setPosition:ccp(200, 160)];
		
		// Decide which button is highlighted
		if ([GameDataManager sharedManager].playSFX == TRUE)
		{	
			[sfxOnButton selected];
			[sfxMenu setSelectedItem:sfxOnButton];
		}
		else 
		{
			[sfxOffButton selected];
			[sfxMenu setSelectedItem:sfxOffButton];
		}
		
		[self addChild:sfxMenu z:1];
		
		CCMenuItem *musicOnButton = [CCMenuItemImage itemFromNormalImage:@"onButton.png" selectedImage:@"onButtonSelected.png" target:self selector:@selector(musicOn:)];
		CCMenuItem *musicOffButton = [CCMenuItemImage itemFromNormalImage:@"offButton.png" selectedImage:@"offButtonSelected.png" target:self selector:@selector(musicOff:)];
		CCRadioMenu *musicMenu = [CCRadioMenu menuWithItems:musicOnButton, musicOffButton, nil];
		
		[musicMenu alignItemsHorizontally];
		[musicMenu setPosition:ccp(200, 210)];
		
		// Decide which button is highlighted
		if ([GameDataManager sharedManager].playMusic == TRUE)
		{	
			[musicOnButton selected];
			[musicMenu setSelectedItem:musicOnButton];
		}
		else 
		{
			[musicMenu setSelectedItem:musicOffButton];
			[musicOffButton selected];
		}

		[self addChild:musicMenu z:1];
		
		// Create "back" button that takes us back to the home screen
		CCMenuItem *backButton = [CCMenuItemImage itemFromNormalImage:@"backButton.png" selectedImage:@"backButtonOn.png" target:self selector:@selector(goToTitleScreen:)];
		CCMenu *backMenu = [CCMenu menuWithItems:backButton, nil];
		[backMenu setPosition:ccp(160, 63)];
		[self addChild:backMenu z:1];
	}
	return self;
}

-(void) sfxOn:(id)selector
{
	[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"playSFX"];
	[GameDataManager sharedManager].playSFX = TRUE;
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

-(void) sfxOff:(id)selector
{
	[[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"playSFX"];
	[GameDataManager sharedManager].playSFX = FALSE;
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

-(void) musicOn:(id)selector
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	if (![[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying])
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"titleScreen.mp3"];
	
	[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"playMusic"];
	[GameDataManager sharedManager].playMusic = TRUE;
}

-(void) musicOff:(id)selector
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	// Turn off music if it's still playing
	if ([[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying])
		[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
	
	[[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"playMusic"];
	[GameDataManager sharedManager].playMusic = FALSE;
}

-(void) goToTitleScreen:(id)selector
{
	// Suggested to synch preferences?
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	// Return to title sceen
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TitleScene node]]];
}

@end
