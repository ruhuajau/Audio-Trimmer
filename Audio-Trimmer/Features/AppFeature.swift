//
//  AppFeature.swift
//  Audio-Trimmer
//
//  Created by Ruby Jau on 2026/1/12.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var path = StackState<Route.State>()
    var settings = SettingsFeature.State()
  }

  enum Action {
    case path(StackAction<Route.State, Route.Action>)
    case settings(SettingsFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.settings, action: \.settings) {
      SettingsFeature()
    }

    Reduce { state, action in
      switch action {
      case .settings(.startTapped):
        // 將 Settings 的設定值帶到 Trimmer
        let s = state.settings
        state.path.append(
          .trimmer(
            TrimmerFeature.State(
              totalLength: s.totalTrackLength,
              keyTimes: s.keyTimes,
              timelineLengthRatio: s.timelineLengthRatio
            )
          )
        )
        return .none

      case .path, .settings:
        return .none
      }
    }
    .forEach(\.path, action: \.path) {
      Route()
    }
  }
}

@Reducer
struct Route {
  enum State: Equatable {
    case trimmer(TrimmerFeature.State)
  }

  enum Action {
    case trimmer(TrimmerFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: /State.trimmer, action: /Action.trimmer) {
      TrimmerFeature()
    }
  }
}

// MARK: - Root View
struct AppView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    NavigationStackStore(
      store.scope(state: \.path, action: \.path)
    ) {
      SettingsView(store: store.scope(state: \.settings, action: \.settings))
    } destination: { state in
      switch state {
      case .trimmer:
        CaseLet(
          /Route.State.trimmer,
          action: Route.Action.trimmer,
          then: TrimmerView.init(store:)
        )
      }
    }
  }
}
