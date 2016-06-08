//
//  FFTViewController.swift
//  EZAudio-Swift-Example
//
//  Created by Kevin Chan on 2016/6/6.
//  Copyright © 2016年 Kevinjay Chan. All rights reserved.
//

import UIKit

class FFTViewController: UIViewController {

    // MARK: Properties
    // EZAudioPlot for frequency plot
    @IBOutlet weak var audioPlotFreq: EZAudioPlot!

    // EZAudioPlot for time plot
    @IBOutlet weak var audioPlotTime: EZAudioPlot!

    // A label used to display the maximum frequency (i.e. the frequency with the
    // highest energy) calculated from the FFT.
    @IBOutlet weak var freqLabel: UILabel!

    // The microphone used to get input.
    var microphone: EZMicrophone?

    // Used to calculate a rolling FFT of the incoming audio data.
    var fft: EZAudioFFTRolling?

    let FFTViewControllerFFTWindowSize: vDSP_Length = 4096

    // MARK: Status Bar Style
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // MARK: View Lifecycle
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

        // Setup time domain audio plot
        audioPlotTime.plotType = .Buffer
        freqLabel.numberOfLines = 0

        // Setup frequency domain audio plot
        audioPlotFreq.shouldFill = true
        audioPlotFreq.plotType = .Buffer
        audioPlotFreq.shouldCenterYAxis = false

        // Create an instance of the microphone and tell it to use this view controller instance as the delegate
        microphone = EZMicrophone(delegate: self)

        // Create an instance of the EZAudioFFTRolling to keep a history of the incoming audio data and calculate the FFT.
        fft = EZAudioFFTRolling.init(windowSize: FFTViewControllerFFTWindowSize, sampleRate: Float((microphone?.audioStreamBasicDescription().mSampleRate)!), delegate: self)

        // Start the mic
        microphone?.startFetchingAudio()
    }
}

// MARK: EZMicrophoneDelegate
extension FFTViewController: EZMicrophoneDelegate {

    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {

        // Calculate the FFT, will trigger EZAudioFFTDelegate
        fft?.computeFFTWithBuffer(buffer[0], withBufferSize: bufferSize)
        dispatch_async(dispatch_get_main_queue()) {
            self.audioPlotTime.updateBuffer(buffer[0], withBufferSize: bufferSize)
        }
    }
}

// MARK: EZAudioFFTDelegate
extension FFTViewController: EZAudioFFTDelegate {

    func fft(fft: EZAudioFFT!, updatedWithFFTData fftData: UnsafeMutablePointer<Float>, bufferSize: vDSP_Length) {

        let maxFrequency = fft.maxFrequency
        let noteName = EZAudioUtilities.noteNameStringForFrequency(maxFrequency, includeOctave: true)

        dispatch_async(dispatch_get_main_queue()) {

            self.freqLabel.text = "Highest Note: \(noteName)\nFrequency: \(maxFrequency)"
            self.audioPlotFreq.updateBuffer(fftData, withBufferSize: UInt32(bufferSize))
        }
    }
}

