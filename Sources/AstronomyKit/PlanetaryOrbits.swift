//
//  PlanetaryOrbits.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 26/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation

@inlinable
func orbitMeanLongitude(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    CAAElementsPlanetaryOrbit.elements(for: planet, jd: jd).meanLongitude
}

@inlinable
func orbitMeanLongitudeJ2000(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    CAAElementsPlanetaryOrbit.elementsJ2000(for: planet, jd: jd).meanLongitude
}

@inlinable
func orbitSemimajorAxis(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    CAAElementsPlanetaryOrbit.elements(for: planet, jd: jd).semimajorAxis
}

@inlinable
func orbitEccentricity(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    CAAElementsPlanetaryOrbit.elements(for: planet, jd: jd).eccentricity
}

@inlinable
func orbitInclination(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    CAAElementsPlanetaryOrbit.elements(for: planet, jd: jd).inclination
}

@inlinable
func orbitInclinationJ2000(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    CAAElementsPlanetaryOrbit.elementsJ2000(for: planet, jd: jd).inclination
}

@inlinable
func orbitLongitudeAscendingNode(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    CAAElementsPlanetaryOrbit.elements(for: planet, jd: jd).longitudeAscendingNode
}

@inlinable
func orbitLongitudeAscendingNodeJ2000(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    CAAElementsPlanetaryOrbit.elementsJ2000(for: planet, jd: jd).longitudeAscendingNode
}

@inlinable
func orbitLongitudePerihelion(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    CAAElementsPlanetaryOrbit.elements(for: planet, jd: jd).longitudePerihelion
}

@inlinable
func orbitLongitudePerihelionJ2000(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    CAAElementsPlanetaryOrbit.elementsJ2000(for: planet, jd: jd).longitudePerihelion
}

func calculateObjectDetailsNoElements(jd: Double, planetStrict: KPCAAPlanetStrict, highPrecision: Bool) -> CAAEllipticalObjectDetails {
    let orb = CAAElementsPlanetaryOrbit.elements(for: planetStrict, jd: jd)
    var elements = CAAEllipticalObjectElements()
    elements.a = orb.semimajorAxis
    elements.e = orb.eccentricity
    elements.i = orb.inclination
    elements.w = orb.longitudePerihelion
    elements.omega = orb.longitudeAscendingNode
    elements.JDEquinox = 2451545.0 // J2000
    
    let fractionalYear = CAADate(jd, true).FractionalYear()
    let k = planetPerihelionK(planetStrict, year: fractionalYear).rounded()
    elements.T = planetPerihelion(planetStrict, k: k)
    
    return CAAElliptical.Calculate(jd, elements, highPrecision)
}

/// This protocol encompasses various elements of planetary orbits.
public protocol PlanetaryOrbits: PlanetaryBase {
    /// The details of the object configuration
    var allObjectDetails: CAAEllipticalObjectDetails { get }

    /// Computes the mean longitude of the orbit
    ///
    /// - Parameter equinox: The equinox for which the computation is made
    /// - Returns: The longitude in degrees
    func meanLongitude(_ equinox: Equinox) -> Degree
    
    /// Computes the semi major axis of the orbit
    ///
    /// - Returns: The semi major axis in astronomical units
    func semimajorAxis() -> AstronomicalUnit
    
    /// Computes the eccentricity of the orbit
    ///
    /// - Returns: The eccentricity (comprise between 0==circular, and 1).
    func eccentricity() -> Double
    
    /// Computes the inclination of the planet on the plane of the ecliptic
    ///
    /// - Parameter equinox: The equinox for which the computation is made
    /// - Returns: The inclination in degrees
    func inclination(_ equinox: Equinox) -> Degree
    
    /// Computes the longitude of the ascending node.
    ///
    /// - Parameter equinox: The equinox for which the computation is made
    /// - Returns: The longitude in degrees
    func longitudeOfAscendingNode(_ equinox: Equinox) -> Degree
    
    /// Compute the longitude of the perihelion
    ///
    /// - Parameter equinox: The equinox for which the computation is made
    /// - Returns: The longitude in degrees
    func longitudeOfPerihelion(_ equinox: Equinox) -> Degree
    
    /// The true geocentric distance between the planet and the Earth's center
    var trueGeocentricDistance: AstronomicalUnit { get }
}

public extension PlanetaryOrbits {
    /// Computes the mean longitude of the orbit
    ///
    /// - Parameter equinox: The equinox for which the computation is made
    /// - Returns: The longitude in degrees
    func meanLongitude(_ equinox: Equinox = .standardJ2000) -> Degree {
        switch equinox {
        case .standardJ2000:
            return Degree(orbitMeanLongitudeJ2000(self.planetStrict, jd: self.julianDay.value))
        default:
            return Degree(orbitMeanLongitude(self.planetStrict, jd: self.julianDay.value))
        }
    }
    
    /// Computes the semi major axis of the orbit
    ///
    /// - Returns: The semi major axis in astronomical units
    func semimajorAxis() -> AstronomicalUnit {
        return AstronomicalUnit(orbitSemimajorAxis(self.planetStrict, jd: self.julianDay.value))
    }
    
    /// Computes the eccentricity of the orbit
    ///
    /// - Returns: The eccentricity (comprise between 0==circular, and 1).
    func eccentricity() -> Double {
        return orbitEccentricity(self.planetStrict, jd: self.julianDay.value)
    }
    
    /// Computes the inclination of the planet on the plane of the ecliptic
    ///
    /// - Parameter equinox: The equinox for which the computation is made
    /// - Returns: The inclination in degrees
    func inclination(_ equinox: Equinox = .standardJ2000) -> Degree {
        switch equinox {
        case .standardJ2000:
            return Degree(orbitInclinationJ2000(self.planetStrict, jd: self.julianDay.value))
        default:
            return Degree(orbitInclination(self.planetStrict, jd: self.julianDay.value))
        }
    }
    
    /// Computes the longitude of the ascending node.
    ///
    /// - Parameter equinox: The equinox for which the computation is made
    /// - Returns: The longitude in degrees
    func longitudeOfAscendingNode(_ equinox: Equinox = .standardJ2000) -> Degree {
        switch equinox {
        case .standardJ2000:
            return Degree(orbitLongitudeAscendingNodeJ2000(self.planetStrict, jd: self.julianDay.value))
        default:
            return Degree(orbitLongitudeAscendingNode(self.planetStrict, jd: self.julianDay.value))
        }
    }
    
    /// Compute the longitude of the perihelion
    ///
    /// - Parameter equinox: The equinox for which the computation is made
    /// - Returns: The longitude in degrees
    func longitudeOfPerihelion(_ equinox: Equinox = .standardJ2000) -> Degree {
        switch equinox {
        case .standardJ2000:
            return Degree(orbitLongitudePerihelionJ2000(self.planetStrict, jd: self.julianDay.value))
        default:
            return Degree(orbitLongitudePerihelion(self.planetStrict, jd: self.julianDay.value))
        }
    }
    
    var trueGeocentricDistance: AstronomicalUnit {
        get { return AstronomicalUnit(self.allObjectDetails.TrueGeocentricDistance) }
    }
}
