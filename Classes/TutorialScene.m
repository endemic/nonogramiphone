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
		
		// Init variables used to keep track of correct/incorrect guesses
		hits = misses = 0;
		
		actionOnPreviousBlock = FALSE;
		
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
		
		// Load tile map for this particular puzzle
		CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"tutorial.tmx"];
		tileMapLayer = [[tileMap layerNamed:@"Layer 1"] retain];
		
		// Get details regarding how large the level is (e.g. 10x10 or 5x5)
		puzzleSize = tileMap.mapSize.width;
		
		
		NSLog(@"Puzzle size: %i", puzzleSize);
		
		// If smaller puzzle, show blockout overlay to signify that part of the larger grid is blank
		if (puzzleSize == 5) 
		{
			CCSprite *blockoutOverlay = [CCSprite spriteWithFile:@"blockoutOverlay2.png"];
			[blockoutOverlay setPosition:ccp(160, 200)];
			[self addChild:blockoutOverlay z:1];
			
			// User smaller highlight bars
			horizontalHighlight = [CCSprite spriteWithFile:@"highlightSmall.png"];
			verticalHighlight = [CCSprite spriteWithFile:@"highlightSmall.png"];
		}
		else 
		{
			horizontalHighlight = [CCSprite spriteWithFile:@"highlight.png"];
			verticalHighlight = [CCSprite spriteWithFile:@"highlight.png"];
		}
		
		// Init horizontal "cursor" highlight
		[horizontalHighlight setPosition:ccp(160, 240)];
		[self addChild:horizontalHighlight z:3];
		
		// Init vertical "cursor" highlight
		[verticalHighlight setPosition:ccp(120, 200)];
		[verticalHighlight setRotation:90.0];
		[self addChild:verticalHighlight z:3];
		
		// Current position of the cursor
		currentColumn = 1;
		currentRow = 10;
		
		// Update sprite positions based on row/column variables
		[verticalHighlight setPosition:ccp(currentColumn * blockSize + 110 - (blockSize / 2), verticalHighlight.position.y)];
		[horizontalHighlight setPosition:ccp(horizontalHighlight.position.x, currentRow * blockSize + 50 - (blockSize / 2))];
		
		// Init block status array
		for (int i = 0; i < puzzleSize; i++)
			for (int j = 0; j < puzzleSize; j++)
				blockStatus[i][j] = 0;		// Unmarked, unfilled
		
		// Create "clue" labels in arrays for rows and columns
		for (int i = 0; i < puzzleSize; i++)
		{
			// Create new label; set position/color/aliasing values
			verticalClues[i] = [CCLabel labelWithString:@"0\n" dimensions:CGSizeMake(25, 100) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:16];
			[verticalClues[i] setPosition:ccp(120 + (blockSize * i), 300)];
			[verticalClues[i] setColor:ccc3(0,0,0)];
			[verticalClues[i].texture setAliasTexParameters];
			[self addChild:verticalClues[i] z:3];
			
			horizontalClues[i] = [CCLabel labelWithString:@"0 " dimensions:CGSizeMake(100, 15) alignment:UITextAlignmentRight fontName:@"slkscr.ttf" fontSize:16];
			[horizontalClues[i] setPosition:ccp(60, 60 + (blockSize * i) + ((10 - puzzleSize) * blockSize))];	// Bizarre placement here corrects for smaller than 10x10 grids
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
		
		for (int i = 0; i < puzzleSize; i++) 
		{
			cluesTextHoriz = @"";
			cluesTextVert = @"";
			for (int j = 0; j < puzzleSize; j++) 
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
				[horizontalClues[(puzzleSize - 1) - i] setString:cluesTextHoriz];
			}
			else 
			{
				[horizontalClues[(puzzleSize - 1) - i] setColor:ccc3(66, 66, 66)];	// Set the text color as lighter since it's a zero - column already completed
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
		
		// Init graphic to highlight certain rows/colums the tutorial text is referencing
		tutorialHighlight = [CCSprite spriteWithFile:@"tutorialRowColumnHighlight.png"];
		[tutorialHighlight setPosition:ccp(160, 240)];
		[tutorialHighlight setOpacity:0];		// Hide for now
		[self addChild:tutorialHighlight z:1];
		
		// Initialize "steps" counter
		step = 0;
		
		text[0] = @"Welcome to Nonogram Madness! Nonograms are logic puzzles where you fill the correct blocks to create a picture!";
		text[1] = @"Use your finger to move the crosshairs around the puzzle. They determine where you mark or fill a block.";
		text[2] = @"The numbers in the rows and columns above the square grid are the clues you'll use to solve each puzzle.";
		text[3] = @"Each number represents the quantity of filled blocks that are in a row or column.";
		
		// Flash highlight over col #1
		text[4] = @"The '0' in the first column means that there are no filled blocks in that column; it's completely blank.";
		text[5] = @"Marking blocks is a good way to remember which blocks are blank. Move your cursor crosshairs all the way to the left.";
		text[6] = @"Double tap to mark one of the blocks. You can double tap then move the cursor to auto-fill. Mark all the blocks in this column.";
		
		// Flash highlight over col #2
		text[7] = @"Look at the next column. The '10' means all the blocks are filled in. Move your cursor over to this column.";
		text[8] = @"Change the action of your cursor from 'mark' to 'fill' by clicking the button in the lower left corner of the screen.";
		text[9] = @"Now go ahead and fill this whole column. You can double tap each block, or double tap then drag the cursor to auto-fill.";
		
		// Flash highlight over col #3
		text[10] = @"The third column is the same as the second. Go ahead and fill in all the blocks in this column as well.";
		
		// Flash highlight over col #4
		text[11] = @"The fourth column is tricky. There are two groups of two filled in blocks. But they could be anywhere in the column.";
		text[12] = @"Instead of guessing the placement of the blocks, let's try to solve some rows instead.";
		
		// Flash highlight over row #1
		text[13] = @"Look at the first row. The clue says it has eight filled blocks, and we've already got a start on it.";
		text[14] = @"Go ahead and finish filling in eight sequential blocks in this row. The second row is the same, so do that one too.";
		
		// Flash highlight over row #3
		text[15] = @"Notice how when you finish a row or column, the clues fade in color? That helps you know you've finished a section.";
		text[16] = @"The third row is already done. But let's mark the empty blocks so that we know those blocks are blank.";
		
		// Flash highlight over row #4
		text[17] = @"Go ahead and do the same to the fourth row.";
		
		// Flash highlight over rows #4-7
		text[18] = @"The next four rows are a problem. They're not finished, but we don't know exactly where to fill in blocks. Skip them for now.";
		
		// Flash highlight over rows #9 and #10
		text[19] = @"The last two rows are the same as the first two: eight sequential blocks filled in. You know the drill.";
		
		// Flash highlight over column #9
		text[20] = @"Let's go back to trying to solve columns. Take a look at the second to last column.";
		text[21] = @"You've filled in the first two blocks, but there are another six in the column.";
		text[22] = @"This time, you can start at the bottom and work your way upwards. Fill in six blocks starting at the bottom of the column.";
		
		// Flash highlight over column #8
		text[23] = @"Go ahead and do the same for the previous column, since it has the same clues.";
		
		// Flash highlight over rows #5 & 6
		text[24] = @"Almost done! There are only two rows left. See if you can complete them on your own. Good luck!";
		
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
		
		// Play music if allowed
		if ([GameDataManager sharedManager].playMusic)
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"play.mp3"];
	}
	return self;
}

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
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

