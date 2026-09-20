//
//  PlanetaryOrbits.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 26/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

func orbitMeanLongitude(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAElementsPlanetaryOrbit.MercuryMeanLongitude(jd)
    case .KPCAAPlanetStrictVenus: return CAAElementsPlanetaryOrbit.VenusMeanLongitude(jd)
    case .KPCAAPlanetStrictEarth: return CAAElementsPlanetaryOrbit.EarthMeanLongitude(jd)
    case .KPCAAPlanetStrictMars: return CAAElementsPlanetaryOrbit.MarsMeanLongitude(jd)
    case .KPCAAPlanetStrictJupiter: return CAAElementsPlanetaryOrbit.JupiterMeanLongitude(jd)
    case .KPCAAPlanetStrictSaturn: return CAAElementsPlanetaryOrbit.SaturnMeanLongitude(jd)
    case .KPCAAPlanetStrictUranus: return CAAElementsPlanetaryOrbit.UranusMeanLongitude(jd)
    case .KPCAAPlanetStrictNeptune: return CAAElementsPlanetaryOrbit.NeptuneMeanLongitude(jd)
    default: return 0
    }
}

func orbitMeanLongitudeJ2000(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAElementsPlanetaryOrbit.MercuryMeanLongitudeJ2000(jd)
    case .KPCAAPlanetStrictVenus: return CAAElementsPlanetaryOrbit.VenusMeanLongitudeJ2000(jd)
    case .KPCAAPlanetStrictEarth: return CAAElementsPlanetaryOrbit.EarthMeanLongitudeJ2000(jd)
    case .KPCAAPlanetStrictMars: return CAAElementsPlanetaryOrbit.MarsMeanLongitudeJ2000(jd)
    case .KPCAAPlanetStrictJupiter: return CAAElementsPlanetaryOrbit.JupiterMeanLongitudeJ2000(jd)
    case .KPCAAPlanetStrictSaturn: return CAAElementsPlanetaryOrbit.SaturnMeanLongitudeJ2000(jd)
    case .KPCAAPlanetStrictUranus: return CAAElementsPlanetaryOrbit.UranusMeanLongitudeJ2000(jd)
    case .KPCAAPlanetStrictNeptune: return CAAElementsPlanetaryOrbit.NeptuneMeanLongitudeJ2000(jd)
    default: return 0
    }
}

func orbitSemimajorAxis(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAElementsPlanetaryOrbit.MercurySemimajorAxis(jd)
    case .KPCAAPlanetStrictVenus: return CAAElementsPlanetaryOrbit.VenusSemimajorAxis(jd)
    case .KPCAAPlanetStrictEarth: return CAAElementsPlanetaryOrbit.EarthSemimajorAxis(jd)
    case .KPCAAPlanetStrictMars: return CAAElementsPlanetaryOrbit.MarsSemimajorAxis(jd)
    case .KPCAAPlanetStrictJupiter: return CAAElementsPlanetaryOrbit.JupiterSemimajorAxis(jd)
    case .KPCAAPlanetStrictSaturn: return CAAElementsPlanetaryOrbit.SaturnSemimajorAxis(jd)
    case .KPCAAPlanetStrictUranus: return CAAElementsPlanetaryOrbit.UranusSemimajorAxis(jd)
    case .KPCAAPlanetStrictNeptune: return CAAElementsPlanetaryOrbit.NeptuneSemimajorAxis(jd)
    default: return 0
    }
}

func orbitEccentricity(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAElementsPlanetaryOrbit.MercuryEccentricity(jd)
    case .KPCAAPlanetStrictVenus: return CAAElementsPlanetaryOrbit.VenusEccentricity(jd)
    case .KPCAAPlanetStrictEarth: return CAAElementsPlanetaryOrbit.EarthEccentricity(jd)
    case .KPCAAPlanetStrictMars: return CAAElementsPlanetaryOrbit.MarsEccentricity(jd)
    case .KPCAAPlanetStrictJupiter: return CAAElementsPlanetaryOrbit.JupiterEccentricity(jd)
    case .KPCAAPlanetStrictSaturn: return CAAElementsPlanetaryOrbit.SaturnEccentricity(jd)
    case .KPCAAPlanetStrictUranus: return CAAElementsPlanetaryOrbit.UranusEccentricity(jd)
    case .KPCAAPlanetStrictNeptune: return CAAElementsPlanetaryOrbit.NeptuneEccentricity(jd)
    default: return 0
    }
}

