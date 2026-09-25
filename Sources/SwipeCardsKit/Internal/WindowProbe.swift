//
//  WindowProbe.swift
//  SwipeCardsKit
//

import SwiftUI

/// Holds the view that hosts the deck, so the deck can read its window's current width on demand.
@MainActor
final class WindowProbe {
    #if os(iOS)
    weak var view: UIView?

    var windowWidth: CGFloat? {
        view?.window?.bounds.width
    }
    #elseif os(macOS)
    weak var view: NSView?

    var windowWidth: CGFloat? {
        view?.window?.contentView?.bounds.width
    }
    #endif
}

#if os(iOS)
struct WindowProbeView: UIViewRepresentable {
    let probe: WindowProbe

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        probe.view = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#elseif os(macOS)
struct WindowProbeView: NSViewRepresentable {
    let probe: WindowProbe

    final class PassthroughView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }

    func makeNSView(context: Context) -> NSView {
        let view = PassthroughView()
        probe.view = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
