//
//  RecordFileViewController.swift
//  EZAudio_Swift2_Example
//
//  Created by Kevin Chan on 2016/6/8.
//  Copyright © 2016年 Kevinjay Chan. All rights reserved.
//

import UIKit

class RecordFileViewController: UIViewController {

    // MARK: Properties
    // Use a OpenGL based plot to visualize the data coming in
    @IBOutlet weak var recordingAudioPlot: EZAudioPlotGL!

    // The second audio plot used on the top right to display the current playing audio
    @IBOutlet weak var playingAudioPlot: EZAudioPlot!

    // The label used to display the current time for recording/playback in the top
    // left
    @IBOutlet weak var currentTimeLabel: UILabel!

    // The label used to display the microphone's play state
    @IBOutlet weak var microphoneStateLabel: UILabel!

    // The label used to display the audio player play state
    @IBOutlet weak var playingStateLabel: UILabel!

    // The label used to display the recording play state
    @IBOutlet weak var recordingStateLabel: UILabel!

    // The switch used to toggle the microphone on/off
    @IBOutlet weak var microphoneSwitch: UISwitch!

    // The switch used to toggle the recording on/off
    @IBOutlet weak var recordSwitch: UISwitch!

    // The button the user taps to play the recorded audio file
    @IBOutlet weak var playButton: UIButton!

    // By default this will record a file to the application's documents directory
    // (within the application's sandbox)
    let kAudioFilePath = "test.m4a"

    // A flag indicating whether we are recording or not
    var isRecording: Bool?

    // The microphone component
    var microphone: EZMicrophone?

    // The audio player that will play the recorded file
    var player: EZAudioPlayer?

    // The recorder component
    var recorder: EZRecorder?

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
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }

        // Customizing the audio plot that'll show the current microphone input/recording
        recordingAudioPlot.backgroundColor = UIColor(colorLiteralRed: 0.984, green: 0.71, blue: 0.365, alpha: 1)
        recordingAudioPlot.color = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        recordingAudioPlot.plotType = .Rolling
        recordingAudioPlot.shouldFill = true
        recordingAudioPlot.shouldMirror = true

        // Customizing the audio plot that'll show the playback
        playingAudioPlot.backgroundColor = UIColor.clearColor()
        playingAudioPlot.plotType = .Rolling
        playingAudioPlot.shouldFill = true
        playingAudioPlot.shouldMirror = true
        playingAudioPlot.gain = 2.5

        // Create an instance of the microphone and tell it to use this view controller instance as the delegate
        microphone = EZMicrophone(microphoneDelegate: self)
        player = EZAudioPlayer(delegate: self)

        // Override the output to the speaker. Do this after creating the EZAudioPlayer
        // to make sure the EZAudioDevice does not reset this.
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.Speaker)
        } catch {
            print(error)
        }

        // Initialize UI components
        microphoneStateLabel.text = "Microphone On"
        recordingStateLabel.text = "Not Recording"
        playingStateLabel.text = "Not Playing"
        playButton.enabled = false

        // Setup notifications
        setupNotifications()

        // Log out where the file is being written to within the app's documents directory
        print("File written to application sandbox's documents directory:\n\(testFilePathURL())")

        // Start the microphone
        microphone?.startFetchingAudio()
    }

    // MARK: Notifications
    func setupNotifications() {

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(playerDidChangePlayState), name: EZAudioPlayerDidChangePlayStateNotification, object: player)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(playerDidReachEndOfFile), name: EZAudioPlayerDidReachEndOfFileNotification, object: player)
    }

    func playerDidChangePlayState(notification: NSNotification) {

        dispatch_async(dispatch_get_main_queue()) { 

            let player = notification.object as! EZAudioPlayer
            let isPlaying = player.isPlaying
            if isPlaying {

                self.recorder?.delegate = nil
            }

            self.playingStateLabel.text = isPlaying ? "Playing" : "Not Playing"
            self.playingAudioPlot.hidden = isPlaying
        }
    }

    func playerDidReachEndOfFile(notification: NSNotification) {

        dispatch_async(dispatch_get_main_queue()) {

            self.playingAudioPlot.clear()
        }
    }

    // MARK: Utility
    func applicationDocuments() -> NSArray {

        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    }

    func applicationDocumentsDirectory() -> String {

        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let basePath = (paths.count > 0) ? paths[0] : ""

        return basePath
    }

    func testFilePathURL() -> NSURL {

        return NSURL.fileURLWithPath("\(applicationDocumentsDirectory())/\(kAudioFilePath)")
    }

    // MARK: Actions
    @IBAction func playFile(sender: UIButton) {

        // Update microphone state
        microphone?.stopFetchingAudio()

        // Update recording state
        isRecording = false
        recordingStateLabel.text = "Not Recording"
        recordSwitch.on = false

        // Close the audio file
        if let recorder = recorder {

            recorder.closeAudioFile()
        }

        let audioFile = EZAudioFile(URL: testFilePathURL())
        player?.playAudioFile(audioFile)
    }

    @IBAction func toggleMicrophone(sender: UISwitch) {

        let isON = sender.on
        if !isON {

            microphone?.stopFetchingAudio()
        } else {

            microphone?.startFetchingAudio()
        }
    }
    
    @IBAction func toggleRecording(sender: UISwitch) {

        player?.pause()
        if sender.on == true {

            // Create the recorder
            recordingAudioPlot.clear()
            guard let microphone = microphone else {
                return
            }

            microphone.startFetchingAudio()
            recorder = EZRecorder(URL: testFilePathURL(), clientFormat: microphone.audioStreamBasicDescription(), fileType: .M4A, delegate: self)
            playButton.enabled = true
        }

        isRecording = sender.on
        recordingStateLabel.text = (isRecording == true) ? "Recording" : "Not Recording"
    }

}

