//
//  Eclipses.swift
//  SwiftAA
//
//  Created for SwiftAA.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

/// Solar eclipse types and flags.
public struct SolarEclipseFlags: OptionSet, Sendable, Codable, Hashable {
    public let rawValue: UInt
    
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
    
    public init(flags: SolarEclipseFlags, timeOfMaximumEclipse: JulianDay, f: Double, u: Double, gamma: Double, greatestMagnitude: Double) {
        self.flags = flags
        self.timeOfMaximumEclipse = timeOfMaximumEclipse
        self.f = f
        self.u = u
        self.gamma = gamma
        self.greatestMagnitude = greatestMagnitude
    }
    
    public var isTotal: Bool { flags.contains(.total) }
    public var isAnnular: Bool { flags.contains(.annular) }
    public var isPartial: Bool { flags.contains(.partial) }
    public var isCentral: Bool { flags.contains(.central) }
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
    
    public var isTotal: Bool { umbralMagnitude >= 1.0 }
    public var isPartial: Bool { umbralMagnitude > 0.0 && umbralMagnitude < 1.0 }
    public var isPenumbral: Bool { hasEclipse && umbralMagnitude <= 0.0 }
}

/// Solar & Lunar Eclipse prediction helper.
public struct Eclipses: Sendable {
    
    /// Calculate solar eclipse characteristics for a given lunation index k.
    /// - Parameter k: Lunation index (integer for New Moon).
    /// - Returns: SolarEclipseDetails.
    public static func calculateSolar(k: Double) -> SolarEclipseDetails {
        let details = CAAEclipses.CalculateSolar(k)
        return SolarEclipseDetails(
            flags: SolarEclipseFlags(rawValue: UInt(details.Flags)),
            timeOfMaximumEclipse: JulianDay(details.TimeOfMaximumEclipse),
            f: details.F,
            u: details.u,
            gamma: details.gamma,
            greatestMagnitude: details.GreatestMagnitude
        )
    }

    /// Calculate lunar eclipse characteristics for a given lunation index k.
    /// - Parameter k: Lunation index (integer + 0.5 for Full Moon).
    /// - Returns: LunarEclipseDetails.
    public static func calculateLunar(k: Double) -> LunarEclipseDetails {
        let details = CAAEclipses.CalculateLunar(k)
        return LunarEclipseDetails(
            hasEclipse: details.bEclipse,
            timeOfMaximumEclipse: JulianDay(details.TimeOfMaximumEclipse),
            f: details.F,
            u: details.u,
            gamma: details.gamma,
            penumbralRadii: details.PenumbralRadii,
            umbralRadii: details.UmbralRadii,
            penumbralMagnitude: details.PenumbralMagnitude,
            umbralMagnitude: details.UmbralMagnitude,
            partialPhaseSemiDuration: Minute(details.PartialPhaseSemiDuration),
            totalPhaseSemiDuration: Minute(details.TotalPhaseSemiDuration),
            partialPhasePenumbraSemiDuration: Minute(details.PartialPhasePenumbraSemiDuration)
        )
    }
}
