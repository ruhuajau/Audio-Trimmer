//
//  SettingsFeature.swift
//  Audio-Trimmer
//
//  Created by Ruby Jau on 2026/1/12.
//

import ComposableArchitecture

@Reducer
struct SettingsFeature {
  @ObservableState
  struct State: Equatable {
    var totalTrackLength: Double = 60 // seconds
    // 0~1 代表百分比
    var keyTimes: [Double] = [0.08, 0.20, 0.33, 0.41, 0.62, 0.78, 0.90]
    // optional: timeline 可視長度佔總長比例
    var timelineLengthRatio: Double? = 1.0
  }

  enum Action: Equatable {
    case totalLengthChanged(Double)
    case timelineLengthRatioChanged(String) 
    case setDefaultKeyTimesTapped
    case startTapped
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .totalLengthChanged(v):
        state.totalTrackLength = max(5, min(600, v))
        return .none

      case let .timelineLengthRatioChanged(text):
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
          state.timelineLengthRatio = nil
        } else if let v = Double(trimmed) {
          state.timelineLengthRatio = max(0.1, min(1.0, v))
        }
        return .none

      case .setDefaultKeyTimesTapped:
        state.keyTimes = [0.08, 0.20, 0.33, 0.41, 0.62, 0.78, 0.90]
        return .none

      case .startTapped:
        return .none
      }
    }
  }
}