func orbitInclination(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAElementsPlanetaryOrbit.MercuryInclination(jd)
    case .KPCAAPlanetStrictVenus: return CAAElementsPlanetaryOrbit.VenusInclination(jd)
    case .KPCAAPlanetStrictEarth: return CAAElementsPlanetaryOrbit.EarthInclination(jd)
    case .KPCAAPlanetStrictMars: return CAAElementsPlanetaryOrbit.MarsInclination(jd)
    case .KPCAAPlanetStrictJupiter: return CAAElementsPlanetaryOrbit.JupiterInclination(jd)
    case .KPCAAPlanetStrictSaturn: return CAAElementsPlanetaryOrbit.SaturnInclination(jd)
    case .KPCAAPlanetStrictUranus: return CAAElementsPlanetaryOrbit.UranusInclination(jd)
    case .KPCAAPlanetStrictNeptune: return CAAElementsPlanetaryOrbit.NeptuneInclination(jd)
    default: return 0
    }
}

func orbitInclinationJ2000(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAElementsPlanetaryOrbit.MercuryInclinationJ2000(jd)
    case .KPCAAPlanetStrictVenus: return CAAElementsPlanetaryOrbit.VenusInclinationJ2000(jd)
    case .KPCAAPlanetStrictEarth: return CAAElementsPlanetaryOrbit.EarthInclinationJ2000(jd)
    case .KPCAAPlanetStrictMars: return CAAElementsPlanetaryOrbit.MarsInclinationJ2000(jd)
    case .KPCAAPlanetStrictJupiter: return CAAElementsPlanetaryOrbit.JupiterInclinationJ2000(jd)
    case .KPCAAPlanetStrictSaturn: return CAAElementsPlanetaryOrbit.SaturnInclinationJ2000(jd)
    case .KPCAAPlanetStrictUranus: return CAAElementsPlanetaryOrbit.UranusInclinationJ2000(jd)
    case .KPCAAPlanetStrictNeptune: return CAAElementsPlanetaryOrbit.NeptuneInclinationJ2000(jd)
    default: return 0
    }
}

func orbitLongitudeAscendingNode(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAElementsPlanetaryOrbit.MercuryLongitudeAscendingNode(jd)
    case .KPCAAPlanetStrictVenus: return CAAElementsPlanetaryOrbit.VenusLongitudeAscendingNode(jd)
    case .KPCAAPlanetStrictEarth: return 0.0
    case .KPCAAPlanetStrictMars: return CAAElementsPlanetaryOrbit.MarsLongitudeAscendingNode(jd)
    case .KPCAAPlanetStrictJupiter: return CAAElementsPlanetaryOrbit.JupiterLongitudeAscendingNode(jd)
    case .KPCAAPlanetStrictSaturn: return CAAElementsPlanetaryOrbit.SaturnLongitudeAscendingNode(jd)
    case .KPCAAPlanetStrictUranus: return CAAElementsPlanetaryOrbit.UranusLongitudeAscendingNode(jd)
    case .KPCAAPlanetStrictNeptune: return CAAElementsPlanetaryOrbit.NeptuneLongitudeAscendingNode(jd)
    default: return 0
    }
}

