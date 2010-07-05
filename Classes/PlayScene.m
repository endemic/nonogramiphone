//
//  PlayScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/25/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "PlayScene.h"
#import "LevelSelectScene.h"
#import "GameState.h"

@implementation PlayScene

-(id) init
{
	if ((self = [super init])) 
	{
		// Add "play" layer
		[self addChild:[PlayLayer node] z:0];
		
		// Tell GameState singleton that we want to restore to current level if player quits during puzzle
		[GameState sharedGameState].restoreLevel = TRUE;
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
		
		actionOnPreviousBlock = FALSE;
		
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
			
			horizontalClues[i] = [CCLabel labelWithString:@"0 " dimensions:CGSizeMake(100, 15) alignment:UITextAlignmentRight fontName:@"slkscr.ttf" fontSize:16];
			[horizontalClues[i] setPosition:ccp(60, 60 + (blockSize * i))];
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
			else 
			{
				[horizontalClues[9 - i] setColor:ccc3(66, 66, 66)];	// Set the text color as lighter since it's a zero - column already completed
			}

			
			if ([cluesTextVert length] > 0)
			{
				[verticalClues[i] setString:cluesTextVert];
				NSArray *numberOfVerticalClues = [cluesTextVert componentsSeparatedByString:@"\n"];
				[verticalClues[i] setPosition:ccp(verticalClues[i].position.x, 200 + (([numberOfVerticalClues count] - 1) * 17))];
			}
			else
			{
				[verticalClues[i] setColor:ccc3(66, 66, 66)];	// Set the text color as lighter since it's a zero - column already completed
				[verticalClues[i] setPosition:ccp(verticalClues[i].position.x, 217)];
			}
		}
		
		// Set up schedulers
		//[self schedule:@selector(update:)];
		
		// Set up % complete label
		percentComplete = [CCLabel labelWithString:@"00" fontName:@"slkscr.ttf" fontSize:48];
		[percentComplete setPosition:ccp(260, 422)];
		[percentComplete.texture setAliasTexParameters];
		[percentComplete setColor:ccc3(00, 00, 00)];
		[self addChild:percentComplete z:3];
		
		// Set up timer labels/internal variables/scheduler
		[self schedule:@selector(timer:) interval:1.0];

		minutesLeft = 30;
		secondsLeft = 0;
		
		minutesLeftLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%02d", minutesLeft] dimensions:CGSizeMake(100, 100) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:48];
		[minutesLeftLabel setPosition:ccp(110, 395)];
		[minutesLeftLabel setColor:ccc3(00, 00, 00)];
		[minutesLeftLabel.texture setAliasTexParameters];
		[self addChild:minutesLeftLabel z:3];
		
		secondsLeftLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%02d", secondsLeft] dimensions:CGSizeMake(100,100) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:48];
		[secondsLeftLabel setPosition:ccp(110, 355)];
		[secondsLeftLabel setColor:ccc3(00, 00, 00)];
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
		CCMenuItem *quitButton = [CCMenuItemImage itemFromNormalImage:@"quitButton.png" selectedImage:@"quitButtonOn.png" disabledImage:@"quitButton.png" target:self selector:@selector(quit:)];
		
		CCMenu *overlayMenu = [CCMenu menuWithItems:resumeButton, quitButton, nil];		// Create container menu object
		[overlayMenu alignItemsVertically];
		[overlayMenu setPosition:ccp(150, 50)];
		[pauseOverlay addChild:overlayMenu];
		
		// Play music if allowed
		if ([GameDataManager sharedManager].playMusic)
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"levelSelect.mp3"];
		
		// If the player was in the middle of a puzzle, restore the variables from where they left off
		if ([GameState sharedGameState].restoreLevel)
		{
			currentRow = [GameState sharedGameState].currentRow;
			currentColumn = [GameState sharedGameState].currentColumn;
			minutesLeft = [GameState sharedGameState].minutesLeft;
			secondsLeft = [GameState sharedGameState].secondsLeft;
			hits = [GameState sharedGameState].hits;
			misses = [GameState sharedGameState].misses;
			
			// Update sprite positions based on row/column variables
			[verticalHighlight setPosition:ccp(currentColumn * blockSize + 110 - (blockSize / 2), verticalHighlight.position.y)];
			[horizontalHighlight setPosition:ccp(horizontalHighlight.position.x, currentRow * blockSize + 50 - (blockSize / 2))];
			
			//Change some labels here, so they don't appear to have the old value for a second until they're updated
			[minutesLeftLabel setString:[NSString stringWithFormat:@"%02d", minutesLeft]];
			[secondsLeftLabel setString:[NSString stringWithFormat:@"%02d", secondsLeft]];
			
			// Update "% complete" number
			[percentComplete setString:[NSString stringWithFormat:@"%02d", (int)(((float)hits / (float)totalBlocksInPuzzle) * 100.0)]];
			
			// Set mark/fill button state
			if ([GameState sharedGameState].fillButtonSelected)
			{
				[actionsMenu setSelectedItem:fillButton];
				[fillButton selected];
				tapAction = FILL;
			}
			
			// array[x + y*size] === array[x][y]
			for (int row = 9; row >= 0; row--)
			{
				for (int col = 0; col < 10; col++)
				{
					// Assign value to the 2D array the game uses
					blockStatus[row][col] = [[[GameState sharedGameState].blockStatus objectAtIndex:(col + row * 10)] intValue];
					//NSLog(@"blockStatus[%i][%i] == %i (from index %i)", row, col, blockStatus[row][col], (col + row * 10));
					
					if (blockStatus[row][col] == FILLED)
					{
						// Draw "mini-map"
						CCSprite *b = [CCSprite spriteWithFile:@"8pxSquare.png"];
						[b setPosition:ccp(16 + (col + 1) * 8, 256 + (row + 1) * 8)];
						[self addChild:b z:2];
						
						// Draw filled tiles
						blockSprites[row][col] = [CCSprite spriteWithFile:@"fillIcon.png"];
						[blockSprites[row][col] setPosition:ccp(col * 20 + 120, row * 20 + 60)];
						[blockSprites[row][col].texture setAliasTexParameters];
						[self addChild:blockSprites[row][col] z:2];
					}
					
					if (blockStatus[row][col] == MARKED)
					{
						// Draw marked tiles
						blockSprites[row][col] = [CCSprite spriteWithFile:@"markIcon.png"];
						[blockSprites[row][col] setPosition:ccp(col * 20 + 120, row * 20 + 60)];
						[blockSprites[row][col].texture setAliasTexParameters];
						[self addChild:blockSprites[row][col] z:2];
					}
				}
			}
			
			for (int j = 1; j <= 10; j++)
			{
				// Set fading for completed clues
				int columnTotal = 0;
				int filledColumnTotal = 0;
				
				int rowTotal = 0;
				int filledRowTotal = 0;
				
				for (int i = 0; i < 10; i++) 
				{
					if (blockStatus[i][j - 1] == FILLED) filledColumnTotal++;
					if ([tileMapLayer tileGIDAt:ccp(j - 1, 9 - i)] == 1) columnTotal++;
					
					if (blockStatus[j - 1][i] == FILLED) filledRowTotal++;
					if ([tileMapLayer tileGIDAt:ccp(i, 10 - j)] == 1) rowTotal++;
				}
				
				if (rowTotal == filledRowTotal)
					[horizontalClues[j - 1] setColor:ccc3(66, 66, 66)];
				
				if (columnTotal == filledColumnTotal) 
					[verticalClues[j - 1] setColor:ccc3(66, 66, 66)];
			}
			
			// Set pause overlay up if enabled
			if ([GameState sharedGameState].paused) 
			{
				// Set 'paused' bool
				paused = TRUE;
				
				// Unschedule the timer
				[self unschedule:@selector(timer:)];
				
				// Make sure the overlay over puzzle
				[pauseOverlay setPosition:ccp(160, 200)];
				
				// Hide cursor highlights
				horizontalHighlight.visible = FALSE;
				verticalHighlight.visible = FALSE;
			}
		}
		else 
		{
			// Reset values here
			for (int i = 0; i < 100; i++) 
				[[GameState sharedGameState].blockStatus replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];

			[GameState sharedGameState].currentRow = currentRow;
			[GameState sharedGameState].currentColumn = currentColumn;
			[GameState sharedGameState].minutesLeft = minutesLeft;
			[GameState sharedGameState].secondsLeft = secondsLeft;
			[GameState sharedGameState].hits = hits;
			[GameState sharedGameState].misses = misses;
			[GameState sharedGameState].paused = FALSE;
		}

	}
	return self;
}

