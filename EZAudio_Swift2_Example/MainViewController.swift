//
//  MainViewController.swift
//  EZAudio_Swift2_Example
//
//  Created by Kevin Chan on 2016/6/7.
//  Copyright © 2016年 Kevinjay Chan. All rights reserved.
//

import UIKit

class MainViewController: UICollectionViewController {

    var numberOfRow = 3
    var numberOfColumn = 2
    let appItem = [
        
        GridMenuItem(imageName: "CoreGraphicsWaveform", name: "CoreGraphicsWaveform"),
        GridMenuItem(imageName: "OpenGLWaveform", name: "OpenGLWaveform"),
        GridMenuItem(imageName: "PlayFile", name: "PlayFile"),
        GridMenuItem(imageName: "RecordFile", name: "RecordFile"),
        GridMenuItem(imageName: "WaveformFromFile", name: "WaveformFromFile"),
        GridMenuItem(imageName: "FFT", name: "FFT"),
        GridMenuItem(imageName: "PassThrough", name: "PassThrough"),
    ]

    override func viewDidLoad() {

        super.viewDidLoad()

        let imageView = UIImageView.init(image: UIImage.init(named: "blurred_background"))
        collectionView?.backgroundView = imageView

        navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.barTintColor = UIColor.clearColor()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationController?.navigationBar.translucent = true
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {

        return .LightContent
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        switch traitCollection.verticalSizeClass {
        case .Compact:
            layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        case .Regular, .Unspecified:
            layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // calcluate cell size
        guard let collectionView = collectionView, layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let width = collectionView.bounds.width - (layout.sectionInset.left + layout.sectionInset.right)
        let height = collectionView.bounds.height - navigationController!.navigationBar.bounds.height - UIApplication.sharedApplication().statusBarFrame.height - (layout.sectionInset.top + layout.sectionInset.bottom)

        let size = CGSize(width: width / CGFloat(numberOfColumn), height: height / CGFloat(numberOfRow))

        if layout.itemSize != size {
            dispatch_async(dispatch_get_main_queue(), { 
                layout.itemSize = size
                layout.invalidateLayout()
            });
        }
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appItem.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AppCell", forIndexPath: indexPath) as! AppCell
        let item = appItem[indexPath.item]

        cell.appImageView.image = item.offImage
        cell.appLabel.text = item.name

        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let item = appItem[indexPath.item]

        switch item.name {
        case "FFT":
            performSegueWithIdentifier(.FFTSegue, sender: nil)
        case "WaveformFromFile":
            performSegueWithIdentifier(.WaveformFromFileSegue, sender: nil)
        case "PassThrough":
            performSegueWithIdentifier(.PassThroughSegue, sender: nil)
        case "CoreGraphicsWaveform":
            performSegueWithIdentifier(.CoreGraphicsWaveformSegue, sender: nil)
        case "OpenGLWaveform":
            performSegueWithIdentifier(.OpenGLWaveformSegue, sender: nil)
        case "PlayFile":
            performSegueWithIdentifier(.PlayFileSegue, sender: nil)
        case "RecordFile":
            performSegueWithIdentifier(.RecordFileSegue, sender: nil)

        default:
            break
        }
    }

}

extension MainViewController: SegueIdentifierHandler {

    enum SegueIdentifier: String {
        case FFTSegue = "FFTSegue"
        case WaveformFromFileSegue = "WaveformFromFileSegue"
        case PassThroughSegue = "PassThroughSegue"
        case CoreGraphicsWaveformSegue = "CoreGraphicsWaveformSegue"
        case OpenGLWaveformSegue = "OpenGLWaveformSegue"
        case PlayFileSegue = "PlayFileSegue"
        case RecordFileSegue = "RecordFileSegue"
    }
}
