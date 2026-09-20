//
//  SaturnTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 07/03/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("SaturnTests")
struct SaturnTests {
    
    @Test("Average Color")
    func testAverageColor() {
        #expect(Saturn.averageColor != CelestialColor.white)
    }

    @Test("Moons Presence")
    func testMoonsPresence() {
        let jd = JulianDay(Date())
        #expect(Saturn(julianDay: jd).moons.count == 8)
        _ = Saturn(julianDay: jd).ringSystem
    }
    
    // Assuming AA+ Tests values are correct!
    @Test("Saturn Moons Details Mimas")
    func testSaturnMoonsDetailsMimas() {
        let jd = JulianDay(2451439.50074)
        let saturn = Saturn(julianDay: jd)
        
        // ------------ Mimas (I)
        
        #expect(saturn.Mimas.inTransit == false)
        #expect(saturn.Mimas.inOccultation == false)
        #expect(saturn.Mimas.inEclipse == false)
        #expect(saturn.Mimas.inShadowTransit == false)
        
        let mimasApparentCoords = saturn.Mimas.rectangularCoordinates()
        #expect(abs(mimasApparentCoords.X - 3.101692606671) <= 1e-12)
        #expect(abs(mimasApparentCoords.Y - -0.203950489650) <= 1e-12)
        #expect(abs(mimasApparentCoords.Z - 0.295455146894) <= 1e-12)

        let mimasTrueCoords = saturn.Mimas.rectangularCoordinates(false)
        #expect(abs(mimasTrueCoords.X - 3.101734252548) <= 1e-12)
        #expect(abs(mimasTrueCoords.Y - -0.203953334696) <= 1e-12)
        #expect(abs(mimasTrueCoords.Z - 0.295455146894) <= 1e-12)

        // ------------ Enceladus (II)
        
        #expect(saturn.Enceladus.inTransit == false)
        #expect(saturn.Enceladus.inTransit == false)
        #expect(saturn.Enceladus.inTransit == false)
        #expect(saturn.Enceladus.inTransit == false)
        
        let enceladusApparentCoords = saturn.Enceladus.rectangularCoordinates()
        #expect(abs(enceladusApparentCoords.X - 3.823372081937) <= 1e-12)
        #expect(abs(enceladusApparentCoords.Y - 0.318118149309) <= 1e-12)
        #expect(abs(enceladusApparentCoords.Z - -0.832552038738) <= 1e-12)
        
        let enceladusTrueCoords = saturn.Enceladus.rectangularCoordinates(false)
        #expect(abs(enceladusTrueCoords.X - 3.823213821469) <= 1e-12)
        #expect(abs(enceladusTrueCoords.Y - 0.318105644626) <= 1e-12)
        #expect(abs(enceladusTrueCoords.Z - -0.832552038738) <= 1e-12)

        // ------------ Tethys (III)
        
        #expect(saturn.Tethys.inTransit == false)
        #expect(saturn.Tethys.inTransit == false)
        #expect(saturn.Tethys.inTransit == false)
        #expect(saturn.Tethys.inTransit == false)

        let tethysApparentCoords = saturn.Tethys.rectangularCoordinates()
        #expect(abs(tethysApparentCoords.X - 4.027137247372) <= 1e-12)
        #expect(abs(tethysApparentCoords.Y - -1.061206420162) <= 1e-12)
        #expect(abs(tethysApparentCoords.Z - 2.544880896976) <= 1e-12)
        
        let tethysTrueCoords = saturn.Tethys.rectangularCoordinates(false)
        #expect(abs(tethysTrueCoords.X - 4.027566633517) <= 1e-12)
        #expect(abs(tethysTrueCoords.Y - -1.061333928969) <= 1e-12)
        #expect(abs(tethysTrueCoords.Z - 2.544880896976) <= 1e-12)

        // ------------ Dione (IV)

        #expect(saturn.Dione.inTransit == false)
        #expect(saturn.Dione.inTransit == false)
        #expect(saturn.Dione.inTransit == false)
        #expect(saturn.Dione.inTransit == false)

        let dioneApparentCoords = saturn.Dione.rectangularCoordinates()
        #expect(abs(dioneApparentCoords.X - -5.365159573458) <= 1e-12)
        #expect(abs(dioneApparentCoords.Y - -1.148174651116) <= 1e-12)
        #expect(abs(dioneApparentCoords.Z - 3.004480672103) <= 1e-12)
        
        let dioneTrueCoords = saturn.Dione.rectangularCoordinates(false)
        #expect(abs(dioneTrueCoords.X - -5.365972347292) <= 1e-12)
        #expect(abs(dioneTrueCoords.Y - -1.148337524538) <= 1e-12)
        #expect(abs(dioneTrueCoords.Z - 3.004480672103) <= 1e-12)

        // ------------ Rhea (V)

        #expect(saturn.Rhea.inTransit == false)
        #expect(saturn.Rhea.inTransit == false)
        #expect(saturn.Rhea.inTransit == false)
        #expect(saturn.Rhea.inTransit == false)

        let rheaApparentCoords = saturn.Rhea.rectangularCoordinates()
        #expect(abs(rheaApparentCoords.X - -0.971846971308) <= 1e-12)
        #expect(abs(rheaApparentCoords.Y - -3.136031295237) <= 1e-12)
        #expect(abs(rheaApparentCoords.Z - 8.0800626622957) <= 1e-12)
        
        let rheaTrueCoords = saturn.Rhea.rectangularCoordinates(false)
        #expect(abs(rheaTrueCoords.X - -0.972445111109) <= 1e-12)
        #expect(abs(rheaTrueCoords.Y - -3.137227671996) <= 1e-12)
        #expect(abs(rheaTrueCoords.Z - 8.080062662295) <= 1e-12)

        // ------------ Titan (VI)
        
        #expect(saturn.Titan.inTransit == false)
        #expect(saturn.Titan.inTransit == false)
        #expect(saturn.Titan.inTransit == false)
        #expect(saturn.Titan.inTransit == false)

        let titanApparentCoords = saturn.Titan.rectangularCoordinates()
        #expect(abs(titanApparentCoords.X - 14.567735390428) <= 1e-9)
        #expect(abs(titanApparentCoords.Y - 4.738374645925) <= 1e-9)
        #expect(abs(titanApparentCoords.Z - -12.754798683918) <= 1e-9)
        
        let titanTrueCoords = saturn.Titan.rectangularCoordinates(false)
        #expect(abs(titanTrueCoords.X - 14.558800712218) <= 1e-9)
        #expect(abs(titanTrueCoords.Y - 4.735521159209) <= 1e-9)
        #expect(abs(titanTrueCoords.Z - -12.754798683918) <= 1e-9)

        // ------------ Hyperion (VII)
        
        #expect(saturn.Hyperion.inTransit == false)
        #expect(saturn.Hyperion.inTransit == false)
        #expect(saturn.Hyperion.inTransit == false)
        #expect(saturn.Hyperion.inTransit == false)
        
        let hyperionApparentCoords = saturn.Hyperion.rectangularCoordinates()
        #expect(abs(hyperionApparentCoords.X - -18.001151501273) <= 1e-9)
        #expect(abs(hyperionApparentCoords.Y - -5.328180833140) <= 1e-9)
        #expect(abs(hyperionApparentCoords.Z - 15.120922945655) <= 1e-9)
        
        let hyperionTrueCoords = saturn.Hyperion.rectangularCoordinates(false)
        #expect(abs(hyperionTrueCoords.X - -18.014172683663) <= 1e-9)
        #expect(abs(hyperionTrueCoords.Y - -5.331984742038) <= 1e-9)
        #expect(abs(hyperionTrueCoords.Z - 15.120922945655) <= 1e-9)

        // ------------ Iapetus (VIII)
        
        #expect(saturn.Iapetus.inTransit == false)
        #expect(saturn.Iapetus.inTransit == false)
        #expect(saturn.Iapetus.inTransit == false)
        #expect(saturn.Iapetus.inTransit == false)
    
        let iapetusApparentCoords = saturn.Iapetus.rectangularCoordinates()
        #expect(abs(iapetusApparentCoords.X - -48.760383752651) <= 1e-9)
        #expect(abs(iapetusApparentCoords.Y - 4.137166068962) <= 1e-9)
        #expect(abs(iapetusApparentCoords.Z - 32.737852943956) <= 1e-9)
        
        let iapetusTrueCoords = saturn.Iapetus.rectangularCoordinates(false)
        #expect(abs(iapetusTrueCoords.X - -48.835951923587) <= 1e-9)
        #expect(abs(iapetusTrueCoords.Y - 4.143560854715) <= 1e-9)
        #expect(abs(iapetusTrueCoords.Z - 32.737852943956) <= 1e-9)
    }
    
    // See AA, p.320, Example 45.a
    @Test("Rings Details")
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

