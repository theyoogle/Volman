//
//  VPlugAudioUnit.m
//  VPlug
//
//  Created by The YooGle on 14/08/22.
//

#import "VPlugAudioUnit.h"
#import "BufferedAudioBus.hpp"

#import <AVFoundation/AVFoundation.h>

// Define parameter addresses.
const AudioUnitParameterID myParam1 = 0;

@interface VPlugAudioUnit ()

@property (nonatomic, readwrite) AUParameterTree *parameterTree;
@property AUAudioUnitBus *inputBus;
@property AUAudioUnitBus *outputBus;
@property AUAudioUnitBusArray *inputBusArray;
@property AUAudioUnitBusArray *outputBusArray;
@end


@implementation VPlugAudioUnit {
    BufferedAudioBus _bufferedAudioBus;
}
@synthesize parameterTree = _parameterTree;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];
    
    if (self == nil) { return nil; }

    _bufferedAudioBus = BufferedAudioBus();
    _bufferedAudioBus.maxFrames = 0;
    _bufferedAudioBus.pcmBuffer = nullptr;
    _bufferedAudioBus.mutableAudioBufferList = nullptr;
    
	[self setupAudioBuses];
	[self setupParameterTree];
	[self setupParameterCallbacks];
    return self;
}

#pragma mark - AUAudioUnit Setup

- (void)setupAudioBuses {
    AVAudioFormat *defaultFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
    
    _inputBus = [[AUAudioUnitBus alloc] initWithFormat:defaultFormat error:nil];
    _outputBus = [[AUAudioUnitBus alloc] initWithFormat:defaultFormat error:nil];
    
	// Create the input and output bus arrays.
	_inputBusArray  = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
															 busType:AUAudioUnitBusTypeInput
															  busses: @[_inputBus]];
	_outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
															 busType:AUAudioUnitBusTypeOutput
															  busses: @[_outputBus]];
}

- (void)setupParameterTree {
    // Create parameter objects.
    AUParameter *param1 = [AUParameterTree createParameterWithIdentifier:@"param1"
																	name:@"Parameter 1"
																 address:myParam1
																	 min:0
																	 max:100
																	unit:kAudioUnitParameterUnit_Percent
																unitName:nil
																   flags:0
															valueStrings:nil
													 dependentParameters:nil];

    // Initialize the parameter values.
    param1.value = 1.0;

    // Create the parameter tree.
    _parameterTree = [AUParameterTree createTreeWithChildren:@[ param1 ]];
}

- (void)setupParameterCallbacks {
	// Make a local pointer to the kernel to avoid capturing self.
	__block BufferedAudioBus* bufferedAudioBus = &_bufferedAudioBus;

	// implementorValueObserver is called when a parameter changes value.
	_parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
        bufferedAudioBus->volume = value;
	};

//	// implementorValueProvider is called when the value needs to be refreshed.
//	_parameterTree.implementorValueProvider = ^(AUParameter *param) {
//		return [dspAdapter valueForParameter:param];
//	};

	// A function to provide string representations of parameter values.
	_parameterTree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
		AUValue value = valuePtr == nil ? param.value : *valuePtr;

		return [NSString stringWithFormat:@"%.f", value];
	};
}

#pragma mark - AUAudioUnit Overrides

- (AUAudioFrameCount)maximumFramesToRender {
	return 512;
}

- (void)setMaximumFramesToRender:(AUAudioFrameCount)maximumFramesToRender {
    self.maximumFramesToRender = maximumFramesToRender;
}

// If an audio unit has input, an audio unit's audio input connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)inputBusses {
	return _inputBusArray;
}

// An audio unit's audio output connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)outputBusses {
	return _outputBusArray;
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    
    if (![super allocateRenderResourcesAndReturnError:outError]) {
        return NO;
    }
    
    // Validate that the bus formats are compatible.
	if (self.outputBus.format.channelCount != self.inputBus.format.channelCount) {
		if (outError) {
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:kAudioUnitErr_FailedInitialization userInfo:nil];
            NSLog(@"kAudioUnitErr_FailedInitialization at %d", __LINE__);
		}
		// Notify superclass that initialization was not successful
		self.renderResourcesAllocated = NO;
        
		return NO;
	}
    
    _bufferedAudioBus.maxFrames = self.maximumFramesToRender;
    _bufferedAudioBus.pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_inputBus.format frameCapacity:self.maximumFramesToRender];
    _bufferedAudioBus.originalAudioBufferList = _bufferedAudioBus.pcmBuffer.audioBufferList;
    _bufferedAudioBus.mutableAudioBufferList = _bufferedAudioBus.pcmBuffer.mutableAudioBufferList;
    
	return YES;
}

// Deallocate resources allocated in allocateRenderResourcesAndReturnError:
// Subclassers should call the superclass implementation.
- (void)deallocateRenderResources {
//	[_dspAdapter deallocateRenderResources];

    // Deallocate your resources.
    [super deallocateRenderResources];
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

// Block which subclassers must provide to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
    // Capture in locals to avoid ObjC member lookups. If "self" is captured in render, we're doing it wrong. See sample code.
    __block BufferedAudioBus* buffer = &_bufferedAudioBus;
    
    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags *actionFlags,
                              const AudioTimeStamp *timestamp,
                              AVAudioFrameCount frameCount,
                              NSInteger outputBusNumber,
                              AudioBufferList *outputData,
                              const AURenderEvent *realtimeEventListHead,
                              AURenderPullInputBlock pullInputBlock) {
        
        // Do event handling and signal processing here.
        AudioUnitRenderActionFlags pullFlags = 0;
        buffer->prepareInputBufferList();
        AUAudioUnitStatus err = pullInputBlock(&pullFlags, timestamp, frameCount, 0, buffer->mutableAudioBufferList);
        
        if (err != 0) {
            NSLog(@"borama VolumePluginAudioUnit AudioUnitRenderActionFlags");
            return err;
        }
        
        AudioBufferList *inAudioBufferList = buffer->mutableAudioBufferList;
        AudioBufferList *outAudioBufferList = outputData;
        
        // If passed null output buffer pointers, process in-place in the input buffer.
        if (outAudioBufferList->mBuffers[0].mData == nullptr) {
            for (UInt32 i = 0; i < outAudioBufferList->mNumberBuffers; ++i) {
                outAudioBufferList->mBuffers[i].mData = inAudioBufferList->mBuffers[i].mData;
            }
        }
        
        UInt32 samplesCount = inAudioBufferList->mBuffers[0].mDataByteSize / sizeof(float);
        
        for (int j = 0; j < inAudioBufferList->mNumberBuffers; j++) {
            float* input = (float*)inAudioBufferList->mBuffers[j].mData;
            float* output = (float*)outAudioBufferList->mBuffers[j].mData;
            // the might be more than one channel (stereo)
            for (int i = 0; i < samplesCount; i++) {
                output[i] = buffer->volume * input[i];
            }
        }
        
        return noErr;
    };
}

@end

