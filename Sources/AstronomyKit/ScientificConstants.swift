//
//  ScientificConstants.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 17/12/2016.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

/// Constant value substracted from Julian Day to create so-called modified julian days.
public let ModifiedJulianDayZero: Double = 2400000.5

/// The length of Julian Years, in days.
public let JulianYear: Day = 365.25            // See p.133 of AA.
/// The length of Besselian Years, in days.
public let BesselianYear: Day = 365.2421988    // See p.133 of AA.

/// The new standard epoch, as decided by the IAU in 1984.
public let StandardEpoch_J2000_0: JulianDay = 2451545.0 // See p.133 of AA.
public let StandardEpoch_B1950_0: JulianDay = 2433282.4235 // See p.133 of AA.

/// Mean value of the lunar equator inclination, relative to the ecliptic.
public let MeanLunarEquatorInclination: Degree = 1.54242 // Relative, to Ecliptic. See p. 372 of AA.

public typealias Kilogram=Double
public typealias Celsius=Double
public typealias Millibar=Double

/// Conversion factor from radians to degrees.
public let rad2deg = 180.0/Double.pi
/// Conversion factor from degrees to radians.
public let deg2rad = Double.pi/180.0

/// Conversion factor from radians to hours.
public let rad2hour = 3.8197186342054880584532103209403
/// Conversion factor from hours to radians.
public let hour2rad = 0.26179938779914943653855361527329

/// Conversion factor from Astronomical Unit to parsecs.
public let AU2pc: Double = tan(1.0/3600.0/deg2rad)
/// Conversion factor from Astronomical Unit to meters.
public let AU2m: Double = 149597870700.0 // Wikipedia
/// Conversion factor from Astronomical Unit to light-years.
public let AU2ly: Double = 1.0/206264.8


/// Standard eqpoch values. Note: equinoxes are directions, epochs are point in time.
public enum Epoch: CustomStringConvertible, Sendable, Codable, Hashable {
    
    /// The mean epoch of the date.
    case epochOfTheDate(JulianDay)
    
    /// The standard 2000 epoch: January 1st, 2000, in the Julian calendar (1 year = 365.25 days).
    case J2000
    
    /// The standard 1950 epoch: January 1st, 1950, in the Besselian calendar
    /// (1 year = 365.2421988 days in AD1900, that is, the length of the tropical year).
    case B1950
    
    /// The value of the epoch, in Julian Days.
    var julianDay: JulianDay {
        switch self {
        case .epochOfTheDate(let julianDay):
            return julianDay
        case .J2000:
            return StandardEpoch_J2000_0
        case .B1950:
            return StandardEpoch_B1950_0
        }
    }
    
    public var description: String {
        switch self {
        case .epochOfTheDate(let julianDay):
            return julianDay.description
        case .J2000:
            return "J2000.0"
        case .B1950:
            return "B1950.0"
        }
    }
}

/// Standard equinox values. Note: equinoxes are directions, epochs are point in time.
/// The vernal equinox, which is the zero point of both right ascension and celestial longitude, is defined
/// to be in the direction of the ascending node of the ecliptic on the equator.
/// Of course, at the standard epoch of J2000 corresponds to a specific (and thus standard) equinox.
public enum Equinox: CustomStringConvertible, Sendable, Codable, Hashable {
    
    /// The mean equinox of the date is the intersection of the ecliptic of the date with the mean equator of the date.
    case meanEquinoxOfTheDate(JulianDay)
    
    /// The standard 2000 equinox: January 1st, 2000, in the Julian calendar (1 year = 365.25 days).
    case standardJ2000
    
    /// The standard 1950 equinox: January 1st, 1950, in the Besselian calendar 
    /// (1 year = 365.2421988 days in AD1900, that is, the length of the tropical year).
    case standardB1950
    
    /// The Julian Day of the given equinox.
    var julianDay: JulianDay {
        switch self {
        case .meanEquinoxOfTheDate(let julianDay):
            return julianDay
        case .standardJ2000:
            return StandardEpoch_J2000_0
        case .standardB1950:
            return StandardEpoch_B1950_0
        }
    }
    
    public var description: String { return self.julianDay.description }
}