func orbitLongitudeAscendingNodeJ2000(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAElementsPlanetaryOrbit.MercuryLongitudeAscendingNodeJ2000(jd)
    case .KPCAAPlanetStrictVenus: return CAAElementsPlanetaryOrbit.VenusLongitudeAscendingNodeJ2000(jd)
    case .KPCAAPlanetStrictEarth: return CAAElementsPlanetaryOrbit.EarthLongitudeAscendingNodeJ2000(jd)
    case .KPCAAPlanetStrictMars: return CAAElementsPlanetaryOrbit.MarsLongitudeAscendingNodeJ2000(jd)
    case .KPCAAPlanetStrictJupiter: return CAAElementsPlanetaryOrbit.JupiterLongitudeAscendingNodeJ2000(jd)
    case .KPCAAPlanetStrictSaturn: return CAAElementsPlanetaryOrbit.SaturnLongitudeAscendingNodeJ2000(jd)
    case .KPCAAPlanetStrictUranus: return CAAElementsPlanetaryOrbit.UranusLongitudeAscendingNodeJ2000(jd)
    case .KPCAAPlanetStrictNeptune: return CAAElementsPlanetaryOrbit.NeptuneLongitudeAscendingNodeJ2000(jd)
    default: return 0
    }
}

func orbitLongitudePerihelion(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAElementsPlanetaryOrbit.MercuryLongitudePerihelion(jd)
    case .KPCAAPlanetStrictVenus: return CAAElementsPlanetaryOrbit.VenusLongitudePerihelion(jd)
    case .KPCAAPlanetStrictEarth: return CAAElementsPlanetaryOrbit.EarthLongitudePerihelion(jd)
    case .KPCAAPlanetStrictMars: return CAAElementsPlanetaryOrbit.MarsLongitudePerihelion(jd)
    case .KPCAAPlanetStrictJupiter: return CAAElementsPlanetaryOrbit.JupiterLongitudePerihelion(jd)
    case .KPCAAPlanetStrictSaturn: return CAAElementsPlanetaryOrbit.SaturnLongitudePerihelion(jd)
    case .KPCAAPlanetStrictUranus: return CAAElementsPlanetaryOrbit.UranusLongitudePerihelion(jd)
    case .KPCAAPlanetStrictNeptune: return CAAElementsPlanetaryOrbit.NeptuneLongitudePerihelion(jd)
    default: return 0
    }
}

func orbitLongitudePerihelionJ2000(_ planet: KPCAAPlanetStrict, jd: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAElementsPlanetaryOrbit.MercuryLongitudePerihelionJ2000(jd)
    case .KPCAAPlanetStrictVenus: return CAAElementsPlanetaryOrbit.VenusLongitudePerihelionJ2000(jd)
    case .KPCAAPlanetStrictEarth: return CAAElementsPlanetaryOrbit.EarthLongitudePerihelionJ2000(jd)
    case .KPCAAPlanetStrictMars: return CAAElementsPlanetaryOrbit.MarsLongitudePerihelionJ2000(jd)
    case .KPCAAPlanetStrictJupiter: return CAAElementsPlanetaryOrbit.JupiterLongitudePerihelionJ2000(jd)
    case .KPCAAPlanetStrictSaturn: return CAAElementsPlanetaryOrbit.SaturnLongitudePerihelionJ2000(jd)
    case .KPCAAPlanetStrictUranus: return CAAElementsPlanetaryOrbit.UranusLongitudePerihelionJ2000(jd)
    case .KPCAAPlanetStrictNeptune: return CAAElementsPlanetaryOrbit.NeptuneLongitudePerihelionJ2000(jd)
    default: return 0
    }
}

func calculateObjectDetailsNoElements(jd: Double, planetStrict: KPCAAPlanetStrict, highPrecision: Bool) -> CAAEllipticalObjectDetails {
    var elements = CAAEllipticalObjectElements()
    elements.a = orbitSemimajorAxis(planetStrict, jd: jd)
    elements.e = orbitEccentricity(planetStrict, jd: jd)
    elements.i = orbitInclination(planetStrict, jd: jd)
    elements.w = orbitLongitudePerihelion(planetStrict, jd: jd)
    elements.omega = orbitLongitudeAscendingNode(planetStrict, jd: jd)
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
