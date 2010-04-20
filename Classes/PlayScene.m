//
//  PlayScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/25/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "PlayScene.h"
#import "LevelSelectScene.h"

@implementation PlayScene

-(id) init
{
	if ((self = [super init])) 
	{
		// Add "play" layer
		[self addChild:[PlayLayer node] z:0];
	}
	return self;
}

@end

@implementation PlayLayer

-(id) init
{
	if ((self = [super init])) 
	{
		// Set touch enabled
		[self setIsTouchEnabled:YES];
		
		// Add background to center of scene
		CCSprite *background = [CCSprite spriteWithFile:@"playBackground.png"];
		[background.texture setAliasTexParameters];	// Make aliased
		[background setPosition:ccp(160, 240)];
		[self addChild:background z:0];
		
		// Set the width of puzzle blocks
		blockSize = 20;
		
		// Current position of the cursor
		currentColumn = 1;
		currentRow = 10;
		
		// Init variables used to keep track of correct/incorrect guesses
		hits = misses = 0;
		
		// Init horizontal "cursor" highlight
		horizontalHighlight = [CCSprite spriteWithFile:@"highlight.png"];
		[horizontalHighlight setPosition:ccp(160, 240)];
		[self addChild:horizontalHighlight z:3];
		
		// Init vertical "cursor" highlight
		verticalHighlight = [CCSprite spriteWithFile:@"highlight.png"];
		[verticalHighlight setPosition:ccp(120, 200)];
		[verticalHighlight setRotation:90.0];
		[self addChild:verticalHighlight z:3];
		
		// Set up buttons to control mark/fill
		CCMenuItem *markButton = [CCMenuItemImage itemFromNormalImage:@"markButton.png" selectedImage:@"markButtonSelected.png" target:self selector:@selector(changeTapActionToMark:)];
		CCMenuItem *fillButton = [CCMenuItemImage itemFromNormalImage:@"fillButton.png" selectedImage:@"fillButtonSelected.png" target:self selector:@selector(changeTapActionToFill:)];
		CCRadioMenu *actionsMenu = [CCRadioMenu menuWithItems:fillButton, markButton, nil];
		[actionsMenu alignItemsHorizontally];
		[actionsMenu setPosition:ccp(160, 23)];
		[actionsMenu setSelectedItem:markButton];
		[markButton selected];
		tapAction = MARK;	// 0 for mark, 1 for fill
		[self addChild:actionsMenu z:3];
		
		// Set up "pause" button
		CCMenuItem *pauseButton = [CCMenuItemImage itemFromNormalImage:@"pauseButton.png" selectedImage:@"pauseButtonOn.png" target:self selector:@selector(pause:)];
		CCMenu *pauseMenu = [CCMenu menuWithItems:pauseButton, nil];
		[pauseMenu setPosition:ccp(25, 415)];
		[self addChild:pauseMenu z:3];

		// Waahhh, can't do multi-line bitmap font aliases :(
		// Check out this forum post for non-blurry text: http://www.cocos2d-iphone.org/forum/topic/2865#post-17718
		//CCBitmapFontAtlas *testAtlas = [CCBitmapFontAtlas bitmapFontAtlasWithString:@"1\n2 \n 3" fntFile:@"slkscr.fnt"];
		//[testAtlas.textureAtlas.texture setAliasTexParameters];
		//[testAtlas setPosition:ccp(110, 273)];
		//[self addChild:testAtlas z:3];
		
		// Load level!
		NSLog(@"Current level: %d", [GameDataManager sharedManager].currentLevel);
		NSDictionary *level = [[GameDataManager sharedManager].levels objectAtIndex:[GameDataManager sharedManager].currentLevel - 1];	// -1 becos we're accessing an array
		
		// Load tile map for this particular puzzle
		CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:[level objectForKey:@"filename"]];
		tileMapLayer = [[tileMap layerNamed:@"Layer 1"] retain];
		
		// Init block status array
		for (int i = 0; i < 10; i++)
			for (int j = 0; j < 10; j++)
				blockStatus[i][j] = 0;		// Unmarked, unfilled
		
		// Create "clue" labels in arrays for rows and columns
		for (int i = 0; i < 10; i++)
		{
			// Create new label; set position/color/aliasing values
			verticalClues[i] = [CCLabel labelWithString:@"0\n" dimensions:CGSizeMake(25, 100) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:16];
			[verticalClues[i] setPosition:ccp(120 + (blockSize * i), 300)];
			[verticalClues[i] setColor:ccc3(0,0,0)];
			[verticalClues[i].texture setAliasTexParameters];
			[self addChild:verticalClues[i] z:3];
			
			horizontalClues[i] = [CCLabel labelWithString:@"0 " dimensions:CGSizeMake(75, 15) alignment:UITextAlignmentRight fontName:@"slkscr.ttf" fontSize:16];
			[horizontalClues[i] setPosition:ccp(70, 60 + (blockSize * i))];
			[horizontalClues[i] setColor:ccc3(0,0,0)];
			[horizontalClues[i].texture setAliasTexParameters];
			[self addChild:horizontalClues[i] z:3];
		}
		
		// Populate/position the clues
		totalBlocksInPuzzle = 0;
		int counterHoriz = 0;
		int counterVert = 0;
		Boolean previousHoriz = FALSE;
		Boolean previousVert = FALSE;
		NSString *cluesTextHoriz = @"";
		NSString *cluesTextVert = @"";

		for (int i = 0; i < 10; i++) 
		{
			cluesTextHoriz = @"";
			cluesTextVert = @"";
			for (int j = 0; j < 10; j++) 
			{
				// Horizontal clues (for rows)
				if ([tileMapLayer tileGIDAt:ccp(j, i)] == 1)
				{
					counterHoriz++;
					previousHoriz = TRUE;
				}
				else if (previousHoriz == TRUE) 
				{
					cluesTextHoriz = [cluesTextHoriz stringByAppendingFormat:@"%i ", counterHoriz];
					totalBlocksInPuzzle += counterHoriz;		// This number is for our win condition - only need to count on one side, since clues are counted twice
					counterHoriz = 0;
					previousHoriz = FALSE;
				}
				
				// Vertical clues (for columns)
				if ([tileMapLayer tileGIDAt:ccp(i, j)] == 1)
				{
					counterVert++;
					previousVert = TRUE;
				}
				else if (previousVert == TRUE) 
				{
					cluesTextVert = [cluesTextVert stringByAppendingFormat:@"%i\n", counterVert];
					counterVert = 0;
					previousVert = FALSE;
				}
			}
			
			// Condition for if a row ends with filled in blocks
			if (previousHoriz == TRUE)
			{
				cluesTextHoriz = [cluesTextHoriz stringByAppendingFormat:@"%i ", counterHoriz];
				totalBlocksInPuzzle += counterHoriz;
				counterHoriz = 0;
				previousHoriz = FALSE;
			}
			if (previousVert == TRUE)
			{
				cluesTextVert = [cluesTextVert stringByAppendingFormat:@"%i\n", counterVert];
				counterVert = 0;
				previousVert = FALSE;
			}
			
			// Add the text to the label objects
			if ([cluesTextHoriz length] > 0)
			{
				[horizontalClues[9 - i] setString:cluesTextHoriz];
			}
			if ([cluesTextVert length] > 0)
			{
				[verticalClues[i] setString:cluesTextVert];
				NSArray *numberOfVerticalClues = [cluesTextVert componentsSeparatedByString:@"\n"];
				[verticalClues[i] setPosition:ccp(verticalClues[i].position.x, 200 + (([numberOfVerticalClues count] - 1) * 17))];
			}
			else
			{
				[verticalClues[i] setPosition:ccp(verticalClues[i].position.x, 217)];
			}
		}
		
		// Set up schedulers
		//[self schedule:@selector(update:)];
		
		// Set up % complete label
		percentComplete = [CCLabel labelWithString:@"0" fontName:@"slkscr.ttf" fontSize:48];
		[percentComplete setPosition:ccp(260, 415)];
		[percentComplete.texture setAliasTexParameters];
		[percentComplete setColor:ccc3(33, 33, 33)];
		[self addChild:percentComplete z:3];
		
		// Set up timer labels/internal variables/scheduler
		[self schedule:@selector(timer:) interval:1.0];

		minutesLeft = 30;
		secondsLeft = 0;
		
		minutesLeftLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%d", minutesLeft] dimensions:CGSizeMake(100, 100) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:48];
		[minutesLeftLabel setPosition:ccp(110, 395)];
		[minutesLeftLabel setColor:ccc3(33, 33, 33)];
		[minutesLeftLabel.texture setAliasTexParameters];
		[self addChild:minutesLeftLabel z:3];
		
		secondsLeftLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%d", secondsLeft] dimensions:CGSizeMake(100,100) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:48];
		[secondsLeftLabel setPosition:ccp(110, 355)];
		[secondsLeftLabel setColor:ccc3(33, 33, 33)];
		[secondsLeftLabel.texture setAliasTexParameters];
		[self addChild:secondsLeftLabel z:3];
		
		// Not paused to start with!
		paused = FALSE;
		
		// Set up pause overlay
		pauseOverlay = [CCSprite spriteWithFile:@"pauseOverlay.png"];
		[pauseOverlay.texture setAliasTexParameters];
		[pauseOverlay setPosition:ccp(-150, 200)];	// It's off screen to the right
		[self addChild:pauseOverlay z:4];
		
		// Add buttons to overlay
		CCMenuItem *resumeButton = [CCMenuItemImage itemFromNormalImage:@"resumeButton.png" selectedImage:@"resumeButtonOn.png" disabledImage:@"resumeButton.png" target:self selector:@selector(resume:)];
		CCMenuItem *quitButton = [CCMenuItemImage itemFromNormalImage:@"quitButton.png" selectedImage:@"quitButtonOn.png" disabledImage:@"quitButton.png" target:self selector:@selector(goToLevelSelect:)];
		
		CCMenu *overlayMenu = [CCMenu menuWithItems:resumeButton, quitButton, nil];		// Create container menu object
		[overlayMenu alignItemsVerticallyWithPadding:20];
		[overlayMenu setPosition:ccp(150, 150)];
		[pauseOverlay addChild:overlayMenu];
	}
	return self;
}

