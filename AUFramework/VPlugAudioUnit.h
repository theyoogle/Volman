//
//  VPlugAudioUnit.h
//  VPlug
//
//  Created by The YooGle on 14/08/22.
//

#import <AudioToolbox/AudioToolbox.h>

// Define parameter addresses.
extern const AudioUnitParameterID myParam1;

@interface VPlugAudioUnit : AUAudioUnit

- (void)setupAudioBuses;
- (void)setupParameterTree;
- (void)setupParameterCallbacks;
@end
