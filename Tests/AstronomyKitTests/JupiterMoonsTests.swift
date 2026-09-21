//
//  JupiterMoonsTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-20.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("JupiterMoonsTests")
struct JupiterMoonsTests {

    // See AA p.303 Example 44.a and p.314 Example 44.b
    @Test("Jupiter Moons Positions")
    func testJupiterMoonsPositions() {
        let jupiter = Jupiter(julianDay: JulianDay(2448972.50068))
        
        let ioCoords = jupiter.Io.rectangularCoordinates(true)
        #expect(abs(ioCoords.X - -3.4502) <= 0.05)
        #expect(abs(ioCoords.Y - 0.2137) <= 0.05)

        let europaCoords = jupiter.Europa.rectangularCoordinates(true)
        #expect(abs(europaCoords.X - 7.4418) <= 0.05)
        #expect(abs(europaCoords.Y - 0.2753) <= 0.05)

        let ganymedeCoords = jupiter.Ganymede.rectangularCoordinates(true)
        #expect(abs(ganymedeCoords.X - 1.2011) <= 0.05)
        #expect(abs(ganymedeCoords.Y - 0.5900) <= 0.05)

        let callistoCoords = jupiter.Callisto.rectangularCoordinates(true)
        #expect(abs(callistoCoords.X - 7.0720) <= 0.05)
        #expect(abs(callistoCoords.Y - 1.0291) <= 0.05)
    }

    
    // Using AA p.303 Example 44.a for the Date, and values to compare with from AA+ Tests values.
    @Test("Jupiter Moons Details")
    func testJupiterMoonsDetails() {
        let jupiter = Jupiter(julianDay: JulianDay(2448972.50068))

        #expect(abs(jupiter.Io.MeanLongitude.value - 335.606283913599) <= 1e-3)
        #expect(abs(jupiter.Io.TrueLongitude.value - 335.599752184702) <= 1e-3)
        #expect(abs(jupiter.Io.TropicalLongitude.value - 336.199774799324) <= 1e-3)
        #expect(abs(jupiter.Io.EquatorialLatitude.value - 0.043408227331) <= 1e-4)
        #expect(abs(jupiter.Io.radiusVector.value - 5.92989277458) <= 1e-4)
        #expect(jupiter.Io.inTransit == false)
        #expect(jupiter.Io.inOccultation == false)
        #expect(jupiter.Io.inEclipse == false)
        #expect(jupiter.Io.inShadowTransit == false)
        
        #expect(abs(jupiter.Europa.MeanLongitude.value - 62.342123420443) <= 1e-3)
        #expect(abs(jupiter.Europa.TrueLongitude.value - 63.442232881789) <= 1e-3)
        #expect(abs(jupiter.Europa.TropicalLongitude.value - 64.042255496411) <= 1e-3)
        #expect(abs(jupiter.Europa.EquatorialLatitude.value - 0.156540366491) <= 1e-4)
        #expect(abs(jupiter.Europa.radiusVector.value - 9.403735359261) <= 1e-4)
        #expect(jupiter.Europa.inTransit == false)
        #expect(jupiter.Europa.inOccultation == false)
        #expect(jupiter.Europa.inEclipse == false)
        #expect(jupiter.Europa.inShadowTransit == false)

        #expect(abs(jupiter.Ganymede.MeanLongitude.value - 15.710050187888) <= 1e-3)
        #expect(abs(jupiter.Ganymede.TrueLongitude.value - 15.750439234543) <= 1e-3)
        #expect(abs(jupiter.Ganymede.TropicalLongitude.value - 16.350461849165) <= 1e-3)
        #expect(abs(jupiter.Ganymede.EquatorialLatitude.value - -0.225526366666) <= 1e-4)
        #expect(abs(jupiter.Ganymede.radiusVector.value - 15.000197430193) <= 1e-4)
        #expect(jupiter.Ganymede.inTransit == false)
        #expect(jupiter.Ganymede.inOccultation == false)
        #expect(jupiter.Ganymede.inEclipse == false)
        #expect(jupiter.Ganymede.inShadowTransit == false)

        #expect(abs(jupiter.Callisto.MeanLongitude.value - 26.191041584184) <= 1e-3)
        #expect(abs(jupiter.Callisto.TrueLongitude.value - 26.782079912794) <= 1e-3)
        #expect(abs(jupiter.Callisto.TropicalLongitude.value - 27.382102527416) <= 1e-3)
        #expect(abs(jupiter.Callisto.EquatorialLatitude.value - -0.148129137852) <= 1e-4)
        #expect(abs(jupiter.Callisto.radiusVector.value - 26.212921477566) <= 1e-4)
        #expect(jupiter.Callisto.inTransit == false)
        #expect(jupiter.Callisto.inOccultation == false)
        #expect(jupiter.Callisto.inEclipse == false)
        #expect(jupiter.Callisto.inShadowTransit == false)

    }
}
