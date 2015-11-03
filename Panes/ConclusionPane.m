//
//  ConclusionPane.m
//  Calibrator
//
//  Created by David Hayward on Wed Nov 20 2002.
//  Copyright (c) 2002 Apple Computer, Inc.. All rights reserved.
//

#import "ConclusionPane.h"


@implementation ConclusionPane

- (BOOL) quitSafe
	{ return YES; }


- (void) paneDidLoad:(BOOL)direction
{
	// if failed to create profile, add error message and return
	if ([_assistant createdProfile]==NO)
	{
		[_text setStringValue:NSLocalizedString(@"CouldNotCreateProfile",nil)];
		return;
	}
	
	
	// add proxy to window title bar
	CMProfileLocation loc = [_assistant profileLocation];
	NSString* path = [NSString stringWithCString:loc.u.pathLoc.path];
	[[NSApp mainWindow] setTitleWithRepresentedFilename:path];
}

@end
