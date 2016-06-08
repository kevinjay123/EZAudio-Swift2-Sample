//
//  AppCell.swift
//  EZAudio_Swift2_Example
//
//  Created by Kevin Chan on 2016/6/7.
//  Copyright © 2016年 Kevinjay Chan. All rights reserved.
//

import UIKit

class AppCell: UICollectionViewCell {

    @IBOutlet weak var appImageView: UIImageView!
    @IBOutlet weak var appLabel: UILabel!

    override func awakeFromNib() {

        appImageView.layer.cornerRadius = 5.0
        appImageView.layer.masksToBounds = true
    }
}