// This scheduled method currently commented out
-(void) update:(ccTime)dt
{	
	// Update sprite positions based on row/column variables
	[verticalHighlight setPosition:ccp(currentColumn * blockSize + 110 - (blockSize / 2), verticalHighlight.position.y)];
	[horizontalHighlight setPosition:ccp(horizontalHighlight.position.x, currentRow * blockSize + 50 - (blockSize / 2))];
}

-(void) timer:(ccTime)dt
{
	secondsLeft--;
	if (minutesLeft == 0 && secondsLeft < 0)
	{
		// Game over
		[self lostGame];
	}
	else if (secondsLeft < 0)
	{
		minutesLeft--;
		secondsLeft = 59;
	}
	// Update labels for time
	[minutesLeftLabel setString:[NSString stringWithFormat:@"%d", minutesLeft]];
	[secondsLeftLabel setString:[NSString stringWithFormat:@"%d", secondsLeft]];
	
	// This is causin' an error
	//[secondsLeftLabel setString:[[NSString stringWithFormat:@"%d", secondsLeft] stringByPaddingToLength:2 withString:@"0" startingAtIndex:1]];
}

-(void) pause:(id)sender
{
	// Do nothing if the game is already paused
	if (!paused)
	{
		// Move "paused" overlay on top of puzzle, and unschedule the timer
		[self unschedule:@selector(timer:)];
		
		// Make sure the overlay is on the left side of the screen
		[pauseOverlay setPosition:ccp(-150, 200)];
		
		// Move pause overlay to 160, 200
		[pauseOverlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];
		
		// Hide cursor highlights
		horizontalHighlight.visible = FALSE;
		verticalHighlight.visible = FALSE;
		
		paused = TRUE;
	}
}

