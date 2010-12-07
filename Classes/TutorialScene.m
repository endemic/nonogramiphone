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
		
		// Get window size
		CGSize winSize = [CCDirector sharedDirector].winSize;
		
		// Check if running on iPad
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) iPad = YES;
		else iPad = NO;
		
		// Add background to center of scene
		CCSprite *background;
		if (iPad) background = [CCSprite spriteWithFile:@"playBackground-hd.png"];
		else background = [CCSprite spriteWithFile:@"playBackground.png"];
		[background.texture setAliasTexParameters];	// Make aliased
		[background setPosition:ccp(winSize.width / 2, winSize.height / 2)];
		[self addChild:background z:0];
		
		// Set the width of puzzle blocks
		if (iPad) blockSize = 40;
		else blockSize = 20;
		
		// Init variables used to keep track of correct/incorrect guesses
		hits = misses = 0;
		
		actionOnPreviousBlock = FALSE;
		
		// Set up buttons to control mark/fill
		CCMenuItem *markButton, *fillButton, *pauseButton;
		if (iPad)
		{
			markButton = [CCMenuItemImage itemFromNormalImage:@"markButton-hd.png" selectedImage:@"markButtonSelected-hd.png" target:self selector:@selector(changeTapActionToMark:)];
			fillButton = [CCMenuItemImage itemFromNormalImage:@"fillButton-hd.png" selectedImage:@"fillButtonSelected-hd.png" target:self selector:@selector(changeTapActionToFill:)];
		}
		else 
		{
			markButton = [CCMenuItemImage itemFromNormalImage:@"markButton.png" selectedImage:@"markButtonSelected.png" target:self selector:@selector(changeTapActionToMark:)];
			fillButton = [CCMenuItemImage itemFromNormalImage:@"fillButton.png" selectedImage:@"fillButtonSelected.png" target:self selector:@selector(changeTapActionToFill:)];			
		}
		
		CCRadioMenu *actionsMenu = [CCRadioMenu menuWithItems:fillButton, markButton, nil];
		[actionsMenu alignItemsHorizontally];
		
		if (iPad) [actionsMenu setPosition:ccp(320 + 64, 46 + 32)];	// Doubled, with 64px/32px guttahs
		else [actionsMenu setPosition:ccp(160, 23)];
		
		[actionsMenu setSelectedItem:markButton];
		[markButton selected];
		tapAction = MARK;	// 0 for mark, 1 for fill
		[self addChild:actionsMenu z:3];
		
		// Set up "pause" button
		if (iPad) pauseButton = [CCMenuItemImage itemFromNormalImage:@"pauseButton-hd.png" selectedImage:@"pauseButtonOn-hd.png" target:self selector:@selector(pause:)];
		else pauseButton = [CCMenuItemImage itemFromNormalImage:@"pauseButton.png" selectedImage:@"pauseButtonOn.png" target:self selector:@selector(pause:)];
		
		CCMenu *pauseMenu = [CCMenu menuWithItems:pauseButton, nil];
		
		if (iPad) [pauseMenu setPosition:ccp(50 + 64, 830 + 32)];		// Doubled, with 64px/32px gutters
		else [pauseMenu setPosition:ccp(25, 415)];
		[self addChild:pauseMenu z:3];
		
		// Load tile map for this particular puzzle
		CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"tutorial.tmx"];
		tileMapLayer = [[tileMap layerNamed:@"Layer 1"] retain];
		
		// Get details regarding how large the level is (e.g. 10x10 or 5x5)
		puzzleSize = tileMap.mapSize.width;
	
		// If smaller puzzle, show blockout overlay to signify that part of the larger grid is blank
		if (puzzleSize == 5) 
		{
			CCSprite *blockoutOverlay;
			if (iPad) blockoutOverlay = [CCSprite spriteWithFile:@"blockoutOverlay2-hd.png"];
			else blockoutOverlay = [CCSprite spriteWithFile:@"blockoutOverlay2.png"];
			if (iPad) [blockoutOverlay setPosition:ccp(winSize.width / 2, 400 + 32)];
			else [blockoutOverlay setPosition:ccp(160, 200)];
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
		
		// Hide cursor crosshairs if on iPad
		if (iPad)
		{
			[verticalHighlight setVisible:NO];
			[horizontalHighlight setVisible:NO];
		}
		
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
			if (iPad) verticalClues[i] = [CCLabel labelWithString:@"0\n" dimensions:CGSizeMake(50, 200) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:32];
			else verticalClues[i] = [CCLabel labelWithString:@"0\n" dimensions:CGSizeMake(25, 100) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:16];
			if (iPad) [verticalClues[i] setPosition:ccp(240 + 64 + (blockSize * i), 600 + 32)];		// Doubled, plus 64px/32px gutters
			else [verticalClues[i] setPosition:ccp(120 + (blockSize * i), 300)];
			[verticalClues[i] setColor:ccc3(0,0,0)];
			[verticalClues[i].texture setAliasTexParameters];
			[self addChild:verticalClues[i] z:3];
			
			if (iPad) horizontalClues[i] = [CCLabel labelWithString:@"0 " dimensions:CGSizeMake(200, 30) alignment:UITextAlignmentRight fontName:@"slkscr.ttf" fontSize:32];
			else horizontalClues[i] = [CCLabel labelWithString:@"0 " dimensions:CGSizeMake(100, 15) alignment:UITextAlignmentRight fontName:@"slkscr.ttf" fontSize:16];
			if (iPad) [horizontalClues[i] setPosition:ccp(120 + 64, 120 + 32 + (blockSize * i) + ((10 - puzzleSize) * blockSize))];	// Bizarre placement here corrects for smaller than 10x10 grids
			else [horizontalClues[i] setPosition:ccp(60, 60 + (blockSize * i) + ((10 - puzzleSize) * blockSize))];	// Bizarre placement here corrects for smaller than 10x10 grids
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
				[horizontalClues[(puzzleSize - 1) - i] setColor:ccc3(77, 77, 77)];	// Set the text color as lighter since it's a zero - column already completed
			}
			
			
			if ([cluesTextVert length] > 0)
			{
				[verticalClues[i] setString:cluesTextVert];
				NSArray *numberOfVerticalClues = [cluesTextVert componentsSeparatedByString:@"\n"];
				if (iPad) [verticalClues[i] setPosition:ccp(verticalClues[i].position.x, 400 + 32 + (([numberOfVerticalClues count] - 1) * 34))];	// Doubled, plus extra 64px/32px gutter
				else [verticalClues[i] setPosition:ccp(verticalClues[i].position.x, 200 + (([numberOfVerticalClues count] - 1) * 17))];
			}
			else
			{
				[verticalClues[i] setColor:ccc3(77, 77, 77)];	// Set the text color as lighter since it's a zero - column already completed
				if (iPad) [verticalClues[i] setPosition:ccp(verticalClues[i].position.x, 434 + 32)];	// Doubled, plus extra 64px/32px gutter
				else [verticalClues[i] setPosition:ccp(verticalClues[i].position.x, 217)];
			}
		}
		
		// Set up % complete label
		if (iPad) percentComplete = [CCLabel labelWithString:@"00" fontName:@"slkscr.ttf" fontSize:96];
		else percentComplete = [CCLabel labelWithString:@"00" fontName:@"slkscr.ttf" fontSize:48];
		if (iPad) [percentComplete setPosition:ccp(520 + 64, 844 + 32)];	// Doubled, plus extra 64px/32px gutter
		else [percentComplete setPosition:ccp(260, 422)];
		[percentComplete.texture setAliasTexParameters];
		[percentComplete setColor:ccc3(00, 00, 00)];
		[self addChild:percentComplete z:3];
		
		// Set up timer labels/internal variables/scheduler
		[self schedule:@selector(timer:) interval:1.0];
		
		minutesLeft = 30;
		secondsLeft = 0;
		
		if (iPad) minutesLeftLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%02d", minutesLeft] dimensions:CGSizeMake(200, 200) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:96];
		else minutesLeftLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%02d", minutesLeft] dimensions:CGSizeMake(100, 100) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:48];
		if (iPad) [minutesLeftLabel setPosition:ccp(220 + 64, 790 + 32)];	// Doubled, plus extra 64px/32px gutter
		else [minutesLeftLabel setPosition:ccp(110, 395)];
		[minutesLeftLabel setColor:ccc3(00, 00, 00)];
		[minutesLeftLabel.texture setAliasTexParameters];
		[self addChild:minutesLeftLabel z:3];
		
		if (iPad) secondsLeftLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%02d", secondsLeft] dimensions:CGSizeMake(200,200) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:96];
		else secondsLeftLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%02d", secondsLeft] dimensions:CGSizeMake(100,100) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:48];
		if (iPad) [secondsLeftLabel setPosition:ccp(220 + 64, 710 + 32)];	// Doubled, plus extra 64px/32px gutter
		else [secondsLeftLabel setPosition:ccp(110, 355)];
		[secondsLeftLabel setColor:ccc3(00, 00, 00)];
		[secondsLeftLabel.texture setAliasTexParameters];
		[self addChild:secondsLeftLabel z:3];
		
		// Not paused to start with!
		paused = FALSE;
		
		// Set up pause overlay
		if (iPad) pauseOverlay = [CCSprite spriteWithFile:@"pauseOverlay-hd.png"];
		else pauseOverlay = [CCSprite spriteWithFile:@"pauseOverlay.png"];
		[pauseOverlay.texture setAliasTexParameters];
		if (iPad) [pauseOverlay setPosition:ccp(-winSize.width / 2, 400 + 32)];	// Doubled, plus 34px vertical gutter
		else [pauseOverlay setPosition:ccp(-winSize.width / 2, 200)];	// It's off screen to the left
		[self addChild:pauseOverlay z:4];
		
		// Add buttons to overlay
		CCMenuItem *resumeButton, *quitButton;
		if (iPad) resumeButton = [CCMenuItemImage itemFromNormalImage:@"resumeButton-hd.png" selectedImage:@"resumeButtonOn-hd.png" target:self selector:@selector(resume:)];
		else resumeButton = [CCMenuItemImage itemFromNormalImage:@"resumeButton.png" selectedImage:@"resumeButtonOn.png" target:self selector:@selector(resume:)];
		
		if (iPad) quitButton = [CCMenuItemImage itemFromNormalImage:@"quitButton-hd.png" selectedImage:@"quitButtonOn-hd.png" target:self selector:@selector(quit:)];
		else quitButton = [CCMenuItemImage itemFromNormalImage:@"quitButton.png" selectedImage:@"quitButtonOn.png" target:self selector:@selector(quit:)];
		
		CCMenu *overlayMenu = [CCMenu menuWithItems:resumeButton, quitButton, nil];		// Create container menu object
		[overlayMenu alignItemsVertically];
		if (iPad) [overlayMenu setPosition:ccp(300, 100)];	// Doubled
		else [overlayMenu setPosition:ccp(150, 50)];
		[pauseOverlay addChild:overlayMenu];
		
		// Init graphic to highlight certain rows/colums the tutorial text is referencing
		if (iPad) tutorialHighlight = [CCSprite spriteWithFile:@"tutorialRowColumnHighlight-hd.png"];
		else tutorialHighlight = [CCSprite spriteWithFile:@"tutorialRowColumnHighlight.png"];
		[tutorialHighlight setPosition:ccp(winSize.width / 2, winSize.height / 2)];
		[tutorialHighlight setOpacity:0];		// Hide for now
		[self addChild:tutorialHighlight z:1];
		
		// Initialize "steps" counter
		step = 0;

		text = [[NSMutableArray arrayWithObjects:
				@"Welcome to Nonogram Madness! Nonograms are logic puzzles where you fill blocks in a grid to make a picture.",
				@"You choose which block to fill by using the orange cursor, which you move with your finger.",
				@"Touch anywhere near the puzzle and move your finger to move the cursor. Why don't you try it out?",
				@"To complete each puzzle, you'll use the numbers above each column and to the left of each row.",
				@"Those numbers show how many blocks are 'filled' in each row or column.",
				// Highlight over col #1 (step 5)
				@"For example, the '5' in the far left column means each block in that column is filled in.",	// 5
				@"To fill a block, click the    'fill' button at the bottom of the screen.",
				@"Now, move your cursor over to the far left column and double-tap.",
				@"Fill in that entire column. Try double-tapping then moving your finger. Don't worry if you make a mistake.",
				@"Mistakes will drain your time limit in normal puzzles, but not here.",
				// Highlight over col #2 (step 10)
				@"The next column is tricky. There are two filled blocks somewhere in this column.",	// 10
				@"'1 1' means there is a single filled block, a space of one or more, then another filled block.",
				@"However, we haven't completed enough of the puzzle to know where those filled blocks are.",
				// Highlight over col #3 (step 13)
				@"Let's move on to the third column. The clue tells us there are three single filled blocks.",	// 13
				@"Since the column is only 5 blocks tall, we can easily figure out where the filled blocks should go.",
				@"There has to be a gap of at least one empty block between each group of filled ones.",
				@"Go ahead and fill in the three blocks with a gap between each one in this column.",
				// Highlight over col #4 (16)
				@"The same idea applies to the next. The clue '1 3' with one gap fills the whole five blocks in the column.",	// 17
				@"Go ahead and fill in the first block, skip a block, then fill in the remaining three.",
				// Highlight over col #5
				@"The last column has a clue of '0', which means no blocks are filled there.",	// 19
				@"To help remember which blocks are intentionally blank, you can 'mark' them.",
				@"Tap the 'mark' button at the bottom of the screen, then double tap each block in this column.",
				@"It's just a helpful reminder that you don't need to worry about those blocks.",
				@"You can also remove a mark by double tapping a marked block.",
				// Highlight over row #1
				@"Making progress! Let's move on to the rows. You can see the first row is almost complete",	// 24
				@"You have three of the four blocks in this row filled in already. Go ahead and fill the last one.",
				// Highlight over row #2
				@"The second row is already done. If you like, you can \n'mark' the remaining blocks in this row.",	// 26
				// Highlight over rows #3-4
				@"Both these rows are completed as well. Go ahead and 'mark' the blank blocks in these two rows.",	// 27
				// Highlight over row #5
				@"Last row! I'm sure you can figure this one out.",	// 28
				nil] retain];
		
		// Modify some text if user is on iPad
		if (iPad)
		{
			[text replaceObjectAtIndex:1 withObject:@"You choose which block to fill by just tapping it."];
			[text replaceObjectAtIndex:2 withObject:@"You can also tap and hold, then move your finger around to fill multiple blocks."];
			[text replaceObjectAtIndex:7 withObject:@"Now, tap any of the blocks in the far left column."];
			[text replaceObjectAtIndex:8 withObject:@"Fill in that entire column. Try tapping then moving your finger downwards. Don't worry if you make a mistake."];
		}
		
		// Set up background for instructions
		if (iPad) textBackground = [CCSprite spriteWithFile:@"textBackground-hd.png"];
		else textBackground = [CCSprite spriteWithFile:@"textBackground.png"];
		if (iPad) [textBackground setPosition:ccp(322 + 64, 190 + 32)];
		else [textBackground setPosition:ccp(161, 95)];
		[self addChild:textBackground z:2];
		
		// Set up tutorial instruction label
		if (iPad) instructions = [CCLabel labelWithString:[text objectAtIndex:step] dimensions:CGSizeMake(580, 200) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:32];
		else instructions = [CCLabel labelWithString:[text objectAtIndex:step] dimensions:CGSizeMake(290, 100) alignment:UITextAlignmentLeft fontName:@"slkscr.ttf" fontSize:16];
		[instructions setColor:ccc3(00, 00, 00)];
		[instructions.texture setAliasTexParameters];
		if (iPad) [instructions setPosition:ccp(384, 222)];		// Doubled, plus 64px/32px gutter
		else [instructions setPosition:ccp(160, 95)];
		[self addChild:instructions z:3];
		
		if (iPad) actions = [CCLabel labelWithString:@"(tap to continue)" dimensions:CGSizeMake(400, 32) alignment:UITextAlignmentRight fontName:@"slkscr.ttf" fontSize:32];
		else actions = [CCLabel labelWithString:@"(tap to continue)" dimensions:CGSizeMake(200, 16) alignment:UITextAlignmentRight fontName:@"slkscr.ttf" fontSize:16];
		[actions setColor:ccc3(00, 00, 00)];
		[actions.texture setAliasTexParameters];
		if (iPad) [actions setPosition:ccp(474, 138)];
		else [actions setPosition:ccp(205, 53)];
		[self addChild:actions z:3];
		
		// Play music if allowed
		if ([GameDataManager sharedManager].playMusic)
			[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"tutorial.mp3"];
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
		// Get window size
		CGSize winSize = [CCDirector sharedDirector].winSize;
		
		// Move "paused" overlay on top of puzzle, and unschedule the timer
		[self unschedule:@selector(timer:)];
		
		// Make sure the overlay is on the left side of the screen
		if (iPad) [pauseOverlay setPosition:ccp(-winSize.width / 2, 400 + 32)];	// Doubled, plus extra 64px/32px gutter
		else [pauseOverlay setPosition:ccp(-winSize.width / 2, 200)];
		
		// Move pause overlay into position
		if (iPad) [pauseOverlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(winSize.width / 2, 400 + 32)]];	// Doubled, plus extra 64px/32px gutter
		else [pauseOverlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(winSize.width / 2, 200)]];
		
		// Hide tutorial text
		textBackground.visible = FALSE;
		instructions.visible = FALSE;
		actions.visible = FALSE;
		
		// Hide cursor highlights
		if (!iPad)
		{
			horizontalHighlight.visible = FALSE;
			verticalHighlight.visible = FALSE;
		}
		
		paused = TRUE;
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
		// Get window size
		CGSize winSize = [CCDirector sharedDirector].winSize;
		
		// Remove "paused" overlay and reschedule timer
		[self schedule:@selector(timer:) interval:1.0];
		
		// Move pause overlay off screen to the right, then reset position offscreen left
		if (iPad) [pauseOverlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(winSize.width * 1.5, 400 + 32)]];	// Doubled, plus extra 64px/32px gutter
		else [pauseOverlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(winSize.width * 1.5, 200)]];
		
		// Show tutorial text
		textBackground.visible = TRUE;
		instructions.visible = TRUE;
		actions.visible = TRUE;
		
		// Show cursor highlights
		if (!iPad)
		{
			horizontalHighlight.visible = TRUE;
			verticalHighlight.visible = TRUE;
		}
		
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
	
	if (touch && !paused) 
	{
		startPoint = previousPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		cursorPoint = ccp(verticalHighlight.position.x, horizontalHighlight.position.y);
		
		if (!iPad)
		{
			tapCount = touch.tapCount;
			if (justMovedCursor)
			{
				tapCount--;
				justMovedCursor = FALSE;
			}
			
			lockedRow = lockedColumn = -1;
			
			// If player has double tapped, try to place a mark/fill in the new block - or any regular ol' touch on iPad
			if (tapCount > 1)
			{
				switch (tapAction) 
				{
					case FILL: [self fillBlock]; break;
					case MARK: [self markBlock]; break;
				}
			}
		}
		else 
		{
			// Get row/column values - change the number of pixels blank space
			currentRow = (startPoint.y - 132) / blockSize + 1;
			currentColumn = (startPoint.x - 284) / blockSize + 1;
			
			//NSLog(@"Tap point: %f, %f", startPoint.x, startPoint.y);
			//NSLog(@"Current row/col: %i, %i", currentRow, currentColumn);
			
			// Only try to mark/fill blocks if the user's finger is in valid place
			if (11 - currentRow >= 1 && 11 - currentRow <= puzzleSize && currentColumn >= 1 && currentColumn <= puzzleSize)
			{
				//NSLog(@"Trying to do action!");
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
	
	if (touch && !paused) 
	{
		// Variables used to determine whether SFX should be played or not
		int previousRow = currentRow;
		int previousColumn = currentColumn;
		
		// User's finger
		CGPoint location = [touch locationInView: [touch view]];
		
		// The touches are always in "portrait" coordinates. You need to convert them to your current orientation
		CGPoint currentPoint = [[CCDirector sharedDirector] convertToGL:location];
		
		if (!iPad)
		{
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
			
			// If user has started moving cursor sideways or downward, and has been locked to that movement, enforce here
			if (lockedColumn != -1) currentColumn = lockedColumn;
			if (lockedRow != -1) currentRow = lockedRow;
			
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
				if (tapCount > 1) 
				{
					// Lock into a specific row or column
					if (lockedRow == -1 && lockedColumn == -1)
					{
						// Changed rows, which means moving up or down - lock into the current column
						if (previousRow != currentRow) 
							lockedColumn = currentColumn;
						// Changed columns, which means moving left or right - lock into the current row
						else if (previousColumn != currentColumn)
							lockedRow = currentRow;
					}
					
					switch (tapAction) 
					{
						case FILL: [self fillBlock]; break;
						case MARK: [self markBlock]; break;
					}
				}
			}
			
		}
		// iPad
		else
		{
			// Get row/column values - change the number of pixels blank space
			currentRow = (currentPoint.y - 132) / blockSize + 1;
			currentColumn = (currentPoint.x - 284) / blockSize + 1;
			
			// Only try to mark/fill blocks if the user's finger has moved to a new block
			if (11 - currentRow >= 1 && 11 - currentRow <= puzzleSize && currentColumn >= 1 && currentColumn <= puzzleSize && (previousRow != currentRow || previousColumn != currentColumn))
				switch (tapAction) 
			{
				case FILL: [self fillBlock]; break;
				case MARK: [self markBlock]; break;
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
		// Remove this value if it existsz
		lockMark = 0;
		
		// convert touch coords
		CGPoint endPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		
		// Only advance tutorial text if both start/end touches are within the text box bounds
		if ((!iPad && CGRectContainsPoint(CGRectMake(10, 44, 300, 100), startPoint) && CGRectContainsPoint(CGRectMake(10, 44, 300, 100), endPoint)) ||
			(iPad && CGRectContainsPoint(CGRectMake(84, 120, 600, 200), startPoint) && CGRectContainsPoint(CGRectMake(84, 120, 600, 200), endPoint)))
		{
			// Advance tutorial text
			step++;
			
			if (step >= [text count])
				step = 0;
			
			// Update label
			[instructions setString:[text objectAtIndex:step]];
			
			// Perform various actions here based on the step number
			switch (step) 
			{
				case 0:
					// Reset the highlight in case the player is viewing instructions for a 2nd time
					[tutorialHighlight stopAllActions];
					[tutorialHighlight setOpacity:0];
					tutorialHighlight.scaleY = 1;
					tutorialHighlight.rotation = 0;
					break;
				case 5:
					// Set up highlight
					if (iPad) [tutorialHighlight setPosition:ccp(240 + 64, 400 + 32)];	// Col #1
					else [tutorialHighlight setPosition:ccp(120, 200)];	// Col #1
					[tutorialHighlight setScaleY:5];
					
					// [CCBlink actionWithDuration:600 blinks:300]
					
					// Move & apply action
					[tutorialHighlight runAction:[CCFadeTo actionWithDuration:0.5 opacity:64]];
					break;
				case 10:
					if (iPad) [tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(280 + 64, 400 + 32)]];	// Col #2
					else [tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(140, 200)]];	// Col #2
					break;
				case 13:
					if (iPad) [tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(320 + 64, 400 + 32)]];	// Col #3
					else [tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];	// Col #3
					break;
				case 17:
					if (iPad) [tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(360 + 64, 400 + 32)]];	// Col #4
					else [tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(180, 200)]];	// Col #4
					break;
				case 19:
					if (iPad) [tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(400 + 64, 400 + 32)]];	// Col #5
					else [tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(200, 200)]];	// Col #5
					break;
				case 24:
					if (iPad) [tutorialHighlight runAction:[CCSequence actions:[CCRotateTo actionWithDuration:0.5 angle:90], [CCMoveTo actionWithDuration:0.5 position:ccp(320 + 64, 480 + 32)], nil]];	// Row #1
					else [tutorialHighlight runAction:[CCSequence actions:[CCRotateTo actionWithDuration:0.5 angle:90], [CCMoveTo actionWithDuration:0.5 position:ccp(160, 240)], nil]];	// Row #1
					break;
				case 26:
					if (iPad) [tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(320 + 64, 440 + 32)]];		// Row #2
					else [tutorialHighlight runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 220)]];		// Row #2
					break;
				case 27:
					if (iPad) [tutorialHighlight runAction:[CCSequence actions:[CCScaleTo actionWithDuration:0.5 scaleX:2 scaleY:5], [CCMoveTo actionWithDuration:0.5 position:ccp(320 + 64, 380 + 32)], nil]];	// Rows #3-4
					else [tutorialHighlight runAction:[CCSequence actions:[CCScaleTo actionWithDuration:0.5 scaleX:2 scaleY:5], [CCMoveTo actionWithDuration:0.5 position:ccp(160,190)], nil]];	// Rows #3-4
					break;
				case 28:
					// Scale back to normal, move over row #5
					if (iPad) [tutorialHighlight runAction:[CCSequence actions:[CCMoveTo actionWithDuration:0.5 position:ccp(320 + 64, 320 + 32)], [CCScaleTo actionWithDuration:0.5 scaleX:1 scaleY:5], nil]];
					else [tutorialHighlight runAction:[CCSequence actions:[CCMoveTo actionWithDuration:0.5 position:ccp(160,160)], [CCScaleTo actionWithDuration:0.5 scaleX:1 scaleY:5], nil]];
					break;
				default:
					break;
			}
			
			if (step == [text count] - 1)
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
		
		// If not marked and not locked, mark
		if (blockStatus[currentRow - 1][currentColumn - 1] != MARKED && (lockMark == 1 || lockMark == 0))
		{
			// Lock into making marks!
			lockMark = 1;
			
			if (iPad)
			{
				blockSprites[currentRow - 1][currentColumn - 1] = [CCSprite spriteWithFile:@"markIcon-hd.png"];
				[blockSprites[currentRow - 1][currentColumn - 1] setPosition:ccp((currentColumn - 1) * blockSize + 284 + (blockSize / 2), (currentRow - 1) * blockSize + 132 + (blockSize / 2))];
			}
			else 
			{
				blockSprites[currentRow - 1][currentColumn - 1] = [CCSprite spriteWithFile:@"markIcon.png"];
				[blockSprites[currentRow - 1][currentColumn - 1] setPosition:ccp(verticalHighlight.position.x, horizontalHighlight.position.y)];
			}
			
			[blockSprites[currentRow - 1][currentColumn - 1].texture setAliasTexParameters];
			[self addChild:blockSprites[currentRow - 1][currentColumn - 1] z:2];
			blockStatus[currentRow - 1][currentColumn - 1] = MARKED;
		}
		// If marked, remove mark
		else if (blockStatus[currentRow - 1][currentColumn - 1] == MARKED && (lockMark == 2 || lockMark == 0))
		{
			// Lock into removing marks
			lockMark = 2;
			
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
		if (iPad)
		{
			blockSprites[currentRow - 1][currentColumn - 1] = [CCSprite spriteWithFile:@"fillIcon-hd.png"];
			[blockSprites[currentRow - 1][currentColumn - 1] setPosition:ccp((currentColumn - 1) * blockSize + 284 + (blockSize / 2), (currentRow - 1) * blockSize + 132 + (blockSize / 2))];
		}
		else 
		{
			blockSprites[currentRow - 1][currentColumn - 1] = [CCSprite spriteWithFile:@"fillIcon.png"];
			[blockSprites[currentRow - 1][currentColumn - 1] setPosition:ccp(verticalHighlight.position.x, horizontalHighlight.position.y)];
		}
		
		[blockSprites[currentRow - 1][currentColumn - 1].texture setAliasTexParameters];
		[self addChild:blockSprites[currentRow - 1][currentColumn - 1] z:2];
		
		// Update "status" 2D array
		blockStatus[currentRow - 1][currentColumn - 1] = FILLED;

		// Add sprite to "minimap" section as well - these don't have to be referenced later
		CCSprite *b;
		int offset;
		
		if (iPad)
		{
			b = [CCSprite spriteWithFile:@"8pxSquare-hd.png"];
			offset = ((10 - puzzleSize) * 16) / 2;
			[b setPosition:ccp(32 + 64 + (currentColumn * 16) + offset, 512 + 32 + (currentRow * 16) - offset)];	// Doubled, 64px/32px gutters
		}
		else
		{
			b = [CCSprite spriteWithFile:@"8pxSquare.png"];
			offset = ((10 - puzzleSize) * 8) / 2;
			[b setPosition:ccp(16 + (currentColumn * 8) + offset, 256 + (currentRow * 8) - offset)];	// New position
		}
		
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
			[horizontalClues[(currentRow - 1) - (10 - puzzleSize)] setColor:ccc3(77, 77, 77)];
		
		if (columnTotal == filledColumnTotal)
			[verticalClues[currentColumn - 1] setColor:ccc3(77, 77, 77)];
		
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
		// Decrement tap count, so that user doesn't keep filling in wrong blocks
		tapCount--;
		justMovedCursor = TRUE;
		
		// Take off time here, as well as play sfx of some kind and shake the screen
		id shake = [CCShaky3D actionWithRange:3 shakeZ:FALSE grid:ccg(5, 5) duration:0.1];
		
		// Run "shake" action, then return the grid to its original state
		[self runAction:[CCSequence actions:shake, [CCStopGrid action], nil]];
		
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
	
	// Hide tutorial text
	textBackground.visible = FALSE;
	instructions.visible = FALSE;
	actions.visible = FALSE;
	
	// Create/move "you win" overlay down on screen
	CCSprite *overlay;
	if (iPad)
	{
		overlay = [CCSprite spriteWithFile:@"winOverlay-hd.png"];
		[overlay setPosition:ccp(384, 1292)];	// Doubled, 64px/32px gutters
	}
	else
	{
		overlay = [CCSprite spriteWithFile:@"winOverlay.png"];
		[overlay setPosition:ccp(160, 630)];	// It's off screen to the top
	}
	[overlay.texture setAliasTexParameters];
	[self addChild:overlay z:4];
	
	// Add buttons to overlay
	CCMenuItem *continueButton;
	if (iPad) continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton-hd.png" selectedImage:@"continueButtonOn-hd.png" target:self selector:@selector(goToTitleScreen:)];
	else continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton.png" selectedImage:@"continueButtonOn.png" target:self selector:@selector(goToTitleScreen:)];
	CCMenu *overlayMenu = [CCMenu menuWithItems:continueButton, nil];		// Create container menu object
	if (iPad) [overlayMenu setPosition:ccp(300, 100)];
	else [overlayMenu setPosition:ccp(150, 50)];
	[overlay addChild:overlayMenu];
	
	// Draw finished puzzle image on to overlay
	CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"tutorial.tmx"];
	
	// Offset the position of the displayed level sprite - the following logic is arcane, don't try to understand it
	int offset = ((10 - tileMap.mapSize.width) * (blockSize / 2)) / 2;
	
	// Try to shrink by half if not iPadz
	if (!iPad) [tileMap setScale:0.5];
	
	if (iPad) [tileMap setPosition:ccp(200 + offset, 250 + offset)];
	else [tileMap setPosition:ccp(100 + offset, 125 + offset)];
	[overlay addChild:tileMap];
	
	// Write image title on to overlay
	CCLabel *levelTitle;
	if (iPad) levelTitle = [CCLabel labelWithString:@"the letter 'g'" fontName:@"slkscr.ttf" fontSize:48];
	else levelTitle = [CCLabel labelWithString:@"the letter 'g'" fontName:@"slkscr.ttf" fontSize:24];
	[levelTitle setColor:ccc3(00, 00, 00)];
	[levelTitle.texture setAliasTexParameters];
	if (iPad) [levelTitle setPosition:ccp(300, 200)];
	else [levelTitle setPosition:ccp(150, 100)];
	
	[overlay addChild:levelTitle];
	
	// Move overlay downwards over play area
	if (iPad) [overlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(384, 432)]];
	else [overlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];
	
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
	
	// Hide tutorial text
	textBackground.visible = FALSE;
	instructions.visible = FALSE;
	actions.visible = FALSE;
	
	// Hide cursor highlights
	horizontalHighlight.visible = FALSE;
	verticalHighlight.visible = FALSE;
	
	// Create/move "you win" overlay down on screen
	CCSprite *overlay;
	if (iPad) overlay = [CCSprite spriteWithFile:@"loseOverlay-hd.png"];
	else overlay = [CCSprite spriteWithFile:@"loseOverlay.png"];
	[overlay.texture setAliasTexParameters];
	if (iPad) [overlay setPosition:ccp(384, 1292)];	// Doubled, 64px/32px gutters
	else [overlay setPosition:ccp(160, 630)];	// It's off screen to the top
	[self addChild:overlay z:4];
	
	// Add buttons to overlay
	CCMenuItem *continueButton, *quitButton;
	if (iPad)
	{
		continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton-hd.png" selectedImage:@"continueButtonOn-hd.png" target:self selector:@selector(retryLevel:)];
		quitButton = [CCMenuItemImage itemFromNormalImage:@"quitButton-hd.png" selectedImage:@"quitButtonOn-hd.png" target:self selector:@selector(goToTitleScreen:)];
	}
	else
	{
		continueButton = [CCMenuItemImage itemFromNormalImage:@"continueButton.png" selectedImage:@"continueButtonOn.png" target:self selector:@selector(retryLevel:)];
		quitButton = [CCMenuItemImage itemFromNormalImage:@"quitButton.png" selectedImage:@"quitButtonOn.png" target:self selector:@selector(goToTitleScreen:)];
	}
	
	CCMenu *overlayMenu = [CCMenu menuWithItems:continueButton, quitButton, nil];		// Create container menu object
	[overlayMenu alignItemsVertically];
	if (iPad) [overlayMenu setPosition:ccp(300, 100)];
	else [overlayMenu setPosition:ccp(150, 50)];
	[overlay addChild:overlayMenu];
	
	// Move overlay downwards over play area
	if (iPad) [overlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(384, 432)]];
	else [overlay runAction:[CCMoveTo actionWithDuration:0.5 position:ccp(160, 200)]];
	
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