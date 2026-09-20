//
//  PlanetaryDiametersTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-23.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("PlanetaryDiametersTests")
struct PlanetaryDiametersTests {

    @Test("Old Values")
    func testOldValues() {
        let jd = JulianDay(Date())
        _ = try! Mercury(julianDay: jd).equatorialSemiDiameter(usingOldValues: true)
        _ = try! Venus(julianDay: jd).equatorialSemiDiameter(usingOldValues: true)
        _ = try! Mars(julianDay: jd).equatorialSemiDiameter(usingOldValues: true)
        _ = try! Jupiter(julianDay: jd).equatorialSemiDiameter(usingOldValues: true)
        _ = try! Saturn(julianDay: jd).equatorialSemiDiameter(usingOldValues: true)
        _ = try! Uranus(julianDay: jd).equatorialSemiDiameter(usingOldValues: true)
        _ = try! Neptune(julianDay: jd).equatorialSemiDiameter(usingOldValues: true)
    }

    @Test("New Values")
    func testNewValues() {
        let jd = JulianDay(Date())
        _ = try! Mercury(julianDay: jd).equatorialSemiDiameter()
        _ = try! Venus(julianDay: jd).equatorialSemiDiameter()
        _ = try! Mars(julianDay: jd).equatorialSemiDiameter()
        _ = try! Jupiter(julianDay: jd).equatorialSemiDiameter()
        _ = try! Saturn(julianDay: jd).equatorialSemiDiameter()
        _ = try! Uranus(julianDay: jd).equatorialSemiDiameter()
        _ = try! Neptune(julianDay: jd).equatorialSemiDiameter()
    }
    
    @Test("Equatorial Polar Compared Values")
    func testEquatorialPolarComparedValues() throws {
        let jd = JulianDay(Date())
        let mercury = try Mercury(julianDay: jd)
        let mEq = try mercury.equatorialSemiDiameter()
        let mPol = try mercury.polarSemiDiameter()
        #expect(mEq == mPol)
        
        let venus = try Venus(julianDay: jd)
        let vEq = try venus.equatorialSemiDiameter()
        let vPol = try venus.polarSemiDiameter()
        #expect(vEq == vPol)
        
        let mars = try Mars(julianDay: jd)
        let maEq = try mars.equatorialSemiDiameter()
        let maPol = try mars.polarSemiDiameter()
        #expect(maEq == maPol)
        
        let jupiter = try Jupiter(julianDay: jd)
        let jEq = try jupiter.equatorialSemiDiameter()
        let jPol = try jupiter.polarSemiDiameter()
        #expect(jEq != jPol)
        
        let saturn = try Saturn(julianDay: jd)
        let sEq = try saturn.equatorialSemiDiameter()
        let sPol = try saturn.polarSemiDiameter()
        #expect(sEq != sPol)
        
        let uranus = try Uranus(julianDay: jd)
        let uEq = try uranus.equatorialSemiDiameter()
        let uPol = try uranus.polarSemiDiameter()
        #expect(uEq == uPol)
        
        let neptune = try Neptune(julianDay: jd)
        let nEq = try neptune.equatorialSemiDiameter()
        let nPol = try neptune.polarSemiDiameter()
        #expect(nEq == nPol)
    }

}
