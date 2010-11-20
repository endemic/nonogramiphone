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
		// Add main layer for scene
		[self addChild:[OptionsLayer node] z:0];
	}
	return self;
}

@end

@implementation OptionsLayer

-(id) init
{
	if ((self = [super init]))
	{
		// Get window size
		CGSize winSize = [CCDirector sharedDirector].winSize;
		
		// Check if running on iPad
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			iPad = YES;
		else
			iPad = NO;
		
		// Init some local UI vars
		CCSprite *background;
		CCMenuItem *sfxOnButton, *sfxOffButton, *musicOnButton, *musicOffButton, *backButton;
		CCRadioMenu *sfxMenu, *musicMenu;
		CCMenu *backMenu;
		
		if (iPad)
			background = [CCSprite spriteWithFile:@"optionsBackground-hd.png"];
		else
			background = [CCSprite spriteWithFile:@"optionsBackground.png"];

		[background setPosition:ccp(winSize.width / 2, winSize.height / 2)];
		[self addChild:background z:0];
		
		// Create buttons, etc. for optionz!
		if (iPad)
		{
			sfxOnButton = [CCMenuItemImage itemFromNormalImage:@"onButton-hd.png" selectedImage:@"onButtonSelected-hd.png" target:self selector:@selector(sfxOn:)];
			sfxOffButton = [CCMenuItemImage itemFromNormalImage:@"offButton-hd.png" selectedImage:@"offButtonSelected-hd.png" target:self selector:@selector(sfxOff:)];
		}
		else 
		{
			sfxOnButton = [CCMenuItemImage itemFromNormalImage:@"onButton.png" selectedImage:@"onButtonSelected.png" target:self selector:@selector(sfxOn:)];
			sfxOffButton = [CCMenuItemImage itemFromNormalImage:@"offButton.png" selectedImage:@"offButtonSelected.png" target:self selector:@selector(sfxOff:)];
		}

		sfxMenu = [CCRadioMenu menuWithItems:sfxOnButton, sfxOffButton, nil];
		
		[sfxMenu alignItemsHorizontally];
		//[sfxMenu setPosition:ccp(200, 160)];
		[sfxMenu setPosition:ccp(winSize.width / 1.6, winSize.height / 2.9)];
		
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
		
		if (iPad)
		{
			musicOnButton = [CCMenuItemImage itemFromNormalImage:@"onButton-hd.png" selectedImage:@"onButtonSelected-hd.png" target:self selector:@selector(musicOn:)];
			musicOffButton = [CCMenuItemImage itemFromNormalImage:@"offButton-hd.png" selectedImage:@"offButtonSelected-hd.png" target:self selector:@selector(musicOff:)];			
		}
		else
		{
			musicOnButton = [CCMenuItemImage itemFromNormalImage:@"onButton.png" selectedImage:@"onButtonSelected.png" target:self selector:@selector(musicOn:)];
			musicOffButton = [CCMenuItemImage itemFromNormalImage:@"offButton.png" selectedImage:@"offButtonSelected.png" target:self selector:@selector(musicOff:)];
		}

		musicMenu = [CCRadioMenu menuWithItems:musicOnButton, musicOffButton, nil];
		
		[musicMenu alignItemsHorizontally];
		//[musicMenu setPosition:ccp(200, 210)];
		[musicMenu setPosition:ccp(winSize.width / 1.6, winSize.height * 0.4375)];
		
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
		if (iPad)
			backButton = [CCMenuItemImage itemFromNormalImage:@"backButton-hd.png" selectedImage:@"backButtonOn-hd.png" target:self selector:@selector(goToTitleScreen:)];
		else
			backButton = [CCMenuItemImage itemFromNormalImage:@"backButton.png" selectedImage:@"backButtonOn.png" target:self selector:@selector(goToTitleScreen:)];

		backMenu = [CCMenu menuWithItems:backButton, nil];
		//[backMenu setPosition:ccp(160, 63)];
		[backMenu setPosition:ccp(winSize.width / 2, winSize.height * 0.13125)];
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
		//[[SimpleAudioEngine sharedEngine] resumeBackgroundMusic];
	
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
		//[[SimpleAudioEngine sharedEngine] pauseBackgroundMusic];
	
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
