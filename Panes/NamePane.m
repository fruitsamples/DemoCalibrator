//
//  NamePane.m
//  Calibrator
//
//  Created by David Hayward on Thu Dec 12 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import "NamePane.h"


@implementation NamePane

- (void) paneDidLoad:(BOOL)direction
{	
	[_name setStringValue:[_assistant name]];
	[self controlTextDidChange:nil];
}

- (void) paneDidUnload:(BOOL)direction
	{ [_assistant setName:[_name stringValue] andAsciiName:nil]; }


static pascal OSErr ProfileIterate (CMProfileIterateData *iterateData, void *refCon)
{
	if (iterateData->header.profileClass == cmDisplayClass &&
		iterateData->header.dataColorSpace == cmRGBData)
		[(NSMutableArray*)refCon addObject:
				[NSString stringWithCharacters:iterateData->uniCodeName 
										length:iterateData->uniCodeNameCount - 1]];
    return noErr;
}


- (NSMutableArray*) otherNameArray
{
	if (_otherNames)
		return _otherNames;
	
    CMProfileIterateUPP	iterUPP = NewCMProfileIterateUPP(ProfileIterate);
	_otherNames = [[NSMutableArray arrayWithCapacity:10] retain];
	(void) CMIterateColorSyncFolder(iterUPP,nil, nil, _otherNames);
	DisposeCMProfileIterateUPP(iterUPP);
	return _otherNames;
}


- (int) checkName
{
	// if name editing in progress
	NSTextView*	curEditor = (NSTextView*)[_name currentEditor];
	if (curEditor && [curEditor hasMarkedText]==YES)
		return 1;
	
	NSString*	curName = (curEditor ? [curEditor string] : [_name stringValue]);
	
	// if empty name
	if ([curName length] == 0)
		return 2;
	
	if ([_assistant fileExistsForName:curName])
		return 3;
	
	if ([[self otherNameArray] containsObject:curName])
		return 4;
	
	return 0;
}


- (BOOL) shouldNextPane
{
	int	check = [self checkName];
	return (check==0 || check==3);
}


- (BOOL) shouldPrevPane
	{ return YES; }


- (void) controlTextDidChange:(NSNotification *)obj
{
	if (obj==nil || [obj object]==_name)
	{
		NSString* oldstr = [_name stringValue];
		
		if ([oldstr length] > 50)
			[_name setStringValue:[oldstr substringToIndex:50]];
		
		int	check = [self checkName];
		
		if (check==2)
			[_note setStringValue:
				NSLocalizedString(@"A profile name is required.\nPlease choose a name.",nil)];
		else if (check==3)
			[_note setStringValue:
				NSLocalizedString(@"A profile with this name already exists.\rThe existing profile will be replaced.",nil)];
		else if (check==4)
			[_note setStringValue:
				NSLocalizedString(@"A profile with this name already exists.\rPlease choose a different name.",nil)];
		else
			[_note setStringValue:@""];
	}
}


@end