/// Earth seasons
///
/// - spring: Spring
/// - summer: Summer
/// - autumn: Autumn
/// - winter: Winter
public enum Season: Sendable, Codable, Hashable, CaseIterable {
    case spring
    case summer
    case autumn
    case winter
}


/// Moon phases
///
/// - new: New Moon
/// - firstQuarter: First Quarter
/// - full: Full Moon
/// - lastQuarter: Last Quarter
public enum MoonPhase: Sendable, Codable, Hashable, CaseIterable {
    case newMoon
    case firstQuarter
    case fullMoon
    case lastQuarter
}

/// Error used when computing Rise Transit and Set times (see Earth twilights and planetary rise, transit and set times).
///
/// - alwaysBelowAltitude: The object is always below the given altitude.
/// - alwaysAboveAltitude: The object is always above the given altitude.
public enum CelestialBodyTransitError: Error, Sendable {
    case alwaysBelowAltitude
    case alwaysAboveAltitude
    case undefinedPlanetaryObject
}

// MARK: - Planet Enums

/// KPCAAPlanet is an enum for all historical 9 planets, that is, including Pluto.
public enum KPCAAPlanet: Int, Sendable, CustomStringConvertible, CaseIterable {
    case KPCAAPlanetMercury = 0
    case KPCAAPlanetVenus = 1
    case KPCAAPlanetEarth = 99
    case KPCAAPlanetMars = 2
    case KPCAAPlanetJupiter = 3
    case KPCAAPlanetSaturn = 4
    case KPCAAPlanetUranus = 5
    case KPCAAPlanetNeptune = 6
    case KPCAAPlanetPluto = 999
    case KPCAAPlanetUndefined = -1
    
    /// Return the KPCAAPlanet enum value from a planet name string.
    ///
    /// - Parameter string: The planet name.
    /// - Returns: The KPCAAPlanet enum value
    public static func fromString(_ string: String) -> KPCAAPlanet {
        switch string {
        case "Mercury": return .KPCAAPlanetMercury
        case "Venus": return .KPCAAPlanetVenus
        case "Earth": return .KPCAAPlanetEarth
        case "Mars": return .KPCAAPlanetMars
        case "Jupiter": return .KPCAAPlanetJupiter
        case "Saturn": return .KPCAAPlanetSaturn
        case "Uranus": return .KPCAAPlanetUranus
        case "Neptune": return .KPCAAPlanetNeptune
        case "Pluto": return .KPCAAPlanetPluto
        default: return .KPCAAPlanetUndefined
        }
    }
    
    /// Return the planet name according to the enum value.
    public var description: String {
        switch self {
        case .KPCAAPlanetMercury: return "Mercury"
        case .KPCAAPlanetVenus: return "Venus"
        case .KPCAAPlanetEarth: return "Earth"
        case .KPCAAPlanetMars: return "Mars"
        case .KPCAAPlanetJupiter: return "Jupiter"
        case .KPCAAPlanetSaturn: return "Saturn"
        case .KPCAAPlanetUranus: return "Uranus"
        case .KPCAAPlanetNeptune: return "Neptune"
        case .KPCAAPlanetPluto: return "Pluto"
        case .KPCAAPlanetUndefined: return ""
        }
    }
}

public let KPCAAPlanetMercury = KPCAAPlanet.KPCAAPlanetMercury
public let KPCAAPlanetVenus = KPCAAPlanet.KPCAAPlanetVenus
public let KPCAAPlanetEarth = KPCAAPlanet.KPCAAPlanetEarth
public let KPCAAPlanetMars = KPCAAPlanet.KPCAAPlanetMars
public let KPCAAPlanetJupiter = KPCAAPlanet.KPCAAPlanetJupiter
public let KPCAAPlanetSaturn = KPCAAPlanet.KPCAAPlanetSaturn
public let KPCAAPlanetUranus = KPCAAPlanet.KPCAAPlanetUranus
public let KPCAAPlanetNeptune = KPCAAPlanet.KPCAAPlanetNeptune
public let KPCAAPlanetPluto = KPCAAPlanet.KPCAAPlanetPluto
public let KPCAAPlanetUndefined = KPCAAPlanet.KPCAAPlanetUndefined

