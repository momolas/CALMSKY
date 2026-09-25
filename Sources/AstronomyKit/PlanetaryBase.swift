//
//  EclipticObject.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 19/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation

// MARK: -

/// The PlanetaryBase extends the simple ObjectBase protocol to provide specific accesors for solar-system planets.
public protocol PlanetaryBase: ObjectBase {
    
    /// The index of the planet in the historical list of all 9 planets: from Mercury to Pluto, including the Earth.
    var planet: KPCAAPlanet { get }
    
    /// The index of the planet in the official list of 8 planets, that is, not accounting the dwarf planet, Pluto.
    var planetStrict: KPCAAPlanetStrict { get }
    
    /// The index of the planet in the list of all planets, but the Earth and Pluto.
    var planetaryObject: KPCPlanetaryObject { get }
    
    /// The index of the planet in the list of all elliptical objects, that is the Sun, all Planets but Earth, and including Pluto.
    var ellipticalObject: KPCAAEllipticalObject { get }
    
    /// The julian day of the perihelion of the planet after the given julian day of the object.
    var perihelion: JulianDay { get }
    
    /// The julian day of the aphelion of the planet after the given julian day of the object.
    var aphelion: JulianDay { get }
    
    /// The distance to the Sun.
    var radiusVector: AstronomicalUnit { get }
}

// MARK: -

@inlinable
func toEllipticalObject(_ object: KPCAAEllipticalObject) -> CAAElliptical.Object {
    switch object {
    case .KPCAAEllipticalObjectSUN: return .SUN
    case .KPCAAEllipticalObjectMERCURY: return .MERCURY
    case .KPCAAEllipticalObjectVENUS: return .VENUS
    case .KPCAAEllipticalObjectMARS: return .MARS
    case .KPCAAEllipticalObjectJUPITER: return .JUPITER
    case .KPCAAEllipticalObjectSATURN: return .SATURN
    case .KPCAAEllipticalObjectURANUS: return .URANUS
    case .KPCAAEllipticalObjectNEPTUNE: return .NEPTUNE
    default: return .MERCURY
    }
}

@inlinable
func toPhenomenaPlanet(_ object: KPCPlanetaryObject) -> CAAPlanetaryPhenomena.Planet {
    switch object {
    case .KPCPlanetaryObjectMERCURY: return .MERCURY
    case .KPCPlanetaryObjectVENUS: return .VENUS
    case .KPCPlanetaryObjectMARS: return .MARS
    case .KPCPlanetaryObjectJUPITER: return .JUPITER
    case .KPCPlanetaryObjectSATURN: return .SATURN
    case .KPCPlanetaryObjectURANUS: return .URANUS
    case .KPCPlanetaryObjectNEPTUNE: return .NEPTUNE
    default: return .MERCURY
    }
}

@inlinable
func planetPerihelionK(_ planet: KPCAAPlanetStrict, year: Double) -> Double {
    CAAPlanetPerihelionAphelion.k(for: planet, year: year)
}

@inlinable
func planetPerihelion(_ planet: KPCAAPlanetStrict, k: Double) -> Double {
    CAAPlanetPerihelionAphelion.perihelion(for: planet, k: k)
}

@inlinable
func planetAphelion(_ planet: KPCAAPlanetStrict, k: Double) -> Double {
    CAAPlanetPerihelionAphelion.aphelion(for: planet, k: k)
}

@inlinable
func planetHeliocentricCoordinates(_ planet: KPCAAPlanet, jd: Double) -> (longitude: Double, latitude: Double, radius: Double) {
    NASAJPLPlanets.coordinates(for: planet, jd: jd)
}

@inlinable
func planetRadiusVector(_ planet: KPCAAPlanet, jd: Double, highPrecision: Bool = true) -> Double {
    planetHeliocentricCoordinates(planet, jd: jd).radius
}

@inlinable
func planetEclipticLongitude(_ planet: KPCAAPlanet, jd: Double, highPrecision: Bool = true) -> Double {
    planetHeliocentricCoordinates(planet, jd: jd).longitude
}

@inlinable
func planetEclipticLatitude(_ planet: KPCAAPlanet, jd: Double, highPrecision: Bool = true) -> Double {
    planetHeliocentricCoordinates(planet, jd: jd).latitude
}


public extension PlanetaryBase {
    
    /// The index of the planet in the historical list of all 9 planets: from Mercury to Pluto, including the Earth.
    var planet: KPCAAPlanet {
        return KPCAAPlanet.fromString(self.name)
    }
    
    /// The index of the planet in the official list of 8 planets, that is, not accounting the dwarf planet, Pluto.
    var planetStrict: KPCAAPlanetStrict {
        return KPCAAPlanetStrict.fromPlanet(self.planet)
    }
    
    /// The index of the planet in the list of all planets, but the Earth.
    var planetaryObject: KPCPlanetaryObject {
        return KPCPlanetaryObject.fromPlanet(self.planet)
    }
    
    /// The index of the planet in the list of all elliptical objects, that is all Planets but Earth, but including Pluto.
    var ellipticalObject: KPCAAEllipticalObject {
        return KPCAAEllipticalObject.fromPlanet(self.planet)
    }
    
    /// The julian day of the perihelion of the planet the after the given julian day of the object.
    var perihelion: JulianDay {
        let fractionalYear = CAADate(self.julianDay.value, true).FractionalYear()
        let k = CAAPlanetPerihelionAphelion.k(for: self.planetStrict, year: fractionalYear).rounded()
        return JulianDay(CAAPlanetPerihelionAphelion.perihelion(for: self.planetStrict, k: k))
    }
    
    /// The julian day of the aphelion of the planet the after the given julian day of the object.
    var aphelion: JulianDay {
        let fractionalYear = CAADate(self.julianDay.value, true).FractionalYear()
        let k = CAAPlanetPerihelionAphelion.k(for: self.planetStrict, year: fractionalYear).rounded() + 0.5
        return JulianDay(CAAPlanetPerihelionAphelion.aphelion(for: self.planetStrict, k: k))
    }
    
    /// The distance to the Sun.
    var radiusVector: AstronomicalUnit {
        get { return AstronomicalUnit(planetRadiusVector(self.planet, jd: self.julianDay.value, highPrecision: self.highPrecision)) }
    }
}


