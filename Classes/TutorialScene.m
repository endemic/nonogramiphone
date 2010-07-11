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
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"levelSelect.mp3"];
	}
	return self;
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
	
	step = 24;
	[actions setString:@"(tap to read again)"];
	
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playMusic)
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"winJingle.mp3" loop:FALSE];
}

- (void)goToTitleScreen:(id)sender
{
	// Play SFX if allowed
	if ([GameDataManager sharedManager].playSFX)
		[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[TitleScene node]]];
}

@end