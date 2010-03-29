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
		[self setIsTouchEnabled:YES];
		
		// Init horizontal "cursor" highlight
		horizontalHighlight = [CCSprite spriteWithFile:@"verticalHighlight.png"];
		[horizontalHighlight setPosition:ccp(160, 240)];
		[horizontalHighlight setRotation:90.0];
		[self addChild:horizontalHighlight z:3];
		
		// Init vertical "cursor" highlight
		verticalHighlight = [CCSprite spriteWithFile:@"verticalHighlight.png"];
		[verticalHighlight setPosition:ccp(160, 240)];
		[self addChild:verticalHighlight z:3];
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
		touchStart = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
		NSLog(@"Touch began at (%f, %f)", touchStart.x, touchStart.y);
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
		
		convertedPoint.x = touchStart.x - floor(convertedPoint.x / 15) * 15;
		convertedPoint.y = touchStart.y - floor(convertedPoint.y / 15) * 15;
		
		NSLog(@"Moving relative to (%f, %f)", convertedPoint.x, convertedPoint.y);
		
		CGPoint newHorizontalPosition = ccp(160, horizontalHighlight.position.y + convertedPoint.y);
		CGPoint newVerticalPosition = ccp(verticalHighlight.position.x + convertedPoint.x, 240);
		
		[verticalHighlight setPosition:newVerticalPosition];
		[horizontalHighlight setPosition:newHorizontalPosition];
	}
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"Touches ended");
}

@end;