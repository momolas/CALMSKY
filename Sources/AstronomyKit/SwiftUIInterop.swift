//
//  SwiftUIInterop.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

#if canImport(SwiftUI)
import SwiftUI

public extension SwiftUI.Angle {
    /// Creates a SwiftUI Angle from a AstronomyKit Degree.
    init(_ degree: Degree) {
        self.init(degrees: degree.value)
    }

    /// Creates a SwiftUI Angle from a AstronomyKit Radian.
    init(_ radian: Radian) {
        self.init(radians: radian.value)
    }

    /// Creates a SwiftUI Angle from a AstronomyKit Hour angle.
    init(_ hour: Hour) {
        self.init(degrees: hour.inDegrees.value)
    }
}

public extension Degree {
    /// Creates a Degree from a SwiftUI Angle.
    init(_ angle: SwiftUI.Angle) {
        self.init(angle.degrees)
    }

    /// Converts the Degree to a SwiftUI Angle.
    var asSwiftUIAngle: SwiftUI.Angle {
        SwiftUI.Angle(degrees: self.value)
    }
}

public extension Radian {
    /// Creates a Radian from a SwiftUI Angle.
    init(_ angle: SwiftUI.Angle) {
        self.init(angle.radians)
    }

    /// Converts the Radian to a SwiftUI Angle.
    var asSwiftUIAngle: SwiftUI.Angle {
        SwiftUI.Angle(radians: self.value)
    }
}
#endif
