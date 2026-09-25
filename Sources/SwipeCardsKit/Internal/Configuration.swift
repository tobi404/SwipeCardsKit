//
//  Configuration.swift
//  SwipeCardsKit
//
//  Created by Beka Demuradze on 04.05.25.
//

import SwiftUI

@MainActor
final class Configuration<Item: Identifiable> {
    var triggerThreshold: CGFloat = 150
    var minimumDistance: CGFloat = 20
    var animateOnYAxes: Bool = false
    var onSwipeEnd: ((Item, CardSwipeDirection) -> Void)?
    var onThresholdPassed: (() -> Void)?
    var onNoMoreCardsLeft: (() -> Void)?
    let visibleCount = 4
    #if os(iOS)
    let screenWidth = { UIScreen.current?.bounds.width ?? 400 }()
    #elseif os(macOS)
    let screenWidth = { NSScreen.current?.frame.width ?? 400 }()
    #endif
}
