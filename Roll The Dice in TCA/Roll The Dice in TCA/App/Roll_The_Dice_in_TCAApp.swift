//
//  Roll_The_Dice_in_TCAApp.swift
//  Roll The Dice in TCA
//
//  Created by Haider Ashfaq on 20/04/2025.
//

import SwiftUI
import ComposableArchitecture

@main
struct Roll_The_Dice_in_TCAApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DiceView(
                    store: Store(
                        initialState: DiceFeature.State()
                    ) {
                        DiceFeature()
                    }
                )
            }
        }
    }
}
