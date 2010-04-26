//
//  TutorialScene.m
//  Nonograms
//
//  Created by Nathan Demick on 3/26/10.
//  Copyright 2010 Ganbaru Games. All rights reserved.
//

#import "TutorialScene.h"


@implementation TutorialScene

-(id) init
{
	if ((self = [super init])) 
	{
		[self addChild:[TutorialLayer node] z: 0];
	}
	return self;
}

@end

@implementation TutorialLayer

-(id) init
{
	if ((self = [super init])) 
	{
		
	}
	return self;
}

@end