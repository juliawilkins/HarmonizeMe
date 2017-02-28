//
//  RecordingViewController.swift
//  HarmonizeMe
//
//  Created by Julia Wilkins on 2/21/17.
//  Copyright © 2017 Julia Wilkins. All rights reserved.
//

import UIKit
import AVFoundation

class RecordingViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    var audioEngine: AVAudioEngine!
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    var soundFileURL: URL!
    
    var playerA: AVAudioPlayerNode!
    var playerB: AVAudioPlayerNode!
    var playerC: AVAudioPlayerNode!
    var pitchShiftA: AVAudioUnitTimePitch!
    var pitchShiftB: AVAudioUnitTimePitch!
    var pitchShiftC: AVAudioUnitTimePitch!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var playHarmonizedButton: UIButton!
 
 
    @IBAction func recordAudio(_ sender: UIButton) {
        if audioRecorder?.isRecording == false {
            playButton.isEnabled = false
            stopButton.isEnabled = true
            audioRecorder?.record()
        }
    }
    
    @IBAction func playAudio(_ sender: UIButton) {
        if audioRecorder?.isRecording == false {
            stopButton.isEnabled = true
            recordButton.isEnabled = false
            
            do {
                try audioPlayer = AVAudioPlayer(contentsOf:
                    (audioRecorder?.url)!)
                audioPlayer!.delegate = self
                audioPlayer!.prepareToPlay()
                audioPlayer!.play()
            } catch let error as NSError {
                print("audioPlayer error: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func stopAudio(_ sender: UIButton) {
        stopButton.isEnabled = false
        playButton.isEnabled = true
        recordButton.isEnabled = true
        
        if audioRecorder?.isRecording == true {
            audioRecorder?.stop()
        } else {
            audioPlayer?.stop()
        }
        
        if audioEngine.isRunning == true {
            audioEngine.detach(pitchShiftA)
            audioEngine.detach(pitchShiftB)
            audioEngine.detach(pitchShiftC)
            audioEngine.detach(playerA)
            audioEngine.detach(playerB)
            audioEngine.detach(playerC)
            audioEngine.stop()
        }
    }
    
    @IBAction func playHarmonizedAudio(_ sender: UIButton) {
        if audioRecorder?.isRecording == false {
            stopButton.isEnabled = true
            recordButton.isEnabled = false
            
            do {
                
                try audioPlayer = AVAudioPlayer(contentsOf:
                    (audioRecorder?.url)!)
                /*
                audioPlayer!.delegate = self
                audioPlayer!.prepareToPlay()
                audioPlayer!.play() */
                
                
                let AVFile = try! AVAudioFile.init(forReading: soundFileURL)
                let buffer = AVAudioPCMBuffer.init(pcmFormat: AVFile.processingFormat, frameCapacity: AVAudioFrameCount(AVFile.length))
                do {
                    try AVFile.read(into: buffer)
                } catch let error as NSError {
                    print("playHarmonizedAudio AVFile read into buffer error: \(error.localizedDescription)")
                }
                
                pitchShiftA.pitch = 0.0 // in cents
                pitchShiftB.pitch = -500.0
                pitchShiftC.pitch = -800.0
                
                audioEngine.attach(playerA)
                audioEngine.attach(playerB)
                audioEngine.attach(playerC)
                audioEngine.attach(pitchShiftA)
                audioEngine.attach(pitchShiftB)
                audioEngine.attach(pitchShiftC)
                
                audioEngine.connect(playerA, to: pitchShiftA, format: buffer.format)
                audioEngine.connect(pitchShiftA, to: audioEngine.mainMixerNode, format: buffer.format)
                audioEngine.connect(playerB, to: pitchShiftB, format: buffer.format)
                audioEngine.connect(pitchShiftB, to: audioEngine.mainMixerNode, format: buffer.format)
                audioEngine.connect(playerC, to: pitchShiftC, format: buffer.format)
                audioEngine.connect(pitchShiftC, to: audioEngine.mainMixerNode, format: buffer.format)
                
                playerB.scheduleBuffer(buffer, completionHandler: nil)
                playerC.scheduleBuffer(buffer, completionHandler: nil)
                playerA.scheduleBuffer(buffer, completionHandler: {
                    self.recordButton.isEnabled = true
                    self.stopButton.isEnabled = true
                    self.audioEngine.detach(self.pitchShiftA)
                    self.audioEngine.detach(self.pitchShiftB)
                    self.audioEngine.detach(self.pitchShiftC)
                    self.audioEngine.detach(self.playerA)
                    self.audioEngine.detach(self.playerB)
                    self.audioEngine.detach(self.playerC)
                    self.audioEngine.stop()
                } )
                
                audioEngine.prepare()
                do {
                    try audioEngine.start()
                    playerA.play()
                    playerB.play()
                    playerC.play()
                } catch let error as NSError {
                    print("playHarmonizedAudio audioEngine error: \(error.localizedDescription)")
                }

            } catch let error as NSError {
                print("playHarmonizedAudio error: \(error.localizedDescription)")
            }
        }
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        playButton.isEnabled = false
        stopButton.isEnabled = false
        
        audioEngine = AVAudioEngine()
        playerA = AVAudioPlayerNode()
        playerB = AVAudioPlayerNode()
        playerC = AVAudioPlayerNode()
        pitchShiftA = AVAudioUnitTimePitch()
        pitchShiftB = AVAudioUnitTimePitch()
        pitchShiftC = AVAudioUnitTimePitch()
        
//        moveToHarmonyButton.isEnabled = false
        
        let fileMgr = FileManager.default
        
        let dirPaths = fileMgr.urls(for: .documentDirectory,
                                    in: .userDomainMask)
        
        soundFileURL = dirPaths[0].appendingPathComponent("sound.caf")
        
        let recordSettings =
            [AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue,
             AVEncoderBitRateKey: 16,
             AVNumberOfChannelsKey: 2,
             AVSampleRateKey: 44100.0] as [String : Any]
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(
                AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
        
        do {
            try audioRecorder = AVAudioRecorder(url: soundFileURL,
                                                settings: recordSettings as [String : AnyObject])
            audioRecorder?.prepareToRecord()
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
    }
        // Do any additional setup after loading the view.
    
    //RECORDER DELEGATE
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.isEnabled = true
        stopButton.isEnabled = false
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio Play Decode Error")
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Audio Record Encode Error")
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
