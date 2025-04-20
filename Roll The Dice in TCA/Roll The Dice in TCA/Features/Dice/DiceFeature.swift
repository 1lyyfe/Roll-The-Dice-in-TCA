//
//  DiceFeature.swift
//  Roll The Dice in TCA
//
//  Created by Haider Ashfaq on 20/04/2025.
//
// DiceFeature.swift — Main TCA-powered dice roller feature

import SwiftUI
import ComposableArchitecture
#if os(iOS)
import UIKit
#endif

/// A reducer that manages the entire dice roller feature.
/// It handles dice rolls, animation state, roll history, and navigation to the history screen.
@Reducer
struct DiceFeature {
    
    /// Enum representing possible navigation destinations from DiceFeature.
    @Reducer(state: .equatable)
    enum Destination {
        case history(DiceHistoryFeature)
        
        enum Action: Equatable {
            case history(DiceHistoryFeature.Action)
        }
    }
    
    /// The state for the dice roller feature.
    /// - currentRoll: The most recent dice roll.
    /// - isRolling: Indicates whether the dice is currently rolling.
    /// - rollHistory: A list of all previous rolls.
    /// - rollAnimationAngle: Drives rotation-based animation.
    /// - destination: Optional destination for navigation (e.g. history screen).
    @ObservableState
    struct State: Equatable {
        var currentRoll: Int? = nil
        var isRolling: Bool = false
        var rollHistory: [Int] = []
        var rollAnimationAngle: Double = 0
        
        @Presents var destination: Destination.State?
    }
    
    /// Actions that represent all user interactions, internal effects, and navigation.
    enum Action: Equatable {
        case view(ViewAction)
        case `internal`(InternalAction)
        case destination(PresentationAction<Destination.Action>)
        
        enum ViewAction: Equatable {
            case rollButtonTapped
            case undoLastRoll
            case resetHistory
            case viewFullHistoryTapped
        }
        
        enum InternalAction: Equatable {
            case rollCompleted(Int)
            case startAnimation
        }
    }
    
    /// The reducer logic for handling all DiceFeature actions, including async roll simulation,
    /// updating state, and navigation.
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.rollButtonTapped):
#if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
                state.isRolling = true
                return .merge(
                    .send(.internal(.startAnimation)),
                    .run { send in
                        try await Task.sleep(nanoseconds: 500_000_000)
                        let result = Int.random(in: 1...6)
                        await send(.internal(.rollCompleted(result)))
                    }
                )
                
            case let .internal(.rollCompleted(result)):
                state.isRolling = false
                state.currentRoll = result
                state.rollHistory.insert(result, at: 0)
                return .none
                
            case .view(.undoLastRoll):
                if !state.rollHistory.isEmpty {
                    state.rollHistory.removeFirst()
                    state.currentRoll = state.rollHistory.first
                }
                return .none
                
            case .view(.resetHistory):
                state.rollHistory = []
                state.currentRoll = nil
                return .none
                
            case .internal(.startAnimation):
                state.rollAnimationAngle += 360
                return .none
                
            case .view(.viewFullHistoryTapped):
                state.destination = .history(DiceHistoryFeature.State(rolls: state.rollHistory))
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.destination, action: \.destination) {
            Scope(state: \.history, action: \.history) {
                DiceHistoryFeature()
            }
        }
    }
}

/// A SwiftUI view powered by TCA that displays the entire dice roller interface.
///
/// This view is responsible for:
/// - Showing the current dice value inside an animated box.
/// - Displaying animated scale, shake, and rotation effects when rolling.
/// - Handling the 'Roll Dice' button and dispatching the corresponding TCA action.
/// - Listing the roll history below the dice box.
/// - Providing 'Undo' and 'Reset' buttons for modifying roll history.
/// - Presenting a 'View Full History' button that navigates to a child TCA feature
///   using state-driven navigation powered by `@Presents` and `.navigationDestination`.
struct DiceView: View {
    @Bindable var store: StoreOf<DiceFeature>
    
    var body: some View {
        VStack(spacing: 24) {
            header
            diceBox
            rollButton
            if !store.rollHistory.isEmpty {
                historySection
            }
            Spacer()
        }
        .padding()
        .overlay(
            store.isRolling ? ProgressView().scaleEffect(1.2).padding(.top, 10) : nil,
            alignment: .bottom
        )
        .navigationDestination(
            
            item: $store.scope(state: \.destination?.history, action: \.destination.history),
            destination: DiceHistoryView.init(store:)
        )
    }
}

/// A SwiftUI preview for the DiceView, initialized with test state and reducer.

private extension DiceView {
    /// Displays the main title header for the dice roller.
    var header: some View {
        Text("🎲 TCA Dice Roller")
            .font(.largeTitle)
    }
    
    /// A stylized and animated container for displaying the current dice roll.
    /// When rolling, the dice animates with scale, rotation, and offset effects.
    /// Displays a placeholder icon when no roll has been made yet.
    var diceBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 120, height: 120)
                .shadow(color: .blue.opacity(0.1), radius: 6, x: 0, y: 4)
            
            if let roll = store.currentRoll {
                Text("\(roll)")
                    .font(.system(size: 56, weight: .bold))
                    .scaleEffect(store.isRolling ? 1.3 : 1.0)
                    .rotationEffect(.degrees(store.rollAnimationAngle))
                    .offset(
                        x: store.isRolling ? CGFloat.random(in: -4...4) : 0,
                        y: store.isRolling ? CGFloat.random(in: -4...4) : 0
                    )
                    .animation(.easeInOut(duration: 0.4), value: store.rollAnimationAngle)
            } else {
                Image(systemName: "questionmark.square.dashed")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
            }
        }
    }
    
    /// The primary button used to trigger a new dice roll.
    /// Disables interaction while a roll is in progress.
    var rollButton: some View {
        Button {
            store.send(.view(.rollButtonTapped))
        } label: {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text(store.isRolling ? "Rolling..." : "Roll Dice")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(store.isRolling)
    }
    
    /// Displays a brief preview of recent dice roll history (up to 5 rolls).
    /// Includes undo and reset buttons, and a navigation trigger for full history view.
    var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2))
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History:")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ForEach(store.rollHistory.prefix(5), id: \.self) { roll in
                            Text("• \(roll)")
                                .font(.body)
                        }
                        
                        HStack {
                            Button("Undo") {
                                store.send(.view(.undoLastRoll))
                            }
                            .disabled(store.rollHistory.isEmpty)
                            
                            Button("Reset") {
                                store.send(.view(.resetHistory))
                            }
                            .foregroundColor(.red)
                        }
                        
                        Button("View Full History") {
                            store.send(.view(.viewFullHistoryTapped))
                        }
                        .padding(.top, 20)
                    })
        }
    }
}

/// A SwiftUI preview for the DiceView, initialized with test state and reducer.
#Preview {
    NavigationStack {
        DiceView(
            store: Store(initialState: DiceFeature.State()) {
                DiceFeature()
            }
        )
    }
}
