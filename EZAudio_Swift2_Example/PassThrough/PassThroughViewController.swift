//
//  PassThroughViewController.swift
//  EZAudio_Swift2_Example
//
//  Created by Kevin Chan on 2016/6/7.
//  Copyright © 2016年 Kevinjay Chan. All rights reserved.
//

import UIKit

class PassThroughViewController: UIViewController {

    // The OpenGL based audio plot
    @IBOutlet weak var audioPlot: EZAudioPlotGL!

    // The UILabel used to display whether the microphone is on or off
    @IBOutlet weak var microphoneTextLabel: UILabel!

    // MARK: Status Bar Style
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // MARK: Customize the Audio Plot
    override func viewDidLoad() {

        super.viewDidLoad()

        // Setup the AVAudioSession. EZMicrophone will not work properly on iOS
        // if you don't do this!
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }

        // Customizing the audio plot's look
        audioPlot.backgroundColor = UIColor(colorLiteralRed: 0.569, green: 0.82, blue: 0.478, alpha: 1.0)
        audioPlot.color = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        audioPlot.plotType = .Buffer

        // Start the microphone
        EZMicrophone.sharedMicrophone().delegate = self
        EZMicrophone.sharedMicrophone().startFetchingAudio()
        microphoneTextLabel.text = "Microphone On"

        // Use the microphone as the EZOutputDataSource
        EZOutput.sharedOutput().dataSource = EZMicrophone.sharedMicrophone()

        // Make sure we override the output to the speaker
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.Speaker)
        } catch {
            print(error)
        }

        // Start the EZOutput
        EZOutput.sharedOutput().startPlayback()
    }
}

// MARK: EZMicrophoneDelegate
extension PassThroughViewController: EZMicrophoneDelegate {

    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {

        dispatch_async(dispatch_get_main_queue()) { 

            self.audioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
        }
    }
}
