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
        
        // 固定 10 秒視窗
        let windowDuration: Double = 10
        
        // selection 起點（0~1）
        var selectionStart: Double = 0.408
        
        // current playhead（0~1）
        // ✅ scrub / keyTime 時會被設回 selectionStart
        // ✅ 播放時會在視窗內前進
        var playhead: Double = 0.408
        
        var isPlaying: Bool = false
        
        init(totalLength: Double, keyTimes: [Double], timelineLengthRatio: Double?) {
            self.totalLength = totalLength
            self.timelineLengthRatio = timelineLengthRatio
            
            self.keyTimes = keyTimes
                .map { $0 > 1 ? $0 / 100 : $0 }   // ✅ 支援 40 或 0.4 兩種輸入
                .map { min(1, max(0, $0)) }
                .sorted()
            
            self.playhead = self.selectionStart
        }
        
        // 視窗比例（0~1）
        var windowRatio: Double {
            windowDuration / max(0.001, totalLength)
        }
        
        // selection 起點要能容納完整 10 秒，不可超出尾巴
        var maxSelectionStart: Double {
            max(0, 1 - windowRatio)
        }
        
        // derived selection range（固定 10 秒）
        var selectionRange: ClosedRange<Double> {
            let start = min(max(0, selectionStart), maxSelectionStart)
            let end = min(1, start + windowRatio)
            return start...end
        }
    }
    
    enum Action: Equatable {
        case keyTimeTapped(Double)       // 0~1
        case scrubbedTo(Double)          // 0~1
        case playPauseTapped
        case resetTapped
        case tick                        // timer
        case stopPlayback                // internal
    }
    
    enum CancelID { case timer }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case let .keyTimeTapped(p):
              return .send(.scrubbedTo(p))

            case let .scrubbedTo(t):
              let start = clamp01(t)
              let maxStart = max(0, 1 - state.windowDuration / state.totalLength)
              state.selectionStart = min(start, maxStart)

              state.playhead = state.selectionStart
              state.isPlaying = false
              return .cancel(id: CancelID.timer)

            case .playPauseTapped:
                state.isPlaying.toggle()
                
                if state.isPlaying {
                    // 開始播放時，確保 playhead 在視窗內；不在就拉回起點
                    if state.playhead < state.selectionRange.lowerBound ||
                        state.playhead > state.selectionRange.upperBound {
                        state.playhead = state.selectionRange.lowerBound
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
                // ✅ reset：current 回到 selectionStart
                state.playhead = state.selectionRange.lowerBound
                state.isPlaying = false
                return .cancel(id: CancelID.timer)
                
            case .tick:
                guard state.isPlaying else { return .none }
                
                let dt = 0.033
                let dp = dt / max(0.001, state.totalLength)
                
                // ✅ 播放時只推進 playhead，不動 selectionStart（框框固定）
                state.playhead = min(state.playhead + dp, state.selectionRange.upperBound)
                
                // 播到尾端就停
                if state.playhead >= state.selectionRange.upperBound {
                    state.isPlaying = false
                    return .cancel(id: CancelID.timer)
                }
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
