# SwipeCardsKit

A lightweight, customizable SwiftUI library for creating Tinder-like swipeable card interfaces in your iOS and macOS applications.

https://github.com/user-attachments/assets/d7611af6-9351-439d-ae98-84f9e43b8e5b

https://github.com/user-attachments/assets/5ea8b372-04bd-43bf-9758-e85154ba5265

## Features

- 🔄 Smooth swipe animations
- 🎨 Fully customizable card appearance
- 📱 iOS 15.0+ and macOS 15.0+ support
- 🔌 Simple integration with SwiftUI
- 📊 Swipe direction tracking (left/right)
- 🔄 Card stack management with visual depth effect
- 🎭 Customizable animations and thresholds
- 📢 Comprehensive callback support for swipe actions

## Requirements

- iOS 15.0+
- macOS 15.0+
- Swift 6.0+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add SwipeCardsKit to your project using Swift Package Manager:

1. In Xcode, select **File** > **Add Packages...**
2. Enter the repository URL: `https://github.com/tobi404/SwipeCardsKit.git`
3. Select the version you want to use

Or add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/tobi404/SwipeCardsKit.git", from: "0.1.0")
]
```

## Quick Start

```swift
import SwiftUI
import SwipeCardsKit

struct ContentView: View {
    // Sample data
    @State private var cards = [
        Card(id: 1, title: "Card 1", color: .red),
        Card(id: 2, title: "Card 2", color: .blue),
        Card(id: 3, title: "Card 3", color: .green),
        Card(id: 4, title: "Card 4", color: .orange),
        Card(id: 5, title: "Card 5", color: .purple)
    ]
    @State private var selectedCard: Card?
    @State private var popTrigger: CardSwipeDirection?
    
    var body: some View {
        VStack {
            CardSwipeView(items: $cards, selectedItem: $selectedCard, popTrigger: $popTrigger) { card, progress, direction in
                // Card content
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(card.color)
                    
                    VStack {
                        Text(card.title)
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        // Show direction indicator based on swipe
                        Text(direction == .left ? "NOPE" : "LIKE")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(direction == .left ? .red : .green)
                            .cornerRadius(10)
                            .opacity(progress)
                    }
                }
                .frame(width: 300, height: 400)
                .shadow(radius: 5)
            }
            .onSwipeEnd { card, direction in
                print("Swiped \(direction) on card: \(card.title)")
            }
            .onNoMoreCardsLeft {
                print("No more cards left!, dismiss?")
            }
        }
    }
}

// Sample card model
struct Card: Identifiable {
    let id: Int
    let title: String
    let color: Color
}
```

## Core Components

### CardSwipeView

The main component that manages the card stack and swipe interactions.

```swift
public struct CardSwipeView<Item: Identifiable, Content: View>: View
```

#### Initialization

```swift
public init(
    items: Binding<[Item]>,
    selectedItem: Binding<Item?> = .constant(nil),
    popTrigger: Binding<CardSwipeDirection?> = .constant(nil),
    @ViewBuilder content: @escaping (Item, _ progress: CGFloat, _ direction: CardSwipeDirection) -> Content
)
```

- `items`: A binding to an array of items that conform to `Identifiable & Hashable`
- `selectedItem`: An optional binding to track the currently displayed item (defaults to nil)
- `popTrigger`: An optional binding to programmatically trigger a card swipe in a specific direction (defaults to nil)
- `content`: A view builder that creates the content for each card
  - `item`: The current item being displayed
  - `progress`: A value between 0 and 1 indicating how far the card has been swiped
  - `direction`: The current swipe direction (`.left`, `.right`, or `.idle`)

### CardSwipeDirection

An enum that represents the direction a card can be swiped:

```swift
public enum CardSwipeDirection {
    case left, right, idle
}
```

- `.left`: The card was swiped to the left
- `.right`: The card was swiped to the right
- `.idle`: The card is not being swiped or is at rest

This enum can also be used with the `popTrigger` binding to programmatically trigger a swipe in a specific direction.

## Customization Options

### Trigger Threshold

Set the minimum distance a card needs to be swiped before it's considered a complete swipe:

```swift
CardSwipeView(items: $cards, selectedItem: $selectedCard) { card, progress, direction in
    // Card content
}
.configure(threshold: 200, minimumDistance: 10, animateOnYAxes: Bool)
// Default threshold is 150, minimum distance is 20, animateOnYAxes is false (disabled)
```

To make the threshold scale with the deck, give it as a fraction of the deck's measured width. The deck re-measures itself on every layout, so the threshold follows window size changes:

```swift
CardSwipeView(items: $cards, selectedItem: $selectedCard) { card, progress, direction in
    // Card content
}
.configure(thresholdFraction: 0.4)
// Or: .configure(thresholdFraction: 0.4, minimumDistance: 10, animateOnYAxes: false)
```

Calling `configure(threshold:minimumDistance:animateOnYAxes:)` switches back to a fixed threshold.

### Swipe Callbacks

Register callbacks for swipe events:

```swift
CardSwipeView(items: $cards, selectedItem: $selectedCard) { card, progress, direction in
    // Card content
}
.onSwipeEnd { card, direction in
    // Handle swipe end
    switch direction {
    case .left:
        print("Swiped left on \(card.id)")
    case .right:
        print("Swiped right on \(card.id)")
    case .idle:
        print("Card returned to center")
    }
}
.onNoMoreCardsLeft {
    // Handle when all cards are swiped
    print("No more cards left!")
}
.onThresholdPassed {
    // Called when a card passes the swipe threshold
    print("Card passed threshold")
    // Add haptic feedback or other effects
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
}
```

## Advanced Usage

### Programmatic Card Swiping

You can programmatically trigger card swipes using the `popTrigger` binding:

```swift
struct ContentView: View {
    @State private var cards = [Card(id: 1), Card(id: 2), Card(id: 3)]
    @State private var selectedCard: Card?
    @State private var popTrigger: CardSwipeDirection?
    
