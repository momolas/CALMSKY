//
//  Eclipses.swift
//  SwiftAA
//
//  Created for SwiftAA.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Solar eclipse types and flags.
public struct SolarEclipseFlags: OptionSet, Sendable, Codable, Hashable {
    public let rawValue: UInt
    
    @inlinable
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let total = SolarEclipseFlags(rawValue: 0x01)
    public static let annular = SolarEclipseFlags(rawValue: 0x02)
    public static let annularTotal = SolarEclipseFlags(rawValue: 0x04)
    public static let central = SolarEclipseFlags(rawValue: 0x08)
    public static let partial = SolarEclipseFlags(rawValue: 0x10)
    public static let nonCentral = SolarEclipseFlags(rawValue: 0x20)
}

/// Details of a predicted solar eclipse.
public struct SolarEclipseDetails: Sendable, Codable, Hashable {
    /// Flags defining the eclipse type (total, annular, partial, etc.)
    public let flags: SolarEclipseFlags
    /// Julian Day of maximum eclipse
    public let timeOfMaximumEclipse: JulianDay
    /// Value of F at maximum eclipse
    public let f: Double
    /// Value of u at maximum eclipse
    public let u: Double
    /// Value of gamma (minimal distance of Moon shadow axis to Earth center)
    public let gamma: Double
    /// Greatest magnitude of the eclipse
    public let greatestMagnitude: Double
    
    @inlinable
    public init(flags: SolarEclipseFlags, timeOfMaximumEclipse: JulianDay, f: Double, u: Double, gamma: Double, greatestMagnitude: Double) {
        self.flags = flags
        self.timeOfMaximumEclipse = timeOfMaximumEclipse
        self.f = f
        self.u = u
        self.gamma = gamma
        self.greatestMagnitude = greatestMagnitude
    }

    @inlinable
    public init(_ details: CAASolarEclipseDetails) {
        self.flags = SolarEclipseFlags(rawValue: UInt(details.Flags))
        self.timeOfMaximumEclipse = JulianDay(details.TimeOfMaximumEclipse)
        self.f = details.F
        self.u = details.u
        self.gamma = details.gamma
        self.greatestMagnitude = details.GreatestMagnitude
    }
    
    @inlinable public var isTotal: Bool { flags.contains(.total) }
    @inlinable public var isAnnular: Bool { flags.contains(.annular) }
    @inlinable public var isPartial: Bool { flags.contains(.partial) }
    @inlinable public var isCentral: Bool { flags.contains(.central) }
}

/// Details of a predicted lunar eclipse.
public struct LunarEclipseDetails: Sendable, Codable, Hashable {
    /// True if an eclipse occurs
    public let hasEclipse: Bool
    /// Julian Day of maximum eclipse
    public let timeOfMaximumEclipse: JulianDay
    /// Value of F at maximum eclipse
    public let f: Double
    /// Value of u at maximum eclipse
    public let u: Double
    /// Value of gamma
    public let gamma: Double
    /// Penumbral radius
    public let penumbralRadii: Double
    /// Umbral radius
    public let umbralRadii: Double
    /// Penumbral magnitude
    public let penumbralMagnitude: Double
    /// Umbral magnitude
    public let umbralMagnitude: Double
    /// Semi-duration of partial phase in minutes
    public let partialPhaseSemiDuration: Minute
    /// Semi-duration of total phase in minutes
    public let totalPhaseSemiDuration: Minute
    /// Semi-duration of partial phase penumbra in minutes
    public let partialPhasePenumbraSemiDuration: Minute

    @inlinable
    public init(hasEclipse: Bool, timeOfMaximumEclipse: JulianDay, f: Double, u: Double, gamma: Double, penumbralRadii: Double, umbralRadii: Double, penumbralMagnitude: Double, umbralMagnitude: Double, partialPhaseSemiDuration: Minute, totalPhaseSemiDuration: Minute, partialPhasePenumbraSemiDuration: Minute) {
        self.hasEclipse = hasEclipse
        self.timeOfMaximumEclipse = timeOfMaximumEclipse
        self.f = f
        self.u = u
        self.gamma = gamma
        self.penumbralRadii = penumbralRadii
        self.umbralRadii = umbralRadii
        self.penumbralMagnitude = penumbralMagnitude
        self.umbralMagnitude = umbralMagnitude
        self.partialPhaseSemiDuration = partialPhaseSemiDuration
        self.totalPhaseSemiDuration = totalPhaseSemiDuration
        self.partialPhasePenumbraSemiDuration = partialPhasePenumbraSemiDuration
    }

    @inlinable
    public init(_ details: CAALunarEclipseDetails) {
        self.hasEclipse = details.bEclipse
        self.timeOfMaximumEclipse = JulianDay(details.TimeOfMaximumEclipse)
        self.f = details.F
        self.u = details.u
        self.gamma = details.gamma
        self.penumbralRadii = details.PenumbralRadii
        self.umbralRadii = details.UmbralRadii
        self.penumbralMagnitude = details.PenumbralMagnitude
        self.umbralMagnitude = details.UmbralMagnitude
        self.partialPhaseSemiDuration = Minute(details.PartialPhaseSemiDuration)
        self.totalPhaseSemiDuration = Minute(details.TotalPhaseSemiDuration)
        self.partialPhasePenumbraSemiDuration = Minute(details.PartialPhasePenumbraSemiDuration)
    }
    
    @inlinable public var isTotal: Bool { umbralMagnitude >= 1.0 }
    @inlinable public var isPartial: Bool { umbralMagnitude > 0.0 && umbralMagnitude < 1.0 }
    @inlinable public var isPenumbral: Bool { hasEclipse && umbralMagnitude <= 0.0 }
}

/// Solar & Lunar Eclipse prediction helper.
public struct Eclipses: Sendable {
    
    /// Calculate solar eclipse characteristics for a given lunation index k.
    /// - Parameter k: Lunation index (integer for New Moon).
    /// - Returns: SolarEclipseDetails.
    @inlinable
    public static func calculateSolar(k: Double) -> SolarEclipseDetails {
        SolarEclipseDetails(CAAEclipses.CalculateSolar(k))
    }

    /// Calculate lunar eclipse characteristics for a given lunation index k.
    /// - Parameter k: Lunation index (integer + 0.5 for Full Moon).
    /// - Returns: LunarEclipseDetails.
    @inlinable
    public static func calculateLunar(k: Double) -> LunarEclipseDetails {
        LunarEclipseDetails(CAAEclipses.CalculateLunar(k))
    }

    /// Calculate solar eclipse characteristics for a date near New Moon.
    /// - Parameter date: Date near the New Moon.
    /// - Returns: SolarEclipseDetails.
    @inlinable
    public static func calculateSolar(at date: Date) -> SolarEclipseDetails {
        let k = round(CAAMoonPhases.K(date.fractionalYear))
        return calculateSolar(k: k)
    }

    /// Calculate lunar eclipse characteristics for a date near Full Moon.
    /// - Parameter date: Date near the Full Moon.
    /// - Returns: LunarEclipseDetails.
    @inlinable
    public static func calculateLunar(at date: Date) -> LunarEclipseDetails {
        let k = round(CAAMoonPhases.K(date.fractionalYear) - 0.5) + 0.5
        return calculateLunar(k: k)
    }
}