// This scheduled method currently commented out
/*
-(void) update:(ccTime)dt
{	
	// Update sprite positions based on row/column variables
	[verticalHighlight setPosition:ccp(currentColumn * blockSize + 110 - (blockSize / 2), verticalHighlight.position.y)];
	[horizontalHighlight setPosition:ccp(horizontalHighlight.position.x, currentRow * blockSize + 50 - (blockSize / 2))];
}
*/

-(void) timer:(ccTime)dt
{
	secondsLeft--;
	if (minutesLeft == 0 && secondsLeft < 0)
	{
		// So '00:00' is correctly shown instead of 00:-01
		secondsLeft = 0;
		
		// Game over
		[self lostGame];
	}
	else if (secondsLeft < 0)
	{
		minutesLeft--;
		secondsLeft = 59;
	}
	// Update labels for time
	[minutesLeftLabel setString:[NSString stringWithFormat:@"%02d", minutesLeft]];
	[secondsLeftLabel setString:[NSString stringWithFormat:@"%02d", secondsLeft]];
	
	// Update GameState
	[GameState sharedGameState].minutesLeft = minutesLeft;
	[GameState sharedGameState].secondsLeft = secondsLeft;
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
		[GameState sharedGameState].paused = TRUE;
	}
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

-(void) resume:(id)sender
{
	// Do nothing if game is not paused
	if (paused)
	{
		// Remove "paused" overlay and reschedule timer
		[self schedule:@selector(timer:) interval:1.0];
		
		// Move pause overlay off screen to the right, then reset position offscreen left
		[pauseOverlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(470, 200)]];
		
		// Show cursor highlights
		horizontalHighlight.visible = TRUE;
		verticalHighlight.visible = TRUE;
		
		paused = FALSE;
		[GameState sharedGameState].paused = FALSE;
	}
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

