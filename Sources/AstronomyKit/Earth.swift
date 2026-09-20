//
//  Earth.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 18/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

public enum TwilightSunAltitude: Degree, Sendable, Codable, Hashable {
    case diskCenterOnGeometricHorizon = 0
    case upperLimbOnGeometricHorizon = -0.25
    case riseAndSet = -0.5833333333333333333333 // -35/60 // diskCenterOnHorizonWithRefraction
    case upperLimbOnHorizonWithRefraction = -0.833
    case civilian = -6.0
    case nautical = -12.0
    case amateurAstronomical = -15.0
    case astronomical = -18.0
}

/// The two types of equinoxes
///
/// - northwardSpring: Spring in northern hemisphere (~March)
/// - southwardSpring: Spring in southern hemisphere (~September)
public enum EarthEquinoxType: Int, Sendable, Codable, Hashable, CaseIterable {
    case northwardSpring
    case southwardSpring
}


/// The two type of solstices
///
/// - northernSummer: Summer in the northern hemisphere (~June)
/// - southernSummer: Summer in the northern hemisphere (~December)
public enum EarthSolsticeType: Int, Sendable, Codable, Hashable, CaseIterable {
    case northernSummer
    case southernSummer
}

public final class Earth: Object, @unchecked Sendable, PlanetaryBase, PlanetaryOrbits {
    public static var averageColor: CelestialColor {
        get { return CelestialColor(red:0.133, green:0.212, blue:0.290, alpha:1.000) }
    }
    
    /// Equatorial radius of the Eart. Source: Wikipedia.
    public static let equatorialRadius: Meter = 6378140.0
    /// Polar radius of the Eart. Source: Wikipedia.
    public static let polarRadius: Meter = 6356760.0
    
    /// Accessor to all values of the underlying object details. Will probably become private
    /// once all relevant accessors are implemented and covered.
    public var allObjectDetails: CAAEllipticalObjectDetails {
        get { return calculateObjectDetailsNoElements(jd: self.julianDay.value, planetStrict: self.planetStrict, highPrecision: self.highPrecision) }
    }
    
    /// The longitude of the ascending node.
    public var longitudeOfAscendingNode: Degree {
        get { return Degree(orbitLongitudeAscendingNodeJ2000(self.planetStrict, jd: self.julianDay.value)) }
    }
    
    /// The mean anomaly (the Sun mean anomaly is the same as the Earth's one. See AA. p163.).
    public var meanAnomaly: Degree {
        get { return Degree(CAAEarth.SunMeanAnomaly(self.julianDay.value)) }
    }
    
    /**
     Computes the julian day of the equinox for the given year
     
     - parameter equinoxType: if yes, means the spring equinox for the northern hemisphere.
     if flase, it is the autumn equinox of the northern hemisphere.
     
     - returns: A julian day of the TT time of the equinox.
     */
    public func equinox(of equinoxType: EarthEquinoxType) -> JulianDay {
        let year = self.julianDay.year
        switch equinoxType {
        case .northwardSpring:
            return JulianDay(CAAEquinoxesAndSolstices.NorthwardEquinox(year, self.highPrecision))
        case .southwardSpring:
            return JulianDay(CAAEquinoxesAndSolstices.SouthwardEquinox(year, self.highPrecision))
        }
    }
    
    /**
     Computes the julian day of the solstice for the given year
     
     - parameter solsticeType: if true, means the summer solstice in the northern hemisphere,
     if false, means the winter solstice in the norther hemisphere.
     
     - returns: A julian day of the TT time of the solstice.
     */
    public func solstice(of solsticeType: EarthSolsticeType) -> JulianDay {
        let year = self.julianDay.year
        switch solsticeType {
        case .northernSummer:
            return JulianDay(CAAEquinoxesAndSolstices.NorthernSolstice(year, self.highPrecision))
        case .southernSummer:
            return JulianDay(CAAEquinoxesAndSolstices.SouthernSolstice(year, self.highPrecision))
        }
    }
    
    /**
     Computes the length of a given season.
     
     - parameter season:             The season to compute the length of.
     - parameter northernHemisphere: A flag indicating which hemisphere to consider
     
     - returns: A length in (Julian) Days.
     */
    public func lengthOfSeason(_ season: Season, northernHemisphere: Bool) -> Day {
        let year = self.julianDay.year
        switch season {
        case .spring:
            return Day(CAAEquinoxesAndSolstices.LengthOfSpring(year, northernHemisphere, self.highPrecision))
        case .summer:
            return Day(CAAEquinoxesAndSolstices.LengthOfSummer(year, northernHemisphere, self.highPrecision))
        case .autumn:
            return Day(CAAEquinoxesAndSolstices.LengthOfAutumn(year, northernHemisphere, self.highPrecision))
        case .winter:
            return Day(CAAEquinoxesAndSolstices.LengthOfWinter(year, northernHemisphere, self.highPrecision))
        }
    }
    
    /// Returns the times of twilights (including transit time).
    ///
    /// - Parameters:
    ///   - sunAltitude: The sun altitude to consider. See TwilightSunAltitude for known values.
    ///   - coordinates: The geographic coordinates for which to compute the twilights.
    /// - Returns: The rise, transit and set times, in Julian Day, and an error, if relevant.
    public func twilights(forSunAltitude sunAltitude: Degree, coordinates: GeographicCoordinates) -> RiseTransitSetTimes {
        let sun = Sun(julianDay: self.julianDay)
        return RiseTransitSetTimes(celestialBody: sun, geographicCoordinates: coordinates, riseSetAltitude: sunAltitude)
    }
    
    
    /// Returns the rise, transit and set times for a given planet, as seen from Earth. That is, the equivalent
    /// of Sun twilights, but for planets.
    ///
    /// - Parameters:
    ///   - planet: The considered planet. Cannot be the Earth.
    ///   - coordinates: The geographic coordinates for which to compute the twilights.
    /// - Returns: The rise, transit and set times, in Julian Day, and an error, if relevant.
    public func riseTransitSetTimes(for planetaryObject: KPCPlanetaryObject, geographicCoordinates: GeographicCoordinates) -> RiseTransitSetTimes {
        guard planetaryObject != .KPCPlanetaryObjectUNDEFINED else {
            return RiseTransitSetTimes(geographicCoordinates: geographicCoordinates, transitError: CelestialBodyTransitError.undefinedPlanetaryObject)
        }
        
        let planetaryObject = planetaryObject.objectType!.init(julianDay: self.julianDay)
        let altitude = (type(of: planetaryObject)).apparentRiseSetAltitude
                
        return RiseTransitSetTimes(celestialBody: planetaryObject as CelestialBody, geographicCoordinates: geographicCoordinates, riseSetAltitude: altitude)
    }
    
    
    /// The heliocentric coordinates of the Earth. That is, its apparent position on the celestial sphere, as
    /// as it would be seen by an observer at rest at the barycenter of the solar system, and referred to the
    /// instantaneous equator, ecliptic and equinox.
    /// See AA pp.217 and following.
    public var heliocentricEclipticCoordinates: EclipticCoordinates {
        get {
            let longitude = CAAEarth.EclipticLongitude(self.julianDay.value, self.highPrecision)
            let latitude = CAAEarth.EclipticLatitude(self.julianDay.value, self.highPrecision)
            // Using standard epoch, thus standard value for the equinox, thus the mean obliquity.
            return EclipticCoordinates(lambda: Degree(longitude), beta: Degree(latitude))
        }
    }
}

