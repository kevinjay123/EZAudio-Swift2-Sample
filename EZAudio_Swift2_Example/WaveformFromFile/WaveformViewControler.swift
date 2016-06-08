//
//  WaveformViewController.swift
//  WaveformFromFile
//
//  Created by Kevin Chan on 2016/6/6.
//  Copyright © 2016年 Kevinjay Chan. All rights reserved.
//

import UIKit

class WaveformViewController: UIViewController {

    // MARK: Properties
    // The CoreGraphics based audio plot
    @IBOutlet weak var audioPlot: EZAudioPlot!

    // The EZAudioFile representing of the currently selected audio file
    var audioFile: EZAudioFile?

    // Here's the default audio file included with the example
    let kAudioFileDefault = NSBundle.mainBundle().pathForResource("simple-drum-beat", ofType: "wav")

    // MARK: Status Bar Style
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // MARK: Customize the Audio Plot
    override func viewDidLoad() {
        super.viewDidLoad()

        // Customizing the audio plot's look
        // Background color
        audioPlot.backgroundColor = UIColor(colorLiteralRed: 0.169, green: 0.643, blue: 0.675, alpha: 1)

        // Waveform color
        audioPlot.color = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        // Plot type
        audioPlot.plotType = .Buffer

        // Fill
        audioPlot.shouldFill = true

        // Mirror
        audioPlot.shouldMirror = true

        // No need to optimze for realtime
        audioPlot.shouldOptimizeForRealtimePlot = false

        // Customize the layer with a shadow for fun
        audioPlot.waveformLayer.shadowOffset = CGSizeMake(0.0, 1.0)
        audioPlot.waveformLayer.shadowRadius = 0.0
        audioPlot.waveformLayer.shadowColor = UIColor(colorLiteralRed: 0.069, green: 0.543, blue: 0.575, alpha: 1.0).CGColor
        audioPlot.waveformLayer.shadowOpacity = 1.0

        // Load in the sample file
        openFileWithFilePathURL(NSURL(fileURLWithPath: kAudioFileDefault!))
    }

    // MARK: Action Extensions
    func openFileWithFilePathURL(filePathURL: NSURL) {

        audioFile = EZAudioFile(URL: filePathURL)

        // Plot the whole waveform
        audioPlot.plotType = .Buffer
        audioPlot.shouldFill = true
        audioPlot.shouldMirror = true

        // Get the audio data from the audio file
        guard let waveFromData = audioFile?.getWaveformData() else {
            return
        }

        audioPlot.updateBuffer(waveFromData.buffers[0], withBufferSize: waveFromData.bufferSize)
    }
}

