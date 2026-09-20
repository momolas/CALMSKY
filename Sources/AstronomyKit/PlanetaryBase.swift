//
//  EclipticObject.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 19/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

enum PlanetError: Error {
    case invalidSubtype
    case invalidCase
}

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

func planetPerihelionK(_ planet: KPCAAPlanetStrict, year: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAPlanetPerihelionAphelion.MercuryK(year)
    case .KPCAAPlanetStrictVenus: return CAAPlanetPerihelionAphelion.VenusK(year)
    case .KPCAAPlanetStrictEarth: return CAAPlanetPerihelionAphelion.EarthK(year)
    case .KPCAAPlanetStrictMars: return CAAPlanetPerihelionAphelion.MarsK(year)
    case .KPCAAPlanetStrictJupiter: return CAAPlanetPerihelionAphelion.JupiterK(year)
    case .KPCAAPlanetStrictSaturn: return CAAPlanetPerihelionAphelion.SaturnK(year)
    case .KPCAAPlanetStrictUranus: return CAAPlanetPerihelionAphelion.UranusK(year)
    case .KPCAAPlanetStrictNeptune: return CAAPlanetPerihelionAphelion.NeptuneK(year)
    default: return 0
    }
}

func planetPerihelion(_ planet: KPCAAPlanetStrict, k: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAPlanetPerihelionAphelion.Mercury(k)
    case .KPCAAPlanetStrictVenus: return CAAPlanetPerihelionAphelion.Venus(k)
    case .KPCAAPlanetStrictEarth: return CAAPlanetPerihelionAphelion.EarthPerihelion(k, false)
    case .KPCAAPlanetStrictMars: return CAAPlanetPerihelionAphelion.Mars(k)
    case .KPCAAPlanetStrictJupiter: return CAAPlanetPerihelionAphelion.Jupiter(k)
    case .KPCAAPlanetStrictSaturn: return CAAPlanetPerihelionAphelion.Saturn(k)
    case .KPCAAPlanetStrictUranus: return CAAPlanetPerihelionAphelion.Uranus(k)
    case .KPCAAPlanetStrictNeptune: return CAAPlanetPerihelionAphelion.Neptune(k)
    default: return 0
    }
}

func planetAphelion(_ planet: KPCAAPlanetStrict, k: Double) -> Double {
    switch planet {
    case .KPCAAPlanetStrictMercury: return CAAPlanetPerihelionAphelion.Mercury(k)
    case .KPCAAPlanetStrictVenus: return CAAPlanetPerihelionAphelion.Venus(k)
    case .KPCAAPlanetStrictEarth: return CAAPlanetPerihelionAphelion.EarthAphelion(k, false)
    case .KPCAAPlanetStrictMars: return CAAPlanetPerihelionAphelion.Mars(k)
    case .KPCAAPlanetStrictJupiter: return CAAPlanetPerihelionAphelion.Jupiter(k)
    case .KPCAAPlanetStrictSaturn: return CAAPlanetPerihelionAphelion.Saturn(k)
    case .KPCAAPlanetStrictUranus: return CAAPlanetPerihelionAphelion.Uranus(k)
    case .KPCAAPlanetStrictNeptune: return CAAPlanetPerihelionAphelion.Neptune(k)
    default: return 0
    }
}

func planetRadiusVector(_ planet: KPCAAPlanet, jd: Double, highPrecision: Bool) -> Double {
    switch planet {
    case .KPCAAPlanetMercury: return CAAMercury.RadiusVector(jd, highPrecision)
    case .KPCAAPlanetVenus: return CAAVenus.RadiusVector(jd, highPrecision)
    case .KPCAAPlanetEarth: return CAAEarth.RadiusVector(jd, highPrecision)
    case .KPCAAPlanetMars: return CAAMars.RadiusVector(jd, highPrecision)
    case .KPCAAPlanetJupiter: return CAAJupiter.RadiusVector(jd, highPrecision)
    case .KPCAAPlanetSaturn: return CAASaturn.RadiusVector(jd, highPrecision)
    case .KPCAAPlanetUranus: return CAAUranus.RadiusVector(jd, highPrecision)
    case .KPCAAPlanetNeptune: return CAANeptune.RadiusVector(jd, highPrecision)
    case .KPCAAPlanetPluto: return CAAPluto.RadiusVector(jd)
    default: return 0
    }
}

func planetEclipticLongitude(_ planet: KPCAAPlanet, jd: Double, highPrecision: Bool) -> Double {
    switch planet {
    case .KPCAAPlanetMercury: return CAAMercury.EclipticLongitude(jd, highPrecision)
    case .KPCAAPlanetVenus: return CAAVenus.EclipticLongitude(jd, highPrecision)
    case .KPCAAPlanetEarth: return CAAEarth.EclipticLongitude(jd, highPrecision)
    case .KPCAAPlanetMars: return CAAMars.EclipticLongitude(jd, highPrecision)
    case .KPCAAPlanetJupiter: return CAAJupiter.EclipticLongitude(jd, highPrecision)
    case .KPCAAPlanetSaturn: return CAASaturn.EclipticLongitude(jd, highPrecision)
    case .KPCAAPlanetUranus: return CAAUranus.EclipticLongitude(jd, highPrecision)
    case .KPCAAPlanetNeptune: return CAANeptune.EclipticLongitude(jd, highPrecision)
    case .KPCAAPlanetPluto: return CAAPluto.EclipticLongitude(jd)
    default: return 0
    }
}

func planetEclipticLatitude(_ planet: KPCAAPlanet, jd: Double, highPrecision: Bool) -> Double {
    switch planet {
    case .KPCAAPlanetMercury: return CAAMercury.EclipticLatitude(jd, highPrecision)
    case .KPCAAPlanetVenus: return CAAVenus.EclipticLatitude(jd, highPrecision)
    case .KPCAAPlanetEarth: return CAAEarth.EclipticLatitude(jd, highPrecision)
    case .KPCAAPlanetMars: return CAAMars.EclipticLatitude(jd, highPrecision)
    case .KPCAAPlanetJupiter: return CAAJupiter.EclipticLatitude(jd, highPrecision)
    case .KPCAAPlanetSaturn: return CAASaturn.EclipticLatitude(jd, highPrecision)
    case .KPCAAPlanetUranus: return CAAUranus.EclipticLatitude(jd, highPrecision)
    case .KPCAAPlanetNeptune: return CAANeptune.EclipticLatitude(jd, highPrecision)
    case .KPCAAPlanetPluto: return CAAPluto.EclipticLatitude(jd)
    default: return 0
    }
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
        get {
            let fractionalYear = CAADate(self.julianDay.value, true).FractionalYear()
            let k = planetPerihelionK(self.planetStrict, year: fractionalYear).rounded()
            return JulianDay(planetPerihelion(self.planetStrict, k: k))
        }
    }
    
    /// The julian day of the aphelion of the planet the after the given julian day of the object.
    var aphelion: JulianDay {
        get {
            let fractionalYear = CAADate(self.julianDay.value, true).FractionalYear()
            let k = planetPerihelionK(self.planetStrict, year: fractionalYear).rounded() + 0.5
            return JulianDay(planetAphelion(self.planetStrict, k: k))
        }
    }
    
    /// The distance to the Sun.
    var radiusVector: AstronomicalUnit {
        get { return AstronomicalUnit(planetRadiusVector(self.planet, jd: self.julianDay.value, highPrecision: self.highPrecision)) }
    }
}