    var body: some View {
        VStack {
            CardSwipeView(items: $cards, selectedItem: $selectedCard, popTrigger: $popTrigger) { card, progress, direction in
                // Card content
            }
            
            HStack {
                Button("Swipe Left") {
                    popTrigger = .left
                }
                
                Button("Swipe Right") {
                    popTrigger = .right
                }
            }
        }
    }
}
```

This is useful for implementing buttons that trigger swipes or for automating swipes based on certain conditions.

### Custom Card Appearance

You have full control over the appearance of your cards:

```swift
CardSwipeView(items: $profiles, selectedItem: $selectedProfile) { profile, progress, direction in
    VStack {
        Image(profile.imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 300)
            .clipped()
        
        VStack(alignment: .leading) {
            Text(profile.name)
                .font(.title)
                .bold()
            
            Text(profile.bio)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        
        // Show swipe indicators
        Text(direction == .left ? "NOPE" : "LIKE")
            .font(.title)
            .foregroundColor(.white)
            .padding(10)
            .background(direction == .left ? .red : .green)
            .cornerRadius(10)
            .rotationEffect(Angle(degrees: direction == .left ? -30 : 30))
            .opacity(progress)
            .position(x: direction == .left ? 75 : 275, y: 100)
    }
    .background(Color.white)
    .cornerRadius(10)
    .shadow(radius: 5)
}
```

### Card Stack Behavior

SwipeCardsKit automatically manages a stack of cards with a visually appealing depth effect. The top 4 cards are visible at any time, with the following properties:

- **Top card**: Fully interactive, can be swiped left or right
- **Second card**: Scales up and moves forward as the top card is swiped
- **Third card**: Becomes more visible as cards above it are swiped
- **Fourth card**: Fades in as cards are swiped

This creates a realistic card stack effect similar to popular dating apps.

**The cards stack is a reusable component that renders only four card views at a time. You can utilize as many items as you desire as a source of truth.**

### Tracking the Current Card

The `selectedItem` binding allows you to track which card is currently at the top of the stack:

```swift
struct ContentView: View {
    @State private var cards = [Card(id: 1, title: "Card 1"), Card(id: 2, title: "Card 2")]
    @State private var selectedCard: Card?
    
    var body: some View {
        VStack {
            CardSwipeView(items: $cards, selectedItem: $selectedCard) { card, progress, direction in
                // Card content
            }
            
            // Display information about the current card
            if let selectedCard {
                Text("Current card: \(selectedCard.title)")
                    .padding()
            }
        }
    }
}
```

This is useful for displaying additional information about the current card or for synchronizing other UI elements with the card stack.

## License

SwipeCardsKit is available under the MIT license. See the LICENSE file for more info.
