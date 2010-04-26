//
//  NonogramsAppDelegate.m
//  Nonograms
//
//  Created by Nathan Demick on 3/24/10.
//  Copyright Ganbaru Games 2010. All rights reserved.
//

#import "NonogramsAppDelegate.h"
#import "cocos2d.h"
#import "CocosDenshion.h"
#import "SimpleAudioEngine.h"
#import "TitleScene.h"
#import "GameDataManager.h"

@implementation NonogramsAppDelegate

@synthesize window;

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	// Init the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// cocos2d will inherit these values
	[window setUserInteractionEnabled:YES];	
	[window setMultipleTouchEnabled:YES];
	
	// Try to use CADisplayLink director
	// if it fails (SDK < 3.1) use the default director
	if( ! [CCDirector setDirectorType:CCDirectorTypeDisplayLink] )
		[CCDirector setDirectorType:CCDirectorTypeDefault];
	
	// Use RGBA_8888 buffers
	// Default is: RGB_565 buffers
	[[CCDirector sharedDirector] setPixelFormat:kPixelFormatRGBA8888];
	
	// Create a depth buffer of 16 bits
	// Enable it if you are going to use 3D transitions or 3d objects
//	[[CCDirector sharedDirector] setDepthBufferFormat:kDepthBuffer16];
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kTexture2DPixelFormat_RGBA8888];
	
	// before creating any layer, set the landscape mode
	//[[CCDirector sharedDirector] setDeviceOrientation:CCDeviceOrientationLandscapeLeft];
	[[CCDirector sharedDirector] setAnimationInterval:1.0/60];
	[[CCDirector sharedDirector] setDisplayFPS:YES];
	[[CCDirector sharedDirector] setProjection:CCDirectorProjection2D];
	
	// create an openGL view inside a window
	[[CCDirector sharedDirector] attachInView:window];	
	[window makeKeyAndVisible];		
	
	// Preload some SFX/muzak!
	// Check this out: http://www.cocos2d-iphone.org/forum/topic/55
	// To convert .wav files: afconvert -v -f WAVE -d LEI16 notworking.wav working.wav
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"buttonPress.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"cursorMove.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"dud.wav"];

	// Load default defaults - I'm just going to assume this is working
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];
	
	// Set global game data singleton options with preferences
	[GameDataManager sharedManager].playSFX = [defaults boolForKey:@"playSFX"];
	[GameDataManager sharedManager].playMusic = [defaults boolForKey:@"playMusic"];
	
	// Load information about levels from .plist
	[GameDataManager sharedManager].levels = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Levels" ofType:@"plist"]];
	
	// Set current level for player
	[GameDataManager sharedManager].currentLevel = 1;
	
	// Run default scene
	[[CCDirector sharedDirector] runWithScene: [TitleScene node]];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	[[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[CCDirector sharedDirector] resume];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[[CCDirector sharedDirector] end];
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void)dealloc {
	[[GameDataManager sharedManager] release];
	[[CCDirector sharedDirector] release];
	[window release];
	[super dealloc];
}

@end
