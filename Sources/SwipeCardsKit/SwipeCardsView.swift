//
//  SwipeCardsView.swift
//  SwipeCardsKit
//
//  Created by Beka Demuradze on 27.04.25.
//

import SwiftUI

public struct CardSwipeView<Item: Identifiable & Hashable, Content: View>: View {
    @State private var configuration = Configuration<Item>()
    @State private var poppedItem: Item?
    @State private var poppedOffset: CGPoint = .zero
    @State private var poppedDirection: CardSwipeDirection = .idle
    @State private var lastDirection: CardSwipeDirection = .idle
    @State private var offset: CGPoint = .zero
    @State private var thresholdPassed = false
    /// The deck's frame in window coordinates, measured on every layout, so swipe distances follow
    /// the deck when its window changes size (a foldable opening, a Split View resize).
    @State private var deckFrame: CGRect = .zero
    @State private var windowProbe = WindowProbe()
    
    @Binding private var items: [Item]
    @Binding private var selectedItem: Item?
    @Binding private var popTrigger: CardSwipeDirection?
    private let content: (Item, _ progress: CGFloat, _ direction: CardSwipeDirection) -> Content
    
    private var triggerThreshold: CGFloat {
        guard let fraction = configuration.triggerThresholdFraction, deckFrame.width > 0 else {
            return configuration.triggerThreshold
        }
        return deckFrame.width * fraction
    }

    /// Far enough for a popped card to leave the window from wherever the deck sits in it:
    /// past the leading edge on a left swipe and past the trailing edge on a right swipe.
    private var flyOffDistance: CGFloat {
        guard deckFrame.width > 0 else { return 1000 }
        let windowWidth = windowProbe.windowWidth ?? 0
        return max(2 * deckFrame.maxX, windowWidth - deckFrame.minX + deckFrame.width)
    }
    
