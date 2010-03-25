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
		CCSprite *background = [CCSprite spriteWithFile:@"playBackground.png"];
		[self addChild:background z:0];
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
		
	}
	return self;
}

@end;