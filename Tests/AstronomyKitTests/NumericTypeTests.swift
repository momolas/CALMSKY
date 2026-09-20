//
//  NumericTypeTests.swift
//  SwiftAA
//
//  Created by Alexander Vasenin on 03/01/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("NumericTypeTests")
struct NumericTypeTests {

    @Test("Circular Interval")
    func testCircularInterval() {
        #expect(Degree(15).isWithinCircularInterval(from: 10, to: 20))
        #expect(!(Degree(55)).isWithinCircularInterval(from: 10, to: 20))
        #expect(!(Degree(10)).isWithinCircularInterval(from: 10, to: 20, isIntervalOpen: true))
        #expect(Degree(15).isWithinCircularInterval(from: 10, to: 20, isIntervalOpen: false))
        #expect(Degree(10).isWithinCircularInterval(from: 340, to: 20))
        #expect(Degree(350).isWithinCircularInterval(from: 340, to: 20))
        #expect(!(Degree(340)).isWithinCircularInterval(from: 340, to: 20, isIntervalOpen: true))
        #expect(Degree(340).isWithinCircularInterval(from: 340, to: 20, isIntervalOpen: false))
    }
    
    @Test("Rounding To Increment")
    func testRoundingToIncrement() {
        let accuracy = Second(1e-3).inJulianDays
        let jd = JulianDay(year: 2017, month: 1, day: 9, hour: 13, minute: 53, second: 39.87)
        AssertEqual(jd.rounded(toIncrement: Minute(1).inJulianDays), JulianDay(year: 2017, month: 1, day: 9, hour: 13, minute: 54), accuracy: accuracy)
        AssertEqual(jd.rounded(toIncrement: Minute(15).inJulianDays), JulianDay(year: 2017, month: 1, day: 9, hour: 14), accuracy: accuracy)
        AssertEqual(jd.rounded(toIncrement: Hour(3).inJulianDays), JulianDay(year: 2017, month: 1, day: 9, hour: 15), accuracy: accuracy)
    }
    
    @Test("Constructors")
    func testConstructors() {
        // Damn one needs to do to increase UT coverage...
        AssertEqual(1.234.degrees, Degree(1.234))
        AssertEqual(-1.234.degrees, Degree(-1.234))

        AssertEqual(1.234.arcminutes, ArcMinute(1.234))
        AssertEqual(-1.234.arcminutes, ArcMinute(-1.234))

        AssertEqual(1.234.arcseconds, ArcSecond(1.234))
        AssertEqual(-1.234.arcseconds, ArcSecond(-1.234))

        AssertEqual(1.234.hours, Hour(1.234))
        AssertEqual(-1.234.hours, Hour(-1.234))

        AssertEqual(1.234.minutes, Minute(1.234))
        AssertEqual(-1.234.minutes, Minute(-1.234))

        AssertEqual(1.234.seconds, Second(1.234))
        AssertEqual(-1.234.seconds, Second(-1.234))

        AssertEqual(1.234.radians, Radian(1.234))
        AssertEqual(-1.234.radians, Radian(-1.234))
        
        AssertEqual(1.234.days, Day(1.234))
        AssertEqual(-1.234.days, Day(-1.234))

        AssertEqual(1.234.julianDays, JulianDay(1.234))
        AssertEqual(-1.234.julianDays, JulianDay(-1.234))

        let s1 =  1.234.sexagesimal
        #expect(s1.sign == .plus)
        #expect(s1.radical == 1)
        #expect(s1.minute == 14)
        #expect(abs(s1.second - 2.4) <= 0.000000001) // rounding error...
        #expect(1.234.sexagesimalShortString == "+01:14:02.4")

        // One needs a true sexagesimal library...
//        let s2 = -1.234.sexagesimal
//        let s3 = -0.123.sexagesimal
        
//        #expect(s2.sign == .minus)
//        #expect(s2.radical == -1)
//        #expect(s2.minute == 2)
//        #expect(s2.second == 3.4)
//
//        #expect(s3.sign == .minus)
//        #expect(s3.radical == 0)
//        #expect(s3.minute == 1)
//        #expect(s3.second == 2.3)
//        #expect(-1.234.sexagesimalShortString == "")


    }
}


