//
//  TrimmerFeature.swift
//  Audio-Trimmer
//
//  Created by Ruby Jau on 2026/1/12.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TrimmerFeature {

  @ObservableState
  struct State: Equatable {
    var totalLength: Double // seconds
    var keyTimes: [Double]  // 0~1
    var timelineLengthRatio: Double?

    // selection：用百分比表示（0~1）
    var selectionStart: Double = 0.408
    var selectionEnd: Double = 0.491

    // 目前播放位置：也是百分比（0~1）
    var playhead: Double = 0.408

    var isPlaying: Bool = false

    init(totalLength: Double, keyTimes: [Double], timelineLengthRatio: Double?) {
      self.totalLength = totalLength
      self.keyTimes = keyTimes.sorted()
      self.timelineLengthRatio = timelineLengthRatio
    }

    var selectionRange: ClosedRange<Double> { selectionStart...selectionEnd }
  }

  enum Action: Equatable {
    case keyTimeTapped(Double)       // 0~1
    case playPauseTapped
    case resetTapped
    case tick                         // timer
    case selectionDragged(start: Double, end: Double)
    case stopPlayback                 // internal
  }

  enum CancelID { case timer }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {

      case let .keyTimeTapped(p):
        // 點 KeyTime：讓 selectionStart 跳到該點，並保持固定視窗長度
        let window = max(0.05, state.selectionEnd - state.selectionStart) // 至少 5%
        let newStart = clamp01(p)
        let newEnd = clamp01(newStart + window)

        state.selectionStart = newStart
        state.selectionEnd = max(newEnd, clamp01(newStart + 0.02))
        state.playhead = state.selectionStart
        state.isPlaying = false
        return .cancel(id: CancelID.timer)

      case .playPauseTapped:
        state.isPlaying.toggle()
        if state.isPlaying {
          // 如果 playhead 不在 selection 範圍內，重置到 start
          if state.playhead < state.selectionStart || state.playhead > state.selectionEnd {
            state.playhead = state.selectionStart
          }
          return .run { send in
            while true {
              try await Task.sleep(nanoseconds: 33_000_000) // ~30fps
              await send(.tick)
            }
          }
          .cancellable(id: CancelID.timer, cancelInFlight: true)
        } else {
          return .cancel(id: CancelID.timer)
        }

      case .resetTapped:
        state.playhead = state.selectionStart
        state.isPlaying = false
        return .cancel(id: CancelID.timer)

      case .tick:
        guard state.isPlaying else { return .none }
        let dt = 0.033
        let dp = dt / max(0.001, state.totalLength)
        state.playhead += dp

        if state.playhead >= state.selectionEnd {
          state.playhead = state.selectionStart
          state.isPlaying = false
          return .cancel(id: CancelID.timer)
        }
        return .none

      case let .selectionDragged(start, end):
        let s = clamp01(min(start, end))
        let e = clamp01(max(start, end))
        state.selectionStart = min(s, e - 0.01)
        state.selectionEnd = max(e, state.selectionStart + 0.01)
        // 拖 selection 時把 playhead clamp 進去
        state.playhead = min(max(state.playhead, state.selectionStart), state.selectionEnd)
        return .none

      case .stopPlayback:
        state.isPlaying = false
        return .cancel(id: CancelID.timer)
      }
    }
  }
}

// MARK: - Helpers
private func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }
