//
//  main.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright Ganbaru Games 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	int retVal = UIApplicationMain(argc, argv, nil, @"NonogramsAppDelegate");
	[pool release];
	return retVal;
}
