//
//  Buffer.hpp
//  Volman
//
//  Created by The YooGle on 14/08/22.
//

#ifndef Buffer_h
#define Buffer_h

#import <AVFoundation/AVFoundation.h>

struct BufferedAudioBus {
    AUAudioFrameCount maxFrames = 0;
    AVAudioPCMBuffer *pcmBuffer = nullptr;
    AudioBufferList* mutableAudioBufferList = nullptr;
    AudioBufferList const* originalAudioBufferList = nullptr;
    
    float volume = 1.0;
    
    void prepareInputBufferList() {
        UInt32 byteSize = maxFrames * sizeof(float);
        mutableAudioBufferList->mNumberBuffers = originalAudioBufferList->mNumberBuffers;

        for (UInt32 i = 0; i < originalAudioBufferList->mNumberBuffers; ++i) {
            mutableAudioBufferList->mBuffers[i].mNumberChannels = originalAudioBufferList->mBuffers[i].mNumberChannels;
            mutableAudioBufferList->mBuffers[i].mData = originalAudioBufferList->mBuffers[i].mData;
            mutableAudioBufferList->mBuffers[i].mDataByteSize = byteSize;
        }
    }
};

#endif /* Buffer_h */
