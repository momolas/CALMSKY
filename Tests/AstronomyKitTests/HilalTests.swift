//
//  HilalTests.swift
//  SwiftAA
//
//  Created by Antigravity on 26/08/2026.
//  MIT Licence. See LICENCE file.
//

import XCTest
@testable import AstronomyKit

class HilalTests: XCTestCase {
    
    // Observer coordinates for Mecca (Saudi Arabia): 21.4225° N, 39.8262° E
    let mecca = GeographicCoordinates(positivelyWestwardLongitude: Degree(-39.8262),
                                      latitude: Degree(21.4225),
                                      altitude: Meter(277))
    
    // Observer coordinates for Amman (Jordan): 31.95° N, 35.93° E
    let amman = GeographicCoordinates(positivelyWestwardLongitude: Degree(-35.93),
                                      latitude: Degree(31.95),
                                      altitude: Meter(800))

    // Observer coordinates for Paris (France): 48.8566° N, 2.3522° E
    let paris = GeographicCoordinates(positivelyWestwardLongitude: Degree(-2.3522),
                                      latitude: Degree(48.8566),
                                      altitude: Meter(35))
    
    func testDanjonLimitBehavior() {
        // Just a couple of hours after conjunction: elongation is very small (< 4°)
        let newMoonJD = JulianDay(year: 2024, month: 4, day: 8, hour: 18, minute: 21, second: 0)
        let moon = Moon(julianDay: newMoonJD)
        
        let resultOdeh = moon.crescentVisibility(for: amman, criterion: .odeh)
        XCTAssertEqual(resultOdeh.zone, .belowDanjonLimit)
        XCTAssertFalse(resultOdeh.isVisible)
        XCTAssertLessThan(resultOdeh.elongation.value, 7.0)
        
        let resultYallop = moon.crescentVisibility(for: amman, criterion: .yallop)
        XCTAssertEqual(resultYallop.zone, .belowDanjonLimit)
        XCTAssertFalse(resultYallop.isVisible)
    }
    
    func testVisibleCrescentOdehAndYallop() {
        // 2 days after new moon (e.g. April 10, 2024): Crescent is well formed, elongation > 15°
        let jd = JulianDay(year: 2024, month: 4, day: 10, hour: 16, minute: 0, second: 0)
        let moon = Moon(julianDay: jd)
        
        let resultOdeh = moon.crescentVisibility(for: mecca, criterion: .odeh)
        XCTAssertGreaterThan(resultOdeh.elongation.value, 15.0)
        XCTAssertGreaterThan(resultOdeh.lagTime.value, 30.0) // Lag > 30 min
        XCTAssertEqual(resultOdeh.zone, .easilyVisibleNakedEye)
        XCTAssertTrue(resultOdeh.isVisible)
        XCTAssertTrue(resultOdeh.isMoonsetAfterSunset)
        XCTAssertTrue(resultOdeh.isConjunctionBeforeSunset)
        
        let resultYallop = moon.crescentVisibility(for: mecca, criterion: .yallop)
        XCTAssertEqual(resultYallop.zone, .easilyVisibleNakedEye)
        XCTAssertTrue(resultYallop.isVisible)
    }
    
    func testIstanbulAndMabimsCriteria() {
        let jd = JulianDay(year: 2024, month: 4, day: 10, hour: 16, minute: 0, second: 0)
        let moon = Moon(julianDay: jd)
        
        let resultIstanbul = moon.crescentVisibility(for: paris, criterion: .istanbul)
        let resultMabims = moon.crescentVisibility(for: paris, criterion: .mabims)
        
        XCTAssertTrue(resultIstanbul.isVisible)
        XCTAssertTrue(resultMabims.isVisible)
    }
    
    func testTopocentricCoordinatesSanity() {
        let jd = JulianDay(year: 2024, month: 4, day: 10, hour: 19, minute: 0, second: 0)
        let moon = Moon(julianDay: jd)
        let sun = Sun(julianDay: jd)
        
        let moonTopoEqu = moon.topocentricEquatorialCoordinates(for: paris)
        let moonTopoHor = moon.topocentricHorizontalCoordinates(for: paris)
        let sunTopoHor = sun.topocentricHorizontalCoordinates(for: paris)
        
        XCTAssertNotNil(moonTopoEqu)
        XCTAssertNotNil(moonTopoHor)
        XCTAssertNotNil(sunTopoHor)
        
        // Lunar horizontal parallax makes topocentric altitude lower than geocentric altitude
        let geocentricHor = moon.apparentEquatorialCoordinates.makeHorizontalCoordinates(for: paris, at: jd)
        XCTAssertLessThan(moonTopoHor.altitude.value, geocentricHor.altitude.value)
    }
}
