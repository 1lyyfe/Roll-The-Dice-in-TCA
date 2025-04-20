# 🎲 Build a Dice Roller App with TCA (The Composable Architecture)

<table align="center">
  <tr>
    <td align="center"><b>🎲 Preview</b></td>
  </tr>
  <tr>
    <td>
      <video src="https://github.com/user-attachments/assets/998d21c8-d510-48c6-adca-be600ed00b71" width="320" autoplay loop muted></video>
    </td>
  </tr>
</table>

Welcome! This is not just a project — it's a practical, educational introduction to **The Composable Architecture (TCA)**. If you've never used TCA before but you're an experienced iOS engineer, you're in the perfect place.


Welcome to this tutorial-style walkthrough on building a SwiftUI Dice Roller app using [The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture) by Point-Free.

If you're an experienced iOS dev new to TCA, this project is designed just for you. We'll teach you how to use TCA's latest v1.4+ syntax, navigation patterns, and reducer modularity through a fun, animated dice app.

---

## 📘 What Is TCA?

TCA is a **library for building applications in a consistent and understandable way**, with a strong emphasis on **modularity, composition, and testability**.

At its core, TCA breaks your app into:

- **State**: What data your feature needs
- **Action**: All the things that can happen (user or system)
- **Reducer**: The logic that updates your state based on an action
- **Store**: The glue that ties state, actions, and views together
- **Effect**: Side effects like async calls or delayed actions

### 💡 TCA Keywords
| Concept     | Role                                                              |
|-------------|-------------------------------------------------------------------|
| `@Reducer`  | Defines your feature's state, actions, and reducer logic         |
| `@ObservableState` | Makes state reactive, enabling SwiftUI to subscribe to changes |
| `Store`     | Holds your state, lets you send actions, and binds to your views |
| `Effect`    | Anything that happens "outside" the reducer — async, delays, etc.|

#### 🔍 What is `@ObservableState`?

This is TCA’s replacement for `@BindableState`, built on Swift’s `Observation` framework.

It does **two things**:

1. Automatically makes the `State` observable by SwiftUI views  
2. Enables binding with the `@Bindable` property wrapper on views

It’s required for:
- UI to reflect state changes
- Binding fields like toggles, sliders, and textfields cleanly

> Think of `@ObservableState` as a declaration that this state should participate in the SwiftUI observation system.



### 🧵 TCA vs MVVM or Vanilla SwiftUI
|                | MVVM                  | SwiftUI (Vanilla)      | TCA ✅                          |
|----------------|------------------------|--------------------------|---------------------------------|
| State Centralization | ❌ Scattered           | ❌ View-bound            | ✅ Global + testable            |
| Testability    | 🟡 Somewhat             | ❌ Limited               | ✅ Fully testable               |
| Effect Isolation | ❌ Often inline        | ❌ With hacks             | ✅ Scoped + separate            |
| Modularity     | ❌ Complex manually     | ❌ Manual                | ✅ Built-in                     |
| Navigation     | ❌ View-driven          | 🟡 Hard to manage         | ✅ State-driven with @Presents  |

TCA helps you **scale features and teams** with a consistent pattern across all modules.

---

## 🧠 Why TCA?
TCA brings **clarity, structure, and testability** to SwiftUI apps. It excels at managing complex state and interactions, especially as your app scales.

This tutorial introduces:
- Reducer-based architecture
- Effect handling
- State-driven navigation using `@Presents`
- Modern action routing (`view`, `internal`, `destination`)

---

## ✨ What You'll Build
A dice roller app that lets users:
- Tap to roll an animated dice 🎲
- See a rolling animation with haptic feedback
- Track roll history inline
- View full history via navigation

All of this is powered entirely by TCA.

---

## 📁 Folder Structure
```
- DiceFeature.swift      // Main feature: logic, view, reducer
- DiceHistoryFeature.swift // Child feature: history screen
```

---

## 🧱 App Architecture
TCA is based on three core parts:

```swift
@Reducer struct DiceFeature { ... }

struct State { ... }

enum Action { ... }
```

We use `@Reducer` for defining state, actions, and effects in a single feature file.

---

## 🎬 Animating a Dice Roll
The `rollButtonTapped` action triggers:

```swift
return .merge(
    .send(.internal(.startAnimation)),
    .run { send in
        try await Task.sleep(nanoseconds: 500_000_000)
        let result = Int.random(in: 1...6)
        await send(.internal(.rollCompleted(result)))
    }
)
```

| Effect Type         | Purpose                                     |
|---------------------|---------------------------------------------|
| `.send(...)`        | Immediately trigger an action               |
| `.run { ... }`      | Run async work, then dispatch               |
| `.merge(..., ...)`  | Run multiple effects in parallel            |

