//
//  PlayFileViewController.swift
//  EZAudio_Swift2_Example
//
//  Created by Kevin Chan on 2016/6/8.
//  Copyright © 2016年 Kevinjay Chan. All rights reserved.
//

import UIKit

class PlayFileViewController: UIViewController {

    // MARK: Properties
    // The CoreGraphics based audio plot
    @IBOutlet weak var audioPlot: EZAudioPlotGL!

    // A label to display the current file path with the waveform shown
    @IBOutlet weak var filePathLabel: UILabel!

    // A slider to indicate the current frame position in the audio file
    @IBOutlet weak var positionSlider: UISlider!

    // A slider to indicate the rolling history length of the audio plot.
    @IBOutlet weak var rollingHistorySlider: UISlider!

    // A slider to indicate the volume on the audio player
    @IBOutlet weak var volumeSlider: UISlider!

    // An EZAudioFile that will be used to load the audio file at the file path specified
    var audioFile: EZAudioFile?

    // An EZAudioPlayer that will be used for playback
    var player: EZAudioPlayer?

    // Here's the default audio file included with the example
    let kAudioFileDefault = NSBundle.mainBundle().pathForResource("simple-drum-beat", ofType: "wav")

    // MARK: Dealloc
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Status Bar Style
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    // MARK: Setup
    override func viewDidLoad() {

        // Setup the AVAudioSession. EZMicrophone will not work properly on iOS
        // if you don't do this!
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }

        // Customizing the audio plot's look
        audioPlot.backgroundColor = UIColor(colorLiteralRed: 0.816, green: 0.349, blue: 0.255, alpha: 1)
        audioPlot.color = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        audioPlot.plotType = .Buffer
        audioPlot.shouldFill = true
        audioPlot.shouldMirror = true

        // Create the audio player
        player = EZAudioPlayer(delegate: self)
        player?.shouldLoop = true

        // Override the output to the speaker
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.Speaker)
        } catch {
            print(error)
        }

        // Customize UI components
        rollingHistorySlider.value = Float(audioPlot.rollingHistoryLength())

        // Listen for EZAudioPlayer notifications
        setupNotifications()

        // Try opening the sample file
        openFileWithFilePathURL(NSURL(fileURLWithPath: kAudioFileDefault!))
    }

    // MARK: Notifications
    func setupNotifications() {

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(audioPlayerDidChangeAudioFile), name: EZAudioPlayerDidChangeOutputDeviceNotification, object: player)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(audioPlayerDidChangeOutputDevice), name: EZAudioPlayerDidChangeOutputDeviceNotification, object: player)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(audioPlayerDidChangePlayState), name: EZAudioPlayerDidChangeOutputDeviceNotification, object: player)
    }

    func audioPlayerDidChangeAudioFile(notification: NSNotification) {

        let player = notification.object as! EZAudioPlayer
        print("Player changed audio file: \(player.audioFile)")
    }

    func audioPlayerDidChangeOutputDevice(notification: NSNotification) {

        let player = notification.object as! EZAudioPlayer
        print("Player changed audio file: \(player.audioFile)")
    }

    func audioPlayerDidChangePlayState(notification: NSNotification) {

        let player = notification.object as! EZAudioPlayer
        print("Player changed audio file: \(player.audioFile)")
    }

    // MARK: Actions
    func openFileWithFilePathURL(filePathURL: NSURL) {

        // Create the EZAudioPlayer
        audioFile = EZAudioFile(URL: filePathURL)

        // Update the UI
        guard let audioFile = audioFile, player = player else {
            return
        }

        filePathLabel.text = filePathURL.lastPathComponent
        positionSlider.maximumValue = Float(audioFile.totalFrames)
        volumeSlider.value = player.volume

        // Plot the whole waveform
        audioPlot.plotType = .Buffer
        audioPlot.shouldFill = true
        audioPlot.shouldMirror = true

        guard let waveFromData = audioFile.getWaveformData() else {
            return
        }

        audioPlot.updateBuffer(waveFromData.buffers[0], withBufferSize: waveFromData.bufferSize)

        // Play the audio file
        player.audioFile = audioFile
    }

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

    // Changes the length of the rolling history of the audio plot.
    @IBAction func changeRollingHistoryLength(sender: UISlider) {

        let value = sender.value
        audioPlot.setRollingHistoryLength(Int32(value))
    }

    // Changes the volume of the audio player.
    @IBAction func changeVolume(sender: UISlider) {

        let value = sender.value
        player?.volume = value
    }

    // Begins playback if a file is loaded. Pauses if the file is already playing.
    @IBAction func play(sender: UIButton) {

        if player?.isPlaying == true {

            player?.pause()
        } else {
            if audioPlot.shouldMirror && (audioPlot.plotType == .Buffer) {

                audioPlot.shouldMirror = false
                audioPlot.shouldFill = false
            }

            player?.play()
        }
    }

    // Seeks to a specific frame in the audio file.
    @IBAction func seekToFrame(sender: UISlider) {

        player?.seekToFrame(Int64(sender.value))
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

}

// MARK: EZAudioPlayerDelegate
extension PlayFileViewController: EZAudioPlayerDelegate {

    func audioPlayer(audioPlayer: EZAudioPlayer!, playedAudio buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32, inAudioFile audioFile: EZAudioFile!) {

        dispatch_async(dispatch_get_main_queue()) { 

            self.audioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
        }
    }

    func audioPlayer(audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, inAudioFile audioFile: EZAudioFile!) {

        dispatch_async(dispatch_get_main_queue()) { 

            if !self.positionSlider.touchInside {

                self.positionSlider.value = Float(framePosition)
            }
        }
    }
}
