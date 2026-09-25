//
//  NutationTests.swift
//  SwiftAA
//
//  Created by Alexander Vasenin on 24/12/2016.
//  MIT Licence. See LICENCE file.
//

import Testing
@testable import AstronomyKit

@Suite("NutationTests")
struct NutationTests {
    
    @Test("Mean Obliquity")
    func testMeanObliquity() { // See AA p.148
        let jd = JulianDay(year: 1987, month: 4, day: 10, hour: 0, minute: 0, second: 0)
        let earth = Earth(julianDay: jd)
        let meanObliquity = earth.obliquityOfEcliptic(mean: true)
        AssertEqual(meanObliquity, Degree(.plus, 23, 26, 27.407), accuracy: ArcSecond(0.01).inDegrees)
    }

    @Test("True Obliquity")
    func testTrueObliquity() { // See AA p.148
        let jd = JulianDay(year: 1987, month: 4, day: 10, hour: 0, minute: 0, second: 0)
        let earth = Earth(julianDay: jd)
        let trueObliquity = earth.obliquityOfEcliptic(mean: false)
        AssertEqual(trueObliquity, Degree(.plus, 23, 26, 36.850), accuracy: ArcSecond(0.01).inDegrees)
    }

    @Test("Nutation In Longitude")
    func testNutationInLongitude() { // See AA p.148
        let jd = JulianDay(year: 1987, month: 4, day: 10, hour: 0, minute: 0, second: 0)
        let earth = Earth(julianDay: jd)
        AssertEqual(earth.nutationInLongitude, ArcSecond(-3.788), accuracy: ArcSecond(0.0001))
    }

    @Test("Nutation In Obliquity")
    func testNutationInObliquity() { // See AA p.148
        let jd = JulianDay(year: 1987, month: 4, day: 10, hour: 0, minute: 0, second: 0)
        let earth = Earth(julianDay: jd)
        AssertEqual(earth.nutationInObliquity, ArcSecond(9.44252), accuracy: ArcSecond(0.0001))
    }

    @Test("Joint Nutation Details & Obliquity Factorization")
    func testJointNutationDetails() {
        let jd = 2446895.5 // 1987 April 10.0
        let details = CAANutation.nutationDetails(jd)
        let (dPsi, dEps) = CAANutation.nutation(jd)

        #expect(abs(details.deltaPsi - dPsi) < 1e-14)
        #expect(abs(details.deltaEpsilon - dEps) < 1e-14)
        #expect(abs(details.meanObliquity - CAANutation.MeanObliquityOfEcliptic(jd)) < 1e-14)
        #expect(abs(details.trueObliquity - CAANutation.TrueObliquityOfEcliptic(jd)) < 1e-14)
        #expect(abs(details.trueObliquity - (details.meanObliquity + details.deltaEpsilon / 3600.0)) < 1e-14)
    }
}


