//
//  AppDelegate.h
//  Calibrator
//
//  Created by David Hayward on Sun Nov 17 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "BackView.h"
#import "TocView.h"
#import "Assistant.h"
#import "PaneController.h"


@interface AppDelegate : NSObject
{
	IBOutlet NSWindow*		_window;
	IBOutlet BackView*		_background;
	IBOutlet NSTextField*	_title;
	IBOutlet NSBox*			_box;
	IBOutlet NSButton*		_next;
	IBOutlet NSButton*		_back;
	IBOutlet TocView*		_toc;
	
	CMDeviceID				_id;
	Assistant*				_assistant;
	NSMutableArray*			_panesArray;
	NSMutableArray*			_panesStack;
	NSMutableArray*			_clickMeWindows;
}

- (void) beginCalibration;
- (PaneController*) currPane;
- (PaneController*) nextPane;

- (IBAction) next:(id)sender;
- (IBAction) back:(id)sender;
- (void) newPaneWithDirection:(BOOL)direction oldPane:(PaneController*)oldPane;
- (void) updateButtons;

@end
