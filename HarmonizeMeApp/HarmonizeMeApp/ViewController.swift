//
//  ViewController.swift
//  HarmonizeMeApp
//
//  Created by Alexander Fang on 2/5/17.
//  Copyright © 2017 Alex Fang. All rights reserved.
//

import UIKit
import AudioKit

class ViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    enum Mode {
        case major
        case minor
    }
    var currMode = Mode.major
    var currTonic = Tonic.C
    
    
    
    enum Tonic: String {
        case C, Df, D, Ef, E, F, Fs, G, Af, A, Bf, B
    }
    
    
    // MARK: Properties
//    @IBOutlet weak var changeFrequency: UITextField!
    
    // MARK: Actions
    
    @IBAction func playKeyButton(_ sender: UIButton) {
        // if let playing whatever this thing is blahblahblah
        // see if it's currently playing, if it is, stop it before going on
        
        let tonicFileName = currTonic.rawValue + "Majormid.mp3"
        let tonicAKAudioFile = try! AKAudioFile(readFileName: tonicFileName)
        let tonicPlayer = try! AKAudioPlayer(file: tonicAKAudioFile)
        AudioKit.output = tonicPlayer
        AudioKit.start()
        tonicPlayer.play()
        //tonicPlayer.stop()
    }
    
    
    //let oscillator = AKOscillator()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        changeFrequency.delegate = self
        //oscillator.amplitude = 0.1
        //oscillator.frequency = 220
        
        //AudioKit.output = oscillator
        //AudioKit.start()
        //oscillator.start()
        
        tonalCenterPicker.dataSource = self
        tonalCenterPicker.delegate = self
        
        modePicker.dataSource = self
        modePicker.delegate = self
        
        /*
         let CMajormid = try? AKAudioFile(readFileName: "CMajormid.mp3")
         let player = try? AKAudioPlayer(file: CMajormid!)
         
         AudioKit.output = player!
         AudioKit.start()
         player!.play()
         */
    }
    
    @IBOutlet weak var tonalCenterPicker: UIPickerView!
    let tonalCenterMajorData = ["C", "C♯/D♭", "D", "E♭", "E", "F", "F♯/G♭", "G", "A♭", "A", "B♭", "B"]
    let tonalCenterMinorData = ["C", "C♯", "D", "D♯/E♭", "E", "F", "F♯/G♭", "G", "G♯/A♭", "A", "B♭", "B"]
    
    @IBOutlet weak var modePicker: UIPickerView!
    let modePickerData = ["Major", "Minor"]
    
    /*
    @IBAction func ChangeFrequency(_ sender: UISlider) {
        oscillator.frequency = Double(sender.value * 880)
    } */
    
    @IBOutlet weak var keyLabel: UILabel!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let input = changeFrequency.text
        let freq: Double = (input! as NSString).doubleValue
        oscillator.frequency = freq
    } */
    
    //PROTOCOL!
    
    //MARK: - Delegates and data sources
    //MARK: Data Sources
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // 1 component regardless of which view
        return 1
    }
    
    // num of rows in component
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == modePicker {
            return modePickerData.count
        }
        else {
            if currMode == .major {
                return tonalCenterMajorData.count
            }
            else {
                return tonalCenterMinorData.count
            }
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
    
    // responding to selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == modePicker {
            switch row {
            case 0:
                //changed mode
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