-(void) resume:(id)sender
{
	// Remove "paused" overlay and reschedule timer
	[self schedule:@selector(timer:) interval:1.0];
	
	// Move pause overlay off screen to the right, then reset position offscreen left
	[pauseOverlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(470, 200)]];
	
	// Show cursor highlights
	horizontalHighlight.visible = TRUE;
	verticalHighlight.visible = TRUE;
	
	paused = FALSE;
}

-(void) changeTapActionToMark:(id)sender
{
	tapAction = MARK;
}

-(void) changeTapActionToFill:(id)sender
{
	tapAction = FILL;
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Figure out initial location of touch
	UITouch *touch = [touches anyObject];
	
	if (touch && !paused) 
	{
		startPoint = previousPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		cursorPoint = ccp(verticalHighlight.position.x, horizontalHighlight.position.y);
	}
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	
	if (touch && !paused) 
	{
		// Variables used to determine whether SFX should be played or not
		int previousRow = currentRow;
		int previousColumn = currentColumn;
		
		// User's finger
		CGPoint location = [touch locationInView: [touch view]];
		
		// The touches are always in "portrait" coordinates. You need to convert them to your current orientation
		CGPoint currentPoint = [[CCDirector sharedDirector] convertToGL:location];
		
		// Gets relative movement
		//CGPoint relativeMovement = ccp(currentPoint.x - previousPoint.x, currentPoint.y - previousPoint.y);
		
		// Gets relative movement - slowed down by 25% - maybe easier to move the cursor?
		CGPoint relativeMovement = ccp((currentPoint.x - previousPoint.x) * 0.75, (currentPoint.y - previousPoint.y) * 0.75);
		
		// Add to current point the cursor is at
		cursorPoint = ccpAdd(cursorPoint, relativeMovement);
		
		// Get row/column values - 50 & 110 is the blank space on the x/y axes 
		currentRow = (cursorPoint.y - 50) / blockSize + 1;
		currentColumn = (cursorPoint.x - 110) / blockSize + 1;
		
		// Enforce positions in grid
		if (currentRow > 10) currentRow = 10;
		if (currentRow < 1) currentRow = 1;
		if (currentColumn > 10) currentColumn = 10;
		if (currentColumn < 1) currentColumn = 1;
		
		// If the cursor has changed rows
		if ((previousRow != currentRow || previousColumn != currentColumn))
		{
			// Update sprite positions based on row/column variables
			[verticalHighlight setPosition:ccp(currentColumn * blockSize + 110 - (blockSize / 2), verticalHighlight.position.y)];
			[horizontalHighlight setPosition:ccp(horizontalHighlight.position.x, currentRow * blockSize + 50 - (blockSize / 2))];
			
			// Play SFX if allowed
			if ([GameDataManager sharedManager].playSFX)
				[[SimpleAudioEngine sharedEngine] playEffect:@"cursorMove.wav"];
			
			// If player has double tapped, try to place a mark/fill in the new block
			if (touch.tapCount > 1) 
			{
				switch (tapAction) 
				{
					case FILL: [self fillBlock]; break;
					case MARK: [self markBlock]; break;
				}
			}
		}
		
		// Set the previous point value to be what we used as current
		previousPoint = currentPoint;
	}
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Determine block placement here
	UITouch *touch = [touches anyObject];
	
	if (touch && !paused)
	{
		// convert touch coords
		CGPoint endPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		
		// This value is the sensitivity for filling/marking a block
		int moveThreshold = 10;
		
		// If a tap is detected - i.e. if the movement of the finger is less than the threshold
		if (ccpDistance(startPoint, endPoint) < moveThreshold)
		{
			switch (tapAction) 
			{
				case FILL: [self fillBlock]; break;
				case MARK: [self markBlock]; break;
			}
		}
	}
}

