//
//  NoteSegmenter.swift
//  Segments an audio file into notes based off of amplitude and pitch
//  HarmonizeMeApp
//
//  Created by Alexander Fang on 2/21/17.
//  Copyright © 2017 Alex Fang. All rights reserved.
//

import Foundation

class NoteSegmenter {
    private var sampleOnsets = [Int]()
    private var sampleOnsetsFromPitch = [Int]()
    private var pitchConverter = PitchConverter()
    private var pitchDetector = PitchDetector()
    private var windowedPitches = [Float]()
    
    // audioSignal in mono
    // only on amplitude right now
    internal func onsetTimes(audioSignal: [Float], windowSize: Int, hopSize: Int, sampleRate: Float) -> [Float] {
        var onsets = [Float]()
        var timeOnsets = [Float]()
        var sampOnsets = [Int]()
        let signal = audioSignal
        let threshold = Float(0.35)
        
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
            let time = Float(ii) * Float(hopSize) / sampleRate
            // print("AT HOP: " + String(ii) + " AND TIME: " + String(time))
            start = ii*hopSize
            end = start + windowSize
            // window is sliced
            window = Array(sigcopy[start..<end])
            currRMS = self.get_rms(sig: window)
            
            // print("currRMS: " + String(currRMS))
            
            
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
            
            // print("Ratio of prevRMS/currRMS is: " + String(prevRMS/currRMS))
            // if the ratio is sufficient, or absolute threshold is met, it is an onset
            if (prevRMS/currRMS < threshold) || (currRMS > 0.75) {
                onsets.append(Float(ii))
                // print("APPENDED! currRMS: " + String(currRMS) + " at " + String(time) + " seconds.")
            }
            prevRMS = currRMS
        }
        
        // converting into time (s)
        for onset in onsets {
            sampOnsets.append(Int(onset * Float(hopSize)))
        }
        sampleOnsets = sampOnsets
        for samp in sampOnsets {
            timeOnsets.append(Float(samp) / sampleRate)
        }
        
        return timeOnsets
    }
    
    internal func onsetSamps(audioSignal: [Float], windowSize: Int, hopSize: Int, sampleRate: Float) -> [Int] {
        self.onsetTimes(audioSignal: audioSignal, windowSize: windowSize, hopSize: hopSize, sampleRate: sampleRate)
        return sampleOnsets
    }
    
    internal func onsetTimesFromPitch(audioSignal: [Float], freqArray: [Float], windowSize: Int, hopSize: Int, sampleRate: Float) -> [Float] {
        var onsets = [Float]()
        var timeOnsets = [Float]()
        var sampOnsets = [Int]()
        var freqs = freqArray
        let sig = audioSignal
        let threshold = Float(0.80)
        
        // normalize b/w -1 and 1
        let normalizedSignal = self.normalize(sig: sig)
        
        // on amplitudes
        var sigcopy = normalizedSignal
        // append 0's to end of sig to make it divisible by hopSize, onset unlikely in last window
        var numZerosToAdd = sigcopy.count % hopSize
        for _ in 0..<numZerosToAdd {
            sigcopy.append(0.0)
        }
        
        numZerosToAdd = freqs.count % hopSize
        for _ in 0..<numZerosToAdd {
            freqs.append(0.0)
        }
        // sigcopy and freqs are the same size
        
        let lengthToCoverWithHops = freqs.count - windowSize
        let numHops = 1 + lengthToCoverWithHops/hopSize
        var start: Int!
        var end: Int!
        var window: [Float]
        
        var prevMIDI = Float(0.0)
        var currMIDI = Float(0.0)
        var currRMS = Float(0.0)
        
        for ii in 0..<numHops {
            let time = Float(ii) * Float(hopSize) / sampleRate
            // print("AT HOP: " + String(ii) + " AND TIME: " + String(time))
            start = ii*hopSize
            end = start + windowSize
            
            // window is sliced
            window = Array(sigcopy[start..<end])
            currRMS = self.get_rms(sig: window)
            
            currMIDI = pitchDetector.detectMIDIExact(freqArray: freqs, start: start, end: end)
            windowedPitches.append(currMIDI)
            // print("currRMS: " + String(currRMS))
            // print("currMIDI: " + String(currMIDI))
            
            // print("currMIDI: " + String(currMIDI))
            
            // first window won't have a ratio of windows, so skip
            if ii == 0 {
                prevMIDI = currMIDI
                continue
            }
            
            // the pitch is the same, skip. or if amp is too low
            if prevMIDI == currMIDI || currRMS < 0.01 {
                prevMIDI = currMIDI
                continue
            }
            
            // iif pitch changes by more than threshold, it is an onset
            if (fabsf(currMIDI - prevMIDI).truncatingRemainder(dividingBy: 12.0) > threshold) {
                onsets.append(Float(ii))
                // print("APPENDED! currMIDI - prevMIDI: " + String(fabsf(currMIDI-prevMIDI)) + " at " + String(time) + " seconds.")
            }
            prevMIDI = currMIDI
        }
        
        // converting into time (s)
        for onset in onsets {
            sampOnsets.append(Int(onset * Float(hopSize)))
        }
        sampleOnsetsFromPitch = sampOnsets
        for samp in sampOnsets {
            timeOnsets.append(Float(samp) / sampleRate)
        }
        
        return timeOnsets
    }
    
    internal func onsetSampsFromPitch(audioSignal: [Float],  freqArray: [Float], windowSize: Int, hopSize: Int, sampleRate: Float) -> [Int] {
        self.onsetTimesFromPitch(audioSignal: audioSignal, freqArray: freqArray, windowSize: windowSize, hopSize: hopSize, sampleRate: sampleRate)
        return sampleOnsetsFromPitch
    }
    
    internal func getWindowedPitches() -> [Float] {
        return windowedPitches
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