- (void)resume:(id)sender
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
	}
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

- (void)changeTapActionToMark:(id)sender
{
	tapAction = MARK;
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
}

- (void)changeTapActionToFill:(id)sender
{
	tapAction = FILL;
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
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
			
			// Gets relative movement - slowed down by 10% - maybe easier to move the cursor?
			CGPoint relativeMovement = ccp((currentPoint.x - previousPoint.x) * 0.90, (currentPoint.y - previousPoint.y) * 0.90);
			
			// Add to current point the cursor is at
			cursorPoint = ccpAdd(cursorPoint, relativeMovement);
			
			// Get row/column values - 50 & 110 is the blank space on the x/y axes 
			currentRow = (cursorPoint.y - 50) / blockSize + 1;
			currentColumn = (cursorPoint.x - 110) / blockSize + 1;
			
			// Enforce positions in grid
			if (currentRow > 10) currentRow = 10;
			if (currentRow < 11 - puzzleSize) currentRow = 11 - puzzleSize;
			if (currentColumn > puzzleSize) currentColumn = puzzleSize;
			if (currentColumn < 1) currentColumn = 1;
			
			// If the cursor has changed rows
			if ((previousRow != currentRow || previousColumn != currentColumn))
			{
				justMovedCursor = TRUE;
				
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
			
			if (step > 24)
				step = 0;
			
			// Update label
			[instructions setString:text[step]];
			
			// Perform various actions here based on the step number
			switch (step) 
			{
				case 0:
					// Reset the highlight in case the player is viewing instructions for a 2nd time
					[tutorialHighlight stopAllActions];
					[tutorialHighlight setOpacity:0];
					tutorialHighlight.scaleY = 1;
					break;
				case 4:
				//case 5:
				//case 6:
					// Set up highlight
					[tutorialHighlight setPosition:ccp(120, 200)];
					[tutorialHighlight setRotation:90.0];		// Rotate vertical since we want to highlight a column
					
					// [CCBlink actionWithDuration:600 blinks:300]
					
					// Move & apply action
					[tutorialHighlight runAction:[CCFadeTo actionWithDuration:0.5 opacity:64]];
					break;
				case 7:
				//case 8:
				//case 9:
					[tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(140, 200)]];	// Col #2
					break;
				case 10:
					[tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];	// Col #3
					break;
				case 11:
				//case 12:
					[tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(180, 200)]];	// Col #4
					break;
				case 13:
				//case 14:
					[tutorialHighlight runAction:[CCSequence actions:[CCRotateTo actionWithDuration:0.5 angle:0], [CCMoveTo actionWithDuration:0.5 position:ccp(160, 240)], nil]];	// Row #1
					break;
				case 15:
				//case 16:
					[tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];		// Row #3
					break;
				case 17:
					[tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160,180)]];		// Row #4
					break;
				case 18:
					// Make it 4x high, rows #5-8
					[tutorialHighlight runAction:[CCSequence actions:[CCMoveTo actionWithDuration:0.5 position:ccp(160,130)], [CCScaleTo actionWithDuration:0.5 scaleX:1 scaleY:4], nil]];
					break;
				case 19:
					// Scale 2x
					[tutorialHighlight runAction:[CCSequence actions:[CCScaleTo actionWithDuration:0.5 scaleX:1 scaleY:2], [CCMoveTo actionWithDuration:0.5 position:ccp(160,70)], nil]];
					break;
				case 20:
					// Rotate back to original position, scale back to normal, move to column #9
					[tutorialHighlight runAction:[CCSequence actions:[CCRotateTo actionWithDuration:0.5 angle:90], [CCMoveTo actionWithDuration:0.5 position:ccp(280,200)], [CCScaleTo actionWithDuration:0.5 scaleX:1 scaleY:1], nil]];
					break;
				case 23:
					[tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(260,200)]];		// Column #8
					break;
				case 24:
					// Rows #5-6,  Make 2x high
					[tutorialHighlight runAction:[CCSequence actions:[CCRotateTo actionWithDuration:0.5 angle:180], [CCMoveTo actionWithDuration:0.5 position:ccp(160,150)], [CCScaleTo actionWithDuration:0.5 scaleX:1 scaleY:2], nil]];
					break;
				default:
					break;
			}
			
			if (step == 24)
				[actions setString:@"(tap to read again)"];
			else if (step == 0)
				[actions setString:@"(tap to continue)"];
		}
	}
}

