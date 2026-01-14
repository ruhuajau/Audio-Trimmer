//
//  SettingsView.swift
//  Audio-Trimmer
//
//  Created by Ruby Jau on 2026/1/12.
//

import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>
    @State private var timelineRatioText: String = ""
    @State private var keyTimesText: String = ""
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case timelineRatio
        case keyTimes
    }
    
    var body: some View {
        WithPerceptionTracking {
            Form {
                Section("Track") {
                    Stepper(
                        value: Binding(
                            get: { store.totalTrackLength },
                            set: { store.send(.totalLengthChanged($0)) }
                        ),
                        in: 5...600,
                        step: 5
                    ) {
                        Text("Total length: \(Int(store.totalTrackLength))s")
                    }
                }
                
                Section("KeyTimes (percentages)") {
                    TextField("", text: $keyTimesText)
                        .keyboardType(.numbersAndPunctuation)
                        .focused($focusedField, equals: .keyTimes)
                        .onChange(of: keyTimesText) { _, v in
                            store.send(.keyTimesTextChanged(v))
                        }
                    
                    Text("Enter comma-separated percentages (0–100), e.g. 8,20,33,41")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section("Timeline length ratio (percentages)") {
                    TextField("", text: $timelineRatioText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .timelineRatio)
                        .onChange(of: timelineRatioText) { _, newValue in
                            store.send(.timelineLengthRatioChanged(newValue))
                        }
                    
                    Text("Enter percentage (0–100), e.g. 100 (no zoom), 50 (zoom in)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button {
                        store.send(.startTapped)
                    } label: {
                        Text("Open Audio Trimmer")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear {
                if let v = store.timelineLengthRatio {
                    timelineRatioText = String(Int((v * 100).rounded()))
                } else {
                    timelineRatioText = ""
                }
                keyTimesText = store.keyTimesText
            }
        }
    }
}
