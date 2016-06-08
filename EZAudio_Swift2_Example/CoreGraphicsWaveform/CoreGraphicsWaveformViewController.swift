//
//  CoreGraphicsWaveformViewController.swift
//  EZAudio_Swift2_Example
//
//  Created by Kevin Chan on 2016/6/7.
//  Copyright © 2016年 Kevinjay Chan. All rights reserved.
//

import UIKit

class CoreGraphicsWaveformViewController: UIViewController {

    // MARK: Properties
    // The CoreGraphics based audio plot
    @IBOutlet weak var audioPlot: EZAudioPlot!

    // The microphone input picker view to display the different microphone input sources
    @IBOutlet weak var microphoneInputPickerView: UIPickerView!

    // The text label displaying "Microphone On" or "Microphone Off"
    @IBOutlet weak var microphoneTextLabel: UILabel!

    // The microphone input picker view's top layout constraint (we use this to hide the control)
    @IBOutlet weak var microphoneInputPickerViewTopConstraint: NSLayoutConstraint!

    // The button at the bottom displaying the currently selected microphone input
    @IBOutlet weak var microphoneInputToggleButton: UIButton!

    // The microphone component
    var microphone: EZMicrophone?
    var inputs: NSArray?

    // MARK: View Style
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // MARK: Setup
    override func viewDidLoad() {

        super.viewDidLoad()

        // Setup the AVAudioSession. EZMicrophone will not work properly on iOS
        // if you don't do this!
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }

        // Background color
        audioPlot.backgroundColor = UIColor(colorLiteralRed: 0.984, green: 0.471, blue: 0.525, alpha: 1.0)

        // Waveform color
        audioPlot.color = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        // Plot type
        audioPlot.plotType = .Buffer

        // Create the microphone
        microphone = EZMicrophone(microphoneDelegate: self)

        // Set up the microphone input UIPickerView items to select
        // between different microphone inputs. Here what we're doing behind the hood
        // is enumerating the available inputs provided by the AVAudioSession.
        inputs = EZAudioDevice.inputDevices()
        microphoneInputPickerView.dataSource = self
        microphoneInputPickerView.delegate = self

        
        // Start the microphone
        microphone?.startFetchingAudio()
        microphoneTextLabel.text = "Microphone On"
    }

    // MARK: Actions
    // Switches the plot drawing type between a buffer plot (visualizes the current
    // stream of audio data from the update function) or a rolling plot (visualizes
    // the audio data over time, this is the classic waveform look)
    @IBAction func changePlotType(sender: AnyObject) {

        let selectedSegment = sender.selectedSegmentIndex
        switch selectedSegment {
        case 0:
            drawBufferPlot()
        case 1:
            drawRollingPlot()
        default: break
        }
    }

    // Toggles the microphone on and off. When the microphone is on it will send its
    // delegate (aka this view controller) the audio data in various ways (check out
    // the EZMicrophoneDelegate documentation for more details);
    @IBAction func toggleMicrophone(sender: UISwitch) {

        let isON = sender.on
        if !isON {

            microphone?.stopFetchingAudio()
            microphoneTextLabel.text = "Microphone Off"
        } else {

            microphone?.startFetchingAudio()
            microphoneTextLabel.text = "Microphone On"
        }
    }

    // Toggles the microphone inputs picker view in and out of display.
    @IBAction func toggleMicrophonePickerView(sender: AnyObject) {

        let isHiddne = microphoneInputPickerViewTopConstraint.constant != 0.0
        setMicrophonePickerViewHidden(!isHiddne)
    }

    // MARK: Utility
    // Give the visualization of the current buffer (this is almost exactly the
    // openFrameworks audio input example)
    func drawBufferPlot() {

        audioPlot.plotType = .Buffer
        audioPlot.shouldFill = false
        audioPlot.shouldMirror = false
    }

    // Give the classic mirrored, rolling waveform look
    func drawRollingPlot() {

        audioPlot.plotType = .Rolling
        audioPlot.shouldFill = true
        audioPlot.shouldMirror = true
    }

    func setMicrophonePickerViewHidden (hidden: Bool) {

        let pickerHeight = CGRectGetHeight(microphoneInputPickerView.bounds)
        self.microphoneInputPickerViewTopConstraint.constant = hidden ? -pickerHeight : 0.0

        UIView.animateWithDuration(0.55,
                             delay: 0.0,
            usingSpringWithDamping: 0.6,
             initialSpringVelocity: 0.5,
                           options: [UIViewAnimationOptions.BeginFromCurrentState,
                                    UIViewAnimationOptions.CurveEaseInOut,
                                    UIViewAnimationOptions.LayoutSubviews],
                        animations: {(
                                self.view.layoutIfNeeded()
                            )},

                        completion: nil
        )
    }
}

// MARK: EZMicrophoneDelegate
extension CoreGraphicsWaveformViewController: EZMicrophoneDelegate {

    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {

        dispatch_async(dispatch_get_main_queue()) {

            self.audioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
        }
    }

    func microphone(microphone: EZMicrophone!, hasAudioStreamBasicDescription audioStreamBasicDescription: AudioStreamBasicDescription) {

        EZAudioUtilities .printASBD(audioStreamBasicDescription)
    }

    func microphone(microphone: EZMicrophone!, changedDevice device: EZAudioDevice!) {

        dispatch_async(dispatch_get_main_queue()) {

            let name = device.name
            let tapText = " Tap To Change"
            let microphoneInputToggleButtonText = "\(name)\(tapText)"

            guard let audioDevice = EZAudioDevice.inputDevices(), pickerView = self.microphoneInputPickerView else {
                return
            }

            self.microphoneInputToggleButton.setTitle(microphoneInputToggleButtonText, forState: .Normal)
            self.inputs = audioDevice
            pickerView.reloadAllComponents()
            self.setMicrophonePickerViewHidden(true)
        }
    }
}

// MARK: UIPickerViewDataSource
extension CoreGraphicsWaveformViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {

        return 1
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        let device: EZAudioDevice = inputs![row] as! EZAudioDevice
        return device.name
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.inputs!.count
    }

    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {

        let device: EZAudioDevice = inputs![row] as! EZAudioDevice
        let textColor = self.audioPlot.backgroundColor ?? UIColor.blackColor()

        return NSAttributedString.init(string: device.name, attributes: [NSForegroundColorAttributeName : textColor])
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        let device: EZAudioDevice = inputs![row] as! EZAudioDevice
        microphone?.device = device
    }

}