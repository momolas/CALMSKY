//
//  Constants.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 18/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation

#if canImport(UIKit)
    import UIKit
    public typealias CelestialColor=UIColor
#elseif canImport(AppKit)
    import AppKit
    public typealias CelestialColor=NSColor
#else
    public struct CelestialColor: Equatable, Hashable, Sendable {
        public static let white = CelestialColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        public let red: Double
        public let green: Double
        public let blue: Double
        public let alpha: Double

        public init (red: Double, green: Double, blue: Double, alpha: Double) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
    }
#endif

#if os(macOS)
    extension NSColor {
        convenience init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
            self.init(calibratedRed: red, green: green, blue: blue, alpha: alpha)
        }
    }
#endif

// See https://stackoverflow.com/questions/32873212/unit-test-fatalerror-in-swift?answertab=active#tab-top
// to make possible to unit test fatalError.
//
// testable drop-in replacement for `fatalError()`
internal func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    FatalErrorUtil.fatalErrorClosure(message(), file, line)
//    unreachable()
}

/// This is a `noreturn` function that pauses forever
public func unreachable() -> Never {
    repeat {
        RunLoop.current.run()
    } while (true)
}

/// Utility functions that can replace and restore the `fatalError` global function.
public struct FatalErrorUtil: Sendable {
    
    // Called by the custom implementation of `fatalError`.
    nonisolated(unsafe) static var fatalErrorClosure: @Sendable (String, StaticString, UInt) -> Never = defaultFatalErrorClosure
    
    // backup of the original Swift `fatalError`
    private static let defaultFatalErrorClosure: @Sendable (String, StaticString, UInt) -> Never = { Swift.fatalError($0, file: $1, line: $2) }
    
    /// Replace the `fatalError` global function with something else.
    public static func replaceFatalError(closure: @escaping @Sendable (String, StaticString, UInt) -> Never) {
        fatalErrorClosure = closure
    }
    
    /// Restore the `fatalError` global function back to the original Swift implementation
    public static func restoreFatalError() {
        fatalErrorClosure = defaultFatalErrorClosure
    }
}
