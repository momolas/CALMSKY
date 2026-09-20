//
//  IlluminatedFractionTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 16/02/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("IlluminatedFractionTests")
struct IlluminatedFractionTests {

    

    // See AA. p.284
    @Test("Fraction Venus")
    func testFractionVenus() {
        let jd = JulianDay(year: 1992, month: 12, day: 20)
        let venus = Venus(julianDay: jd)
        #expect(abs(venus.illuminatedFraction - 0.647) <= 0.001)
    }
    
    // See AA. p.285
    @Test("Magnitude Muller Venus")
    func testMagnitudeMullerVenus() {
        let jd = JulianDay(year: 1992, month: 12, day: 20)
        let venus = Venus(julianDay: jd)
        #expect(abs(venus.magnitudeMuller.value - -3.8) <= 0.05)
    }
    
    @Test("Magnitude Venus")
    func testMagnitudeVenus() {
        let jd = JulianDay(year: 1992, month: 12, day: 20)
        let venus = Venus(julianDay: jd)
        #expect(abs(venus.magnitude.value - -4.2) <= 0.05)
    }
    
    // See AA. p.286
    @Test("Magnitude Saturn")
    func testMagnitudeSaturn() {
        let jd = JulianDay(year: 1992, month: 12, day: 16)
        let saturn = Saturn(julianDay: jd)
        #expect(abs(saturn.magnitudeMuller.value - 0.9) <= 0.05)
        // Magnitude (not Muller) is using Astronomical Almanacs algorithm.
        #expect(abs(saturn.magnitude.value - 0.75) <= 0.05)
    }
}
