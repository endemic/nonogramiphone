//
//  LevelSelectScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "LevelSelectScene.h"
#import "Button.h"

// Set up level select scene
@implementation LevelSelectScene

-(id)init
{
	if ((self = [super init]))
	{
		[self addChild:[LevelSelectLayer node] z:0];
	}
	return self;
}

@end

// Level select layer
@implementation LevelSelectLayer

-(id) init
{
	if ((self = [super init]))
	{
		// Level manager is a singleton?
		// Set up next/previous buttons as well as the text/graphic that displays the current level
		
		[self addChild:[Button buttonWithText:@"Previous" atPosition:ccp(0, 240) target:self selector:@selector(showPreviousLevel:) z:1]];
	}
	return self;
}

-(void) showPreviousLevel: (id)sender
{
	NSLog(@"Show previous level");
}

-(void) showNextLevel: (id)sender
{
	NSLog(@"Show next level");
}

@end
