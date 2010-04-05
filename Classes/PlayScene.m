//
//  PlayScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/25/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "PlayScene.h"


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
		
		// A value to let us know if we should move the cursor or place a mark on the board
		cursorMoved = FALSE;
		
		// Init horizontal "cursor" highlight
		horizontalHighlight = [CCSprite spriteWithFile:@"highlight.png"];
		[horizontalHighlight setPosition:ccp(160, 240)];
		[self addChild:horizontalHighlight z:3];
		
		// Init vertical "cursor" highlight
		verticalHighlight = [CCSprite spriteWithFile:@"highlight.png"];
		[verticalHighlight setPosition:ccp(120, 200)];
		[verticalHighlight setRotation:90.0];
		[self addChild:verticalHighlight z:3];
		
		// A record of where the player's finger is at. The highlights & "cursor" get their values from this via rounding
		fingerPoint = ccp(120, 227);
		
		// Testing labels
		CCLabel *testLabel = [CCLabel labelWithString:@"11\n2\n3" dimensions:CGSizeMake(15, 75) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:8.0];
		[testLabel setColor:ccc3(0, 0, 0)];
		[testLabel.texture setAliasTexParameters];
		[testLabel setPosition:ccp(92, 273)];
		[self addChild:testLabel z:3];
		
		// Waahhh, can't do multi-line bitmap font aliases :(
		// Check out this forum post for non-blurry text: http://www.cocos2d-iphone.org/forum/topic/2865#post-17718
		//CCBitmapFontAtlas *testAtlas = [CCBitmapFontAtlas bitmapFontAtlasWithString:@"1\n2 \n 3" fntFile:@"slkscr.fnt"];
		//[testAtlas.textureAtlas.texture setAliasTexParameters];
		//[testAtlas setPosition:ccp(110, 273)];
		//[self addChild:testAtlas z:3];
		
		// Look into CGImage for loading level data
		// CGImageGetBitsPerPixel / [CCSprite initWithCGImage:image]
		
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
		
		// Try out tile stuff
		CCTMXTiledMap *map = [CCTMXTiledMap tiledMapWithTMXFile:@"test.tmx"];
		CCTMXLayer *layer = [map layerNamed:@"Layer 1"];
		NSLog(@"Tile GID at (20,0) is %d", [layer tileGIDAt:ccp(20, 0)]);
		
		[self addChild:map z:5];	// Doesn't seem to be working?
		
		// Level manager
		NSLog(@"Current level: %d", [LevelManager sharedInstance].currentLevel);
	}
	return self;
}

-(void) update:(ccTime)dt
{
	// Update sprite positions based on internal varaibles! also, check for win/lose conditions
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
}

// Idea for movement: if touches move beyond column/row size, then move "cursor," otherwise register a tap

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Figure out initial location of touch
	UITouch *touch = [touches anyObject];
	
	if (touch) 
	{
		startPoint = previousPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
	}
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	
	if (touch) 
	{
		CGPoint location = [touch locationInView: [touch view]];
		
		// The touches are always in "portrait" coordinates. You need to convert them to your current orientation
		CGPoint convertedPoint = [[CCDirector sharedDirector] convertToGL:location];
		
		// Gets relative movement
		CGPoint relativePoint = ccp(convertedPoint.x - previousPoint.x, convertedPoint.y - previousPoint.y);

		fingerPoint = ccpAdd(fingerPoint, relativePoint);
		
		// Genii idea: get row/column values
		
		/*
		 int col = (location.y - PAD_SLIDER_DIVISION) / (320/3);
		 int row = (location.x / (320/3));
		 */
		
		// 480 - 229 = 251, 480 - 429 = 51
		int newHorizontalPosition = floor(fingerPoint.y / blockSize) * blockSize;
		if (newHorizontalPosition >= 51 && newHorizontalPosition <= 251)
		{
			[horizontalHighlight setPosition:ccp(160, newHorizontalPosition)];
			cursorMoved = TRUE;
		}
		
		int newVerticalPosition = floor(fingerPoint.x / blockSize) * blockSize;
		if (newVerticalPosition >= 109 && newVerticalPosition <= 309)
		{
			[verticalHighlight setPosition:ccp(newVerticalPosition, 200)];
			cursorMoved = TRUE;
		}
		
		//if (cursorMoved)
		//	[[SimpleAudioEngine sharedEngine] playEffect:@"buttonPress.wav"];
		
		previousPoint = convertedPoint;
	}
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (!cursorMoved)
	{
		CCSprite *b = [CCSprite spriteWithFile:@"fillIcon.png"];
		[b setPosition:ccp(verticalHighlight.position.x, horizontalHighlight.position.y)];
		[self addChild:b z:2];
	}
	cursorMoved = FALSE;
}

@end;