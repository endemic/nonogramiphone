//
//  LevelSelectScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "LevelSelectScene.h"
#import "PlayScene.h"
#import "GameDataManager.h"

// Set up level select scene
@implementation LevelSelectScene

-(id)init
{
	if ((self = [super init]))
	{
		// Add up background
		CCSprite *background = [CCSprite spriteWithFile:@"levelSelectBackground.png"];
		[background setPosition:ccp(160,240)];
		[self addChild:background z:0];
		
		// Add layer
		[self addChild:[LevelSelectLayer node] z:1];
	}
	return self;
}

@end

// Level select layer
// Level manager is a singleton?
// Maybe use NSSelectorFromString to select levels?
@implementation LevelSelectLayer

-(id) init
{
	if ((self = [super init]))
	{
		// Set up "previous" button
		CCMenuItem *previousButton = [CCMenuItemImage itemFromNormalImage:@"prevButton.png" selectedImage:@"prevButtonOn.png" disabledImage:@"prevButton.png" target:self selector:@selector(showPreviousLevel:)];
		CCMenu *previousButtonMenu = [CCMenu menuWithItems:previousButton, nil];
		[previousButtonMenu setPosition:ccp(20, 240)];
		[self addChild:previousButtonMenu z:1];
		
		// Set up "next" button
		CCMenuItem *nextButton = [CCMenuItemImage itemFromNormalImage:@"nextButton.png" selectedImage:@"nextButtonOn.png" disabledImage:@"nextButton.png" target:self selector:@selector(showNextLevel:)];
		CCMenu *nextButtonMenu = [CCMenu menuWithItems:nextButton, nil];
		[nextButtonMenu setPosition:ccp(300, 240)];
		[self addChild:nextButtonMenu z:1];
		
		// Set up "play" button
		CCMenuItem *playButton = [CCMenuItemImage itemFromNormalImage:@"playButton.png" selectedImage:@"playButtonOn.png" disabledImage:@"playButton.png" target:self selector:@selector(playLevel:)];
		CCMenu *playButtonMenu = [CCMenu menuWithItems:playButton, nil];
		[playButtonMenu setPosition:ccp(160, 80)];
		[self addChild:playButtonMenu z:1];
		
		// Get best times/attempts
		NSArray *levelTimes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"];
		
		NSLog(@"First time for level %i: %@", [GameDataManager sharedManager].currentLevel, [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"firstTime"]);
		NSLog(@"Best time for level %i: %@", [GameDataManager sharedManager].currentLevel, [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"bestTime"]);
		NSLog(@"# of attempts at level %i: %@", [GameDataManager sharedManager].currentLevel, [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"attempts"]);
		
		// Re-save
		[[NSUserDefaults standardUserDefaults] setObject:levelTimes forKey:@"levelTimes"];
		
		// Set up sprites that show level details
		for (int i = 0; i < [[GameDataManager sharedManager].levels count]; i++) 
		{
			CCSprite *s = [CCSprite spriteWithFile:@"defaultLevelPreview.png"];
			
			if (i < [GameDataManager sharedManager].currentLevel - 1)
				[s setPosition:ccp(-140, 230)];	// Position to the left
			else if (i == [GameDataManager sharedManager].currentLevel - 1)
				[s setPosition:ccp(160, 230)];	// Current one is in the middle of the screen
			else
				[s setPosition:ccp(440, 230)];	// Offscreen for the rest

			[self addChild:s];
			levelDisplayList[i] = s;
			//[s release];
		}
	}
	return self;
}

-(void) showPreviousLevel: (id)sender
{
	NSLog(@"Show previous level");
	if ([GameDataManager sharedManager].currentLevel > 1)
	{
		// Subtract array key values by one
		[levelDisplayList[[GameDataManager sharedManager].currentLevel - 1] runAction:[CCMoveTo actionWithDuration:0.75 position:ccp(440, 230)]];
		[GameDataManager sharedManager].currentLevel--;
		[levelDisplayList[[GameDataManager sharedManager].currentLevel - 1] runAction:[CCMoveTo actionWithDuration:0.75 position:ccp(160, 230)]];
	}
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

-(void) showNextLevel: (id)sender
{
	NSLog(@"Show next level");
	if ([GameDataManager sharedManager].currentLevel < [[GameDataManager sharedManager].levels count] - 1)
	{
		// Subtract key values by one, since arrays start at 0
		[levelDisplayList[[GameDataManager sharedManager].currentLevel - 1] runAction:[CCMoveTo actionWithDuration:0.75 position:ccp(-120, 230)]];
		[GameDataManager sharedManager].currentLevel++;
		[levelDisplayList[[GameDataManager sharedManager].currentLevel - 1] runAction:[CCMoveTo actionWithDuration:0.75 position:ccp(160, 230)]];
	}
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

-(void) playLevel: (id)sender
{
	NSLog(@"Play level");
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[PlayScene node]]];
}

@end
