//
//  ProgressionCreater.swift
//  HarmonizeMeApp
//
//  Created by Alexander Fang on 2/24/17.
//  Copyright © 2017 Alex Fang. All rights reserved.
//

import Foundation

// no audio processing at all
// Basic: given a melody in scale degrees, it gives you how much to pitch shift from the melody
class ProgressionCreater {

    private var progressionInRomanNumerals = [String]()
    
    private func getRandomProgression(melodyInScaleDegrees: [Int], mode: Int) -> [String] {
        var progression = [String]()
        for note in melodyInScaleDegrees {
            // possible chords to harmonize the melodic note:
            let possibleChords = self.getPossibleChords(noteInScaleDegree: note, mode: mode)
            
            // randomly choosing one of them
            let randomIndex = Int(arc4random_uniform(UInt32(possibleChords.count)))
            let randomChord = possibleChords[randomIndex]
            
            // adding it to the progression
            progression.append(randomChord)
            
            /*  UNNECESSARY
            // chord in scale degrees
            let chordInScaleDegrees = fillChord(noteInScaleDegree: note, chord: randomChord)
            progressionInScaleDegrees.append(chordInScaleDegrees)
            */
        }
        return progression
    }
    
    // Call this only after getRandomProgressionInSemitones
    internal func getProgressionInRomanNumerals() -> [String] {
        return progressionInRomanNumerals
    }
    
    // Given a melody in scale degrees and mode, returns how much to shift each melody note by semitone
    internal func getRandomProgressionInSemitones(melodyInScaleDegrees: [Int], mode: Int) -> [[Int]] {
        var progressionInSemitones = [[Int]]()
        var progression = self.getRandomProgression(melodyInScaleDegrees: melodyInScaleDegrees, mode: mode)
        progressionInRomanNumerals = progression
        
        for ii in 0..<melodyInScaleDegrees.count {
            // fillChord: 2 + V --> [2, 7, 5]
            let chordInScaleDegrees = self.fillChord(noteInScaleDegree: melodyInScaleDegrees[ii], chord: progression[ii])
            // chordInSemitones: [2, 7, 5] + major --> [0, -3, -7]
            let chordInSemitones = self.chordScaleDegreesToSemitones(chord: chordInScaleDegrees, mode: mode)
            progressionInSemitones.append(chordInSemitones)
        }
        return progressionInSemitones
    }
    
    internal func getPossibleChords(noteInScaleDegree: Int, mode: Int) -> [String] {
        // major
        if mode == 0 {
            switch noteInScaleDegree {
            case 1:
                return ["I", "I⁶", "IV", "vi"]
            case 2:
                return ["V", "V⁶", "ii⁶"]
            case 3:
                return ["I"]
            case 4:
                return ["IV"]
            case 5:
                return ["I", "I⁶", "V", "V⁶"]
            case 6:
                return ["IV", "ii⁶", "vi"]
            case 7:
                return ["V"]
            default:
                return ["INVALID MELODY NOTE"]
            }
        }
            
        // natural minor
        else { // mode == 1
            switch noteInScaleDegree {
            case 1:
                return ["i", "i⁶", "iv", "VI"]
            case 2:
                return ["v", "v⁶", "iiº⁶"]
            case 3:
                return ["i"]
            case 4:
                return ["iv"]
            case 5:
                return ["i", "i⁶", "v", "v⁶"]
            case 6:
                return ["iv", "ii⁶", "VI"]
            case 7:
                return ["v"]
            default:
                return ["INVALID MELODY NOTE"]
            }
        }
    }
    
    // Given a melodic note and a chord, returns an array of 3 pitches in scale degrees that are in the chord
    // Returns: [melody, mid, bass]
    private func fillChord(noteInScaleDegree: Int, chord: String) -> [Int] {
        var filledChord = [Int]()
        filledChord.append(noteInScaleDegree)
        filledChord.append(self.midNote(noteInScaleDegree: noteInScaleDegree, chord: chord))
        filledChord.append(self.bassNote(chord: chord))
        return filledChord
    }
    
    // Given a chord from fillChord and mode, sets mid and bass to semitones away from the melody
    internal func chordScaleDegreesToSemitones(chord: [Int], mode: Int) -> [Int] {
        var chordInSemitones = [Int]()
        
        let top = self.noteScaleDegreesToSemitones(note: chord[0], mode: mode)
        let mid = self.noteScaleDegreesToSemitones(note: chord[1], mode: mode)
        let bottom = self.noteScaleDegreesToSemitones(note: chord[2], mode: mode)
        
        // top note
        chordInSemitones.append(0)
        
        // mid note
        let midSemitones = mid - top
        // if mid is still higher than top
        if mid > top {
            chordInSemitones.append(midSemitones - 12)
        }
        else {
            chordInSemitones.append(midSemitones)
        }
        
        // bottom note
        chordInSemitones.append(bottom - top - 12)
        
        return chordInSemitones
    }
    
    // Given a pitch in scale degrees and mode, returns how many semitones it is above the tonic
    private func noteScaleDegreesToSemitones(note: Int, mode: Int) -> Int {
        // major
        if mode == 0 {
            switch note {
            case 1:
                return 0
            case 2:
                return 2
            case 3:
                return 4
            case 4:
                return 5
            case 5:
                return 7
            case 6:
                return 9
            case 7:
                return 11
            default:
                return -1
            }
        }
        
        // minor
        else { // mode == 1
            switch note {
            case 1:
                return 0
            case 2:
                return 2
            case 3:
                return 3
            case 4:
                return 5
            case 5:
                return 7
            case 6:
                return 8
            case 7:
                return 10
            default:
                return -1
            }
        }
    }
    
    
    // Given a chord, returns the bass note that it should have in scale degrees
    private func bassNote(chord: String) -> Int {
        switch chord {
        case "I", "i":
            return 1
        case "I⁶", "i⁶":
            return 3
        case "IV", "iv", "ii⁶", "iiº⁶":
            return 4
        case "V", "v":
            return 5
        case "VI", "vi":
            return 6
        case "V⁶", "v⁶":
            return 7
        default:
            return -1
        }
    }
    
    // Given a melody note and its chord, returns the mid note that it should have in scale degrees
    private func midNote(noteInScaleDegree: Int, chord: String) -> Int {
        switch chord {
        case "I", "i":
            switch noteInScaleDegree {
            case 1, 5:
                return 3
            case 3:
                return 5
            default:
                return -1
            }
        case "I⁶", "i⁶":
            switch noteInScaleDegree {
            case 1:
                return 5
            case 5:
                return 1
            default:
                return -1
            }
        case "IV", "iv":
            switch noteInScaleDegree {
            case 1, 4:
                return 6
            case 6:
                return 1
            default:
                return -1
            }
        case "ii⁶", "iiº⁶":
            switch noteInScaleDegree {
            case 2:
                return 6
            case 6:
                return 2
            default:
                return -1
            }
        case "V", "v":
            switch noteInScaleDegree {
            case 2, 5:
                return 7
            case 7:
                return 5
            default:
                return -1
            }
        case "VI", "vi":
            switch noteInScaleDegree {
            case 1:
                return 3
            case 3, 6:
                return 1
            default:
                return -1
            }
        case "V⁶", "v⁶":
            switch noteInScaleDegree {
            case 2:
                return 5
            case 5:
                return 2
            default:
                return -1
            }
        default:
            return -1
        }
    }
}