- (void)changeTapActionToMark:(id)sender
{
	tapAction = MARK;
	[GameState sharedGameState].fillButtonSelected = FALSE;
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

- (void)changeTapActionToFill:(id)sender
{
	tapAction = FILL;
	[GameState sharedGameState].fillButtonSelected = TRUE;
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// IDEA: Store the grid location of the first touch; if it doesn't equal the second, then ignore
	// Figure out initial location of touch
	UITouch *touch = [touches anyObject];
	
	if (touch && !paused) 
	{
		startPoint = previousPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		cursorPoint = ccp(verticalHighlight.position.x, horizontalHighlight.position.y);
		
		tapCount = touch.tapCount;
		if (justMovedCursor)
		{
			tapCount--;
			justMovedCursor = FALSE;
		}
		
		// If player has double tapped, try to place a mark/fill in the new block
		if (tapCount > 1)
		{
			switch (tapAction) 
			{
				case FILL: [self fillBlock]; break;
				case MARK: [self markBlock]; break;
			}
		}
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
		CGPoint relativeMovement = ccp(currentPoint.x - previousPoint.x, currentPoint.y - previousPoint.y);
		
		// Gets relative movement - slowed down by 25% - maybe easier to move the cursor?
		//CGPoint relativeMovement = ccp((currentPoint.x - previousPoint.x) * 0.75, (currentPoint.y - previousPoint.y) * 0.75);
		
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
			justMovedCursor = TRUE;
			
			// Update sprite positions based on row/column variables
			[verticalHighlight setPosition:ccp(currentColumn * blockSize + 110 - (blockSize / 2), verticalHighlight.position.y)];
			[horizontalHighlight setPosition:ccp(horizontalHighlight.position.x, currentRow * blockSize + 50 - (blockSize / 2))];
			
			// Save position values to the GameState singleton, which will be saved on exiting the game
			[GameState sharedGameState].currentRow = currentRow;
			[GameState sharedGameState].currentColumn = currentColumn;
			
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
		//CGPoint endPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		
		// This value is the sensitivity for filling/marking a block
		//int moveThreshold = 10;
		
		// If a tap is detected - i.e. if the movement of the finger is less than the threshold
		/*
		if (ccpDistance(startPoint, endPoint) < moveThreshold)
		{
			switch (tapAction) 
			{
				case FILL: [self fillBlock]; break;
				case MARK: [self markBlock]; break;
			}
		}
		 */
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
			
			// Update GameState singleton
			// array[x + y*size] === array[x][y]
			int tmpIndex = (currentColumn - 1) + (currentRow - 1) * 10;
			[[GameState sharedGameState].blockStatus replaceObjectAtIndex:tmpIndex withObject:[NSNumber numberWithInt:MARKED]];
		}
		// If marked, remove mark
		else
		{
			[self removeChild:blockSprites[currentRow - 1][currentColumn - 1] cleanup:FALSE];
			blockSprites[currentRow - 1][currentColumn - 1] = nil;
			blockStatus[currentRow - 1][currentColumn - 1] = BLANK;
			
			// Update GameState singleton
			// array[x + y*size] === array[x][y]
			int tmpIndex = (currentColumn - 1) + (currentRow - 1) * 10;
			[[GameState sharedGameState].blockStatus replaceObjectAtIndex:tmpIndex withObject:[NSNumber numberWithInt:BLANK]];
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
		// Play SFX if allowed
		if ([GameDataManager sharedManager].playSFX)
			[[SimpleAudioEngine sharedEngine] playEffect:@"hit.wav"];
		
		// Draw a "filled" block to the puzzle grid
		blockSprites[currentRow - 1][currentColumn - 1] = [CCSprite spriteWithFile:@"fillIcon.png"];
		[blockSprites[currentRow - 1][currentColumn - 1] setPosition:ccp(verticalHighlight.position.x, horizontalHighlight.position.y)];
		[blockSprites[currentRow - 1][currentColumn - 1].texture setAliasTexParameters];
		[self addChild:blockSprites[currentRow - 1][currentColumn - 1] z:2];
		
		// Update "status" 2D array
		blockStatus[currentRow - 1][currentColumn - 1] = FILLED;
		
		// Update GameState singleton
		// array[x + y*size] === array[x][y]
		int tmpIndex = (currentColumn - 1) + (currentRow - 1) * 10;
		[[GameState sharedGameState].blockStatus replaceObjectAtIndex:tmpIndex withObject:[NSNumber numberWithInt:FILLED]];
		//NSLog(@"blockStatus[%i][%i] == %i (index %i)", currentRow - 1, currentColumn - 1, FILLED, tmpIndex);

		// Add sprite to "minimap" section as well - these don't have to be referenced later
		CCSprite *b = [CCSprite spriteWithFile:@"8pxSquare.png"];
		[b setPosition:ccp(16 + currentColumn * 8, 256 + currentRow * 8)];	// New position
		[self addChild:b z:2];
		
		// Increment correct guess counter
		hits++;
		
		// Update GameState singleton
		[GameState sharedGameState].hits = hits;
		
		// Cycle through that particular row/column to see if all the blocks have been filled in; if so, "dim" the row/column clues
		int columnTotal = 0;
		int filledColumnTotal = 0;
		
		int rowTotal = 0;
		int filledRowTotal = 0;
		
		for (int i = 0; i < 10; i++) 
		{
			if (blockStatus[i][currentColumn - 1] == FILLED) filledColumnTotal++;
			if ([tileMapLayer tileGIDAt:ccp(currentColumn - 1, 9 - i)] == 1) columnTotal++;
			
			if (blockStatus[currentRow - 1][i] == FILLED) filledRowTotal++;
			if ([tileMapLayer tileGIDAt:ccp(i, 10 - currentRow)] == 1) rowTotal++;
		}
		
		//NSLog(@"Filled vs. total in column: %i, %i", filledColumnTotal, columnTotal);
		//NSLog(@"Filled vs. total in row: %i, %i", filledRowTotal, rowTotal);
		
		if (rowTotal == filledRowTotal)
			[horizontalClues[currentRow - 1] setColor:ccc3(66, 66, 66)];
		
		if (columnTotal == filledColumnTotal) 
			[verticalClues[currentColumn - 1] setColor:ccc3(66, 66, 66)];
		
		// Update "% complete" number
		[percentComplete setString:[NSString stringWithFormat:@"%02d", (int)(((float)hits / (float)totalBlocksInPuzzle) * 100.0)]];
		
		// Win condition
		if (hits == totalBlocksInPuzzle) 
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
		
		// Play SFX if allowed
		if ([GameDataManager sharedManager].playSFX)
			[[SimpleAudioEngine sharedEngine] playEffect:@"dud.wav"];
		
		// Create a label that shows how much time you lost
		CCLabel *label = [CCLabel labelWithString:@" " fontName:@"slkscr.ttf" fontSize:16];
		[label setPosition:ccp(verticalHighlight.position.x, horizontalHighlight.position.y)];
		[label setColor:ccc3(0,0,0)];
		[label.texture setAliasTexParameters];
		[self addChild:label z:5];
		
		// Move and fade actions
		id moveAction = [CCMoveTo actionWithDuration:1 position:ccp(verticalHighlight.position.x, horizontalHighlight.position.y + 20)];
		id fadeAction = [CCFadeOut actionWithDuration:1];
		id removeAction = [CCCallFuncN actionWithTarget:self selector:@selector(removeFromParent:)];
		
		// Subtract time based on how many mistakes you made previously
		switch (++misses)
		{
			case 1: 
				minutesLeft -= 2;
				[label setString:@"-2"];
			break;
			case 2: 
				minutesLeft -= 4;
				[label setString:@"-4"];
			break;
			default: 
				minutesLeft -= 8; 
				[label setString:@"-8"];
			break;
		}
		
		[label runAction:[CCSequence actions:[CCSpawn actions:moveAction, fadeAction, nil], removeAction, nil]];
		
		if (minutesLeft < 0)
		{
			minutesLeft = 0;
			secondsLeft = 0;
		}
		
		// Update GameState singleton
		[GameState sharedGameState].misses = misses;
		
		// Update time labels
		[minutesLeftLabel setString:[NSString stringWithFormat:@"%02d", minutesLeft]];
		[secondsLeftLabel setString:[NSString stringWithFormat:@"%02d", secondsLeft]];
	}
}

- (void)removeFromParent:(CCNode *)sprite
{
	[sprite.parent removeChild:sprite cleanup:YES];
}
																				
- (void)wonGame
{
	paused = TRUE;
	[self unschedule:@selector(timer:)];
	
	// Hide cursor highlights
	horizontalHighlight.visible = FALSE;
	verticalHighlight.visible = FALSE;
	
	// Create/move "you win" overlay down on screen
	CCSprite *overlay = [CCSprite spriteWithFile:@"winOverlay.png"];
	[overlay.texture setAliasTexParameters];
	[overlay setPosition:ccp(160, 630)];	// It's off screen to the top
	[self addChild:overlay z:4];
	
	// Add buttons to overlay
	CCMenuItem *continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton.png" selectedImage:@"continueButtonOn.png" target:self selector:@selector(goToLevelSelect:)];
	
	CCMenu *overlayMenu = [CCMenu menuWithItems:continueButton, nil];		// Create container menu object
	[overlayMenu setPosition:ccp(150, 50)];
	[overlay addChild:overlayMenu];
	
	// Load level!
	NSDictionary *level = [[GameDataManager sharedManager].levels objectAtIndex:[GameDataManager sharedManager].currentLevel - 1];	// -1 becos we're accessing an array
	
	// Draw finished puzzle image on to overlay
	CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:[level objectForKey:@"filename"]];
	
	// Try to shrink by half
	[tileMap setScale:0.5];
	
	[tileMap setPosition:ccp(100, 125)];
	[overlay addChild:tileMap];
	
	// Write image title on to overlay
	CCLabel *levelTitle = [CCLabel labelWithString:[level objectForKey:@"title"] fontName:@"slkscr.ttf" fontSize:24];
	[levelTitle setColor:ccc3(00, 00, 00)];
	[levelTitle.texture setAliasTexParameters];
	[levelTitle setPosition:ccp(150, 100)];
	
	[overlay addChild:levelTitle];
	
	// Move overlay downwards over play area
	[overlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];

	// Play SFX if allowed
	if ([GameDataManager sharedManager].playMusic)
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"winJingle.mp3" loop:FALSE];
	
	// Get whole array of default level times
	NSMutableArray *levelTimes = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"]];
	
	// Make mutable dictionary of current level times
	NSMutableDictionary *timeData = [NSMutableDictionary dictionaryWithDictionary: [levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1]];
	
	// Set local vars with the default/current values
	NSNumber *attempts = [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"attempts"];
	NSString *firstTime = [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"firstTime"];
	NSString *bestTime = [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"bestTime"];
	
	// Subtract minute/second values by 29/60 respectively, so that time shown is total time taken, rather than time left
	NSString *currentTime = [NSString stringWithFormat:@"%@:%@", [NSString stringWithFormat:@"%02d", 29 - minutesLeft], [NSString stringWithFormat:@"%02d", 60 - secondsLeft]];
	
	// Decide if they need to be updated
	if ([firstTime isEqualToString:@"--:--"])
		[timeData setValue:currentTime forKey:@"firstTime"];
	
	if ([bestTime isEqualToString:@"--:--"])
		[timeData setValue:currentTime forKey:@"bestTime"];
	
	// If currentTime is lower than bestTime
	if ([currentTime compare:bestTime options:NSNumericSearch] == NSOrderedAscending)
	{
		NSLog(@"Replacing %@ with %@ as the best time", bestTime, currentTime);
		[timeData setValue:currentTime forKey:@"bestTime"];
	}
	
	// Increment attempts
	[timeData setValue:[NSNumber numberWithInt:[attempts intValue] + 1] forKey:@"attempts"];
	
	// Re-save
	[levelTimes replaceObjectAtIndex:[GameDataManager sharedManager].currentLevel - 1 withObject:timeData];
	[[NSUserDefaults standardUserDefaults] setObject:levelTimes forKey:@"levelTimes"];
	
	// Player has won/lost, we don't need to restore playing position anymore
	[GameState sharedGameState].restoreLevel = FALSE;
}