---

## 📦 Action Structure
We follow a clean structure for actions:

```swift
enum Action {
  case view(ViewAction)
  case internal(InternalAction)
  case destination(PresentationAction<Destination.Action>)

  enum ViewAction {
    case rollButtonTapped
    case undoLastRoll
    case resetHistory
    case viewFullHistoryTapped
  }

  enum InternalAction {
    case rollCompleted(Int)
    case startAnimation
  }
}
```

This separation makes it easier to reason about what's coming from the UI vs internal effects.

---

## 🧭 Navigation with @Presents

Navigation in TCA is fundamentally **state-driven**, not view-driven. This is a powerful concept that differs from how navigation typically works in SwiftUI or MVVM.

### 🚪 Vanilla SwiftUI Navigation
In SwiftUI, navigation is often tied directly to the view hierarchy:
```swift
NavigationLink(destination: DetailView(), isActive: $isDetailShown) { ... }
```

But this creates coupling between UI and navigation logic — and managing programmatic navigation across multiple layers becomes painful.

### 🧭 TCA Navigation Philosophy
TCA flips the model:
> "If the state says we should show a screen, we show it."

This means **navigation happens by updating the state** — and SwiftUI observes that change.

We use:
```swift
@Presents var destination: Destination.State?
```

This creates a navigation destination stored in state. When `destination` becomes non-nil, the navigation triggers automatically.

### 🔁 Parent-Child Reducers
Navigation usually means moving from one feature to another. In TCA:
- The **parent reducer** owns and presents the child
- The **child reducer** handles the logic for its own screen

The parent scopes into the child like this:
```swift
.ifLet(\.{destination}, action: \.destination) {
  Scope(state: \.history, action: \.history) {
    DiceHistoryFeature()
  }
}
```

This means:
- The child only exists **when that enum case is active**
- It receives only the state and actions scoped to it

### 🧩 Destination Enum Explained
This enum drives navigation cases:
```swift
@Reducer(state: .equatable)
enum Destination {
    case history(DiceHistoryFeature)

    enum Action: Equatable {
        case history(DiceHistoryFeature.Action)
    }
}
```

Each case represents a screen. When we set the parent state like this:
```swift
state.destination = .history(DiceHistoryFeature.State(rolls: state.rollHistory))
```

It triggers the child feature to appear.

### 🔗 Tying It to the View
Finally, we connect this to SwiftUI like so:
```swift
.navigationDestination(
  item: $store.scope(state: \.destination?.history, action: \.destination.history),
  destination: DiceHistoryView.init(store:)
)
```

This completes the loop:
1. **State becomes non-nil** → triggers child reducer
2. **View observes and presents destination**
3. **Scoped reducer ensures clean boundaries**
swift
@Presents var destination: Destination.State?

---

## 🛠 App Entry Point

To bring your TCA-powered app to life, we need to wire the `Store` into your root view.

Here’s what your app entry point should look like:

```swift
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
```

### 💡 Why do we need this?
TCA works through a central `Store` which holds:
- Your feature’s `State`
- A reducer that handles `Action`
- A place to emit `Effect`s

By injecting this store into the view hierarchy at the app’s root, everything is ready to:
- React to user interaction
- Update state predictably
- Trigger side effects like animations, async tasks, or navigation

Without this store injection, your TCA-powered views won’t function — this is where TCA “starts up.”

---

## 🎨 View Highlights
The main UI is clean and fun:
- Bouncy roll animation with `scale`, `rotation`, and `offset`
- Card-style preview of the last 5 rolls
- Tidy modular layout with `diceBox`, `rollButton`, and `historySection`

---

## 🧪 Coming Soon: Tests
We'll add unit tests for the reducer, navigation, and effects.

---

## 📘 Want to Learn More?
- Check out [Point-Free’s TCA Docs](https://pointfreeco.github.io/swift-composable-architecture/)

---

## 🚀 Ready to Roll?
Clone the repo, run the app, and learn TCA by building something delightful!

```bash
git clone https://github.com/1lyyfe/Roll-The-Dice-in-TCA.git
```

---

## 💡 Looking for More Ideas?

If you're inspired to build more, check out my best-selling guide:

👉 [100 iOS App Ideas with MVP Scopes](https://heeydurh.gumroad.com/l/hwfkko) — perfect for indie devs, TCA learners, and SwiftUI side projects!

---

## 🙌 Author
Built by Haider Ashfaq - [@1lyyfe](https://github.com/1lyyfe) as part of **My Dev Diaries** — documenting, sharing, and shipping indie projects in public.

