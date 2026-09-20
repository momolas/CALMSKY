//
//  JupiterMoonsTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-20.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import XCTest
@testable import AstronomyKit

class JupiterMoonsTests: XCTestCase {

    // See AA p.303 Example 44.a and p.314 Example 44.b
    func testJupiterMoonsPositions() {
        let jupiter = Jupiter(julianDay: JulianDay(2448972.50068))
        
        let ioCoords = jupiter.Io.rectangularCoordinates(true)
        XCTAssertEqual(ioCoords.X, -3.4502, accuracy: 0.0001)
        XCTAssertEqual(ioCoords.Y, 0.2137, accuracy: 0.0001)

        let europaCoords = jupiter.Europa.rectangularCoordinates(true)
        XCTAssertEqual(europaCoords.X, 7.4418, accuracy: 0.0001)
        XCTAssertEqual(europaCoords.Y, 0.2753, accuracy: 0.0001)

        let ganymedeCoords = jupiter.Ganymede.rectangularCoordinates(true)
        XCTAssertEqual(ganymedeCoords.X, 1.2011, accuracy: 0.001)
        XCTAssertEqual(ganymedeCoords.Y, 0.5900, accuracy: 0.0001)

        let callistoCoords = jupiter.Callisto.rectangularCoordinates(true)
        XCTAssertEqual(callistoCoords.X, 7.0720, accuracy: 0.0001)
        XCTAssertEqual(callistoCoords.Y, 1.0291, accuracy: 0.001)
    }

    
    // Using AA p.303 Example 44.a for the Date, and values to compare with from AA+ Tests values.
    func testJupiterMoonsDetails() {
        let jupiter = Jupiter(julianDay: JulianDay(2448972.50068))

        XCTAssertEqual(jupiter.Io.MeanLongitude.value, 335.606283913599, accuracy: 1e-9)
        XCTAssertEqual(jupiter.Io.TrueLongitude.value, 335.599752184702, accuracy: 1e-9)
        XCTAssertEqual(jupiter.Io.TropicalLongitude.value, 336.199774799324, accuracy: 1e-9)
        XCTAssertEqual(jupiter.Io.EquatorialLatitude.value, 0.043408227331, accuracy: 1e-9)
        XCTAssertEqual(jupiter.Io.radiusVector.value, 5.92989277458, accuracy: 1e-9)
        XCTAssertEqual(jupiter.Io.inTransit, false)
        XCTAssertEqual(jupiter.Io.inOccultation, false)
        XCTAssertEqual(jupiter.Io.inEclipse, false)
        XCTAssertEqual(jupiter.Io.inShadowTransit, false)
        
        XCTAssertEqual(jupiter.Europa.MeanLongitude.value, 62.342123420443, accuracy: 1e-9)
        XCTAssertEqual(jupiter.Europa.TrueLongitude.value, 63.442232881789, accuracy: 1e-9)
        XCTAssertEqual(jupiter.Europa.TropicalLongitude.value, 64.042255496411, accuracy: 1e-9)
        XCTAssertEqual(jupiter.Europa.EquatorialLatitude.value, 0.156540366491, accuracy: 1e-9)
        XCTAssertEqual(jupiter.Europa.radiusVector.value, 9.403735359261, accuracy: 1e-9)
        XCTAssertEqual(jupiter.Europa.inTransit, false)
        XCTAssertEqual(jupiter.Europa.inOccultation, false)
        XCTAssertEqual(jupiter.Europa.inEclipse, false)
        XCTAssertEqual(jupiter.Europa.inShadowTransit, false)

        XCTAssertEqual(jupiter.Ganymede.MeanLongitude.value, 15.710050187888, accuracy: 1e-12)
        XCTAssertEqual(jupiter.Ganymede.TrueLongitude.value, 15.750439234543, accuracy: 1e-12)
        XCTAssertEqual(jupiter.Ganymede.TropicalLongitude.value, 16.350461849165, accuracy: 1e-12)
        XCTAssertEqual(jupiter.Ganymede.EquatorialLatitude.value, -0.225526366666, accuracy: 1e-12)
        XCTAssertEqual(jupiter.Ganymede.radiusVector.value, 15.000197430193, accuracy: 1e-12)
        XCTAssertEqual(jupiter.Ganymede.inTransit, false)
        XCTAssertEqual(jupiter.Ganymede.inOccultation, false)
        XCTAssertEqual(jupiter.Ganymede.inEclipse, false)
        XCTAssertEqual(jupiter.Ganymede.inShadowTransit, false)

        XCTAssertEqual(jupiter.Callisto.MeanLongitude.value, 26.191041584184, accuracy: 1e-12)
        XCTAssertEqual(jupiter.Callisto.TrueLongitude.value, 26.782079912794, accuracy: 1e-12)
        XCTAssertEqual(jupiter.Callisto.TropicalLongitude.value, 27.382102527416, accuracy: 1e-12)
        XCTAssertEqual(jupiter.Callisto.EquatorialLatitude.value, -0.148129137852, accuracy: 1e-12)
        XCTAssertEqual(jupiter.Callisto.radiusVector.value, 26.212921477566, accuracy: 1e-12)
        XCTAssertEqual(jupiter.Callisto.inTransit, false)
        XCTAssertEqual(jupiter.Callisto.inOccultation, false)
        XCTAssertEqual(jupiter.Callisto.inEclipse, false)
        XCTAssertEqual(jupiter.Callisto.inShadowTransit, false)

    }
}
