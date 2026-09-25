//
//  AngularSeparationTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 25/02/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("AngularSeparationTests")
struct AngularSeparationTests {

    // See AA. p110
    @Test("Angular Separation1")
    func testAngularSeparation1() {
        let alphaBoo = EquatorialCoordinates(rightAscension: Hour(.plus, 14, 15, 39.7), declination: Degree(.plus, 19, 10, 57.0))
        let alphaVir = EquatorialCoordinates(rightAscension: Hour(.plus, 13, 25, 11.6), declination: Degree(.minus, 11, 09, 41.0))
        
        AssertEqual(alphaBoo.angularSeparation(with: alphaVir), 32.7930.degrees, accuracy: 0.0001.degrees)
    }

    @Test("Distance from Great Arc - SIMD Vector & Non-Singularity")
    func testDistanceFromGreatArc() {
        // Celestial equator great circle: P1 = (0h, 0°), P2 = (12h, 0°)
        // Point on equator: (6h, 0°) -> distance must be 0°
        let distEquator = GreatCircleSeparationEngine.distanceFromGreatArc(
            alpha1: 0.0, delta1: 0.0,
            alpha2: 12.0, delta2: 0.0,
            alpha3: 6.0, delta3: 0.0
        )
        #expect(abs(distEquator) < 1e-12)

        // Point at North Pole: (6h, 90°) -> distance must be 90°
        let distPole = GreatCircleSeparationEngine.distanceFromGreatArc(
            alpha1: 0.0, delta1: 0.0,
            alpha2: 12.0, delta2: 0.0,
            alpha3: 6.0, delta3: 90.0
        )
        #expect(abs(distPole - 90.0) < 1e-12)

        // Point at 45° Dec at 6h RA (critical singularity point cos(alpha3) == 0 in legacy formula)
        let distSingularity = GreatCircleSeparationEngine.distanceFromGreatArc(
            alpha1: 0.0, delta1: 0.0,
            alpha2: 12.0, delta2: 0.0,
            alpha3: 6.0, delta3: 45.0
        )
        #expect(abs(distSingularity - 45.0) < 1e-12)

        // Point at 18h RA:
        let dist18h = GreatCircleSeparationEngine.distanceFromGreatArc(
            alpha1: 0.0, delta1: 0.0,
            alpha2: 12.0, delta2: 0.0,
            alpha3: 18.0, delta3: -30.0
        )
        #expect(abs(dist18h - 30.0) < 1e-12)
    }
}
