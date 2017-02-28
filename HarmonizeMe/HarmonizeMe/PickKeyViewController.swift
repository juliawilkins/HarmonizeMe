//
//  PickKeyViewController.swift
//  HarmonizeMe
//
//  Created by Julia Wilkins on 2/21/17.
//  Copyright © 2017 Julia Wilkins. All rights reserved.
//

import UIKit
import AudioKit
import Foundation

class PickKeyViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource  {

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
    var time = 0.0 // keep track of time
    
    var trackedFrequencies = [Float]()
    
    
    @IBOutlet weak var homeButton: UIButton!
    
    @IBAction func homeAction(_ sender: UIButton) {
        AudioKit.stop()
    }
    
    
    @IBOutlet weak var soundsGoodButton: UIButton!
    
    @IBAction func soundsGoodAction(_ sender: UIButton) {
        AudioKit.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
        let signal_data = tonicAKAudioFile.floatChannelData![0]
        
        //make into stereo
        var stereo_data = [[Float]]()
        stereo_data.append(signal_data)
        stereo_data.append(signal_data)
        
        let newAudioFile = try! AKAudioFile(createFileFromFloats: stereo_data)
        
        try! tonicPlayer.replace(file: newAudioFile)
        tracker = AKFrequencyTracker(tonicPlayer)
        
        AudioKit.output = tracker
        AudioKit.start()
        tonicPlayer.play()
        pitchTrackerTimer = Timer.scheduledTimer(timeInterval: 512.0/44100.0, target: self, selector: #selector(self.trackFreq), userInfo: nil, repeats: true)
        
        let noteSegmenter = NoteSegmenter()
        let onsetTimes = noteSegmenter.onsetTimes(audioSignal: signal_data, windowSize: 1024, hopSize: 512, sampleRate: 44100.0)
        print("Onset times: " + String(describing: onsetTimes))
        //let testOnsets = onset_times(audioFile: tonicAKAudioFile, windowSize: 1024, hopSize: 512, sampleRate: 44100.0) ***
    }
    
    public func trackFreq() {
        //print(String(format: "%.2f", tracker.frequency))
        let roundedFreq = Float(round(100*tracker.frequency)/100) // attempt to round to two decimal places
        trackedFrequencies.append(roundedFreq)
        
        // to make it stop when the duration is over
        if (time >= tonicAKAudioFile.duration)
        {
            pitchTrackerTimer.invalidate()
            print("Frequencies every 512/44100 seconds: " + String(describing: trackedFrequencies))
            print("Size of above array: " + String(trackedFrequencies.count))
        }
        time += 512.0/44100.0
        
    }
    
    // MARK: Properties
    
    @IBOutlet weak var tonalCenterPicker: UIPickerView!
    
    @IBOutlet weak var modePicker: UIPickerView!
    
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