    public init(
        items: Binding<[Item]>,
        selectedItem: Binding<Item?> = .constant(nil),
        popTrigger: Binding<CardSwipeDirection?> = .constant(nil),
        @ViewBuilder content: @escaping (Item, _ progress: CGFloat, _ direction: CardSwipeDirection) -> Content
    ) {
        self._items = items
        self._selectedItem = selectedItem
        self._popTrigger = popTrigger
        self.content = content
    }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: configuration.minimumDistance)
            .onChanged { value in
                onDragChanged(value)
            }
            .onEnded { value in
                if abs(value.translation.width) < triggerThreshold {
                    withAnimation(.bouncy) {
                        offset = .zero
                    }
                } else if !items.isEmpty {
                    popItem()
                }
            }
    }
    
    public var body: some View {
        ZStack {
            ForEach(Array(items.prefix(configuration.visibleCount).enumerated()), id: \.element.id) { index, item in
                let progress = index == 0 ? min(abs(offset.x) / triggerThreshold, 1) : 0
                
                content(item, progress, lastDirection)
                    .modifier(
                        CardSwipeEffect(
                            index: index,
                            offset: offset,
                            triggerThreshold: triggerThreshold
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .global)
                WindowProbeView(probe: windowProbe)
                    .onAppear { deckFrame = frame }
                    .onChange(of: frame) { deckFrame = $0 }
            }
        }
        .overlay { poppedCard }
        .simultaneousGesture(swipeGesture)
        .onAppear {
            selectedItem = items.first
        }
        .onChange(of: popTrigger ?? .idle) { newValue in
            guard newValue != .idle else { return }
            lastDirection = newValue
            popItem(notifyCaller: false)
            popTrigger = nil
        }
    }
    
    @ViewBuilder
    var poppedCard: some View {
        if let poppedItem {
            content(poppedItem, min(abs(poppedOffset.x) / triggerThreshold, 1), poppedDirection)
                .modifier(
                    CardSwipeEffect(
                        index: 0,
                        offset: poppedOffset,
                        triggerThreshold: triggerThreshold
                    )
                )
                .id(poppedItem.id)
                .onAppear {
                    animatePoppedItem()
                }
        }
    }
    
    func onDragChanged(_ value: DragGesture.Value) {
        let translation = value.translation.width
        let correction = correction(for: translation)
        let offsetX = translation + correction
        let offsetY = configuration.animateOnYAxes
            ? value.translation.height
            : 0
        offset = CGPoint(x: offsetX, y: offsetY)
        
        let newDirection = CardSwipeDirection(offset: offsetX)
        if lastDirection != newDirection {
            lastDirection = newDirection
        }
        
        let thresholdReached = abs(offsetX) >= triggerThreshold
        if thresholdReached != thresholdPassed {
            thresholdPassed = thresholdReached
            if thresholdReached {
                configuration.onThresholdPassed?()
            }
        }
    }

    func correction(for translation: CGFloat) -> CGFloat {
        if translation >= configuration.minimumDistance {
            -configuration.minimumDistance
        } else if translation <= -configuration.minimumDistance {
            configuration.minimumDistance
        } else {
            -translation
        }
    }
    
    func animatePoppedItem() {
        let multiplier: CGFloat = poppedDirection == .left ? -1 : 1
        
        if #available(iOS 17.0, *) {
            withAnimation(.spring(duration: 0.5)) {
                poppedOffset.x += (flyOffDistance * multiplier)
            } completion: {
                self.poppedItem = nil
                self.poppedOffset = .zero
                
                if items.isEmpty {
                    configuration.onNoMoreCardsLeft?()
                }
            }
        } else {
            withAnimation(.spring(duration: 0.5)) {
                poppedOffset.x += (flyOffDistance * multiplier)
            }
            
            Task {
                try? await Task.sleep(nanoseconds: (1 * NSEC_PER_SEC) / 2)
                
                self.poppedItem = nil
                
                if items.isEmpty {
                    configuration.onNoMoreCardsLeft?()
                }
            }
        }
    }
    
    func popItem(notifyCaller: Bool = true) {
        guard !items.isEmpty else { return }
        poppedOffset = offset
        poppedDirection = lastDirection
        poppedItem = items.removeFirst()
        selectedItem = items.first
        if let poppedItem, notifyCaller {
            configuration.onSwipeEnd?(poppedItem, lastDirection)
        }
        offset = .zero
    }
}

public extension CardSwipeView {
    func configure(
        threshold: CGFloat,
        minimumDistance: CGFloat,
        animateOnYAxes: Bool
    ) -> CardSwipeView {
        configuration.triggerThreshold = threshold
        configuration.triggerThresholdFraction = nil
        configuration.minimumDistance = minimumDistance
        configuration.animateOnYAxes = animateOnYAxes
        return self
    }

    /// Commits a swipe after `thresholdFraction` of the deck's width (for example 0.42), so the
    /// gesture scales with the deck instead of using a fixed distance.
    func configure(
        thresholdFraction: CGFloat,
        minimumDistance: CGFloat,
        animateOnYAxes: Bool
    ) -> CardSwipeView {
        configuration.triggerThresholdFraction = thresholdFraction
        configuration.minimumDistance = minimumDistance
        configuration.animateOnYAxes = animateOnYAxes
        return self
    }

    /// Commits a swipe after `thresholdFraction` of the deck's width, keeping the other defaults.
    func configure(thresholdFraction: CGFloat) -> CardSwipeView {
        configuration.triggerThresholdFraction = thresholdFraction
        return self
    }
    
    func onSwipeEnd(_ newValue: @escaping (Item, CardSwipeDirection) -> Void) -> CardSwipeView {
        configuration.onSwipeEnd = newValue
        return self
    }
    
    func onNoMoreCardsLeft(_ newValue: @escaping () -> Void) -> CardSwipeView {
        configuration.onNoMoreCardsLeft = newValue
        return self
    }
    
    func onThresholdPassed(_ newValue: @escaping () -> Void) -> CardSwipeView {
        configuration.onThresholdPassed = newValue
        return self
    }
}
