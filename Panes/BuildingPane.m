//
//  BuildingPane.m
//  Calibrator
//
//  Created by David Hayward on Thu Dec 12 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import "BuildingPane.h"


@implementation BuildingPane

- (BOOL) shouldNextPane;
	{ return _shouldNext; }

- (BOOL) shouldPrevPane
	{ return _shouldNext; }


- (void) paneDidLoad:(BOOL)direction
{
	_shouldNext = NO;
	[self performSelector:@selector(deferredBuild) withObject:nil afterDelay:0.0];
}


- (void) deferredBuild
{
	[_assistant createProfile];
	_shouldNext = YES;
	[self performNext];
}


@end

