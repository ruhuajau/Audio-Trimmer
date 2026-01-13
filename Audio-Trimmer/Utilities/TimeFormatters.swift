//
//  TimeFormatters.swift
//  Audio-Trimmer
//
//  Created by Ruby Jau on 2026/1/12.
//

import Foundation

enum TimeFormatters {
  static func mmss(_ seconds: Double) -> String {
    let s = max(0, Int(seconds.rounded(.down)))
    let m = s / 60
    let r = s % 60
    return String(format: "%d:%02d", m, r)
  }
}