-(void) markBlock
{
	// Toggle 'X' mark on a block if it's not already filled in
	if (blockStatus[currentRow - 1][currentColumn - 1] != FILLED)
	{
		// If not marked, mark
		if (blockStatus[currentRow - 1][currentColumn - 1] != MARKED)
		{
			blockSprites[currentRow - 1][currentColumn - 1] = [CCSprite spriteWithFile:@"markIcon.png"];
			[blockSprites[currentRow - 1][currentColumn - 1] setPosition:ccp(verticalHighlight.position.x, horizontalHighlight.position.y)];
			[blockSprites[currentRow - 1][currentColumn - 1].texture setAliasTexParameters];
			[self addChild:blockSprites[currentRow - 1][currentColumn - 1] z:2];
			blockStatus[currentRow - 1][currentColumn - 1] = MARKED;
		}
		// If marked, remove mark
		else
		{
			[self removeChild:blockSprites[currentRow - 1][currentColumn - 1] cleanup:FALSE];
			blockSprites[currentRow - 1][currentColumn - 1] = nil;
			blockStatus[currentRow - 1][currentColumn - 1] = BLANK;
		}
	}
	// Block is filled
	else
	{
		// Play SFX if allowed
		if ([GameDataManager sharedManager].playSFX)
			[[SimpleAudioEngine sharedEngine] playEffect:@"dud.wav"];
	}
}

