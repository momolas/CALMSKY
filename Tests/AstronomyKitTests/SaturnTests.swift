//
//  SaturnTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 07/03/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import XCTest
@testable import AstronomyKit

class SaturnTests: XCTestCase {
    
    func testAverageColor() {
        XCTAssertNotEqual(Saturn.averageColor, CelestialColor.white)
    }

    func testMoonsPresence() {
        let jd = JulianDay(Date())
        XCTAssertEqual(Saturn(julianDay: jd).moons.count, 8)
        XCTAssertNotNil(Saturn(julianDay: jd).ringSystem)
    }
    
    // Assuming AA+ Tests values are correct!
    func testSaturnMoonsDetailsMimas() {
        let jd = JulianDay(2451439.50074)
        let saturn = Saturn(julianDay: jd)
        
        // ------------ Mimas (I)
        
        XCTAssertEqual(saturn.Mimas.inTransit, false)
        XCTAssertEqual(saturn.Mimas.inOccultation, false)
        XCTAssertEqual(saturn.Mimas.inEclipse, false)
        XCTAssertEqual(saturn.Mimas.inShadowTransit, false)
        
        let mimasApparentCoords = saturn.Mimas.rectangularCoordinates()
        XCTAssertEqual(mimasApparentCoords.X, 3.101692606671, accuracy: 1e-12)
        XCTAssertEqual(mimasApparentCoords.Y, -0.203950489650, accuracy: 1e-12)
        XCTAssertEqual(mimasApparentCoords.Z, 0.295455146894, accuracy: 1e-12)

        let mimasTrueCoords = saturn.Mimas.rectangularCoordinates(false)
        XCTAssertEqual(mimasTrueCoords.X, 3.101734252548, accuracy: 1e-12)
        XCTAssertEqual(mimasTrueCoords.Y, -0.203953334696, accuracy: 1e-12)
        XCTAssertEqual(mimasTrueCoords.Z, 0.295455146894, accuracy: 1e-12)

        // ------------ Enceladus (II)
        
        XCTAssertEqual(saturn.Enceladus.inTransit, false)
        XCTAssertEqual(saturn.Enceladus.inTransit, false)
        XCTAssertEqual(saturn.Enceladus.inTransit, false)
        XCTAssertEqual(saturn.Enceladus.inTransit, false)
        
        let enceladusApparentCoords = saturn.Enceladus.rectangularCoordinates()
        XCTAssertEqual(enceladusApparentCoords.X, 3.823372081937, accuracy: 1e-12)
        XCTAssertEqual(enceladusApparentCoords.Y, 0.318118149309, accuracy: 1e-12)
        XCTAssertEqual(enceladusApparentCoords.Z,  -0.832552038738, accuracy: 1e-12)
        
        let enceladusTrueCoords = saturn.Enceladus.rectangularCoordinates(false)
        XCTAssertEqual(enceladusTrueCoords.X, 3.823213821469, accuracy: 1e-12)
        XCTAssertEqual(enceladusTrueCoords.Y, 0.318105644626, accuracy: 1e-12)
        XCTAssertEqual(enceladusTrueCoords.Z, -0.832552038738, accuracy: 1e-12)

        // ------------ Tethys (III)
        
        XCTAssertEqual(saturn.Tethys.inTransit, false)
        XCTAssertEqual(saturn.Tethys.inTransit, false)
        XCTAssertEqual(saturn.Tethys.inTransit, false)
        XCTAssertEqual(saturn.Tethys.inTransit, false)

        let tethysApparentCoords = saturn.Tethys.rectangularCoordinates()
        XCTAssertEqual(tethysApparentCoords.X, 4.027137247372, accuracy: 1e-12)
        XCTAssertEqual(tethysApparentCoords.Y, -1.061206420162, accuracy: 1e-12)
        XCTAssertEqual(tethysApparentCoords.Z, 2.544880896976, accuracy: 1e-12)
        
        let tethysTrueCoords = saturn.Tethys.rectangularCoordinates(false)
        XCTAssertEqual(tethysTrueCoords.X, 4.027566633517, accuracy: 1e-12)
        XCTAssertEqual(tethysTrueCoords.Y, -1.061333928969, accuracy: 1e-12)
        XCTAssertEqual(tethysTrueCoords.Z, 2.544880896976, accuracy: 1e-12)

        // ------------ Dione (IV)

        XCTAssertEqual(saturn.Dione.inTransit, false)
        XCTAssertEqual(saturn.Dione.inTransit, false)
        XCTAssertEqual(saturn.Dione.inTransit, false)
        XCTAssertEqual(saturn.Dione.inTransit, false)

        let dioneApparentCoords = saturn.Dione.rectangularCoordinates()
        XCTAssertEqual(dioneApparentCoords.X, -5.365159573458, accuracy: 1e-12)
        XCTAssertEqual(dioneApparentCoords.Y, -1.148174651116, accuracy: 1e-12)
        XCTAssertEqual(dioneApparentCoords.Z, 3.004480672103, accuracy: 1e-12)
        
        let dioneTrueCoords = saturn.Dione.rectangularCoordinates(false)
        XCTAssertEqual(dioneTrueCoords.X, -5.365972347292, accuracy: 1e-12)
        XCTAssertEqual(dioneTrueCoords.Y, -1.148337524538, accuracy: 1e-12)
        XCTAssertEqual(dioneTrueCoords.Z, 3.004480672103, accuracy: 1e-12)

        // ------------ Rhea (V)

        XCTAssertEqual(saturn.Rhea.inTransit, false)
        XCTAssertEqual(saturn.Rhea.inTransit, false)
        XCTAssertEqual(saturn.Rhea.inTransit, false)
        XCTAssertEqual(saturn.Rhea.inTransit, false)

        let rheaApparentCoords = saturn.Rhea.rectangularCoordinates()
        XCTAssertEqual(rheaApparentCoords.X, -0.971846971308, accuracy: 1e-12)
        XCTAssertEqual(rheaApparentCoords.Y, -3.136031295237, accuracy: 1e-12)
        XCTAssertEqual(rheaApparentCoords.Z, 8.0800626622957, accuracy: 1e-12)
        
        let rheaTrueCoords = saturn.Rhea.rectangularCoordinates(false)
        XCTAssertEqual(rheaTrueCoords.X, -0.972445111109, accuracy: 1e-12)
        XCTAssertEqual(rheaTrueCoords.Y, -3.137227671996, accuracy: 1e-12)
        XCTAssertEqual(rheaTrueCoords.Z, 8.080062662295, accuracy: 1e-12)

        // ------------ Titan (VI)
        
        XCTAssertEqual(saturn.Titan.inTransit, false)
        XCTAssertEqual(saturn.Titan.inTransit, false)
        XCTAssertEqual(saturn.Titan.inTransit, false)
        XCTAssertEqual(saturn.Titan.inTransit, false)

        let titanApparentCoords = saturn.Titan.rectangularCoordinates()
        XCTAssertEqual(titanApparentCoords.X, 14.567735390428, accuracy: 1e-9)
        XCTAssertEqual(titanApparentCoords.Y, 4.738374645925, accuracy: 1e-9)
        XCTAssertEqual(titanApparentCoords.Z, -12.754798683918, accuracy: 1e-9)
        
        let titanTrueCoords = saturn.Titan.rectangularCoordinates(false)
        XCTAssertEqual(titanTrueCoords.X, 14.558800712218, accuracy: 1e-9)
        XCTAssertEqual(titanTrueCoords.Y, 4.735521159209, accuracy: 1e-9)
        XCTAssertEqual(titanTrueCoords.Z, -12.754798683918, accuracy: 1e-9)

        // ------------ Hyperion (VII)
        
        XCTAssertEqual(saturn.Hyperion.inTransit, false)
        XCTAssertEqual(saturn.Hyperion.inTransit, false)
        XCTAssertEqual(saturn.Hyperion.inTransit, false)
        XCTAssertEqual(saturn.Hyperion.inTransit, false)
        
        let hyperionApparentCoords = saturn.Hyperion.rectangularCoordinates()
        XCTAssertEqual(hyperionApparentCoords.X, -18.001151501273, accuracy: 1e-9)
        XCTAssertEqual(hyperionApparentCoords.Y, -5.328180833140, accuracy: 1e-9)
        XCTAssertEqual(hyperionApparentCoords.Z, 15.120922945655, accuracy: 1e-9)
        
        let hyperionTrueCoords = saturn.Hyperion.rectangularCoordinates(false)
        XCTAssertEqual(hyperionTrueCoords.X, -18.014172683663, accuracy: 1e-9)
        XCTAssertEqual(hyperionTrueCoords.Y, -5.331984742038, accuracy: 1e-9)
        XCTAssertEqual(hyperionTrueCoords.Z, 15.120922945655, accuracy: 1e-9)

        // ------------ Iapetus (VIII)
        
        XCTAssertEqual(saturn.Iapetus.inTransit, false)
        XCTAssertEqual(saturn.Iapetus.inTransit, false)
        XCTAssertEqual(saturn.Iapetus.inTransit, false)
        XCTAssertEqual(saturn.Iapetus.inTransit, false)
    
        let iapetusApparentCoords = saturn.Iapetus.rectangularCoordinates()
        XCTAssertEqual(iapetusApparentCoords.X, -48.760383752651, accuracy: 1e-9)
        XCTAssertEqual(iapetusApparentCoords.Y, 4.137166068962, accuracy: 1e-9)
        XCTAssertEqual(iapetusApparentCoords.Z, 32.737852943956, accuracy: 1e-9)
        
        let iapetusTrueCoords = saturn.Iapetus.rectangularCoordinates(false)
        XCTAssertEqual(iapetusTrueCoords.X, -48.835951923587, accuracy: 1e-9)
        XCTAssertEqual(iapetusTrueCoords.Y, 4.143560854715, accuracy: 1e-9)
        XCTAssertEqual(iapetusTrueCoords.Z, 32.737852943956, accuracy: 1e-9)
    }
    
