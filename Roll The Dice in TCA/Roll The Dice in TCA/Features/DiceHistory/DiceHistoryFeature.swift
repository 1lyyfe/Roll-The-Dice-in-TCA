//
//  DiceHistoryFeature.swift
//  Roll The Dice in TCA
//
//  Created by Haider Ashfaq on 20/04/2025.
//

// DiceHistoryFeature.swift — TCA child feature for history screen

import SwiftUI
import ComposableArchitecture

/// A reducer that manages the state for the dice roll history screen.
/// This feature receives roll history from the parent (`DiceFeature`) and shows it in a list.
/// It currently does not support any user interaction or dynamic updates.
@Reducer
struct DiceHistoryFeature {
    /// The state for the history feature.
    /// - rolls: An array of previously rolled dice values.
    @ObservableState
    struct State: Equatable {
        var rolls: [Int]
    }
    
    enum Action: Equatable {}
    
    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

/// A view that displays a list of previously rolled dice results.
/// It shows them in reverse order (latest roll first) with index.
struct DiceHistoryView: View {
    let store: StoreOf<DiceHistoryFeature>
    
    var body: some View {
        List {
            Section(header: Text("Roll History")) {
                ForEach(store.rolls.indices, id: \.self) { index in
                    Text("Roll \(store.rolls.count - index): \(store.rolls[index])")
                }
            }
        }
        .navigationTitle("History")
    }
}