// MARK: EZMicrophoneDelegate
extension RecordFileViewController: EZMicrophoneDelegate {

    func microphone(microphone: EZMicrophone!, changedPlayingState isPlaying: Bool) {

        microphoneStateLabel.text = (isPlaying == true) ? "Microphone On" : "Microphone Off"
        microphoneSwitch.on = isPlaying
    }

    // Note that any callback that provides streamed audio data (like streaming
    // microphone input) happens on a separate audio thread that should not be
    // blocked. When we feed audio data into any of the UI components we need to
    // explicity create a GCD block on the main thread to properly get the UI to
    // work.
    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {

        // Getting audio data as an array of float buffer arrays. What does that
        // mean? Because the audio is coming in as a stereo signal the data is split
        // into a left and right channel. So buffer[0] corresponds to the float* data
        // for the left channel while buffer[1] corresponds to the float* data for
        // the right channel.

        //
        // See the Thread Safety warning above, but in a nutshell these callbacks
        // happen on a separate audio thread. We wrap any UI updating in a GCD block
        // on the main thread to avoid blocking that audio flow.
        dispatch_async(dispatch_get_main_queue()) {

            // All the audio plot needs is the buffer data (float*) and the size.
            // Internally the audio plot will handle all the drawing related code,
            // history management, and freeing its own resources. Hence, one badass
            // line of code gets you a pretty plot :)
            self.recordingAudioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
        }
    }

    func microphone(microphone: EZMicrophone!, hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {

        // Getting audio data as a buffer list that can be directly fed into the
        // EZRecorder. This is happening on the audio thread - any UI updating needs
        // a GCD main queue block. This will keep appending data to the tail of the
        // audio file.
        if isRecording == true {

            recorder?.appendDataFromBufferList(bufferList, withBufferSize: bufferSize)
        }
    }
}

// MARK: EZRecorderDelegate
extension RecordFileViewController: EZRecorderDelegate {

    func recorderDidClose(recorder: EZRecorder!) {

        recorder.delegate = nil
    }

    func recorderUpdatedCurrentTime(recorder: EZRecorder!) {

        let formattedCurrentTime = recorder.formattedCurrentTime
        dispatch_async(dispatch_get_main_queue()) {

            self.currentTimeLabel.text = formattedCurrentTime
        }
    }
}

// MARK: EZAudioPlayerDelegate
extension RecordFileViewController: EZAudioPlayerDelegate {

    func audioPlayer(audioPlayer: EZAudioPlayer!, playedAudio buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32, inAudioFile audioFile: EZAudioFile!) {

        dispatch_async(dispatch_get_main_queue()) {

            self.playingAudioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
        }
    }

    func audioPlayer(audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, inAudioFile audioFile: EZAudioFile!) {

        dispatch_async(dispatch_get_main_queue()) {

            self.currentTimeLabel.text = audioPlayer.formattedCurrentTime
        }
    }
}