- (void)lostGame
{
	paused = TRUE;
	[self unschedule:@selector(timer:)];
	
	// Hide cursor highlights
	horizontalHighlight.visible = FALSE;
	verticalHighlight.visible = FALSE;
	
	// Create/move "you win" overlay down on screen
	CCSprite *overlay = [CCSprite spriteWithFile:@"loseOverlay.png"];
	[overlay.texture setAliasTexParameters];
	[overlay setPosition:ccp(160, 630)];	// It's off screen to the top
	[self addChild:overlay z:4];
	
	// Add buttons to overlay
	CCMenuItem *continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton.png" selectedImage:@"continueButtonOn.png" target:self selector:@selector(goToLevelSelect:)];
	CCMenuItem *retryButton = [CCMenuItemImage itemFromNormalImage:@"retryButton.png" selectedImage:@"retryButtonOn.png" target:self selector:@selector(retryLevel:)];
	
	CCMenu *overlayMenu = [CCMenu menuWithItems:retryButton, continueButton, nil];		// Create container menu object
	[overlayMenu alignItemsVertically];
	[overlayMenu setPosition:ccp(150, 50)];
	[overlay addChild:overlayMenu];
	
	// Move overlay downwards over play area
	[overlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playMusic)
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"loseJingle.mp3" loop:FALSE];
	
	// Get whole array of default level times
	NSMutableArray *levelTimes = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"]];
	
	// Make mutable dictionary of current level times
	NSMutableDictionary *timeData = [NSMutableDictionary dictionaryWithDictionary: [levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1]];
	
	// Set local vars with the default/current values
	NSNumber *attempts = [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"attempts"];
	
	// Increment attempts
	[timeData setValue:[NSNumber numberWithInt:[attempts intValue] + 1] forKey:@"attempts"];
	
	// Re-save
	[levelTimes replaceObjectAtIndex:[GameDataManager sharedManager].currentLevel - 1 withObject:timeData];
	[[NSUserDefaults standardUserDefaults] setObject:levelTimes forKey:@"levelTimes"];
	
	// Player has won/lost, we don't need to restore playing position anymore
	[GameState sharedGameState].restoreLevel = FALSE;
}

