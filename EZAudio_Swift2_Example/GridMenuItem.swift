//
//  GridMenuItem.swift
//  EZAudio_Swift2_Example
//
//  Created by Kevin Chan on 2016/6/7.
//  Copyright © 2016年 Kevinjay Chan. All rights reserved.
//

import UIKit

struct GridMenuItem {
    private var imageName: String
    var name: String

    init(imageName: String, name: String) {
        self.imageName = imageName
        self.name = name
    }

    var offImage: UIImage? {
        return UIImage(named: imageName)
    }
}