-(void) fillBlock
{
	// If the tile at the current location is a filled in tile...
	// The tilemap's y-coords are inverse of the iphone coords, so invert it
	if ([tileMapLayer tileGIDAt:ccp(currentColumn - 1, 10 - currentRow)] == 1 && blockStatus[currentRow - 1][currentColumn - 1] != FILLED)
	{
		// Add a "filled" block to the grid
		blockSprites[currentRow - 1][currentColumn - 1] = [CCSprite spriteWithFile:@"fillIcon.png"];
		[blockSprites[currentRow - 1][currentColumn - 1] setPosition:ccp(verticalHighlight.position.x, horizontalHighlight.position.y)];
		[blockSprites[currentRow - 1][currentColumn - 1].texture setAliasTexParameters];
		[self addChild:blockSprites[currentRow - 1][currentColumn - 1] z:2];
		blockStatus[currentRow - 1][currentColumn - 1] = FILLED;
		
		// Add sprite to "minimap" section as well - these don't have to be referenced later
		CCSprite *b = [CCSprite spriteWithFile:@"8pxSquare.png"];
		//[b setPosition:ccp(216 + currentColumn * 8, 365 + currentRow * 8)];	// Old position
		[b setPosition:ccp(16 + currentColumn * 8, 256 + currentRow * 8)];	// New position
		[self addChild:b z:2];
		
		// Update "% complete" number
		// This is not working for some reason
		[percentComplete setString:[NSString stringWithFormat:@"%f", (float)(hits / totalBlocksInPuzzle)]];
		
		// Win condition
		if (++hits == totalBlocksInPuzzle) 
			[self wonGame];
	}
	else if (blockStatus[currentRow - 1][currentColumn - 1] == FILLED)
	{
		// Play SFX if allowed
		if ([GameDataManager sharedManager].playSFX)
			[[SimpleAudioEngine sharedEngine] playEffect:@"dud.wav"];
	}
	else
	{
		// Take off time here, as well as play sfx of some kind and shake the screen
		id shake = [CCShaky3D actionWithRange:3 shakeZ:FALSE grid:ccg(5, 5) duration:0.1];
		
		// Run "shake" action, then return the grid to its original state
		[self runAction:[CCSequence actions:shake, [CCStopGrid action], nil]];
		
		// Subtract time based on how many mistakes you made previously
		switch (++misses)
		{
			case 1: minutesLeft -= 2; break;
			case 2: minutesLeft -= 4; break;
			default: minutesLeft -= 8; break;
		}
		if (minutesLeft < 0)
		{
			minutesLeft = 0;
			secondsLeft = 0;
		}
		
		// Update time labels
		[minutesLeftLabel setString:[NSString stringWithFormat:@"%d", minutesLeft]];
		[secondsLeftLabel setString:[NSString stringWithFormat:@"%d", secondsLeft]];
	}
}

