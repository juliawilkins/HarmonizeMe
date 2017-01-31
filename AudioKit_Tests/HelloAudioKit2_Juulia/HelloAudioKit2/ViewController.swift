//
//  ViewController.swift
//  HelloAudioKit2
//
//  Created by Julia Wilkins on 1/24/17.
//  Copyright © 2017 Julia Wilkins. All rights reserved.
//

import UIKit
import AudioKit

class ViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: Properties
    @IBOutlet weak var changeFrequency: UITextField!
    
    
   let oscillator = AKOscillator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        changeFrequency.delegate = self
        oscillator.amplitude = 0.1
        //oscillator.frequency = 220
        
        AudioKit.output = oscillator
        AudioKit.start()
        
        oscillator.start()
        
        myPicker.dataSource = self
        myPicker.delegate = self
        
    }
    @IBOutlet weak var myPicker: UIPickerView!
    let pickerData = ["C major", "A major", "C minor", "A minor"]
   // @IBOutlet weak var onSwitch: UISwitch!
    
//    @IBOutlet weak var myLabel: UILabel!
//   
//    @IBAction func onSwitchPressed(_ sender: AnyObject) {
//            myLabel.text = "Woah! \(onSwitch.isOn)"
//    }
    
    @IBAction func ChangeFrequency(_ sender: UISlider) {
        oscillator.frequency = Double(sender.value * 880)
    }

    @IBOutlet weak var keyLabel: UILabel!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let input = changeFrequency.text
        let freq: Double = (input! as NSString).doubleValue
        oscillator.frequency = freq
    }
    
    //PROTOCOL!
    
    
    //MARK: - Delegates and data sources
    //MARK: Data Sources
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    //MARK: Delegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }

}

