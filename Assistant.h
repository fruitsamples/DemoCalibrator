//
//  Assistant.h
//  Calibrator
//
//  Created by David Hayward on Sat Nov 30 2002.
//  Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Assistant : NSObject
{
	CMDeviceID				_id;
	CMProfileRef			_ref;
	BOOL					_refSet;
	NSString*				_name;
	NSString*				_nameAscii;
}

+ (NSString*) nameOfDisplay:(CMDeviceID)devID;

- (id) initWithDisplay:(CMDeviceID)devID;
- (CMDeviceID) display;

- (id) prefObjectForKey:(NSString*)key;
- (void) prefSetObject:(id)value forKey:(NSString*)key;
- (int) prefIntegerForKey:(NSString*)defaultName; 
- (void) prefSetInteger:(int)value forKey:(NSString*)defaultName;
- (float) prefFloatForKey:(NSString*)defaultName; 
- (void) prefSetFloat:(float)value forKey:(NSString*)defaultName;
- (void) prefRegFloat:(float)value forKey:(NSString*)key;

- (NSString*) factoryName;
- (NSString*) name;
- (NSString*) nameAscii;
- (void) setName:(NSString*)name andAsciiName:(NSString*)nameAscii;

- (CMProfileLocation) profileLocation;
- (BOOL) fileExistsForName:(NSString*)name;
- (void) createProfile;
- (BOOL) createdProfile;

- (void) loadLuts;
- (void) loadOriginalLuts;


@end
