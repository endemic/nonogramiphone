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
		// Add background to center of scene
		CCSprite *background = [CCSprite spriteWithFile:@"playBackground.png"];
		[background setPosition:ccp(160, 240)];
		[self addChild:background z:0];
		
		// Add "play" layer
		[self addChild:[PlayLayer node] z: 1];
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
		
		// Set the width of puzzle blocks
		blockSize = 20;
		
		// Current position of the cursor
		currentRow = currentColumn = 1;
		
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
		
		// Set up "quit" button
		CCMenuItem *quitButton = [CCMenuItemImage itemFromNormalImage:@"quitButton.png" selectedImage:@"quitButtonOn.png" target:self selector:@selector(goToLevelSelect:)];
		CCMenu *quitMenu = [CCMenu menuWithItems:quitButton, nil];
		[quitMenu setPosition:ccp(25, 415)];
		[self addChild:quitMenu z:3];
		
		// Testing labels
//		CCLabel *testLabel = [CCLabel labelWithString:@"11\n2\n3" dimensions:CGSizeMake(15, 75) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:16];
//		[testLabel setColor:ccc3(0, 0, 0)];
//		[testLabel.texture setAliasTexParameters];
//		[testLabel setPosition:ccp(115, 300)];
//		[self addChild:testLabel z:3];

		// Waahhh, can't do multi-line bitmap font aliases :(
		// Check out this forum post for non-blurry text: http://www.cocos2d-iphone.org/forum/topic/2865#post-17718
		//CCBitmapFontAtlas *testAtlas = [CCBitmapFontAtlas bitmapFontAtlasWithString:@"1\n2 \n 3" fntFile:@"slkscr.fnt"];
		//[testAtlas.textureAtlas.texture setAliasTexParameters];
		//[testAtlas setPosition:ccp(110, 273)];
		//[self addChild:testAtlas z:3];
		
		// Load tile map for this particular puzzle
		CCTMXTiledMap *tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"test.tmx"];
		tileMapLayer = [[tileMap layerNamed:@"Layer 1"] retain];
		
		// Create "clue" labels in arrays for rows and columns
		for (int i = 0; i < 10; i++)
		{
			// Create new label; set position/color/aliasing values
			verticalClues[i] = [CCLabel labelWithString:@"testing" dimensions:CGSizeMake(20, 100) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:12];
			[verticalClues[i] setPosition:ccp(120 + (blockSize * i), 300)];
			[verticalClues[i] setColor:ccc3(0,0,0)];
			[verticalClues[i].texture setAliasTexParameters];
			[self addChild:verticalClues[i] z:3];
			
			horizontalClues[i] = [CCLabel labelWithString:@"testing" dimensions:CGSizeMake(75, 15) alignment:UITextAlignmentRight fontName:@"slkscr.ttf" fontSize:12];
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
				[verticalClues[i] setPosition:ccp(verticalClues[i].position.x, 200 + (([numberOfVerticalClues count] - 1) * 13))];
			}
			else
			{
				//_verticalClues[i].y = 93;
			}
		}
		
		// Set up schedulers
		[self schedule:@selector(update:)];
		
		// Set up timer labels/internal variables/scheduler
		[self schedule:@selector(timer:) interval:1.0];
		
		minutesLeft = 30;
		secondsLeft = 0;
		
		minutesLeftLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%d", minutesLeft] fontName:@"slkscr.ttf" fontSize:48];
		[minutesLeftLabel setPosition:ccp(90, 420)];
		[minutesLeftLabel setColor:ccc3(33, 33, 33)];
		[minutesLeftLabel.texture setAliasTexParameters];
		[self addChild:minutesLeftLabel z:3];
		
		secondsLeftLabel = [CCLabel labelWithString:[NSString stringWithFormat:@"%d", secondsLeft] fontName:@"slkscr.ttf" fontSize:48];
		[secondsLeftLabel setPosition:ccp(90, 380)];
		[secondsLeftLabel setColor:ccc3(33, 33, 33)];
		[secondsLeftLabel.texture setAliasTexParameters];
		[self addChild:secondsLeftLabel z:3];
		
		// Level manager
		NSLog(@"Current level: %d", [GameDataManager sharedManager].currentLevel);
		
		// Movement debug info
//		pixelTarget = [CCSprite spriteWithFile:@"pixelTarget.png"];
//		[self addChild:pixelTarget z:4];
	}
	return self;
}

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
		// End game here
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

-(void) changeTapActionToMark:(id)selector
{
	tapAction = MARK;
}

-(void) changeTapActionToFill:(id)selector
{
	tapAction = FILL;
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Figure out initial location of touch
	UITouch *touch = [touches anyObject];
	
	if (touch) 
	{
		startPoint = previousPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		cursorPoint = ccp(verticalHighlight.position.x, horizontalHighlight.position.y);
	}
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	
	if (touch) 
	{
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
		
		// Set the previous point value to be what we used as current
		previousPoint = currentPoint;
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
		
		// This value is the sensitivity for filling/marking a block
		int moveThreshold = 5;
		
		// If a tap is detected - i.e. if the movement of the finger is less than the threshold
		if (ccpDistance(startPoint, endPoint) < moveThreshold)
		{
			if (tapAction == FILL)
			{
				// If the tile at the current location is a filled in tile...
				// The tilemap's y-coords are inverse of the iphone coords, so invert it
				if ([tileMapLayer tileGIDAt:ccp(currentColumn - 1, 10 - currentRow)] == 1)
				{
					// Draw filled in sprite on top ov it
					CCSprite *b = [CCSprite spriteWithFile:@"fillIcon.png"];
					[b setPosition:ccp(verticalHighlight.position.x, horizontalHighlight.position.y)];
					[self addChild:b z:2];
				}
				else
				{
					// Take off time here, as well as play sfx of some kind and shake the screen
					id shake = [CCShaky3D actionWithRange:3 shakeZ:FALSE grid:ccg(5, 5) duration:0.1];
					
					// Run "shake" action, then return the grid to its original state
					[self runAction:[CCSequence actions:shake, [CCStopGrid action], nil]];
				}
			}
			else if (tapAction == MARK)
			{
				// Draw filled in sprite on top ov it
				CCSprite *c = [CCSprite spriteWithFile:@"markIcon.png"];
				[c setPosition:ccp(verticalHighlight.position.x, horizontalHighlight.position.y)];
				[self addChild:c z:2];	
			}
		}
	}
}

-(void) goToLevelSelect:(id)sender
{
	NSLog(@"Level select");
	[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
	[[CCDirector sharedDirector] replaceScene:[CCTurnOffTilesTransition transitionWithDuration:0.5 scene:[LevelSelectScene node]]];
}

-(void) dealloc
{
	[super dealloc];
	[tileMapLayer dealloc];
}

@end;