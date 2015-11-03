//
//  PaneController.h
//  Calibrator
//
//  Created by David Hayward on Mon Nov 18 2002.
//  Copyright (c) 2002 Apple Computer, Inc.. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "Assistant.h"

@interface PaneController : NSObject
{
	IBOutlet id			_view;
	IBOutlet NSView*	_initialFirstResponder;
	Assistant*			_assistant;
}

- (PaneController*) initWithAssistant:(id)asst;

- (NSString*) bulletString;
- (NSString*) titleString;

- (BOOL) shouldSkip;
- (BOOL) quitSafe;

- (NSString*) nibName;
- (void) loadPaneNib;
- (id) view;

- (void) paneDidLoad:(BOOL)direction;
- (void) paneDidUnload:(BOOL)direction;

- (BOOL) shouldPrevPane;
- (BOOL) shouldNextPane;
- (void) performNext;

- (id)initialFirstResponder;
- (id) responderChainBegin;
- (id) responderChainEnd;

@end
