//
//  TitleScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "TitleScene.h"
#import "OptionsScene.h"
#import "LevelSelectScene.h"
#import "GameDataManager.h"

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
		
		CCMenu *menu = [CCMenu menuWithItems:playButton, tutorialButton, optionsButton, nil];		// Create container menu object
		[menu alignItemsVertically];
		[menu setPosition:ccp(160, 100)];
		[self addChild:menu	z:1];
	}
	return self;
}

-(void) goToLevelSelect: (id)sender
{
	NSLog(@"Level select");
	[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[LevelSelectScene node]]];
}

-(void) goToTutorial: (id)sender
{
	[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	NSLog(@"Tutorial");
}

-(void) goToOptions: (id)sender
{
	NSLog(@"Options");
	[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[OptionsScene node]]];
}

@end