-(void) markBlock
{
	// Toggle 'X' mark on a block if it's not already filled in
	if (blockStatus[currentRow - 1][currentColumn - 1] != FILLED)
	{
		// Play SFX if allowed
		if ([GameDataManager sharedManager].playSFX)
			[[SimpleAudioEngine sharedEngine] playEffect:@"mark.wav"];
		
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
		
		// Add sprite to "minimap" section as well - these don't have to be referenced later
		CCSprite *b = [CCSprite spriteWithFile:@"8pxSquare.png"];
		int offset = ((10 - puzzleSize) * 8) / 2;
		[b setPosition:ccp(16 + (currentColumn * 8) + offset, 256 + (currentRow * 8) - offset)];	// New position
		[self addChild:b z:2];
		
		// Increment correct guess counter
		hits++;
		
		// Cycle through that particular row/column to see if all the blocks have been filled in; if so, "dim" the row/column clues
		int columnTotal = 0;
		int filledColumnTotal = 0;
		
		int rowTotal = 0;
		int filledRowTotal = 0;
		
		for (int i = 0; i < puzzleSize; i++) 
		{
			if (blockStatus[i + (10 - puzzleSize)][currentColumn - 1] == FILLED) filledColumnTotal++;
			if ([tileMapLayer tileGIDAt:ccp(currentColumn - 1, (puzzleSize - 1) - i)] == 1) columnTotal++;	// Y value here WAS (10 - 1) - i; changed to reflect variable puzzle size
			
			if (blockStatus[currentRow - 1][i] == FILLED) filledRowTotal++;
			if ([tileMapLayer tileGIDAt:ccp(i, 10 - currentRow)] == 1) rowTotal++;
		}
		
		if (rowTotal == filledRowTotal)
			[horizontalClues[(currentRow - 1) - (10 - puzzleSize)] setColor:ccc3(66, 66, 66)];
		
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
		
		// Create a label that helps show you got one wrong
		CCLabel *label = [CCLabel labelWithString:@"miss!" fontName:@"slkscr.ttf" fontSize:16];
		[label setPosition:ccp(verticalHighlight.position.x, horizontalHighlight.position.y)];
		[label setColor:ccc3(0,0,0)];
		[label.texture setAliasTexParameters];
		[self addChild:label z:5];
		
		// Move and fade actions
		id moveAction = [CCMoveTo actionWithDuration:1 position:ccp(verticalHighlight.position.x, horizontalHighlight.position.y + 20)];
		id fadeAction = [CCFadeOut actionWithDuration:1];
		id removeAction = [CCCallFuncN actionWithTarget:self selector:@selector(removeFromParent:)];
		
		[label runAction:[CCSequence actions:[CCSpawn actions:moveAction, fadeAction, nil], removeAction, nil]];

		// Play SFX if allowed
		if ([GameDataManager sharedManager].playSFX)
			[[SimpleAudioEngine sharedEngine] playEffect:@"miss.wav"];
	}
}

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
	CCMenuItem *continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton.png" selectedImage:@"continueButtonOn.png" target:self selector:@selector(goToTitleScreen:)];
	
	CCMenu *overlayMenu = [CCMenu menuWithItems:continueButton, nil];		// Create container menu object
	[overlayMenu setPosition:ccp(150, 50)];
	[overlay addChild:overlayMenu];
	
	// Draw finished puzzle image on to overlay
	CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"tutorial.tmx"];
	
	// Offset the position of the displayed level sprite - the following logic is arcane, don't try to understand it
	int offset = ((10 - tileMap.mapSize.width) * (blockSize / 2)) / 2;
	
	// Try to shrink by half
	[tileMap setScale:0.5];
	
	[tileMap setPosition:ccp(100 + offset, 125 + offset)];
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
	
	step = 24;
	[actions setString:@"(tap to read again)"];
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playMusic)
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"winJingle.mp3" loop:FALSE];
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
	CCMenuItem *continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton.png" selectedImage:@"continueButtonOn.png" target:self selector:@selector(goToTitle::)];
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
}

- (void)retryLevel:(id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	// Just reload the scene
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TutorialScene node]]];
}

- (void)quit:(id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	// Make sure background music is stopped before going to next scene
	[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
	
	// Return to level select scene
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TitleScene node]]];
}

- (void)goToTitleScreen:(id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	// Make sure background music is stopped before going to next scene
	[[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TitleScene node]]];
}

@end