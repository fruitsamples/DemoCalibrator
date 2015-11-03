//
//  TocView.h
//  Calibrator
//
//  Created by David Hayward on Tue Nov 19 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface TocView : NSView
{
	int					_currPaneIndex;
	NSImage*			_bulletImage;
	NSDictionary*		_fontAttribs;
	NSMutableArray*		_panesArray;
	NSMutableArray*		_panesStack;
}

- (void) setPanesArray:(NSMutableArray*)array andStack:(NSMutableArray*)stack;

@end
