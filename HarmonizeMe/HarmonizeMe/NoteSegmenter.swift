//
//  NoteSegmenter.swift
//  Segments an audio file into notes based off of amplitude and pitch
//  HarmonizeMe
//
//  Created by Alexander Fang on 2/21/17.
//  Copyright © 2017 Alex Fang. All rights reserved.
//

import Foundation

class NoteSegmenter {
    
    // audioSignal in mono
    // only on amplitude right now
    internal func onset_times(audioSignal: [Float], windowSize: Int, hopSize: Int, sampleRate: Float) -> [Float] {
        var onsets = [Float]()
        var timeOnsets = [Float]()
        var sampOnsets = [Float]()
        let signal = audioSignal
        let threshold = Float(0.25)
        
        // normalize b/w -1 and 1
        let normalizedSignal = self.normalize(sig: signal)
        
        var sigcopy = normalizedSignal
        // append 0's to end of sig to make it divisible by hopSize, onset unlikely in last window
        let numZerosToAdd = signal.count % hopSize
        for _ in 0..<numZerosToAdd {
            sigcopy.append(0.0)
        }
        
        let lengthToCoverWithHops = sigcopy.count - windowSize
        let numHops = 1 + lengthToCoverWithHops/hopSize
        var start: Int!
        var end: Int!
        var window: [Float]
        
        var prevRMS: Float = 0.0
        var currRMS: Float = 0.0
        
        for ii in 0..<numHops {
            start = ii*hopSize
            end = start + windowSize
            // window is sliced
            window = Array(sigcopy[start..<end])
            currRMS = self.get_rms(sig: window)
            
            // first window won't have a ratio of windows, so skip
            if ii == 0 {
                prevRMS = currRMS
                continue
            }
            
            // the amp goes down, skip or is too low
            if prevRMS >= currRMS || currRMS < 0.01 {
                prevRMS = currRMS
                continue
            }
            
            // if the ratio is sufficient, or absolute threshold is met, it is an onset
            if (prevRMS/currRMS < threshold) || (currRMS > 0.25) {
                onsets.append(Float(ii))
            }
            prevRMS = currRMS
        }
        
        // converting into time (s)
        for onset in onsets {
            sampOnsets.append(onset * Float(hopSize))
        }
        for samp in sampOnsets {
            timeOnsets.append(samp / sampleRate)
        }
        
        return timeOnsets
    }
    
    private func get_rms(sig: [Float]) -> Float {
        var summation = Float(0.0)
        let len = sig.count
        for ii in 0..<len {
            summation += sig[ii] * sig[ii]
        }
        return sqrt(summation/Float(len))
    }
    
    // normalize b/w -1 and 1
    private func normalize(sig: [Float]) -> [Float] {
        var normalizedSignal = sig
        
        // find max of entire signal
        var max: Float = 0.0
        for sample in normalizedSignal {
            if abs(sample) > max {
                max = abs(sample)
            }
        }
        
        // normalizing
        for ii in 0..<normalizedSignal.count {
            normalizedSignal[ii] = normalizedSignal[ii] / max
        }
        return normalizedSignal
    }
}