- (void)goToLevelSelect:(id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[LevelSelectScene node]]];
}

- (void)retryLevel:(id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	// Just reload the scene
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[PlayScene node]]];
}

// This function is here to increase the "attempts" counter as well as send you back to the level select scene
- (void)quit:(id)sender
{
	// Get whole array of default level times
	NSMutableArray *levelTimes = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"levelTimes"]];
	
	// Make mutable dictionary of current level times
	NSMutableDictionary *timeData = [NSMutableDictionary dictionaryWithDictionary: [levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1]];
	
	// Set local vars with the default/current values
	NSNumber *attempts = [[levelTimes objectAtIndex:[GameDataManager sharedManager].currentLevel - 1] objectForKey:@"attempts"];
	
	// Increment attempts
	[timeData setValue:[NSNumber numberWithInt:[attempts intValue] + 1] forKey:@"attempts"];
	
	// Re-save
	[levelTimes replaceObjectAtIndex:[GameDataManager sharedManager].currentLevel - 1 withObject:timeData];
	[[NSUserDefaults standardUserDefaults] setObject:levelTimes forKey:@"levelTimes"];
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	// Player has won/lost, we don't need to restore playing position anymore
	[GameState sharedGameState].restoreLevel = FALSE;
	
	// Return to level select scene
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[LevelSelectScene node]]];
}

- (void)dealloc
{
	[tileMapLayer release];
	[super dealloc];
}

@end;