/// KPCAAPlanetStrict is an enum for all true planets, that is, excluding the now official
/// Dwarf Planet category, that is, Pluto.
public enum KPCAAPlanetStrict: Int, Sendable, CaseIterable {
    case KPCAAPlanetStrictMercury = 0
    case KPCAAPlanetStrictVenus = 1
    case KPCAAPlanetStrictEarth = 99
    case KPCAAPlanetStrictMars = 2
    case KPCAAPlanetStrictJupiter = 3
    case KPCAAPlanetStrictSaturn = 4
    case KPCAAPlanetStrictUranus = 5
    case KPCAAPlanetStrictNeptune = 6
    case KPCAAPlanetStrictUndefined = -1
    
    /// Return the equivalent KPCAAPlanetStrict enum value from the KPCAAPlanet enum.
    ///
    /// - Parameter planet: The KPCAAPlanet enum value
    /// - Returns: The equivalent KPCAAPlanetStrict enum value
    public static func fromPlanet(_ planet: KPCAAPlanet) -> KPCAAPlanetStrict {
        switch planet {
        case .KPCAAPlanetPluto, .KPCAAPlanetUndefined:
            return .KPCAAPlanetStrictUndefined
        default:
            return KPCAAPlanetStrict(rawValue: planet.rawValue) ?? .KPCAAPlanetStrictUndefined
        }
    }
}

public let KPCAAPlanetStrictMercury = KPCAAPlanetStrict.KPCAAPlanetStrictMercury
public let KPCAAPlanetStrictVenus = KPCAAPlanetStrict.KPCAAPlanetStrictVenus
public let KPCAAPlanetStrictEarth = KPCAAPlanetStrict.KPCAAPlanetStrictEarth
public let KPCAAPlanetStrictMars = KPCAAPlanetStrict.KPCAAPlanetStrictMars
public let KPCAAPlanetStrictJupiter = KPCAAPlanetStrict.KPCAAPlanetStrictJupiter
public let KPCAAPlanetStrictSaturn = KPCAAPlanetStrict.KPCAAPlanetStrictSaturn
public let KPCAAPlanetStrictUranus = KPCAAPlanetStrict.KPCAAPlanetStrictUranus
public let KPCAAPlanetStrictNeptune = KPCAAPlanetStrict.KPCAAPlanetStrictNeptune
public let KPCAAPlanetStrictUndefined = KPCAAPlanetStrict.KPCAAPlanetStrictUndefined

/// KPCPlanetaryObject is an enum for all planets, excluding Earth and Pluto.
public enum KPCPlanetaryObject: Int, Sendable, CaseIterable {
    case KPCPlanetaryObjectMERCURY = 0
    case KPCPlanetaryObjectVENUS = 1
    case KPCPlanetaryObjectMARS = 2
    case KPCPlanetaryObjectJUPITER = 3
    case KPCPlanetaryObjectSATURN = 4
    case KPCPlanetaryObjectURANUS = 5
    case KPCPlanetaryObjectNEPTUNE = 6
    case KPCPlanetaryObjectUNDEFINED = -1
    
    /// Returns the planetary object index from a given planet index.
    ///
    /// - Parameter planet: The planet index.
    /// - Returns: The corresponding planetary object index.
    public static func fromPlanet(_ planet: KPCAAPlanet) -> KPCPlanetaryObject {
        switch planet {
        case .KPCAAPlanetMercury: return .KPCPlanetaryObjectMERCURY
        case .KPCAAPlanetVenus: return .KPCPlanetaryObjectVENUS
        case .KPCAAPlanetMars: return .KPCPlanetaryObjectMARS
        case .KPCAAPlanetJupiter: return .KPCPlanetaryObjectJUPITER
        case .KPCAAPlanetSaturn: return .KPCPlanetaryObjectSATURN
        case .KPCAAPlanetUranus: return .KPCPlanetaryObjectURANUS
        case .KPCAAPlanetNeptune: return .KPCPlanetaryObjectNEPTUNE
        default: return .KPCPlanetaryObjectUNDEFINED
        }
    }
    
    /// Returns the SwiftAA Class type for the given planetary object.
    public var objectType: Planet.Type? {
        switch self {
        case .KPCPlanetaryObjectMERCURY: return Mercury.self
        case .KPCPlanetaryObjectVENUS: return Venus.self
        case .KPCPlanetaryObjectMARS: return Mars.self
        case .KPCPlanetaryObjectJUPITER: return Jupiter.self
        case .KPCPlanetaryObjectSATURN: return Saturn.self
        case .KPCPlanetaryObjectURANUS: return Uranus.self
        case .KPCPlanetaryObjectNEPTUNE: return Neptune.self
        default: return nil
        }
    }
}

