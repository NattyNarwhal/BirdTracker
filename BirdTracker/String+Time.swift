//
//  String+Time.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-09-07.
//

import Foundation

extension String {
    init(timeInterval: TimeInterval) {
        if timeInterval == 0 || timeInterval.isNaN {
            self = "00:00"
            return
        }

        let ti = Int(timeInterval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)

        if (hours > 0) {
            self = String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds);
        }
        else {
            self = String(format: "%0.2d:%0.2d", minutes, seconds);
        }
    }
}
