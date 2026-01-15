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
        
        let windowDuration: Double = 10
        
        var selectionStart: Double = 0.408
        
        var playhead: Double = 0.408
        
        var isPlaying: Bool = false
        
        init(totalLength: Double, keyTimes: [Double], timelineLengthRatio: Double?) {
            self.totalLength = totalLength
            self.timelineLengthRatio = timelineLengthRatio
            
            self.keyTimes = keyTimes
                .map { $0 > 1 ? $0 / 100 : $0 }
                .map { min(1, max(0, $0)) }
                .sorted()
            
            self.playhead = self.selectionStart
        }
        
        var windowRatio: Double {
            windowDuration / max(0.001, totalLength)
        }
        
        var maxSelectionStart: Double {
            max(0, 1 - windowRatio)
        }
        
        var selectionRange: ClosedRange<Double> {
            let start = min(max(0, selectionStart), maxSelectionStart)
            let end = min(1, start + windowRatio)
            return start...end
        }
    }
    
    enum Action: Equatable {
        case keyTimeTapped(Double)
        case scrubbedTo(Double)
        case playPauseTapped
        case resetTapped
        case tick
        case stopPlayback
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
                state.playhead = state.selectionRange.lowerBound
                state.isPlaying = false
                return .cancel(id: CancelID.timer)
                
            case .tick:
                guard state.isPlaying else { return .none }
                
                let dt = 0.033
                let dp = dt / max(0.001, state.totalLength)
                
                state.playhead = min(state.playhead + dp, state.selectionRange.upperBound)
                
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
