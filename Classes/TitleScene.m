//
//  TitleScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "TitleScene.h"
#import "CreditsScene.h"
#import "LevelSelectScene.h"

@implementation TitleScene

-(id) init
{
	if ((self = [super init]))
	{
		// Add "scene" container
		[self addChild:[TitleLayer node]];
	}
	return self;
}

@end


@implementation TitleLayer

-(id) init
{
	if ((self = [super init]))
	{
		// Set up background
		CCSprite *background = [CCSprite spriteWithFile:@"titleBackground.png"];		// Create background sprite object
		[background setPosition:ccp(160, 240)];											// Move background to center of screen
		[self addChild:background z:0];													// Add background with lowest z-index
		
		// Set up buttons
		CCMenuItem *startButton = [CCMenuItemFont itemFromString:@"Start" target:self selector:@selector(goToLevelSelect:)];
		CCMenuItem *tutorialButton = [CCMenuItemFont itemFromString:@"Tutorial" target:self selector:@selector(goToTutorial:)];
		CCMenuItem *creditsButton = [CCMenuItemFont itemFromString:@"Credits" target:self selector:@selector(goToCredits:)];
		
		CCMenu *menu = [CCMenu menuWithItems:startButton, tutorialButton, creditsButton, nil];		// Create container menu object
		[menu alignItemsVertically];
		[self addChild:menu	z:1];
	}
	return self;
}

-(void) goToLevelSelect: (id)sender
{
	NSLog(@"Level select");
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[LevelSelectScene node]]];
}

-(void) goToTutorial: (id)sender
{
	NSLog(@"Tutorial");
}

-(void) goToCredits: (id)sender
{
	NSLog(@"Credits");
	//CreditsScene *scene = [CreditsScene node];
	
	//[[CCDirector sharedDirector] runScene:scene];
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[CreditsScene node]]];
	//[[CCDirector sharedDirector] replaceScene:[CreditsScene node]];
}

@end
