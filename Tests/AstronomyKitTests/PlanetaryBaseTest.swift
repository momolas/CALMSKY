//
//  PlanetaryBaseTest.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 17/12/2016.
//  MIT Licence. See LICENCE file.
//

import Testing
@testable import AstronomyKit

@Suite("PlanetaryBaseTest")
struct PlanetaryBaseTest {
    var jd: JulianDay = 0.0

    @Test("Planet Basic")
    func testPlanetBasic() {
        #expect(Planet.averageColor == CelestialColor.white)
    }
    
    @Test("Mercury Types")
    func testMercuryTypes() {
        let mercury = Mercury(julianDay: self.jd)
        #expect(mercury.name == "Mercury")
        #expect(mercury.planet == KPCAAPlanetMercury)
        #expect(mercury.planetStrict == KPCAAPlanetStrictMercury)
        #expect(mercury.planetaryObject == KPCPlanetaryObjectMERCURY)
    }

    @Test("Venus Types")
    func testVenusTypes() {
        let venus = Venus(julianDay: self.jd)
        #expect(venus.name == "Venus")
        #expect(venus.planet == KPCAAPlanetVenus)
        #expect(venus.planetStrict == KPCAAPlanetStrictVenus)
        #expect(venus.planetaryObject == KPCPlanetaryObjectVENUS)
    }

    @Test("Earth Types")
    func testEarthTypes() {
        let earth = Earth(julianDay: self.jd)
        #expect(earth.name == "Earth")
        #expect(earth.planet == KPCAAPlanetEarth)
        #expect(earth.planetStrict == KPCAAPlanetStrictEarth)
        #expect(earth.planetaryObject == KPCPlanetaryObjectUNDEFINED) // <-- yes, UNDEFINED.
    }

    @Test("Mars Types")
    func testMarsTypes() {
        let mars = Mars(julianDay: self.jd)
        #expect(mars.name == "Mars")
        #expect(mars.planet == KPCAAPlanetMars)
        #expect(mars.planetStrict == KPCAAPlanetStrictMars)
        #expect(mars.planetaryObject == KPCPlanetaryObjectMARS)
    }

    @Test("Jupiter Types")
    func testJupiterTypes() {
        let jupiter = Jupiter(julianDay: self.jd)
        #expect(jupiter.name == "Jupiter")
        #expect(jupiter.planet == KPCAAPlanetJupiter)
        #expect(jupiter.planetStrict == KPCAAPlanetStrictJupiter)
        #expect(jupiter.planetaryObject == KPCPlanetaryObjectJUPITER)
    }

    @Test("Saturn Types")
    func testSaturnTypes() {
        let saturn = Saturn(julianDay: self.jd)
        #expect(saturn.name == "Saturn")
        #expect(saturn.planet == KPCAAPlanetSaturn)
        #expect(saturn.planetStrict == KPCAAPlanetStrictSaturn)
        #expect(saturn.planetaryObject == KPCPlanetaryObjectSATURN)
    }

    @Test("Uranus Types")
    func testUranusTypes() {
        let uranus = Uranus(julianDay: self.jd)
        #expect(uranus.name == "Uranus")
        #expect(uranus.planet == KPCAAPlanetUranus)
        #expect(uranus.planetStrict == KPCAAPlanetStrictUranus)
        #expect(uranus.planetaryObject == KPCPlanetaryObjectURANUS)
    }

    @Test("Neptune Types")
    func testNeptuneTypes() {
        let neptune = Neptune(julianDay: self.jd)
        #expect(neptune.name == "Neptune")
        #expect(neptune.planet == KPCAAPlanetNeptune)
        #expect(neptune.planetStrict == KPCAAPlanetStrictNeptune)
        #expect(neptune.planetaryObject == KPCPlanetaryObjectNEPTUNE)
    }

    @Test("Pluto Types")
    func testPlutoTypes() {
        let pluto = Pluto(julianDay: self.jd)
        #expect(pluto.name == "Pluto")
        #expect(pluto.planet == KPCAAPlanetPluto)
        #expect(pluto.planetStrict == KPCAAPlanetStrictUndefined) // <-- yes, undefined.
        #expect(pluto.planetaryObject == KPCPlanetaryObjectUNDEFINED) // <-- yes, UNDEFINED.
    }
    
    // See AA, p.270, Example 38.a
    @Test("Perihelion Aphelion")
    func testPerihelionAphelion() {
        let venus = Venus(julianDay: JulianDay(year: 1978, month: 10, day: 15))
        AssertEqual(venus.perihelion, JulianDay(2443873.704), accuracy: JulianDay(0.001))
    }
    
    // See AA, p.270, Example 38.b
    @Test("Aphelion")
    func testAphelion() {
        let mars = Mars(julianDay: JulianDay(year: 2032, month: 1, day: 1))
        AssertEqual(mars.aphelion, JulianDay(2463530.456), accuracy: JulianDay(0.001))
    }

}
