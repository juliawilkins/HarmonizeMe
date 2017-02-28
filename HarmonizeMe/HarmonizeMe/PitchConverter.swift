//
//  PitchRepresentation.swift
//  HarmonizeMe
//
//  Created by Alexander Fang on 2/21/17.
//  Copyright © 2017 Alex Fang. All rights reserved.
//

import Foundation

class PitchConverter {
    private let NUMPITCHES = 12
    private let noteMIDI = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] // mod 12
    private let noteFrequencies = [261.63, 277.18, 293.66, 311.13, 329.63, 349.23, 369.99, 392.00, 415.30, 440.00, 466.16, 493.88] // MIDI 60-71
    private let noteNames = ["C", "C♯/D♭", "D", "D♯/E♭", "E", "F", "F♯/G♭", "G", "G♯/A♭", "A", "A♯/B♭", "B"]
    private let noteNamesWithSharps = ["C", "C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"]
    private let noteNamesWithFlats = ["C", "D♭","D","E♭","E","F","G♭","G","A♭","A","B♭","B"]
    
    internal func MIDIfromFreq(frequency: Float) -> Int {
        let freq = frequency
        let midi = 69.00 + (12.00*log2f(freq / 440.00)) // exact MIDI
        return Int(round(midi)) % 12 // nearest MIDI mod 12
    }
    
    // doesn't round, doesn't mod 12
    internal func exactMIDIfromFreq(frequency: Float) -> Float {
        let freq = frequency
        let midi = 69.00 + (12.00*log2f(freq / 440.00)) // exact MIDI
        return midi
    }
    
    internal func noteNameFromMIDI(midiNum: Int) -> String {
        return noteNames[midiNum % 12]
    }
    
}
