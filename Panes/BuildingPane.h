//
//  BuildingPane.h
//  Calibrator
//
//  Created by David Hayward on Thu Dec 12 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import "PaneController.h"


@interface BuildingPane : PaneController
{
	BOOL	_shouldNext;
}

- (void) deferredBuild;

@end
