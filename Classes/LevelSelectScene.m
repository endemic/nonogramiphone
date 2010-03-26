//
//  LevelSelectScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright 2010 huber+co.. All rights reserved.
//

#import "LevelSelectScene.h"
#import "PlayScene.h"

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
// Level manager is a singleton?
@implementation LevelSelectLayer

-(id) init
{
	if ((self = [super init]))
	{
		// Set up "previous" button
		CCMenuItem *previousButton = [CCMenuItemImage itemFromNormalImage:@"Icon.png" selectedImage:@"Icon.png" disabledImage: @"Icon.png" target:self selector:@selector(showPreviousLevel:)];
		CCMenu *previousButtonMenu = [CCMenu menuWithItems:previousButton, nil];
		[previousButtonMenu setPosition:ccp(20, 240)];
		[self addChild:previousButtonMenu z:1];
		
		// Set up "next" button
		CCMenuItem *nextButton = [CCMenuItemImage itemFromNormalImage:@"Icon.png" selectedImage:@"Icon.png" disabledImage: @"Icon.png" target:self selector:@selector(showNextLevel:)];
		CCMenu *nextButtonMenu = [CCMenu menuWithItems:nextButton, nil];
		[nextButtonMenu setPosition:ccp(300, 240)];
		[self addChild:nextButtonMenu z:1];
		
		// Set up "play" button
		CCMenuItem *playButton = [CCMenuItemFont itemFromString:@"Play" target: self selector: @selector(playLevel:)];
		CCMenu *playButtonMenu = [CCMenu menuWithItems:playButton, nil];
		[playButtonMenu setPosition:ccp(160, 80)];
		[self addChild:playButtonMenu z:1];
		
		// Set up sprites that show level details
		for (int i = 0; i < 15; i++) 
		{
			CCSprite *s = [CCSprite spriteWithFile:@"Icon.png"];
			if (i == 0)
				[s setPosition:ccp(160, 260)];	// First one is in the middle of the screen
			else
				[s setPosition:ccp(350, 260)];	// Offscreen for the rest

			[self addChild:s];
			
			levelDisplayList[i] = s;
		}
		
		currentlyDisplayedLevel = 0;
	}
	return self;
}

-(void) showPreviousLevel: (id)sender
{
	NSLog(@"Show previous level");
	if (currentlyDisplayedLevel > 0)
	{
		[levelDisplayList[currentlyDisplayedLevel] runAction:[CCMoveTo actionWithDuration:0.75 position:ccp(360, 260)]];
		currentlyDisplayedLevel--;
		[levelDisplayList[currentlyDisplayedLevel] runAction:[CCMoveTo actionWithDuration:0.75 position:ccp(160, 260)]];
	}
}

-(void) showNextLevel: (id)sender
{
	NSLog(@"Show next level");
	if (currentlyDisplayedLevel < 14)
	{
		[levelDisplayList[currentlyDisplayedLevel] runAction:[CCMoveTo actionWithDuration:0.75 position:ccp(-40, 260)]];
		currentlyDisplayedLevel++;
		[levelDisplayList[currentlyDisplayedLevel] runAction:[CCMoveTo actionWithDuration:0.75 position:ccp(160, 260)]];
	}
}

-(void) playLevel: (id)sender
{
	NSLog(@"Play level");
	[[CCDirector sharedDirector] replaceScene:[PlayScene node]];
}

@end
