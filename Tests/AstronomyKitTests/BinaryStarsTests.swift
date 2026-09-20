//
//  BinaryStarsTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-17.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("BinaryStarsTests")
struct BinaryStarsTests {
    
    
    var CoronoaeBorealisOrbitalElements: BinaryStarOrbitalElements = BinaryStarOrbitalElements(
        revolutionPeriod: 41.623,
        timeOfPeriastron: 1934.008,
        eccentricity: 0.2763,
        inclination: 59.025,
        semiMajorAxis: ArcSecond(0.907).inDegrees,
        positionAngleOfAscendingNode: Degree(23.717),
        longitudeOfPeriastron: Degree(219.907)
    )

    @Test("Binary Star Orbital Elements Short Getters")
    func testBinaryStarOrbitalElementsShortGetters() {
        // non=numeri types
        #expect(self.CoronoaeBorealisOrbitalElements.revolutionPeriod == self.CoronoaeBorealisOrbitalElements.P)
        #expect(self.CoronoaeBorealisOrbitalElements.timeOfPeriastron == self.CoronoaeBorealisOrbitalElements.T)
        #expect(self.CoronoaeBorealisOrbitalElements.eccentricity == self.CoronoaeBorealisOrbitalElements.e)
        
        // numeric types
        AssertEqual(self.CoronoaeBorealisOrbitalElements.inclination, self.CoronoaeBorealisOrbitalElements.i)
        AssertEqual(self.CoronoaeBorealisOrbitalElements.semiMajorAxis, self.CoronoaeBorealisOrbitalElements.a)
        AssertEqual(self.CoronoaeBorealisOrbitalElements.positionAngleOfAscendingNode, self.CoronoaeBorealisOrbitalElements.Omega)
        AssertEqual(self.CoronoaeBorealisOrbitalElements.longitudeOfPeriastron, self.CoronoaeBorealisOrbitalElements.w)
    }
    
    @Test("Binary Star Details")
    func testBinaryStarDetails() {
        
        let details = binaryStarDetails(time: 1980.0, elements: self.CoronoaeBorealisOrbitalElements)
        AssertEqual(details.radiusVector, ArcSecond(0.74557), accuracy: ArcSecond(0.0005))
        AssertEqual(details.apparentPositionAngle, Degree(318.4), accuracy: Degree(0.05))
        AssertEqual(details.angularDistance, ArcSecond(0.411), accuracy: ArcSecond(0.0005))
        
        AssertEqual(details.radiusVector, details.r)
        AssertEqual(details.apparentPositionAngle, details.theta)
        AssertEqual(details.angularDistance, details.rho)
    }
    
    @Test("Coronoae Borealis Apparent Eccentricity")
    func testCoronoaeBorealisApparentEccentricity() {
        let eccPrime = binaryStarApparentEccentricity(eccentricity: self.CoronoaeBorealisOrbitalElements.e,
                                                      inclination: self.CoronoaeBorealisOrbitalElements.i,
                                                      omega: self.CoronoaeBorealisOrbitalElements.Omega)
        
        #expect(abs(eccPrime - 0.86) <= 0.01)
    }
}
