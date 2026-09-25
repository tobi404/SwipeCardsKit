//
//  ScreenBoundHelper.swift
//  SwipeCardsKit
//
//  Created by Beka Demuradze on 07.05.25.
//

import SwiftUI

#if os(iOS)
extension UIWindow {
    static var current: UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                if window.isKeyWindow { return window }
            }
        }
        return nil
    }
}

extension UIScreen {
    static var current: UIScreen? {
        UIWindow.current?.screen
    }
}
#elseif os(macOS)
extension NSWindow {
    static var current: NSWindow? {
        NSApplication.shared.keyWindow
    }
}

extension NSScreen {
    @MainActor
    static var current: NSScreen? {
        NSWindow.current?.screen ?? NSScreen.main
    }
}
#endif
