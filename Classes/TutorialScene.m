//
//  TutorialScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/26/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

/**
 Idea for tutorial: full puzzle logic, but no time limits, so players can experiment with controls. 
 Tutorial text at top of screen advances with taps, so player can go at own pace.
 Now just need to write tutorial text...
 */

#import "TutorialScene.h"
#import "TitleScene.h"

@implementation TutorialScene

- (id)init
{
	if ((self = [super init])) 
	{
		[self addChild:[TutorialLayer node] z:0];
	}
	return self;
}

@end

@implementation TutorialLayer

- (id)init
{
	if ((self = [super init])) 
	{
		// Set touch enabled
		[self setIsTouchEnabled:YES];
		
		// Add background to center of scene
		CCSprite *background = [CCSprite spriteWithFile:@"tutorialBackground.png"];
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
		
		// Load level!
		//NSDictionary *level = [[GameDataManager sharedManager].levels objectAtIndex:[GameDataManager sharedManager].currentLevel - 1];	// -1 becos we're accessing an array
		
		// Load tile map for this particular puzzle
		CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"tutorial.tmx"];
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
		
		step = 0;
		
		text[0] = @"Welcome to Nonogram Madness! Nonograms are logic puzzles; fill in the correct blocks to create a picture!";
		text[1] = @"Use your finger to move your cursor on the puzzle. Why don't you try it now?";
		text[2] = @"See the numbers in the rows and columns? You'll use those to solve the puzzle.";
		text[3] = @"The '0' in the first column means no blocks need to be filled in.";
		text[4] = @"Move your cursor all the way to the left, then tap to mark a block.";
		text[5] = @"Looks good! Do that for the whole column. You can double-tap then move the cursor to auto-fill.";
		text[6] = @"Take a look at the next column. The '10' means all the blocks are filled in.";
		text[7] = @"Tap the 'fill' button, move your cursor to the next column, then tap to fill in a block.";
		text[8] = @"Looks good! Do that for the whole column. You can double-tap then move the cursor to auto-fill.";
		text[9] = @"Next, let's take a look at the rows. Look at the top row. It's got 8 filled in blocks.";
		text[10] = @"You filled in the first one, so do 7 more after that.";
		text[11] = @"The next row is the same as the first, so go ahead and fill in those blocks too.";
		text[12] = @"The middle rows are more tricky. See how there are two numbers as clues?";
		text[13] = @"'2 4' means there are two sequential filled in blocks, a gap, then four filled in blocks.";
		text[14] = @"If you don't know how big the gap is, you can always come back to it later.";
		text[15] = @"You can also work from the bottom to the top. Go ahead and fill in the bottom row.";
		text[16] = @"Now you have a base you can build on moving upwards.";
		text[17] = @"See if you can finish this puzzle using what you've learned. There's no time limit!";
		text[18] = @"Good luck!";
		
		// Set up tutorial instruction label
		instructions = [CCLabel labelWithString:text[step] dimensions:CGSizeMake(290, 100) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:16];
		[instructions setColor:ccc3(00, 00, 00)];
		[instructions.texture setAliasTexParameters];
		[instructions setPosition:ccp(160, 415)];
		[self addChild:instructions];
		
		actions = [CCLabel labelWithString:@"(tap to continue)" dimensions:CGSizeMake(200, 16) alignment:UITextAlignmentRight fontName:@"slkscr.ttf" fontSize:16];
		[actions setColor:ccc3(00, 00, 00)];
		[actions.texture setAliasTexParameters];
		[actions setPosition:ccp(205, 370)];
		[self addChild:actions];
	}
	return self;
}

- (void)changeTapActionToMark:(id)sender
{
	tapAction = MARK;
}

- (void)changeTapActionToFill:(id)sender
{
	tapAction = FILL;
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Figure out initial location of touch
	UITouch *touch = [touches anyObject];
	
	if (touch) 
	{
		CGPoint currentPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];
		
		if (CGRectContainsPoint(CGRectMake(0, 360, 320, 120), currentPoint))
		{
			// Do nothing if at top of screen
			//NSLog(@"Ignoring starting touch");
		}
		else
		{
			startPoint = previousPoint = currentPoint;
			cursorPoint = ccp(verticalHighlight.position.x, horizontalHighlight.position.y);
		}
	}
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	
	if (touch) 
	{
		// Variables used to determine whether SFX should be played or not
		int previousRow = currentRow;
		int previousColumn = currentColumn;
		
		// User's finger
		CGPoint location = [touch locationInView: [touch view]];
		
		// The touches are always in "portrait" coordinates. You need to convert them to your current orientation
		CGPoint currentPoint = [[CCDirector sharedDirector] convertToGL:location];
		
		if (CGRectContainsPoint(CGRectMake(0, 360, 320, 120), currentPoint))
		{
			// Do nothing if at top of screen
			//NSLog(@"Ignoring movement");
		}
		else 
		{
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
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Determine block placement here
	UITouch *touch = [touches anyObject];
	
	if (touch)
	{
		// convert touch coords
		CGPoint endPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		
		if (CGRectContainsPoint(CGRectMake(0, 360, 320, 120), endPoint))
		{
			// Advance tutorial text if at top of screen
			step++;
			
			if (step > 18)
				step = 0;
			
			// Update label
			[instructions setString:text[step]];
			
			if (step == 18)
				[actions setString:@"(tap to read again)"];
			else if (step == 0)
				[actions setString:@"(tap to continue)"];
		}
		else 
		{
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
		
		// Increment correct guess counter
		hits++;
		
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
		
		if (rowTotal == filledRowTotal)
			[horizontalClues[currentRow - 1] setColor:ccc3(66, 66, 66)];
		
		if (columnTotal == filledColumnTotal) 
			[verticalClues[currentColumn - 1] setColor:ccc3(66, 66, 66)];
		
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
	}
}

- (void)wonGame
{
	// Hide cursor highlights
	horizontalHighlight.visible = FALSE;
	verticalHighlight.visible = FALSE;
	
	// Create/move "you win" overlay down on screen
	CCSprite *overlay = [CCSprite spriteWithFile:@"winOverlay.png"];
	[overlay.texture setAliasTexParameters];
	[overlay setPosition:ccp(160, 630)];	// It's off screen to the top
	[self addChild:overlay z:4];
	
	// Add buttons to overlay
	CCMenuItem *continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton.png" selectedImage:@"continueButtonOn.png" target:self selector:@selector(goToTitleScreen:)];
	
	CCMenu *overlayMenu = [CCMenu menuWithItems:continueButton, nil];		// Create container menu object
	[overlayMenu setPosition:ccp(150, 50)];
	[overlay addChild:overlayMenu];
	
	// Draw finished puzzle image on to overlay
	CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"tutorial.tmx"];
	
	// Try to shrink by half
	[tileMap setScale:0.5];
	
	[tileMap setPosition:ccp(100, 125)];
	[overlay addChild:tileMap];
	
	// Write image title on to overlay
	CCLabel *levelTitle = [CCLabel labelWithString:@"the letter 'g'" fontName:@"slkscr.ttf" fontSize:24];
	[levelTitle setColor:ccc3(00, 00, 00)];
	[levelTitle.texture setAliasTexParameters];
	[levelTitle setPosition:ccp(150, 100)];
	
	[overlay addChild:levelTitle];
	
	// Move overlay downwards over play area
	[overlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];
	
	// Set instructions label to contain congratulatory message
	[instructions setString:@"Congratulations! You understand the basics, now try some more difficult puzzles!"];
}

- (void)goToTitleScreen:(id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TitleScene node]]];
}

@end