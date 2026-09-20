//
//  JulianDayTest.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 17/09/2016.
//  MIT Licence. See LICENCE file.
//

import Testing
@testable import AstronomyKit

@Suite("JulianDayTest")
struct JulianDayTest {
    
    @Test("Date1 To Julian Day")
    func testDate1ToJulianDay() {
        var components = DateComponents()
        components.year = 2016
        components.month = 9
        components.day = 17
        let date = Calendar.gregorianGMT.date(from: components)
        #expect(date?.julianDay == 2457648.500000)
    }

    @Test("Date2 To Julian Day")
    func testDate2ToJulianDay() {
        var components = DateComponents()
        components.year = 1916
        components.month = 9
        components.day = 17
        components.hour = 2
        components.minute = 3
        components.second = 4
        components.nanosecond = 500000000
        let date = Calendar.gregorianGMT.date(from: components)!
        // 2421123.5 + 2.0/24.0 + 3.0/1440.0 + (4.0+500000000/1e9)/86400.0
        let jd = JulianDay(2421123.58546875)
        AssertEqual(date.julianDay, jd, accuracy: Second(0.001).inJulianDays)
    }

    @Test("Julian Day To Date Components")
    func testJulianDayToDateComponents() {
        let julianDay = JulianDay(2421123.585469)
        let components = Calendar.gregorianGMT.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: julianDay.date)
        #expect(components.year! == 1916)
        #expect(components.month! == 9)
        #expect(components.day! == 17)
        #expect(components.hour! == 2)
        #expect(components.minute! == 3)
        #expect(components.second! == 4)
        #expect(abs(Double(components.nanosecond!)/1e9 - 521659000/1e9) <= 0.001)
    }

    @Test("Date1 To Modified Julian Day")
    func testDate1ToModifiedJulianDay() {
        var components = DateComponents()
        components.year = 2016
        components.month = 9
        components.day = 17
        let date = Calendar.gregorianGMT.date(from: components)
        #expect(date?.julianDay.modified == 57648.0)
    }

    @Test("Modified Julian Day To Date")
    func testModifiedJulianDayToDate() {
        var components = DateComponents()
        components.year = 2016
        components.month = 9
        components.day = 17
        let date = Calendar.gregorianGMT.date(from: components)!
        #expect(JulianDay(modified: 57648.0) == date.julianDay)
    }

    @Test("Julian2016")
    func testJulian2016() {
        let components = DateComponents(year: 2016, month: 12, day: 21, hour: 01, minute: 04, second: 09, nanosecond: Int(0.1035*1e9))
        // 2457743.5 + 1.0/24.0 + 4.0/1440.0 + 9.1035/86400
        let jd = JulianDay(2457743.544549809)
        testJulian(components, jd)
        let jd2 = JulianDay(year: 2016, month: 12, day: 21, hour: 1, minute: 4, second: 9.1035)
        AssertEqual(jd, jd2, accuracy: Second(0.001).inJulianDays)
    }
    
    @Test("Julian1980")
    func testJulian1980() {
        let components = DateComponents(year: 1980, month: 03, day: 15, hour: 03, minute: 47, second: 05, nanosecond: 0)
        // 2444313.5 + 03.0/24.0 + 47.0/1440.0 + 05.0/86400.0
        let jd = JulianDay(2444313.6576967593)
        testJulian(components, jd)
    }
    
    @Test("Julian1932")
    func testJulian1932() {
        let components = DateComponents(year: 1932, month: 10, day: 02, hour: 21, minute: 15, second: 59, nanosecond: 0)
        // 2426982.5 + 21.0/24.0 + 15.0/1440.0 + 59.0/86400.0
        let jd = JulianDay(2426983.386099537)
        testJulian(components, jd)
    }
    
    func testJulian(_ components: DateComponents, _ jd: JulianDay) {
        let date = Calendar.gregorianGMT.date(from: components)!
        let date1 = jd.date
        let jd1 = date.julianDay
        let date2 = jd1.date
        let jd2 = date1.julianDay
        let accuracy = TimeInterval(0.001)
        #expect(abs(date.timeIntervalSinceReferenceDate - date1.timeIntervalSinceReferenceDate) <= accuracy)
        #expect(abs(date.timeIntervalSinceReferenceDate - date2.timeIntervalSinceReferenceDate) <= accuracy)
        AssertEqual(jd, jd1, accuracy: Second(accuracy).inJulianDays)
        AssertEqual(jd, jd2, accuracy: Second(accuracy).inJulianDays)
    }
    
    @Test("Mean Greenwich Sidereal Time1")
    func testMeanGreenwichSiderealTime1() { // See AA p.88
        let jd = JulianDay(year: 1987, month: 04, day: 10)
        let gmst = jd.meanGreenwichSiderealTime()
        AssertEqual(gmst, Hour(.plus, 13, 10, 46.3668), accuracy: Second(0.001).inHours)
    }

    @Test("Apparent Greenwich Sidereal Time1")
    func testApparentGreenwichSiderealTime1() { // See also AA p.88
        let jd = JulianDay(year: 1987, month: 04, day: 10)
        let gmst = jd.apparentGreenwichSiderealTime()
        AssertEqual(gmst, Hour(.plus, 13, 10, 46.1351), accuracy: Second(0.001).inHours)
    }

    @Test("Mean Greenwich Sidereal Time2")
    func testMeanGreenwichSiderealTime2() { // See AA p.89
        let jd = JulianDay(year: 1987, month: 04, day: 10, hour: 19, minute: 21, second: 00)
        let gmst = jd.meanGreenwichSiderealTime()
        AssertEqual(gmst, Hour(.plus, 8, 34, 57.0898), accuracy: Second(0.001).inHours)
    }
    
    @Test("Mean Local Sidereal Time1")
    func testMeanLocalSiderealTime1() { // Data from SkySafari
        let jd = JulianDay(year: 2016, month: 12, day: 1, hour: 14, minute: 15, second: 3)
        let geographic = GeographicCoordinates(positivelyWestwardLongitude: -37.615559, latitude: 55.752220)
        let lmst = jd.meanLocalSiderealTime(longitude: geographic.longitude)
        AssertEqual(lmst, Hour(.plus, 21, 28, 59.0), accuracy: Second(1.0).inHours)
    }
    
    @Test("Midnight")
    func testMidnight() {
        let jd1 = JulianDay(year: 2016, month: 12, day: 20, hour: 3, minute: 5, second: 3.5)
        AssertEqual(jd1.midnight, JulianDay(year: 2016, month: 12, day: 20))
        
        let jd2 = JulianDay(year: 2016, month: 12, day: 19, hour: 23, minute: 13, second: 39.1)
        AssertEqual(jd2.midnight, JulianDay(year: 2016, month: 12, day: 19))
        AssertEqual(jd2.midnight, jd2.midnight.midnight)
        AssertEqual(jd2.midnight, jd2.midnight.midnight.midnight)
    }
    
    @Test("Local Midnight For Longitude")
    func testLocalMidnightForLongitude() {
        let jd = JulianDay(year: 2016, month: 12, day: 20, hour: 3, minute: 5, second: 3.5)
        
        let longitude1 = 0.0.degrees        
        AssertEqual(jd.localMidnight(longitude: longitude1), JulianDay(year: 2016, month: 12, day: 20, hour: 0))
        
        let longitude2 = 15.0.degrees
        AssertEqual(jd.localMidnight(longitude: longitude2), JulianDay(year: 2016, month: 12, day: 20, hour: 1))
        
        let longitude3 = -15.0.degrees
        AssertEqual(jd.localMidnight(longitude: longitude3), JulianDay(year: 2016, month: 12, day: 19, hour: 23))
        
        let longitude4 = 90.0.degrees
        AssertEqual(jd.localMidnight(longitude: longitude4), JulianDay(year: 2016, month: 12, day: 19, hour: 6))
        
        let longitude5 = -90.0.degrees
        AssertEqual(jd.localMidnight(longitude: longitude5), JulianDay(year: 2016, month: 12, day: 19, hour: 18))
    }
    
    @Test("Local Midnight For Time Zone")
    func testLocalMidnightForTimeZone() {
        let jd = JulianDay(year: 2016, month: 12, day: 20, hour: 3, minute: 5, second: 3.5)
        
        let timeZone0 = TimeZone(secondsFromGMT: 0)!
        AssertEqual(jd.localMidnight(timeZone: timeZone0), JulianDay(year: 2016, month: 12, day: 20, hour: 0))
        
        let timeZone1 = TimeZone(secondsFromGMT: -1 * 60 * 60)!
        AssertEqual(jd.localMidnight(timeZone: timeZone1), JulianDay(year: 2016, month: 12, day: 20, hour: 1))
        
        let timeZone2 = TimeZone(secondsFromGMT: +1 * 60 * 60)!
        AssertEqual(jd.localMidnight(timeZone: timeZone2), JulianDay(year: 2016, month: 12, day: 19, hour: 23))
        
        let timeZone3 = TimeZone(secondsFromGMT: -6 * 60 * 60)!
        AssertEqual(jd.localMidnight(timeZone: timeZone3), JulianDay(year: 2016, month: 12, day: 19, hour: 6))
        
        let timeZone4 = TimeZone(secondsFromGMT: +6 * 60 * 60)!
        AssertEqual(jd.localMidnight(timeZone: timeZone4), JulianDay(year: 2016, month: 12, day: 19, hour: 18))
    }
    
    @Test("Local Midnight Westward")
    func testLocalMidnightWestward() {
        let jd = JulianDay(year: 2016, month: 12, day: 20, hour: 3, minute: 5, second: 3.5)
        
        let longitude1 = 0.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude1).date, JulianDay(year: 2016, month: 12, day: 20, hour: 0).date)

        let longitude2 = 15.0.degrees // positive = going west, midnight is "later" than UTC hour of input jd
        XCTAssertEqual(jd.localMidnight(longitude: longitude2).date, JulianDay(year: 2016, month: 12, day: 20, hour: 1).date)
        
        let longitude3 = 30.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude3).date, JulianDay(year: 2016, month: 12, day: 20, hour: 2).date)
        
        let longitude4 = 60.0.degrees // from now on, jump back by one day, degree(60)=hour(4) is greater than input 3hm5s3.5
        XCTAssertEqual(jd.localMidnight(longitude: longitude4).date, JulianDay(year: 2016, month: 12, day: 19, hour: 4).date)
        
        let longitude5 = 90.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude5).date, JulianDay(year: 2016, month: 12, day: 19, hour: 6).date)

        let longitude6 = 180.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude6).date, JulianDay(year: 2016, month: 12, day: 19, hour: 12).date)
        
        let longitude7 = 270.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude7).date, JulianDay(year: 2016, month: 12, day: 19, hour: 18).date)

        let longitude8 = 360.0.degrees // back to Dec 20.
        XCTAssertEqual(jd.localMidnight(longitude: longitude8).date, JulianDay(year: 2016, month: 12, day: 20, hour: 0).date)
    }
    
    @Test("Local Midnight Eastward")
    func testLocalMidnightEastward() {
        let jd = JulianDay(year: 2016, month: 12, day: 20, hour: 3, minute: 5, second: 3.5)
        
        let longitude1 = 0.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude1).date, JulianDay(year: 2016, month: 12, day: 20, hour: 0).date)
    
        let longitude2 = -15.0.degrees // negative = going east, midnight is "earlier" than UTC hour of input jd
        XCTAssertEqual(jd.localMidnight(longitude: longitude2).date, JulianDay(year: 2016, month: 12, day: 19, hour: 23).date)
        
        let longitude3 = -30.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude3).date, JulianDay(year: 2016, month: 12, day: 19, hour: 22).date)
        
        let longitude4 = -60.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude4).date, JulianDay(year: 2016, month: 12, day: 19, hour: 20).date)
        
        let longitude5 = -90.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude5).date, JulianDay(year: 2016, month: 12, day: 19, hour: 18).date)
    
        let longitude6 = -180.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude6).date, JulianDay(year: 2016, month: 12, day: 19, hour: 12).date)
        
        let longitude7 = -270.0.degrees // From now on, jump forward by one day, since we crossed the line.
        XCTAssertEqual(jd.localMidnight(longitude: longitude7).date, JulianDay(year: 2016, month: 12, day: 20, hour: 6).date)

        let longitude8 = -360.0.degrees
        XCTAssertEqual(jd.localMidnight(longitude: longitude8).date, JulianDay(year: 2016, month: 12, day: 20, hour: 0).date)
    }
    
    // See AA p.78
    @Test("Delta TWith New Moon")
    func testDeltaTWithNewMoon() {
        // See AA. p353, ex. 49.a for the value.
        // This is the value of the Dynamical Time (TD) of the New Moon on Feb. 1997
        // To me, the value given by AA of 48 seconds is probably too cautious.
        let jd_td = JulianDay(2443192.65118)
        AssertEqual(jd_td.deltaT(), Second(48.0), accuracy: Second(0.5))
    }
    
    // See AA p. 148.
    @Test("Obliquity Of Ecliptic")
    func testObliquityOfEcliptic() {
        let jd = JulianDay(year: 1987, month: 4, day: 10)
        AssertEqual(jd, JulianDay	(2446895.5))
        AssertEqual(jd.obliquityOfEcliptic(mean: true), Degree(.plus, 23, 26, 27.407), accuracy: ArcSecond(0.001).inDegrees)
        AssertEqual(jd.obliquityOfEcliptic(mean: false), Degree(.plus, 23, 26, 36.850), accuracy: ArcSecond(0.001).inDegrees)
    }
    
    // Data taken from USNO (http://tycho.usno.navy.mil/leapsec.html)
    @Test("Cumulative Leap Second")
    func testCumulativeLeapSecond() {
        let jd1 = JulianDay(year: 1972, month: 6, day: 29) // One day before introduction of the first leap second.
        AssertEqual(jd1.cumulativeLeapSeconds(), Second(10))

        let jd2 = JulianDay(year: 2006, month: 1, day: 1) // One day before introduction of the first leap second.
        AssertEqual(jd2.cumulativeLeapSeconds(), Second(33))

        let jd3 = JulianDay(year: 2017, month: 1, day: 1)
        AssertEqual(jd3.cumulativeLeapSeconds(), Second(37))
    }
    
    @Test("Julian Day Description")
    func testJulianDayDescription() {
        #expect(String(describing: JulianDay(StandardEpoch_J2000_0.value)) == "J2000.0")
        #expect(String(describing: JulianDay(StandardEpoch_B1950_0.value)) == "B1950.0")
    }
}


