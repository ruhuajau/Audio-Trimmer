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
    var keyTimesText: String = "8,20,33,41"
    var keyTimes: [Double] = []
    var timelineLengthRatio: Double? = 1.0
  }

  enum Action: Equatable {
    case totalLengthChanged(Double)
    case keyTimesTextChanged(String)
    case timelineLengthRatioChanged(String)
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
          let ratio = v / 100.0
          state.timelineLengthRatio = max(0.1, min(1.0, ratio))
        }
        return .none

      case .startTapped:
        return .none
          
      case let .keyTimesTextChanged(text):
        state.keyTimesText = text

        let values = text
          .split(separator: ",")
          .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
          .map { min(max($0 / 100.0, 0), 1) }
          .sorted()

        if !values.isEmpty {
          state.keyTimes = values
        }
        return .none

      }
    }
  }
}
