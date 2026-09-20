//
//  RefractionTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 25/02/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("RefractionTests")
struct RefractionTests {

    // See AA. p 107
    @Test("Refraction From Apparent Altitude")
    func testRefractionFromApparentAltitude() {
        AssertEqual(refraction(fromApparentAltitude: 0.5.degrees), 28.735.arcminutes, accuracy: 0.01.arcminutes)
    }

    @Test("Refraction From True Altitude")
    func testRefractionFromTrueAltitude() {
        AssertEqual(refraction(fromTrueAltitude: 0.5541.degrees), 24.618.arcminutes, accuracy: 0.01.arcminutes)
    }
}
