//
//  PitchDetector.swift
//  HarmonizeMeApp
//
//  Created by Alexander Fang on 2/21/17.
//  Copyright © 2017 Alex Fang. All rights reserved.
//

import Foundation

class PitchDetector {
    private var pitchConverter = PitchConverter()
    private var detectedFrequencies = [Float]() // partitioned based off of onsets already
    
    // array of frequencies from AKFrequencyTracker
    
    // detectMIDIExact, detectMIDIRounded, detectNoteName, detectFreq
    // all supposedly work on one note only.
    internal func detectMIDIExact(freqArray: [Float], start: Int, end: Int) -> Float {
        let freqCopy = freqArray
        let window = Array(freqCopy[start..<end])
        let freq = self.median(data: window)
        return pitchConverter.exactMIDIfromFreq(frequency: freq)
        
    }
    
    internal func detectMIDIRounded(freqArray: [Float], start: Int, end: Int) -> Int {
        let freqCopy = freqArray
        let window = Array(freqCopy[start..<end])
        let freq = self.median(data: window)
        return pitchConverter.MIDIfromFreq(frequency: freq)
    }
    
    internal func detectNoteName(freqArray: [Float], start: Int, end: Int) -> String {
        let midiNum = self.detectMIDIRounded(freqArray: freqArray, start: start, end: end)
        return pitchConverter.noteNameFromMIDI(midiNum: midiNum)
    }
    
    internal func detectFreq(freqArray: [Float], start: Int, end: Int) -> Float {
        let freqCopy = freqArray
        let window = Array(freqCopy[start..<end])
        return self.median(data: window)
    }
    
    internal func detectFrequencies(freqArray: [Float], onsetSamps: [Int]) -> [Float] {
        var detectedFreqArray = [Float]()
        let numOnsets = onsetSamps.count
        // onsetSamps = [3, 9]
        
        // start and end are in samps
        var start: Int!
        var end: Int!
        for ii in 0..<numOnsets {
            start = onsetSamps[ii]
            // if we're at the end, then take the window from the last onset to the last sample of freqArray
            if ii == numOnsets - 1 {
                end = freqArray.count - 1
            }
            else {
                end = onsetSamps[ii + 1] // be careful!!!!
                
            }
            detectedFreqArray.append(self.detectFreq(freqArray: freqArray, start: start, end: end))
        }
        detectedFrequencies = detectedFreqArray
        return detectedFrequencies
    }
    
    
    internal func detectExactMIDI(freqArray: [Float], onsetSamps: [Int]) -> [Float] {
        let freqArray = self.detectFrequencies(freqArray: freqArray, onsetSamps: onsetSamps)
        detectedFrequencies = freqArray
        var exactMIDI = [Float]()
        for freq in freqArray {
            let midiFromFreq = pitchConverter.exactMIDIfromFreq(frequency: freq)
            exactMIDI.append(midiFromFreq)
        }
        return exactMIDI
    }
    
    
    // this will detect the pitches when given the frequency array and the onsets in samples
    internal func detectNoteNames(freqArray: [Float], onsetSamps: [Int]) -> [String] {
        let freqArray = self.detectFrequencies(freqArray: freqArray, onsetSamps: onsetSamps)
        detectedFrequencies = freqArray
        var noteNameArray = [String]()
        for freq in freqArray {
            let midiFromFreq = pitchConverter.MIDIfromFreq(frequency: freq)
            noteNameArray.append(pitchConverter.noteNameFromMIDI(midiNum: midiFromFreq))
        }
        return noteNameArray
    }
    
    // Tonic: C: 0, D: 2, etc. Mode: Major: 0, Minor: 1
    internal func convertMelodyToScaleDegrees(detectedExactMIDI: [Float], tonic: Int, mode: Int) -> [Int] {
        var melodyInScaleDegrees = [Int]()
        for note in detectedExactMIDI {
            melodyInScaleDegrees.append(self.pitchInScaleDegree(exactMIDI: note, tonic: tonic, mode: mode))
        }
        return melodyInScaleDegrees
    }
    
    internal func pitchInScaleDegree(exactMIDI: Float, tonic: Int, mode: Int) -> Int {
        // pretend it's in C Major for simplicity
        let exactMIDIShiftedToC = exactMIDI - Float(tonic % 12)
        let exactMIDImod = exactMIDIShiftedToC.truncatingRemainder(dividingBy: 12.0)
        
        // major
        if mode == 0 {
            if exactMIDImod > 11.5 || exactMIDImod <= 1.0 {
                return 1
            }
            else if exactMIDImod > 1.0 && exactMIDImod <= 3.0 {
                return 2
            }
            else if exactMIDImod > 3.0 && exactMIDImod <= 4.5 {
                return 3
            }
            else if exactMIDImod > 4.5 && exactMIDImod <= 6.0 {
                return 4
            }
            else if exactMIDImod > 6.0 && exactMIDImod <= 8.0 {
                return 5
            }
            else if exactMIDImod > 8.0 && exactMIDImod <= 10.0 {
                return 6
            }
            else { //exactMIDImod > 10.0 && exactMIDImod <= 11.5
                return 7
            }
        }
            // natural minor
        else { // mode == 1
            if exactMIDImod > 11.0 || exactMIDImod <= 1.0 {
                return 1
            }
            else if exactMIDImod > 1.0 && exactMIDImod <= 2.5 {
                return 2
            }
            else if exactMIDImod > 2.5 && exactMIDImod <= 4.0 {
                return 3
            }
            else if exactMIDImod > 4.0 && exactMIDImod <= 6.0 {
                return 4
            }
            else if exactMIDImod > 6.0 && exactMIDImod <= 7.5 {
                return 5
            }
            else if exactMIDImod > 7.5 && exactMIDImod <= 9 {
                return 6
            }
            else { //exactMIDImod > 9.0 && exactMIDImod <= 11.0
                return 7
            }
        }
    }
    
    private func median(data: [Float]) -> Float {
        let sortedData = data.sorted()
        let length = sortedData.count
        if (length % 2 == 0) {
            return (sortedData[length/2] + sortedData[length/2 - 1]) / 2
        }
        else {
            return sortedData[length/2]
        }
        
    }
    
}
