//
//  EllipticalDetails.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 20/09/2016.
//  MIT Licence. See LICENCE file.
//

import Foundation

enum InvalidParameterError: Error {
    case invalidPlanet(KPCAAPlanet)
}

@inlinable
func planetEquatorialSemiDiameterA(_ planet: KPCAAPlanetStrict, delta: Double) -> Double {
    CAADiameters.equatorialSemidiameterA(for: planet, delta: delta)
}

@inlinable
func planetEquatorialSemiDiameterB(_ planet: KPCAAPlanet, delta: Double) -> Double {
    CAADiameters.equatorialSemidiameterB(for: planet, delta: delta)
}

@inlinable
func planetPolarSemiDiameterA(_ planet: KPCAAPlanetStrict, delta: Double) -> Double {
    CAADiameters.polarSemidiameterA(for: planet, delta: delta)
}

@inlinable
func planetPolarSemiDiameterB(_ planet: KPCAAPlanet, delta: Double) -> Double {
    CAADiameters.polarSemidiameterB(for: planet, delta: delta)
}

@inlinable
func planetMagnitudeAA(_ object: KPCPlanetaryObject, r: Double, delta: Double, i: Double) -> Double {
    CAAIlluminatedFraction.magnitudeAA(for: object, r: r, delta: delta, i: i)
}

@inlinable
func planetMagnitudeMuller(_ object: KPCPlanetaryObject, r: Double, delta: Double, i: Double) -> Double {
    CAAIlluminatedFraction.magnitudeMuller(for: object, r: r, delta: delta, i: i)
}

/// The EllipticalPlanetaryDetails encompasses various elliptical details of solar-system planets.
public protocol PlanetaryDetails: PlanetaryBase {
    /// The details of the planet configuration
    var allPlanetaryDetails: CAAEllipticalPlanetaryDetails { get }
        
    /// Useful named accessors:
 
    /// The apparent geocentric distance
    var apparentGeocentricDistance: AstronomicalUnit { get }
        
    /// The phase angle, that is the angle (Sun-planet-Earth).
    var phaseAngle: Degree { get }
    
    /// The illuminated fraction of the planet as seen from the Earth. Between 0 and 1.
    var illuminatedFraction: Double { get }
    
    /// The magnitude of the planet, which depends on the planet's distance to the Earth,
    /// its distance to the Sun and the phase angle i (Sun-planet-Earth).
    /// Implementation return the modern American Astronomical Almanac value instead of Mueller's
    var magnitude: Magnitude { get }
    
    /// The magnitude of the planet, which depends on the planet's distance to the Earth,
    /// its distance to the Sun and the phase angle i (Sun-planet-Earth).
    /// Implementation return the old Muller's values.
    var magnitudeMuller: Magnitude { get }

    /// The equatorial semi diameter of the planet. Note that values of the Astronomical Almanac of 1984 are returned.
    /// There are also older values (1980) named "A" values. In the case of Venus, the "B" value refers to the planet's
    /// crust, while the "A" value refers to the top of the cloud level. The latter is more relevant for astronomical
    /// phenomena such as transits and occultations.
    func equatorialSemiDiameter(usingOldValues: Bool) throws -> ArcSecond

    /// The polar semi diameter of the planet. See `equatorialSemiDiameter` about "A" et "B" values.
    /// Note that for all planets but Jupiter and Saturn, the polarSemiDiameter is identical to the equatorial one.
    func polarSemiDiameter(usingOldValues: Bool) throws -> ArcSecond
}

public extension PlanetaryDetails {
    
    var apparentGeocentricDistance: AstronomicalUnit {
        get { return AstronomicalUnit(self.allPlanetaryDetails.ApparentGeocentricDistance) }
    }
        
    /// The phase angle, that is the angle (Sun-planet-Earth).
    var phaseAngle: Degree {
        get { return Degree(CAAIlluminatedFraction.PhaseAngle(self.radiusVector.value,
                                                              CAAEarth.radiusVector(self.julianDay.value, self.highPrecision),
                                                              self.apparentGeocentricDistance.value)) }
    }
    
    var illuminatedFraction: Double {
        get { return CAAIlluminatedFraction.IlluminatedFraction(self.phaseAngle.value) }
    }

    /// The magnitude of the planet, which depends on the planet's distance to the Earth,
    /// its distance to the Sun and the phase angle i (Sun-planet-Earth).
    /// Implementation return the modern American Astronomical Almanac value instead of Mueller's
    var magnitude: Magnitude {
        get { return Magnitude(planetMagnitudeAA(self.planetaryObject,
                                                 r: self.radiusVector.value,
                                                 delta: self.apparentGeocentricDistance.value,
                                                 i: self.phaseAngle.value)) }
    }
    
    /// The magnitude of the planet, which depends on the planet's distance to the Earth,
    /// its distance to the Sun and the phase angle i (Sun-planet-Earth).
    /// Implementation return the old Muller's values.
    var magnitudeMuller: Magnitude {
        get { return Magnitude(planetMagnitudeMuller(self.planetaryObject,
                                                     r: self.radiusVector.value,
                                                     delta: self.apparentGeocentricDistance.value,
                                                     i: self.phaseAngle.value)) }
    }
    /// The apparent equatorial coordinates of the planet. That is, its apparent position on the celestial sphere, as
    /// it is actually seen from the center of the moving Earth, and referred to the instantaneous equator, ecliptic
    /// and equinox.
    /// It accounts for 1) the effect of light-time and 2) the effect of the Earth motion. See AA p224.
    var apparentGeocentricEquatorialCoordinates: EquatorialCoordinates {
        get {
            let ra = Hour(self.allPlanetaryDetails.ApparentGeocentricRA)
            let dec = Degree(self.allPlanetaryDetails.ApparentGeocentricDeclination)
            return EquatorialCoordinates(alpha: ra,
                                         delta: dec,
                                         epoch: .epochOfTheDate(self.julianDay),
                                         equinox: .meanEquinoxOfTheDate(self.julianDay))
        }
    }
    
    /// The equatorial semi diameter of the object
    func equatorialSemiDiameter(usingOldValues: Bool = false) throws -> ArcSecond {
        guard self.planet != .KPCAAPlanetPluto else {
            throw InvalidParameterError.invalidPlanet(self.planet)
        }
        if (usingOldValues) {
            return ArcSecond(planetEquatorialSemiDiameterA(self.planetStrict, delta: self.apparentGeocentricDistance.value))
        } else {
            return ArcSecond(planetEquatorialSemiDiameterB(self.planet, delta: self.apparentGeocentricDistance.value))
        }
    }
    
    /// The polar semi diameter of the object.
    func polarSemiDiameter(usingOldValues: Bool = false) throws -> ArcSecond {
        guard self.planet != .KPCAAPlanetPluto else {
            throw InvalidParameterError.invalidPlanet(self.planet)
        }
        if (usingOldValues) {
            return ArcSecond(planetPolarSemiDiameterA(self.planetStrict, delta: self.apparentGeocentricDistance.value))
        } else {
            return ArcSecond(planetPolarSemiDiameterB(self.planet, delta: self.apparentGeocentricDistance.value))
        }
    }
    
}
