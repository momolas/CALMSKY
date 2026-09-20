//
//  JupiterTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 07/03/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("JupiterTests")
struct JupiterTests {
    
    @Test("Average Color")
    func testAverageColor() {
        #expect(Jupiter.averageColor != CelestialColor.white)
    }
    
    @Test("Moons Presence")
    func testMoonsPresence() {
        let jd = JulianDay(Date())
        #expect(Jupiter(julianDay: jd).moons.count == 4)
    }
    
    // See AA p.295, Example 43.a
    @Test("Appearance")
    func testAppearance() {
        let jd = JulianDay(2448972.50068)
        let jupiter = Jupiter(julianDay: jd)
        AssertEqual(jupiter.positionAngleOfNorthernRotationPole, Degree(24.80), accuracy: Degree(0.01))
        AssertEqual(jupiter.planetocentricDeclinationOfTheEarth, Degree(-2.48), accuracy: Degree(0.01))
        AssertEqual(jupiter.planetocentricDeclinationOfTheSun, Degree(-2.20), accuracy: Degree(0.01))
        AssertEqual(jupiter.geometricCentralMeridianLongitudeSystemI, Degree(267.63), accuracy: Degree(0.01))
        AssertEqual(jupiter.geometricCentralMeridianLongitudeSystemII, Degree(72.31), accuracy: Degree(0.01))
        AssertEqual(jupiter.apparentCentralMeridianLongitudeSystemI, Degree(268.06), accuracy: Degree(0.01))
        AssertEqual(jupiter.apparentCentralMeridianLongitudeSystemII, Degree(72.74), accuracy: Degree(0.01))
    }
}
