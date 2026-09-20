//
//  DistancesTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-23.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("DistancesTests")
struct DistancesTests {

    @Test("Basic Conversions")
    func testBasicConversions() {
        AssertEqual(Kilometer(12345.6789).inMeters, Meter(12345678.9))
        AssertEqual(Meter(12345.6789).inKilometers, Kilometer(12.3456789), accuracy: Kilometer(0.0000001)) // rounding error
        
        AssertEqual(AstronomicalUnit(2.0).inParsecs, Parsec(2.0*AU2pc))
        AssertEqual(AstronomicalUnit(3.0).inMeters, Meter(3.0*AU2m))
        AssertEqual(AstronomicalUnit(3.0).inKilometers, Kilometer(3.0*AU2m/1000.0))
        #expect(AstronomicalUnit(4.0).inLightYears == 4.0*AU2ly)
        
        AssertEqual(Meter(2.0).inAstronomicalUnits, AstronomicalUnit(2.0/AU2m))
        AssertEqual(Parsec(3.0).inAstronomicalUnits, AstronomicalUnit(3.0/AU2pc))
    }

    @Test("Geometric Parallax")
    func testGeometricParallax() {
        AssertEqual(Parsec(1.0).parallax(), ArcSecond(1.0))
        AssertEqual(Parsec(10.0).parallax(), ArcSecond(0.1))
    }
    
    @Test("Description Presence")
    func testDescriptionPresence() {
        #expect(!AstronomicalUnit(1.0).description.isEmpty)
        #expect(!Parsec(1.0).description.isEmpty)
        #expect(!Kilometer(1.0).description.isEmpty)
        #expect(!Meter(1.0).description.isEmpty)
    }
}
