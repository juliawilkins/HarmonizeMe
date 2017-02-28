//
//  Harmonizer.swift
//  HarmonizeMeApp
//
//  Created by Alexander Fang on 2/24/17.
//  Copyright © 2017 Alex Fang. All rights reserved.
//

import Foundation
import AudioKit
import AVFoundation

// hopefully returns 3 different AVQueuePlayers to play at the same time?
class Harmonizer {
    // self-written classes
    private var progressionCreater = ProgressionCreater()
    private var pitchConverter = PitchConverter()
    private var noteSegmenter = NoteSegmenter()
    private var pitchDetector = PitchDetector()
    
    // outputs from self-written classes
    private var onsetSamps = [Int]()
    private var detectedExactMIDI = [Float]()
    private var melodyInScaleDegrees = [Int]()
    private var progressionInSemitones = [Int]()
    
    // AVAudio and AKAudio
    private var audioFile: AKAudioFile!
    private var testFile: AKAudioFile!
    
    private var fileName = String()
    private var signalData = [Float]()
    private var freqArray = [Float]()
    

    
    // freqs might be partitioned every 512 samples in the future?
    init(fileString: String, freqs: [Float], tonic: Int, mode: Int) {
        fileName = fileString
        freqArray = freqs
        audioFile = try! AKAudioFile(readFileName: fileName)
        signalData = audioFile.floatChannelData![0]
        onsetSamps = noteSegmenter.onsetSamps(audioSignal: signalData, windowSize: 1024, hopSize: 512, sampleRate: 44100.0)
        //detectedExactMIDI = pitchDetector.detectExactMIDI(freqArray: freqArray, onsetSamps: onsetSamps)
        melodyInScaleDegrees = pitchDetector.convertMelodyToScaleDegrees(detectedExactMIDI: detectedExactMIDI, tonic: tonic, mode: mode)
    }
    
    internal func test(fileString: String) -> AVAudioFile {
        testFile = try! AKAudioFile(readFileName: fileString)
        let signal = testFile.floatChannelData![0]
        
        // get first second only
        let newSignal = Array(signal[0..<44100])
        //make into stereo
        var stereoData = [[Float]]()
        stereoData.append(newSignal)
        stereoData.append(newSignal)
        let newAudioFile = try! AKAudioFile(createFileFromFloats: stereoData)
        let newAVAudioFile = newAudioFile as AVAudioFile
        
        return newAVAudioFile
    }
    
    
    
    
    
}
