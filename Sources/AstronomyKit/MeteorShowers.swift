//
//  MeteorShowers.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Rating of observation conditions for a meteor shower based on lunar interference.
public enum MeteorObservationRating: String, Sendable, Codable {
    case favorable
    case moderate
    case poor

    public var description: String {
        switch self {
        case .favorable: return "Favorable (Dark skies, minimal moonlight)"
        case .moderate: return "Moderate (Partial moonlight interference)"
        case .poor: return "Poor (Bright moonlight, reduced visibility)"
        }
    }
}

/// A major annual meteor shower catalogued with radiant coordinates and activity parameters.
public struct MeteorShower: Sendable, Identifiable, Hashable, Codable {
    public var id: String { name }

    /// Common name of the meteor shower.
    public let name: String

    /// Approximate calendar month of the peak.
    public let peakMonth: Int

    /// Approximate day of the month of the peak.
    public let peakDay: Int

    /// Nominal right ascension of the radiant at peak.
    public let radiantAlpha: Hour

    /// Nominal declination of the radiant at peak.
    public let radiantDelta: Degree

    /// Zenithal Hourly Rate (ZHR) under optimal conditions.
    public let zhr: Int

    /// Atmospheric entry velocity in kilometers per second.
    public let velocityKmS: Double

    /// The parent comet or asteroid responsible for the debris stream.
    public let parentBody: String

    public init(
        name: String,
        peakMonth: Int,
        peakDay: Int,
        radiantAlpha: Hour,
        radiantDelta: Degree,
        zhr: Int,
        velocityKmS: Double,
        parentBody: String
    ) {
        self.name = name
        self.peakMonth = peakMonth
        self.peakDay = peakDay
        self.radiantAlpha = radiantAlpha
        self.radiantDelta = radiantDelta
        self.zhr = zhr
        self.velocityKmS = velocityKmS
        self.parentBody = parentBody
    }

    /// The equatorial coordinates of the radiant.
    public var radiantCoordinates: EquatorialCoordinates {
        EquatorialCoordinates(alpha: radiantAlpha, delta: radiantDelta)
    }

    /// Computes the exact Julian Day corresponding to the nominal peak for a given year at 00:00 UTC.
    public func peakJulianDay(year: Int) -> JulianDay {
        JulianDay(year: year, month: peakMonth, day: peakDay, hour: 0, minute: 0, second: 0.0)
    }

    /// Computes the lunar illumination fraction (0.0 to 1.0) on the night of the peak for the given year.
    public func moonIlluminationAtPeak(year: Int) -> Double {
        let jd = peakJulianDay(year: year)
        let moon = Moon(julianDay: jd)
        return moon.illuminatedFraction()
    }

    /// Evaluates the observation conditions for the peak of the shower in the given year.
    public func observationRating(year: Int) -> MeteorObservationRating {
        let moonIllum = moonIlluminationAtPeak(year: year)
        if moonIllum < 0.25 {
            return .favorable
        } else if moonIllum < 0.65 {
            return .moderate
        } else {
            return .poor
        }
    }
}

// MARK: - Catalogue of Major Annual Showers

public extension MeteorShower {
    static let quadrantids = MeteorShower(
        name: "Quadrantids",
        peakMonth: 1,
        peakDay: 4,
        radiantAlpha: Hour(15.33),
        radiantDelta: Degree(49.5),
        zhr: 110,
        velocityKmS: 41.0,
        parentBody: "Asteroid 2003 EH1"
    )

    static let lyrids = MeteorShower(
        name: "Lyrids",
        peakMonth: 4,
        peakDay: 22,
        radiantAlpha: Hour(18.07),
        radiantDelta: Degree(34.0),
        zhr: 18,
        velocityKmS: 49.0,
        parentBody: "Comet C/1861 G1 (Thatcher)"
    )

    static let etaAquariids = MeteorShower(
        name: "Eta Aquariids",
        peakMonth: 5,
        peakDay: 6,
        radiantAlpha: Hour(22.53),
        radiantDelta: Degree(-1.0),
        zhr: 50,
        velocityKmS: 66.0,
        parentBody: "1P/Halley"
    )

    static let perseids = MeteorShower(
        name: "Perseids",
        peakMonth: 8,
        peakDay: 12,
        radiantAlpha: Hour(3.07),
        radiantDelta: Degree(58.0),
        zhr: 100,
        velocityKmS: 59.0,
        parentBody: "109P/Swift-Tuttle"
    )

    static let orionids = MeteorShower(
        name: "Orionids",
        peakMonth: 10,
        peakDay: 21,
        radiantAlpha: Hour(6.33),
        radiantDelta: Degree(16.0),
        zhr: 20,
        velocityKmS: 66.0,
        parentBody: "1P/Halley"
    )

    static let leonids = MeteorShower(
        name: "Leonids",
        peakMonth: 11,
        peakDay: 17,
        radiantAlpha: Hour(10.20),
        radiantDelta: Degree(22.0),
        zhr: 15,
        velocityKmS: 71.0,
        parentBody: "55P/Tempel-Tuttle"
    )

    static let geminids = MeteorShower(
        name: "Geminids",
        peakMonth: 12,
        peakDay: 14,
        radiantAlpha: Hour(7.47),
        radiantDelta: Degree(33.0),
        zhr: 120,
        velocityKmS: 35.0,
        parentBody: "3200 Phaethon"
    )

    static let ursids = MeteorShower(
        name: "Ursids",
        peakMonth: 12,
        peakDay: 22,
        radiantAlpha: Hour(14.47),
        radiantDelta: Degree(76.0),
        zhr: 10,
        velocityKmS: 33.0,
        parentBody: "8P/Tuttle"
    )

    /// All major annual meteor showers.
    static let majorShowers: [MeteorShower] = [
        .quadrantids,
        .lyrids,
        .etaAquariids,
        .perseids,
        .orionids,
        .leonids,
        .geminids,
        .ursids
    ]
}
