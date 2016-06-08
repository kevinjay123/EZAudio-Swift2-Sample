//
//  SegueIdentifier.swift
//  EZAudio_Swift2_Example
//
//  Created by Kevin Chan on 2016/6/7.
//  Copyright © 2016年 Kevinjay Chan. All rights reserved.
//

import UIKit

protocol SegueIdentifierHandler {
    associatedtype SegueIdentifier: RawRepresentable
}

extension SegueIdentifierHandler where Self: UIViewController, SegueIdentifier.RawValue == String {

    func performSegueWithIdentifier(identifier: SegueIdentifier, sender: AnyObject?) {
        performSegueWithIdentifier(identifier.rawValue, sender: sender)
    }

    func segueIdentifierForSegue(segue: UIStoryboardSegue) -> SegueIdentifier {

        guard let identifier = segue.identifier, segueIdentifier = SegueIdentifier(rawValue: identifier) else {
            fatalError("segue error")
        }

        return segueIdentifier
    }
}