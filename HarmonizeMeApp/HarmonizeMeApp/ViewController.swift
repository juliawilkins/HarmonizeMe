//
//  ViewController.swift
//  HarmonizeMeApp
//
//  Created by Alexander Fang on 2/5/17.
//  Copyright © 2017 Alex Fang. All rights reserved.
//

import UIKit
import AudioKit
import Foundation

class ViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // tonic and mode
    enum Tonic: String {
        case C, Df, D, Ef, E, F, Fs, G, Af, A, Bf, B
    }
    enum Mode {
        case major
        case minor
    }
    // default mode and tonic of C Major
    var currMode = Mode.major
    var currTonic = Tonic.C
    
    // data for UIPickerView's
    let tonalCenterMajorData = ["C", "C♯/D♭", "D", "E♭", "E", "F", "F♯/G♭", "G", "A♭", "A", "B♭", "B"]
    let tonalCenterMinorData = ["C", "C♯", "D", "D♯/E♭", "E", "F", "F♯/G♭", "G", "G♯/A♭", "A", "B♭", "B"]
    let modePickerData = ["Major", "Minor"]
    let numTonalCenters = 12
    
    // instance variables to play tonic files
    // can't initialize here, but need to access outside of viewDidLoad
    var tonicFileName: String!
    var tonicAKAudioFile: AKAudioFile!
    var tonicPlayer: AKAudioPlayer!
    var tracker: AKFrequencyTracker!
    var pitchTrackerTimer: Timer!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // init with default C Major
        tonicFileName = currTonic.rawValue + "Majormid.mp3"
        tonicAKAudioFile = try! AKAudioFile(readFileName: tonicFileName)
        tonicPlayer = try! AKAudioPlayer(file: tonicAKAudioFile!)
        //tracker = AKFrequencyTracker(tonicPlayer)
        
        // need to set .output before starting
        // .start() allowed only once in entire code
        AudioKit.output = tonicPlayer
        AudioKit.start()
        
        tonalCenterPicker.dataSource = self
        tonalCenterPicker.delegate = self
        
        modePicker.dataSource = self
        modePicker.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Actions
    @IBAction func playKeyButton(_ sender: UIButton) {
        // currently only playing middle register tonic files
        if currMode == .major {
            tonicFileName = currTonic.rawValue + "Majormid.mp3"
        }
        else {
            tonicFileName = currTonic.rawValue + "Minormid.mp3"
        }
        tonicAKAudioFile = try! AKAudioFile(readFileName: tonicFileName)
        try! tonicPlayer.replace(file: tonicAKAudioFile)
        tonicPlayer.play()
        
    }
    
    @IBAction func playTestPitchTrack(_ sender: UIButton) {
        AudioKit.stop()
        tonicAKAudioFile = try! AKAudioFile(readFileName: "tatest.wav")
        try! tonicPlayer.replace(file: tonicAKAudioFile)
        tracker = AKFrequencyTracker(tonicPlayer)
        //print(String(describing: (tonicAKAudioFile.floatChannelData![0])))
        var signal_data = tonicAKAudioFile.floatChannelData![0]
        // AudioKit.output = tracker
        // AudioKit.start()
        // tonicPlayer.play()
        // pitchTrackerTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.printFreq), userInfo: nil, repeats: true)
        
        //print(signal_data)
        //print(get_rms(sig: [7.0, 20.0]))
        
        
        print(onset_times(audioFile: tonicAKAudioFile, windowSize: 1000, hopSize: 500, sampleRate: 44100.0))
        
    }
    
    public func get_rms(sig: [Float]) -> Float {
        var summation = Float(0.0)
        let len = sig.count
        for ii in 0..<len {
            summation += sig[ii] * sig[ii]
        }
        return sqrt(summation/Float(len))
    }
    
    // [1, 2, 3] % 2
    
    public func onset_times(audioFile: AKAudioFile, windowSize: Int, hopSize: Int, sampleRate: Float) -> [Float] {
        var onsets = [Float]()
        var timeOnsets = [Float]()
        var sampOnsets = [Float]()
        let sig = audioFile.floatChannelData![0]
        let duration = Float(audioFile.duration)
        let sampleCount = audioFile.samplesCount
        var sigcopy = sig
        let threshold = 0.40
        
        // append 0's to end of sig to make it divisible by hopSize
        let numZerosToAdd = sig.count % hopSize
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
            currRMS = get_rms(sig: window)
            print("currRMS: " + String(currRMS))
            
            // first window won't have a ratio of windows, so skip
            if ii == 0 {
                prevRMS = currRMS
                continue
            }
            else if (prevRMS/currRMS < threshold) || (currRMS > 10.0) {
                onsets.append(Float(ii))
                prevRMS = currRMS
            }
        }
        
        // converting into time (s)
        for onset in onsets {
            sampOnsets.append(onset * Float(hopSize))
        }
        print("duration of audio file: " + String(duration))
        for samp in sampOnsets {
            timeOnsets.append(samp / sampleRate)
        }
        
        return timeOnsets
    }

    
    public func printFreq() {
        print(String(format: "%.2f", tracker.frequency))
    }
    
    // MARK: Properties
    @IBOutlet weak var tonalCenterPicker: UIPickerView!
    @IBOutlet weak var modePicker: UIPickerView!
    @IBOutlet weak var keyLabel: UILabel!
    

    //PROTOCOL!
    
    //MARK: - Delegates and data sources
    //MARK: Data Sources
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // one list displayed each UIPickerView
    }
    
    // num of rows in component
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == modePicker {
            return modePickerData.count // only two modes for now
        }
        else {
            return numTonalCenters // quarter-tones will probably never be implemented in this app
        }
    }
    
    //MARK: Delegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == modePicker {
            return modePickerData[row]
        }
        else {
            if currMode == .major {
                return tonalCenterMajorData[row]
            }
            else {
                return tonalCenterMinorData[row]
            }
        }
    }
    
    // responding to selection -- update tonic and mode
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == modePicker {
            switch row {
            case 0:
                // if changed mode, then refresh which enharmonic spellings the user sees
                if currMode != .major {
                    tonalCenterPicker.reloadAllComponents()
                }
                currMode = .major
            case 1:
                if currMode != .minor {
                    tonalCenterPicker.reloadAllComponents()
                }
                currMode = .minor
            default:
                break
            }
        }
        else {
            switch row {
            case 0:
                currTonic = Tonic.C
            case 1:
                currTonic = Tonic.Df
            case 2:
                currTonic = Tonic.D
            case 3:
                currTonic = Tonic.Ef
            case 4:
                currTonic = Tonic.E
            case 5:
                currTonic = Tonic.F
            case 6:
                currTonic = Tonic.Fs
            case 7:
                currTonic = Tonic.G
            case 8:
                currTonic = Tonic.Af
            case 9:
                currTonic = Tonic.A
            case 10:
                currTonic = Tonic.Bf
            case 11:
                currTonic = Tonic.B
            default:
                break
            }
        }
    }
}
