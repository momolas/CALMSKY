//
//  EllipticalDetails.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 20/09/2016.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

enum InvalidParameterError: Error {
    case invalidPlanet(KPCAAPlanet)
}

func planetEquatorialSemiDiameterA(_ planet: KPCAAPlanetStrict, delta: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAADiameters.MercurySemidiameterA(delta)
    case .KPCAAPlanetStrictVenus: return CAADiameters.VenusSemidiameterA(delta)
    case .KPCAAPlanetStrictMars: return CAADiameters.MarsSemidiameterA(delta)
    case .KPCAAPlanetStrictJupiter: return CAADiameters.JupiterEquatorialSemidiameterA(delta)
    case .KPCAAPlanetStrictSaturn: return CAADiameters.SaturnEquatorialSemidiameterA(delta)
    case .KPCAAPlanetStrictUranus: return CAADiameters.UranusSemidiameterA(delta)
    case .KPCAAPlanetStrictNeptune: return CAADiameters.NeptuneSemidiameterA(delta)
    default: return 0
    }
}

func planetEquatorialSemiDiameterB(_ planet: KPCAAPlanet, delta: Double) -> Double {
    switch planet {
    case .KPCAAPlanetMercury: return CAADiameters.MercurySemidiameterB(delta)
    case .KPCAAPlanetVenus: return CAADiameters.VenusSemidiameterB(delta)
    case .KPCAAPlanetMars: return CAADiameters.MarsSemidiameterB(delta)
    case .KPCAAPlanetJupiter: return CAADiameters.JupiterEquatorialSemidiameterB(delta)
    case .KPCAAPlanetSaturn: return CAADiameters.SaturnEquatorialSemidiameterB(delta)
    case .KPCAAPlanetUranus: return CAADiameters.UranusSemidiameterB(delta)
    case .KPCAAPlanetNeptune: return CAADiameters.NeptuneSemidiameterB(delta)
    case .KPCAAPlanetPluto: return CAADiameters.PlutoSemidiameterB(delta)
    default: return 0
    }
}

func planetPolarSemiDiameterA(_ planet: KPCAAPlanetStrict, delta: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAADiameters.MercurySemidiameterA(delta)
    case .KPCAAPlanetStrictVenus: return CAADiameters.VenusSemidiameterA(delta)
    case .KPCAAPlanetStrictMars: return CAADiameters.MarsSemidiameterA(delta)
    case .KPCAAPlanetStrictJupiter: return CAADiameters.JupiterPolarSemidiameterA(delta)
    case .KPCAAPlanetStrictSaturn: return CAADiameters.SaturnPolarSemidiameterA(delta)
    case .KPCAAPlanetStrictUranus: return CAADiameters.UranusSemidiameterA(delta)
    case .KPCAAPlanetStrictNeptune: return CAADiameters.NeptuneSemidiameterA(delta)
    default: return 0
    }
}

func planetPolarSemiDiameterB(_ planet: KPCAAPlanet, delta: Double) -> Double {
    switch planet {
    case .KPCAAPlanetMercury: return CAADiameters.MercurySemidiameterB(delta)
    case .KPCAAPlanetVenus: return CAADiameters.VenusSemidiameterB(delta)
    case .KPCAAPlanetMars: return CAADiameters.MarsSemidiameterB(delta)
    case .KPCAAPlanetJupiter: return CAADiameters.JupiterPolarSemidiameterB(delta)
    case .KPCAAPlanetSaturn: return CAADiameters.SaturnPolarSemidiameterB(delta)
    case .KPCAAPlanetUranus: return CAADiameters.UranusSemidiameterB(delta)
    case .KPCAAPlanetNeptune: return CAADiameters.NeptuneSemidiameterB(delta)
    case .KPCAAPlanetPluto: return CAADiameters.PlutoSemidiameterB(delta)
    default: return 0
    }
}

func planetMagnitudeAA(_ object: KPCPlanetaryObject, r: Double, delta: Double, i: Double) -> Double {
    switch object {
    case .KPCPlanetaryObjectMERCURY: return CAAIlluminatedFraction.MercuryMagnitudeAA(r, delta, i)
    case .KPCPlanetaryObjectVENUS: return CAAIlluminatedFraction.VenusMagnitudeAA(r, delta, i)
    case .KPCPlanetaryObjectMARS: return CAAIlluminatedFraction.MarsMagnitudeAA(r, delta, i)
    case .KPCPlanetaryObjectJUPITER: return CAAIlluminatedFraction.JupiterMagnitudeAA(r, delta, i)
    case .KPCPlanetaryObjectSATURN: return CAAIlluminatedFraction.SaturnMagnitudeAA(r, delta, 0, 0)
    case .KPCPlanetaryObjectURANUS: return CAAIlluminatedFraction.UranusMagnitudeAA(r, delta)
    case .KPCPlanetaryObjectNEPTUNE: return CAAIlluminatedFraction.NeptuneMagnitudeAA(r, delta)
    default: return 0
    }
}

func planetMagnitudeMuller(_ object: KPCPlanetaryObject, r: Double, delta: Double, i: Double) -> Double {
    switch object {
    case .KPCPlanetaryObjectMERCURY: return CAAIlluminatedFraction.MercuryMagnitudeMuller(r, delta, i)
    case .KPCPlanetaryObjectVENUS: return CAAIlluminatedFraction.VenusMagnitudeMuller(r, delta, i)
    case .KPCPlanetaryObjectMARS: return CAAIlluminatedFraction.MarsMagnitudeMuller(r, delta, i)
    case .KPCPlanetaryObjectJUPITER: return CAAIlluminatedFraction.JupiterMagnitudeMuller(r, delta)
    case .KPCPlanetaryObjectSATURN: return CAAIlluminatedFraction.SaturnMagnitudeMuller(r, delta, 0, 0)
    case .KPCPlanetaryObjectURANUS: return CAAIlluminatedFraction.UranusMagnitudeMuller(r, delta)
    case .KPCPlanetaryObjectNEPTUNE: return CAAIlluminatedFraction.NeptuneMagnitudeMuller(r, delta)
    default: return 0
    }
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
                                                              Earth(julianDay: self.julianDay).radiusVector.value,
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