    // See AA, p.320, Example 45.a
    func testRingsDetails() {
        let jd = JulianDay(2448972.5)
        let saturn = Saturn(julianDay: jd)
        AssertEqual(saturn.ringSystem.earthCoordinates.latitude, Degree(16.442), accuracy: Degree(0.001))  // B
        AssertEqual(saturn.ringSystem.earthCoordinates.longitude, Degree(149.0663), accuracy: Degree(0.001)) // U2
        AssertEqual(saturn.ringSystem.sunCoordinates.latitude, Degree(14.679), accuracy: Degree(0.001)) // Bdash
        AssertEqual(saturn.ringSystem.sunCoordinates.longitude, Degree(153.2645), accuracy: Degree(0.001)) // U1
        AssertEqual(saturn.ringSystem.saturnicentricSunEarthLongitudesDifference, Degree(4.198), accuracy: Degree(0.001))
        AssertEqual(saturn.ringSystem.northPolePositionAngle, Degree(6.741), accuracy: Degree(0.001))
        AssertEqual(saturn.ringSystem.majorAxis, ArcSecond(35.87), accuracy: ArcSecond(0.1))
        AssertEqual(saturn.ringSystem.minorAxis, ArcSecond(10.15), accuracy: ArcSecond(0.1))
    }
}

