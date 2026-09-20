//
//  ConstantsTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 17/12/2016.
//  MIT Licence. See LICENCE file.
//

import Testing
@testable import AstronomyKit

@Suite("ConstantsTests")
struct ConstantsTests {
    
    /// That's the Geocentric to Topocentric parallax correction. See AA p280.
    @Test("Parallax To Distance")
    func testParallaxToDistance() {
        let parallax1: ArcSecond = 23.592
        AssertEqual(parallax1.distanceFromEquatorialHorizontalParallax(), AstronomicalUnit(0.37276), accuracy: AstronomicalUnit(0.0005))
    }
    
    @Test("Distance To Equatorial Horizontal Parallax")
    func testDistanceToEquatorialHorizontalParallax() {
        let distance1: AstronomicalUnit = 0.37276
        AssertEqual(distance1.equatorialHorizontalParallax(), ArcSecond(23.592), accuracy: ArcSecond(0.0005))
    }
    
    @Test("Equinox")
    func testEquinox() {
        let date = Date()
        #expect(Equinox.meanEquinoxOfTheDate(date.julianDay).julianDay == date.julianDay)
        #expect(Equinox.standardJ2000.julianDay == StandardEpoch_J2000_0)
        #expect(Equinox.standardB1950.julianDay == StandardEpoch_B1950_0)
        #expect(!String(describing: Equinox.meanEquinoxOfTheDate(date.julianDay)).isEmpty)
    }

    @Test("Epoch")
    func testEpoch() {
        let date = Date()
        #expect(Epoch.epochOfTheDate(date.julianDay).julianDay == date.julianDay)
        #expect(Epoch.J2000.julianDay == StandardEpoch_J2000_0)
        #expect(Epoch.B1950.julianDay == StandardEpoch_B1950_0)
        #expect(!String(describing: Epoch.epochOfTheDate(date.julianDay)).isEmpty)
    }

    @Test("Planet2 Planetary Object")
    func testPlanet2PlanetaryObject() {
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetMercury) == KPCPlanetaryObjectMERCURY)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetVenus) == KPCPlanetaryObjectVENUS)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetEarth) == KPCPlanetaryObjectUNDEFINED)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetMars) == KPCPlanetaryObjectMARS)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetJupiter) == KPCPlanetaryObjectJUPITER)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetSaturn) == KPCPlanetaryObjectSATURN)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetNeptune) == KPCPlanetaryObjectNEPTUNE)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetUranus) == KPCPlanetaryObjectURANUS)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetPluto) == KPCPlanetaryObjectUNDEFINED)
    }
    
    @Test("Planet2 Planetary Object Type")
    func testPlanet2PlanetaryObjectType() {
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetMercury).objectType! is AstronomyKit.Mercury.Type)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetVenus).objectType! is AstronomyKit.Venus.Type)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetEarth).objectType == nil)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetMars).objectType! is AstronomyKit.Mars.Type)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetJupiter).objectType! is AstronomyKit.Jupiter.Type)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetSaturn).objectType! is AstronomyKit.Saturn.Type)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetNeptune).objectType! is AstronomyKit.Neptune.Type)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetUranus).objectType! is AstronomyKit.Uranus.Type)
        #expect(KPCPlanetaryObject.fromPlanet(KPCAAPlanetPluto).objectType == nil)
    }
    
    @Test("Planet2 Planet Strict")
    func testPlanet2PlanetStrict() {
        #expect(KPCAAPlanetStrict.fromPlanet(KPCAAPlanetMercury) == KPCAAPlanetStrictMercury)
        #expect(KPCAAPlanetStrict.fromPlanet(KPCAAPlanetVenus) == KPCAAPlanetStrictVenus)
        #expect(KPCAAPlanetStrict.fromPlanet(KPCAAPlanetEarth) == KPCAAPlanetStrictEarth)
        #expect(KPCAAPlanetStrict.fromPlanet(KPCAAPlanetMars) == KPCAAPlanetStrictMars)
        #expect(KPCAAPlanetStrict.fromPlanet(KPCAAPlanetJupiter) == KPCAAPlanetStrictJupiter)
        #expect(KPCAAPlanetStrict.fromPlanet(KPCAAPlanetSaturn) == KPCAAPlanetStrictSaturn)
        #expect(KPCAAPlanetStrict.fromPlanet(KPCAAPlanetNeptune) == KPCAAPlanetStrictNeptune)
        #expect(KPCAAPlanetStrict.fromPlanet(KPCAAPlanetUranus) == KPCAAPlanetStrictUranus)
        #expect(KPCAAPlanetStrict.fromPlanet(KPCAAPlanetPluto) == KPCAAPlanetStrictUndefined)
    }

    @Test("Planet Descriptions")
    func testPlanetDescriptions() {
        #expect(String(describing: KPCAAPlanetMercury) == "Mercury")
        #expect(String(describing: KPCAAPlanetVenus) == "Venus")
        #expect(String(describing: KPCAAPlanetEarth) == "Earth")
        #expect(String(describing: KPCAAPlanetMars) == "Mars")
        #expect(String(describing: KPCAAPlanetJupiter) == "Jupiter")
        #expect(String(describing: KPCAAPlanetSaturn) == "Saturn")
        #expect(String(describing: KPCAAPlanetNeptune) == "Neptune")
        #expect(String(describing: KPCAAPlanetUranus) == "Uranus")
        #expect(String(describing: KPCAAPlanetPluto) == "Pluto")
        #expect(String(describing: KPCAAPlanetUndefined) == "")
    }
    
    @Test("Planet From String")
    func testPlanetFromString() {
        #expect(KPCAAPlanet.fromString("Mercury") == KPCAAPlanetMercury)
        #expect(KPCAAPlanet.fromString("Venus") == KPCAAPlanetVenus)
        #expect(KPCAAPlanet.fromString("Earth") == KPCAAPlanetEarth)
        #expect(KPCAAPlanet.fromString("Mars") == KPCAAPlanetMars)
        #expect(KPCAAPlanet.fromString("Jupiter") == KPCAAPlanetJupiter)
        #expect(KPCAAPlanet.fromString("Saturn") == KPCAAPlanetSaturn)
        #expect(KPCAAPlanet.fromString("Neptune") == KPCAAPlanetNeptune)
        #expect(KPCAAPlanet.fromString("Uranus") == KPCAAPlanetUranus)
        #expect(KPCAAPlanet.fromString("Pluto") == KPCAAPlanetPluto)
        #expect(KPCAAPlanet.fromString("") == KPCAAPlanetUndefined)
        #expect(KPCAAPlanet.fromString(">??") == KPCAAPlanetUndefined)
    }
}
