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
		[previousButtonMenu setPosition:ccp(30, 300)];
		[self addChild:previousButtonMenu z:1];
		
		// Set up "next" button
		CCMenuItem *nextButton = [CCMenuItemImage itemFromNormalImage:@"nextButton.png" selectedImage:@"nextButtonOn.png" disabledImage:@"nextButton.png" target:self selector:@selector(showNextLevel:)];
		CCMenu *nextButtonMenu = [CCMenu menuWithItems:nextButton, nil];
		[nextButtonMenu setPosition:ccp(290, 300)];
		[self addChild:nextButtonMenu z:1];
		
		// Set up "play" button
		CCMenuItem *playButton = [CCMenuItemImage itemFromNormalImage:@"playButton.png" selectedImage:@"playButtonOn.png" disabledImage:@"playButton.png" target:self selector:@selector(playLevel:)];
		CCMenu *playButtonMenu = [CCMenu menuWithItems:playButton, nil];
		[playButtonMenu setPosition:ccp(160, 30)];
		[self addChild:playButtonMenu z:1];
		
		// Get best times/attempts
		NSArray *levelTimes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"];
		
		// Set up labels to show level number, difficulty, times, etc.
		
		// Large headline that shows level number
		headerLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"Level %i", [GameDataManager sharedManager].currentLevel] dimensions:CGSizeMake(320, 40) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:48];
		[headerLabel setPosition:ccp(160, 440)];
		[headerLabel setColor:ccc3(255,255,255)];
		[headerLabel.texture setAliasTexParameters];
		[self addChild:headerLabel z:3];
		
		// Details for each level
		NSLog(@"Difficulty: %@", [[[GameDataManager sharedManager].levels objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"difficulty"]);
		difficultyLabel = [CCLabel labelWithString:[[[GameDataManager sharedManager].levels objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"difficulty"] dimensions:CGSizeMake(150, 15) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:16];
		[difficultyLabel setPosition:ccp(230, 175)];
		[difficultyLabel setColor:ccc3(255,255,255)];
		[difficultyLabel.texture setAliasTexParameters];
		[self addChild:difficultyLabel z:3];
		
		NSLog(@"Attempts: %@", [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"attempts"]);
		attemptsLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%@", [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"attempts"]] dimensions:CGSizeMake(150, 15) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:16];
		[attemptsLabel setPosition:ccp(230, 156)];
		[attemptsLabel setColor:ccc3(255,255,255)];
		[attemptsLabel.texture setAliasTexParameters];
		[self addChild:attemptsLabel z:3];
		
		NSLog(@"First time for level %i: %@", [GameDataManager sharedManager].currentLevel, [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"firstTime"]);
		firstTimeLabel = [CCLabel labelWithString:[[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"firstTime"] dimensions:CGSizeMake(150, 15) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:16];
		[firstTimeLabel setPosition:ccp(230, 137)];
		[firstTimeLabel setColor:ccc3(255,255,255)];
		[firstTimeLabel.texture setAliasTexParameters];
		[self addChild:firstTimeLabel z:3];
		
		NSLog(@"Best time for level %i: %@", [GameDataManager sharedManager].currentLevel, [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"bestTime"]);
		bestTimeLabel = [CCLabel labelWithString:[[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"bestTime"] dimensions:CGSizeMake(150, 15) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:16];
		[bestTimeLabel setPosition:ccp(230, 118)];
		[bestTimeLabel setColor:ccc3(255,255,255)];
		[bestTimeLabel.texture setAliasTexParameters];
		[self addChild:bestTimeLabel z:3];
		
		// Set up sprites that show level details
		for (int i = 0; i < [[GameDataManager sharedManager].levels count]; i++) 
		{
			CCSprite *s = [CCSprite spriteWithFile:@"defaultLevelPreview.png"];
			
			if (i < [GameDataManager sharedManager].currentLevel - 1)
				[s setPosition:ccp(-140, 300)];	// Position to the left
			else if (i == [GameDataManager sharedManager].currentLevel - 1)
				[s setPosition:ccp(160, 300)];	// Current one is in the middle of the screen
			else
				[s setPosition:ccp(440, 300)];	// Offscreen for the rest

			[self addChild:s];
			levelDisplayList[i] = s;
		}
	}
	return self;
}

- (void)hideLevelData:(id)sender
{
	// Hide all the labels that show meta about the level
	headerLabel.visible = FALSE;
	difficultyLabel.visible = FALSE;
	attemptsLabel.visible = FALSE;
	firstTimeLabel.visible = FALSE;
	bestTimeLabel.visible = FALSE;
}

- (void)showLevelData:(id)sender
{
	// Get best times/attempts
	NSArray *levelTimes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"];
	
	// Update all labels
	[headerLabel setString:[NSString stringWithFormat:@"Level %i", [GameDataManager sharedManager].currentLevel]];
	[difficultyLabel setString:[[[GameDataManager sharedManager].levels objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"difficulty"]];
	[attemptsLabel setString:[NSString stringWithFormat:@"%@", [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"attempts"]]];
	[firstTimeLabel setString:[[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"firstTime"]];
	[bestTimeLabel setString:[[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"bestTime"]];
	
	// Show all meta labels
	headerLabel.visible = TRUE;
	difficultyLabel.visible = TRUE;
	attemptsLabel.visible = TRUE;
	firstTimeLabel.visible = TRUE;
	bestTimeLabel.visible = TRUE;	
}

- (void)showPreviousLevel:(id)sender
{
	if ([GameDataManager sharedManager].currentLevel > 1)
	{
		// Move current offscreen
		id moveOffScreenAction = [CCMoveTo actionWithDuration:0.75 position:ccp(440, 300)];
		id hideLevelDataAction = [CCCallFunc actionWithTarget:self selector:@selector(hideLevelData:)];
		
		[levelDisplayList[[GameDataManager sharedManager].currentLevel - 1] runAction:[CCSequence actions:hideLevelDataAction, moveOffScreenAction, nil]];
		
		// Decrement level counter
		[GameDataManager sharedManager].currentLevel--;
		
		// Move previous onscreen
		id moveOnScreenAction = [CCMoveTo actionWithDuration:0.75 position:ccp(160, 300)];
		id showLevelDataAction = [CCCallFunc actionWithTarget:self selector:@selector(showLevelData:)];
		
		[levelDisplayList[[GameDataManager sharedManager].currentLevel - 1] runAction:[CCSequence actions:moveOnScreenAction, showLevelDataAction, nil]];
	}
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

-(void) showNextLevel: (id)sender
{
	if ([GameDataManager sharedManager].currentLevel < [[GameDataManager sharedManager].levels count] - 1)
	{
		// Move current offscreen
		id moveOffScreenAction = [CCMoveTo actionWithDuration:0.75 position:ccp(-120, 300)];
		id hideLevelDataAction = [CCCallFunc actionWithTarget:self selector:@selector(hideLevelData:)];
		
		[levelDisplayList[[GameDataManager sharedManager].currentLevel - 1] runAction:[CCSequence actions:hideLevelDataAction, moveOffScreenAction, nil]];
		
		// Increment level counter
		[GameDataManager sharedManager].currentLevel++;
		
		// Move next onscreen
		id moveOnScreenAction = [CCMoveTo actionWithDuration:0.75 position:ccp(160, 300)];
		id showLevelDataAction = [CCCallFunc actionWithTarget:self selector:@selector(showLevelData:)];
		
		[levelDisplayList[[GameDataManager sharedManager].currentLevel - 1] runAction:[CCSequence actions:moveOnScreenAction, showLevelDataAction, nil]];
	}
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

-(void) playLevel: (id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[PlayScene node]]];
}

@end