-(void) wonGame
{
	NSLog(@"You win!");
	
	paused = TRUE;
	[self unschedule:@selector(timer:)];
	
	// Hide cursor highlights
	horizontalHighlight.visible = FALSE;
	verticalHighlight.visible = FALSE;
	
	// Create/move "you win" overlay down on screen
	CCSprite *overlay = [CCSprite spriteWithFile:@"pauseOverlay.png"];
	[overlay.texture setAliasTexParameters];
	[overlay setPosition:ccp(160, 630)];	// It's off screen to the top
	[self addChild:overlay z:4];
	
	// Add buttons to overlay
	CCMenuItem *continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton.png" selectedImage:@"continueButtonOn.png" target:self selector:@selector(goToLevelSelect:)];
	
	CCMenu *overlayMenu = [CCMenu menuWithItems:continueButton, nil];		// Create container menu object
	[overlayMenu setPosition:ccp(150, 50)];
	[overlay addChild:overlayMenu];
	
	// Draw finished puzzle image on to overlay
	
	// Write image title on to overlay
	NSDictionary *level = [[GameDataManager sharedManager].levels objectAtIndex:[GameDataManager sharedManager].currentLevel - 1];	// -1 becos we're accessing an array
	CCLabel *levelTitle = [CCLabel labelWithString:[level objectForKey:@"title"] fontName:@"slkscr.ttf" fontSize:24];
	[levelTitle setPosition:ccp(150, 100)];
	[overlay addChild:levelTitle];
	
	// Move overlay downwards over play area
	[overlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];
}

-(void) lostGame
{
	NSLog(@"You lose!");

	paused = TRUE;
	[self unschedule:@selector(timer:)];
	
	// Hide cursor highlights
	horizontalHighlight.visible = FALSE;
	verticalHighlight.visible = FALSE;
	
	// Create/move "you win" overlay down on screen
	CCSprite *overlay = [CCSprite spriteWithFile:@"pauseOverlay.png"];
	[overlay.texture setAliasTexParameters];
	[overlay setPosition:ccp(160, 630)];	// It's off screen to the top
	[self addChild:overlay z:4];
	
	// Add buttons to overlay
	CCMenuItem *continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton.png" selectedImage:@"continueButtonOn.png" target:self selector:@selector(goToLevelSelect:)];
	
	CCMenu *overlayMenu = [CCMenu menuWithItems:continueButton, nil];		// Create container menu object
	[overlayMenu setPosition:ccp(150, 50)];
	[overlay addChild:overlayMenu];
	
	// Move overlay downwards over play area
	[overlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];
	
	// Get best times/attempts
	NSMutableArray *levelTimes = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"]];
	NSNumber *attempts = [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"attempts"];
	NSLog(@"Attempts: %@", [NSNumber numberWithInt:[attempts intValue] + 1]);
	
	NSMutableDictionary *timeData = [NSMutableDictionary dictionaryWithDictionary: [levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1]];
	[timeData setValue:[NSNumber numberWithInt:[attempts intValue] + 1] forKey:@"attempts"];
	
	// Re-save
	[levelTimes replaceObjectAtIndex:[GameDataManager sharedManager].currentLevel - 1 withObject:timeData];
	[[NSUserDefaults standardUserDefaults] setObject:levelTimes forKey:@"levelTimes"];
}

-(void) goToLevelSelect:(id)sender
{
	[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[LevelSelectScene node]]];
}

-(void) dealloc
{
	[super dealloc];
	[tileMapLayer dealloc];
}

@end;