public let KPCPlanetaryObjectMERCURY = KPCPlanetaryObject.KPCPlanetaryObjectMERCURY
public let KPCPlanetaryObjectVENUS = KPCPlanetaryObject.KPCPlanetaryObjectVENUS
public let KPCPlanetaryObjectMARS = KPCPlanetaryObject.KPCPlanetaryObjectMARS
public let KPCPlanetaryObjectJUPITER = KPCPlanetaryObject.KPCPlanetaryObjectJUPITER
public let KPCPlanetaryObjectSATURN = KPCPlanetaryObject.KPCPlanetaryObjectSATURN
public let KPCPlanetaryObjectURANUS = KPCPlanetaryObject.KPCPlanetaryObjectURANUS
public let KPCPlanetaryObjectNEPTUNE = KPCPlanetaryObject.KPCPlanetaryObjectNEPTUNE
public let KPCPlanetaryObjectUNDEFINED = KPCPlanetaryObject.KPCPlanetaryObjectUNDEFINED

/// KPCAAEllipticalObject is an enum for the Sun, all planets, excluding Earth but including Pluto.
public enum KPCAAEllipticalObject: Int, Sendable, CaseIterable {
    case KPCAAEllipticalObjectSUN = -1
    case KPCAAEllipticalObjectMERCURY = 0
    case KPCAAEllipticalObjectVENUS = 1
    case KPCAAEllipticalObjectMARS = 2
    case KPCAAEllipticalObjectJUPITER = 3
    case KPCAAEllipticalObjectSATURN = 4
    case KPCAAEllipticalObjectURANUS = 5
    case KPCAAEllipticalObjectNEPTUNE = 6
    case KPCAAEllipticalObjectUNDEFINED = -99
    
    /// Returns the elliptical object index from a given planet index.
    ///
    /// - Parameter planet: The planet index.
    /// - Returns: The corresponding elliptical object index. The Sun must be handled individually.
    public static func fromPlanet(_ planet: KPCAAPlanet) -> KPCAAEllipticalObject {
        switch planet {
        case .KPCAAPlanetMercury: return .KPCAAEllipticalObjectMERCURY
        case .KPCAAPlanetVenus: return .KPCAAEllipticalObjectVENUS
        case .KPCAAPlanetMars: return .KPCAAEllipticalObjectMARS
        case .KPCAAPlanetJupiter: return .KPCAAEllipticalObjectJUPITER
        case .KPCAAPlanetSaturn: return .KPCAAEllipticalObjectSATURN
        case .KPCAAPlanetUranus: return .KPCAAEllipticalObjectURANUS
        case .KPCAAPlanetNeptune: return .KPCAAEllipticalObjectNEPTUNE
        default: return .KPCAAEllipticalObjectUNDEFINED
        }
    }
}

public let KPCAAEllipticalObjectSUN = KPCAAEllipticalObject.KPCAAEllipticalObjectSUN
public let KPCAAEllipticalObjectMERCURY = KPCAAEllipticalObject.KPCAAEllipticalObjectMERCURY
public let KPCAAEllipticalObjectVENUS = KPCAAEllipticalObject.KPCAAEllipticalObjectVENUS
public let KPCAAEllipticalObjectMARS = KPCAAEllipticalObject.KPCAAEllipticalObjectMARS
public let KPCAAEllipticalObjectJUPITER = KPCAAEllipticalObject.KPCAAEllipticalObjectJUPITER
public let KPCAAEllipticalObjectSATURN = KPCAAEllipticalObject.KPCAAEllipticalObjectSATURN
public let KPCAAEllipticalObjectURANUS = KPCAAEllipticalObject.KPCAAEllipticalObjectURANUS
public let KPCAAEllipticalObjectNEPTUNE = KPCAAEllipticalObject.KPCAAEllipticalObjectNEPTUNE
public let KPCAAEllipticalObjectUNDEFINED = KPCAAEllipticalObject.KPCAAEllipticalObjectUNDEFINED
