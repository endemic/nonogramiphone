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
		blockSize = 15;
		
		// Init horizontal "cursor" highlight
		horizontalHighlight = [CCSprite spriteWithFile:@"highlight.png"];
		[horizontalHighlight setPosition:ccp(160, 228)];
		[self addChild:horizontalHighlight z:3];
		
		// Init vertical "cursor" highlight
		verticalHighlight = [CCSprite spriteWithFile:@"highlight.png"];
		[verticalHighlight setPosition:ccp(160, 240)];
		[verticalHighlight setRotation:90.0];
		[self addChild:verticalHighlight z:3];
		
		// A record of where the player's finger is at. The highlights & "cursor" get their values from this via rounding
		fingerPoint = ccp(160, 240);
		
		// Testing labels
		CCLabel *testLabel = [CCLabel labelWithString:@"11\n2\n3" dimensions:CGSizeMake(15, 75) alignment:UITextAlignmentCenter fontName:@"slkscr.ttf" fontSize:8.0];
		[testLabel setColor:ccc3(0, 0, 0)];
		[testLabel setPosition:ccp(92, 273)];
		[self addChild:testLabel z:3];
	}
	return self;
}

// Idea for movement: if touches move beyond column/row size, then move "cursor," otherwise register a tap

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Figure out initial location of touch
	UITouch *touch = [touches anyObject];
	
	if (touch) 
	{
		previousPoint = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		NSLog(@"Touch began at (%f, %f)", previousPoint.x, previousPoint.y);
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

		NSLog(@"Moving relatively: (%f, %f)", relativePoint.x, relativePoint.y);
		
		fingerPoint = ccpAdd(fingerPoint, relativePoint);
		
		[horizontalHighlight setPosition:ccp(160, floor(fingerPoint.y / blockSize) * blockSize)];
		[verticalHighlight setPosition:ccp(floor(fingerPoint.x / blockSize) * blockSize, 240)];
		
		previousPoint = convertedPoint;
	}
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"Touches ended");
}

@end;