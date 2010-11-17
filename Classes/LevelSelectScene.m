//
//  LevelSelectScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "TitleScene.h"
#import "LevelSelectScene.h"
#import "PlayScene.h"
#import "GameDataManager.h"

// Set up level select scene
@implementation LevelSelectScene

-(id)init
{
	if ((self = [super init]))
	{
		// Add layer
		[self addChild:[LevelSelectLayer node] z:0];
	}
	return self;
}

@end

// Level select layer
@implementation LevelSelectLayer

- (id)init
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
		
		CCSprite *background;
		// Add up background
		if (iPad)
			background = [CCSprite spriteWithFile:@"levelSelectBackground-hd.png"];
		else
			background = [CCSprite spriteWithFile:@"levelSelectBackground.png"];
		[background setPosition:ccp(winSize.width / 2, winSize.height / 2)];
		[self addChild:background z:0];
		
		// Play music if allowed
		if ([GameDataManager sharedManager].playMusic)
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"levelSelect.mp3"];
		
		// Set up "previous" button
		if (iPad)
			previousButton = [CCMenuItemImage itemFromNormalImage:@"prevButton-hd.png" selectedImage:@"prevButtonOn-hd.png" disabledImage:@"prevButtonDisabled-hd.png" target:self selector:@selector(showPreviousLevel:)];
		else
			previousButton = [CCMenuItemImage itemFromNormalImage:@"prevButton.png" selectedImage:@"prevButtonOn.png" disabledImage:@"prevButtonDisabled.png" target:self selector:@selector(showPreviousLevel:)];
		CCMenu *previousButtonMenu = [CCMenu menuWithItems:previousButton, nil];
		//[previousButtonMenu setPosition:ccp(30, 300)];
		[previousButtonMenu setPosition:ccp(winSize.width * 0.09375, winSize.height * 0.625)];
		[self addChild:previousButtonMenu z:1];
		
		// Set up "next" button
		if (iPad)
			nextButton = [CCMenuItemImage itemFromNormalImage:@"nextButton-hd.png" selectedImage:@"nextButtonOn-hd.png" disabledImage:@"nextButtonDisabled-hd.png" target:self selector:@selector(showNextLevel:)];
		else
			nextButton = [CCMenuItemImage itemFromNormalImage:@"nextButton.png" selectedImage:@"nextButtonOn.png" disabledImage:@"nextButtonDisabled.png" target:self selector:@selector(showNextLevel:)];
		CCMenu *nextButtonMenu = [CCMenu menuWithItems:nextButton, nil];
		//[nextButtonMenu setPosition:ccp(290, 300)];
		[nextButtonMenu setPosition:ccp(winSize.width * 0.90625, winSize.height * 0.625)];
		[self addChild:nextButtonMenu z:1];
		
		// Set up play/back buttons
		CCMenuItem *playButton, *backButton;
		if (iPad)
		{
			playButton = [CCMenuItemImage itemFromNormalImage:@"playButton-hd.png" selectedImage:@"playButtonOn-hd.png" target:self selector:@selector(playLevel:)];
			backButton = [CCMenuItemImage itemFromNormalImage:@"backButton-hd.png" selectedImage:@"backButtonOn-hd.png" target:self selector:@selector(goToTitle:)];
		}
		else
		{
			playButton = [CCMenuItemImage itemFromNormalImage:@"playButton.png" selectedImage:@"playButtonOn.png" target:self selector:@selector(playLevel:)];
			backButton = [CCMenuItemImage itemFromNormalImage:@"backButton.png" selectedImage:@"backButtonOn.png" target:self selector:@selector(goToTitle:)];
		}
		CCMenu *playButtonMenu = [CCMenu menuWithItems:playButton, backButton, nil];
		[playButtonMenu alignItemsVertically];
		[playButtonMenu setPosition:ccp(winSize.width / 2, winSize.height / 9.6)];
		[self addChild:playButtonMenu z:1];
		
		// Get best times/attempts
		NSArray *levelTimes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"];
		// Set up labels to show level number, difficulty, times, etc.
		
		// Determine some font sizes!
		int headerFontSize, fontSize;
		if (iPad)
		{
			headerFontSize = 96;
			fontSize = 32;
		}
		else
		{
			headerFontSize = 48;
			fontSize = 16;
		}
		
		// Large headline that shows level number
		headerLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"Level %i", [GameDataManager sharedManager].currentLevel] dimensions:CGSizeMake(winSize.width, winSize.height / 10) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:headerFontSize];
		//[headerLabel setPosition:ccp(winSize.width / 2, 440)];
		[headerLabel setPosition:ccp(winSize.width / 2, winSize.height / 1.1)];
		[headerLabel setColor:ccc3(255,255,255)];
		[headerLabel.texture setAliasTexParameters];
		[self addChild:headerLabel z:4];

		// Details for each level
		// Difficulty
		difficultyLabel = [CCLabel labelWithString:[[[GameDataManager sharedManager].levels objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"difficulty"] dimensions:CGSizeMake(winSize.width / 2, fontSize) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:fontSize];
		//[difficultyLabel setPosition:ccp(265, 171)];
		[difficultyLabel setPosition:ccp(winSize.width * 0.828125, winSize.height * 0.35625)];
		[difficultyLabel setColor:ccc3(255,255,255)];
		[difficultyLabel.texture setAliasTexParameters];
		[self addChild:difficultyLabel z:3];
		
		// # of attempts
		attemptsLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%@", [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"attempts"]] dimensions:CGSizeMake(winSize.width / 2, fontSize) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:fontSize];
		//[attemptsLabel setPosition:ccp(265, 152)];
		[attemptsLabel setPosition:ccp(winSize.width * 0.828125, winSize.height * 0.316666666666667)];
		[attemptsLabel setColor:ccc3(255,255,255)];
		[attemptsLabel.texture setAliasTexParameters];
		[self addChild:attemptsLabel z:3];
		
		// First time completed
		firstTimeLabel = [CCLabel labelWithString:[[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"firstTime"] dimensions:CGSizeMake(winSize.width / 2, fontSize) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:fontSize];
		//[firstTimeLabel setPosition:ccp(265, 133)];
		[firstTimeLabel setPosition:ccp(winSize.width * 0.828125, winSize.height * 0.277083333333333)];
		[firstTimeLabel setColor:ccc3(255,255,255)];
		[firstTimeLabel.texture setAliasTexParameters];
		[self addChild:firstTimeLabel z:3];
		
		// Best time completed
		bestTimeLabel = [CCLabel labelWithString:[[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"bestTime"] dimensions:CGSizeMake(winSize.width / 2, fontSize) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:fontSize];
		//[bestTimeLabel setPosition:ccp(265, 114)];
		[bestTimeLabel setPosition:ccp(winSize.width * 0.828125, winSize.height * 0.2375)];
		[bestTimeLabel setColor:ccc3(255,255,255)];
		[bestTimeLabel.texture setAliasTexParameters];
		[self addChild:bestTimeLabel z:3];
		
		// Init level display list
		levelDisplayList = [[NSMutableArray arrayWithCapacity:[[GameDataManager sharedManager].levels count]] retain];
		
		// Populate level
		for (int j = 0, k = [[GameDataManager sharedManager].levels count]; j < k; j++)
			[levelDisplayList insertObject:[NSNumber numberWithInt:0] atIndex:j];
		
		// New code
		int i = [GameDataManager sharedManager].currentLevel - 1;
		CCSprite *s;
		
		if ([[[levelTimes objectAtIndex:i] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
		{
			// Load question mark
			s = [CCSprite spriteWithFile:@"defaultLevelPreview.png"];
		}
		else 
		{
			// Create blank sprite
			s = [CCSprite spriteWithFile:@"blankLevelPreview.png"];
			
			// Load puzzle data
			NSDictionary *level = [[GameDataManager sharedManager].levels objectAtIndex:i];
			
			// Draw puzzle on to overlay
			CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:[level objectForKey:@"filename"]];
			
			// Get details regarding how large the level is (e.g. 10x10 or 5x5)
			int offset = ((10 - tileMap.mapSize.width) * 15) / 2;

			[tileMap setScale:0.75];
			[tileMap setPosition:ccp(25 + offset, 35 + offset)];
			[s addChild:tileMap];
			
			// Draw title
			CCLabel *label = [CCLabel labelWithString:[level objectForKey:@"title"] dimensions:CGSizeMake(200, 25) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:16];
			[label setColor:ccc3(00, 00, 00)];
			[label setPosition:ccp(100, 15)];
			[label.texture setAliasTexParameters];
			[s addChild:label];
		}
		
		[levelDisplayList replaceObjectAtIndex:i withObject:s];
		[s setPosition:ccp(winSize.width / 2, winSize.height / 1.6)];
		[self addChild:s];
		
		// Set prev/next buttons as disabled if needed
		if ([GameDataManager sharedManager].currentLevel == 1)
			[previousButton setIsEnabled:FALSE];
		else
			[previousButton setIsEnabled:TRUE];
		
		if ([GameDataManager sharedManager].currentLevel == [[GameDataManager sharedManager].levels count])
			[nextButton setIsEnabled:FALSE];
		else
			[nextButton setIsEnabled:TRUE];
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
	// Load level data!
	NSDictionary *level = [[GameDataManager sharedManager].levels objectAtIndex:[GameDataManager sharedManager].currentLevel - 1];	// -1 becos we're accessing an array

	// Get best times/attempts
	NSArray *levelTimes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"];
	
	// Update all labels
	[headerLabel setString:[NSString stringWithFormat:@"Level %i", [GameDataManager sharedManager].currentLevel]];
	[difficultyLabel setString:[level objectForKey:@"difficulty"]];
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
		/**
		 Add code that loads a sprite for new level here, moves it into place, then moves current sprite off screen and removes it from parent
		 */
		NSArray *levelTimes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"];
		int currentLevel = [GameDataManager sharedManager].currentLevel - 1;
		int previousLevel = [GameDataManager sharedManager].currentLevel - 2;
		
		CCSprite *s;
		
		// Check to see if the object is a NSNumber... if so, create a sprite and replace the number in the array
		if ([[levelDisplayList objectAtIndex:previousLevel] isKindOfClass:[NSNumber class]])
		{
			if ([[[levelTimes objectAtIndex:previousLevel] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				// Load question mark
				s = [CCSprite spriteWithFile:@"defaultLevelPreview.png"];
			}
			else 
			{
				// Create blank sprite
				s = [CCSprite spriteWithFile:@"blankLevelPreview.png"];
				
				// Load puzzle data
				NSDictionary *level = [[GameDataManager sharedManager].levels objectAtIndex:previousLevel];
				
				// Draw puzzle on to overlay
				CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:[level objectForKey:@"filename"]];
				
				// Get details regarding how large the level is (e.g. 10x10 or 5x5)
				int offset = ((10 - tileMap.mapSize.width) * 15) / 2;
				
				[tileMap setScale:0.75];
				[tileMap setPosition:ccp(25 + offset, 35 + offset)];
				[s addChild:tileMap];
				
				// Draw title
				CCLabel *label = [CCLabel labelWithString:[level objectForKey:@"title"] dimensions:CGSizeMake(200, 25) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:16];
				[label setColor:ccc3(00, 00, 00)];
				[label setPosition:ccp(100, 15)];
				[label.texture setAliasTexParameters];
				[s addChild:label];
			}
			
			[levelDisplayList replaceObjectAtIndex:previousLevel withObject:s];
			[s setPosition:ccp(-140, 300)];
			[self addChild:s];
		}
		else
		{
			s = [levelDisplayList objectAtIndex:previousLevel];
			[s setPosition:ccp(-140, 300)];
			[self addChild:s];
		}
		
		// Move current offscreen
		id moveOffScreenAction = [CCMoveTo actionWithDuration:0.75 position:ccp(440, 300)];
		id hideLevelDataAction = [CCCallFunc actionWithTarget:self selector:@selector(hideLevelData:)];
		id removeSelfAction = [CCCallFuncN actionWithTarget:self selector:@selector(removeFromParent:)];
		
		[[levelDisplayList objectAtIndex:currentLevel] runAction:[CCSequence actions:hideLevelDataAction, moveOffScreenAction, removeSelfAction, nil]];
		
		// Decrement level counter
		[GameDataManager sharedManager].currentLevel--;

		// Move previous onscreen
		id moveOnScreenAction = [CCMoveTo actionWithDuration:0.75 position:ccp(160, 300)];
		id showLevelDataAction = [CCCallFunc actionWithTarget:self selector:@selector(showLevelData:)];
		
		[[levelDisplayList objectAtIndex:previousLevel] runAction:[CCSequence actions:moveOnScreenAction, showLevelDataAction, nil]];
	}
	
	// Muck with enabling/disabling prev/next buttons
	[nextButton setIsEnabled:TRUE];
	if ([GameDataManager sharedManager].currentLevel == 1)
		[previousButton setIsEnabled:FALSE];
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

- (void)showNextLevel:(id)sender
{
	if ([GameDataManager sharedManager].currentLevel < [[GameDataManager sharedManager].levels count])
	{
		NSArray *levelTimes = [[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"];
		int currentLevel = [GameDataManager sharedManager].currentLevel - 1;
		int nextLevel = [GameDataManager sharedManager].currentLevel;
		
		CCSprite *s;
		
		// Check to see if the object is a NSNumber... if so, create a sprite and replace the number in the array
		if ([[levelDisplayList objectAtIndex:nextLevel] isKindOfClass:[NSNumber class]])
		{
			if ([[[levelTimes objectAtIndex:nextLevel] objectForKey:@"firstTime"] isEqualToString:@"--:--"])
			{
				// Load question mark
				s = [CCSprite spriteWithFile:@"defaultLevelPreview.png"];
			}
			else 
			{
				// Create blank sprite
				s = [CCSprite spriteWithFile:@"blankLevelPreview.png"];
				
				// Load puzzle data
				NSDictionary *level = [[GameDataManager sharedManager].levels objectAtIndex:nextLevel];
				
				// Draw puzzle on to overlay
				CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:[level objectForKey:@"filename"]];
				
				// Get details regarding how large the level is (e.g. 10x10 or 5x5)
				int offset = ((10 - tileMap.mapSize.width) * 15) / 2;
				NSLog(@"Offset: %i", offset);
				
				[tileMap setScale:0.75];
				[tileMap setPosition:ccp(25 + offset, 35 + offset)];
				[s addChild:tileMap];
				
				// Draw title
				CCLabel *label = [CCLabel labelWithString:[level objectForKey:@"title"] dimensions:CGSizeMake(200, 25) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:16];
				[label setColor:ccc3(00, 00, 00)];
				[label setPosition:ccp(100, 15)];
				[label.texture setAliasTexParameters];
				[s addChild:label];
			}
			
			[levelDisplayList replaceObjectAtIndex:nextLevel withObject:s];
			[s setPosition:ccp(440, 300)];
			[self addChild:s];
		}
		else 
		{
			s = [levelDisplayList objectAtIndex:nextLevel];
			[s setPosition:ccp(440, 300)];
			[self addChild:s];
		}

		
		// Move current offscreen
		id moveOffScreenAction = [CCMoveTo actionWithDuration:0.75 position:ccp(-140, 300)];
		id hideLevelDataAction = [CCCallFunc actionWithTarget:self selector:@selector(hideLevelData:)];
		id removeSelfAction = [CCCallFuncN actionWithTarget:self selector:@selector(removeFromParent:)];
		
		[[levelDisplayList objectAtIndex:currentLevel] runAction:[CCSequence actions:hideLevelDataAction, moveOffScreenAction, removeSelfAction, nil]];
		
		// Increment level counter
		[GameDataManager sharedManager].currentLevel++;

		// Move next onscreen
		id moveOnScreenAction = [CCMoveTo actionWithDuration:0.75 position:ccp(160, 300)];
		id showLevelDataAction = [CCCallFunc actionWithTarget:self selector:@selector(showLevelData:)];
		
		[[levelDisplayList objectAtIndex:nextLevel] runAction:[CCSequence actions:moveOnScreenAction, showLevelDataAction, nil]];
	}
	
	// Muck with enabling/disabling prev/next buttons
	[previousButton setIsEnabled:TRUE];
	if ([GameDataManager sharedManager].currentLevel == [[GameDataManager sharedManager].levels count])
		[nextButton setIsEnabled:FALSE];

	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

- (void)playLevel:(id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[PlayScene node]]];
}

- (void)goToTitle:(id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	// Make sure background music is stopped before going to next scene
	[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TitleScene node]]];
}

// This isn't used; might not work
- (void)removeFromParent:(CCNode *)sprite
{
	//[sprite.parent removeChild:sprite cleanup:YES];
	
	// Trying this from forum post http://www.cocos2d-iphone.org/forum/topic/981#post-5895
	// Apparently fixes a memory error?
	CCNode *parent = sprite.parent;
	[sprite retain];
	[parent removeChild:sprite cleanup:YES];
	[sprite autorelease];
}

- (void)dealloc
{
	[levelDisplayList release];
	[super dealloc];
}

@end
