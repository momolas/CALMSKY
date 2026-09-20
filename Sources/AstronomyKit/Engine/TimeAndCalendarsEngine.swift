//
//  TimeAndCalendarsEngine.swift
//  AstronomyKit
//
//  Pure Swift implementations of time scales (JD, TT, TAI, UTC, UT1, Delta-T, GMST, GAST, Equation of Time)
//  and civil/religious calendars (Gregorian, Julian, Easter, Jewish, Islamic).
//  Replaces CAADate, CAADynamicalTime, CAASidereal, CAAEquationOfTime, CAAEaster, CAAJewishCalendar, CAAMoslemCalendar.
//

import Foundation

// MARK: - Date and Julian Day Engine (CAADate)

public struct CAADate: Sendable, Codable, Hashable {
    public enum DOW: Int, Sendable, Codable, Hashable {
        case sunday = 0
        case monday = 1
        case tuesday = 2
        case wednesday = 3
        case thursday = 4
        case friday = 5
        case saturday = 6
    }

    private var m_dblJulian: Double
    private var m_bGregorianCalendar: Bool

    public init() {
        self.m_dblJulian = 0.0
        self.m_bGregorianCalendar = false
    }

    public init(_ Year: Int, _ Month: Int, _ Day: Double, _ bGregorianCalendar: Bool) {
        self.m_dblJulian = 0.0
        self.m_bGregorianCalendar = false
        Set(Year, Month, Day, 0, 0, 0, bGregorianCalendar)
    }

    public init(_ Year: Int, _ Month: Int, _ Day: Double, _ Hour: Double, _ Minute: Double, _ Second: Double, _ bGregorianCalendar: Bool) {
        self.m_dblJulian = 0.0
        self.m_bGregorianCalendar = false
        Set(Year, Month, Day, Hour, Minute, Second, bGregorianCalendar)
    }

    public init(_ JD: Double, _ bGregorianCalendar: Bool) {
        self.m_dblJulian = 0.0
        self.m_bGregorianCalendar = false
        Set(JD, bGregorianCalendar)
    }

    public static func int(_ value: Double) -> Int {
        value >= 0 ? Int(value) : Int(value - 1.0)
    }

    public static func INT(_ value: Double) -> Int {
        int(value)
    }

    public static func DateToJD(_ Year: Int, _ Month: Int, _ Day: Double, _ bGregorianCalendar: Bool) -> Double {
        var y = Year
        var m = Month
        if m < 3 {
            y -= 1
            m += 12
        }

        var b = 0
        if bGregorianCalendar {
            let a = int(Double(y) / 100.0)
            b = 2 - a + int(Double(a) / 4.0)
        }

        return Double(int(365.25 * Double(y + 4716))) + Double(int(30.6001 * Double(m + 1))) + Day + Double(b) - 1524.5
    }

    public static func IsLeap(_ Year: Int, _ bGregorianCalendar: Bool) -> Bool {
        if bGregorianCalendar {
            if (Year % 100) == 0 {
                return (Year % 400) == 0
            } else {
                return (Year % 4) == 0
            }
        } else {
            return (Year % 4) == 0
        }
    }

    public static func AfterPapalReform(_ JD: Double) -> Bool {
        JD >= 2299160.5
    }

    public static func AfterPapalReform(_ Year: Int, _ Month: Int, _ Day: Double) -> Bool {
        if Year > 1582 {
            return true
        } else if Year < 1582 {
            return false
        } else {
            if Month > 10 {
                return true
            } else if Month < 10 {
                return false
            } else {
                return Day >= 15.0
            }
        }
    }

    public mutating func Set(_ Year: Int, _ Month: Int, _ Day: Double, _ Hour: Double, _ Minute: Double, _ Second: Double, _ bGregorianCalendar: Bool) {
        let dblDay = Day + (Hour / 24.0) + (Minute / 1440.0) + (Second / 86400.0)
        Set(CAADate.DateToJD(Year, Month, dblDay, bGregorianCalendar), bGregorianCalendar)
    }

    public mutating func Set(_ JD: Double, _ bGregorianCalendar: Bool) {
        self.m_dblJulian = JD
        SetInGregorianCalendar(bGregorianCalendar)
    }

    public mutating func SetInGregorianCalendar(_ bGregorianCalendar: Bool) {
        let bAfter = CAADate.AfterPapalReform(m_dblJulian)
        self.m_bGregorianCalendar = bGregorianCalendar && bAfter
    }

    public func Get(_ Year: inout Int, _ Month: inout Int, _ Day: inout Int, _ Hour: inout Int, _ Minute: inout Int, _ Second: inout Double) {
        let jd = m_dblJulian + 0.5
        let z = Int(floor(jd))
        var f = jd - floor(jd)

        var a = z
        if m_bGregorianCalendar {
            let alpha = CAADate.int((Double(z) - 1867216.25) / 36524.25)
            a = z + 1 + alpha - CAADate.int(Double(alpha) / 4.0)
        }

        let b = a + 1524
        let c = CAADate.int((Double(b) - 122.1) / 365.25)
        let d = CAADate.int(365.25 * Double(c))
        let e = CAADate.int(Double(b - d) / 30.6001)

        let dblDay = Double(b - d) - Double(CAADate.int(30.6001 * Double(e))) + f
        Day = Int(dblDay)

        if e < 14 {
            Month = e - 1
        } else {
            Month = e - 13
        }

        if Month > 2 {
            Year = c - 4716
        } else {
            Year = c - 4715
        }

        f = dblDay - floor(dblDay)
        Hour = CAADate.int(f * 24.0)
        Minute = CAADate.int((f - (Double(Hour) / 24.0)) * 1440.0)
        Second = (f - (Double(Hour) / 24.0) - (Double(Minute) / 1440.0)) * 86400.0
    }

    public func Julian() -> Double { m_dblJulian }
    public func InGregorianCalendar() -> Bool { m_bGregorianCalendar }

    public func Year() -> Int {
        var y = 0, m = 0, d = 0, h = 0, min = 0
        var s = 0.0
        Get(&y, &m, &d, &h, &min, &s)
        return y
    }

    public func Month() -> Int {
        var y = 0, m = 0, d = 0, h = 0, min = 0
        var s = 0.0
        Get(&y, &m, &d, &h, &min, &s)
        return m
    }

    public func Day() -> Int {
        var y = 0, m = 0, d = 0, h = 0, min = 0
        var s = 0.0
        Get(&y, &m, &d, &h, &min, &s)
        return d
    }

    public func Hour() -> Int {
        var y = 0, m = 0, d = 0, h = 0, min = 0
        var s = 0.0
        Get(&y, &m, &d, &h, &min, &s)
        return h
    }

    public func Minute() -> Int {
        var y = 0, m = 0, d = 0, h = 0, min = 0
        var s = 0.0
        Get(&y, &m, &d, &h, &min, &s)
        return min
    }

    public func Second() -> Double {
        var y = 0, m = 0, d = 0, h = 0, min = 0
        var s = 0.0
        Get(&y, &m, &d, &h, &min, &s)
        return s
    }

    public func DayOfWeek() -> DOW {
        let t = Int(floor(m_dblJulian + 1.5))
        if t >= 0 {
            return DOW(rawValue: t % 7) ?? .sunday
        } else {
            var r = 7 - (abs(t) % 7)
            if r == 7 { r -= 7 }
            return DOW(rawValue: r) ?? .sunday
        }
    }

    public static func DaysInMonth(_ Month: Int, _ bLeap: Bool) -> Int {
        let leapMonths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        let nonLeapMonths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        guard Month >= 1 && Month <= 12 else { return 30 }
        return bLeap ? leapMonths[Month - 1] : nonLeapMonths[Month - 1]
    }

    public func DaysInMonth() -> Int {
        var y = 0, m = 0, d = 0, h = 0, min = 0
        var s = 0.0
        Get(&y, &m, &d, &h, &min, &s)
        return CAADate.DaysInMonth(m, CAADate.IsLeap(y, m_bGregorianCalendar))
    }

    public static func DayOfYear(_ JD: Double, _ Year: Int, _ bGregorianCalendar: Bool) -> Double {
        JD - DateToJD(Year, 1, 1, bGregorianCalendar) + 1.0
    }

    public func DayOfYear() -> Double {
        var y = 0, m = 0, d = 0, h = 0, min = 0
        var s = 0.0
        Get(&y, &m, &d, &h, &min, &s)
        return CAADate.DayOfYear(m_dblJulian, y, CAADate.AfterPapalReform(y, 1, 1.0))
    }

    public func FractionalYear() -> Double {
        var y = 0, m = 0, d = 0, h = 0, min = 0
        var s = 0.0
        Get(&y, &m, &d, &h, &min, &s)
        let daysInYear: Double = CAADate.IsLeap(y, m_bGregorianCalendar) ? 366.0 : 365.0
        return Double(y) + ((m_dblJulian - CAADate.DateToJD(y, 1, 1, CAADate.AfterPapalReform(y, 1, 1.0))) / daysInYear)
    }

    public static func DayOfYearToDayAndMonth(_ DayOfYear: Int, _ bLeap: Bool, _ DayOfMonth: inout Int, _ Month: inout Int) {
        let k = bLeap ? 1 : 2
        Month = CAADate.int(9.0 * Double(k + DayOfYear) / 275.0 + 0.98)
        if DayOfYear < 32 {
            Month = 1
        }
        DayOfMonth = DayOfYear - CAADate.int((275.0 * Double(Month)) / 9.0) + (k * CAADate.int(Double(Month + 9) / 12.0)) + 30
    }

    public static func JulianToGregorian(_ Year: Int, _ Month: Int, _ Day: Int) -> CAACalendarDate {
        var date = CAADate(Year, Month, Double(Day), false)
        date.SetInGregorianCalendar(true)
        var greg = CAACalendarDate()
        var h = 0, min = 0
        var s = 0.0
        date.Get(&greg.Year, &greg.Month, &greg.Day, &h, &min, &s)
        return greg
    }

    public static func GregorianToJulian(_ Year: Int, _ Month: Int, _ Day: Int) -> CAACalendarDate {
        var date = CAADate(Year, Month, Double(Day), true)
        date.SetInGregorianCalendar(false)
        var jul = CAACalendarDate()
        var h = 0, min = 0
        var s = 0.0
        date.Get(&jul.Year, &jul.Month, &jul.Day, &h, &min, &s)
        return jul
    }

    public static func - (lhs: CAADate, rhs: CAADate) -> Double {
        lhs.Julian() - rhs.Julian()
    }
}

// MARK: - Dynamical Time & Delta T (CAADynamicalTime)

private struct LeapSecondRecord: Sendable {
    let jd: Double
    let leapSeconds: Double
    let baseMJD: Double
    let coefficient: Double
}

private let gLeapSeconds: [LeapSecondRecord] = [
    LeapSecondRecord(jd: 2437300.5, leapSeconds: 1.4228180, baseMJD: 37300, coefficient: 0.001296),
    LeapSecondRecord(jd: 2437512.5, leapSeconds: 1.3728180, baseMJD: 37300, coefficient: 0.001296),
    LeapSecondRecord(jd: 2437665.5, leapSeconds: 1.8458580, baseMJD: 37665, coefficient: 0.0011232),
    LeapSecondRecord(jd: 2438334.5, leapSeconds: 1.9458580, baseMJD: 37665, coefficient: 0.0011232),
    LeapSecondRecord(jd: 2438395.5, leapSeconds: 3.2401300, baseMJD: 38761, coefficient: 0.001296),
    LeapSecondRecord(jd: 2438486.5, leapSeconds: 3.3401300, baseMJD: 38761, coefficient: 0.001296),
    LeapSecondRecord(jd: 2438639.5, leapSeconds: 3.4401300, baseMJD: 38761, coefficient: 0.001296),
    LeapSecondRecord(jd: 2438761.5, leapSeconds: 3.5401300, baseMJD: 38761, coefficient: 0.001296),
    LeapSecondRecord(jd: 2438820.5, leapSeconds: 3.6401300, baseMJD: 38761, coefficient: 0.001296),
    LeapSecondRecord(jd: 2438942.5, leapSeconds: 3.7401300, baseMJD: 38761, coefficient: 0.001296),
    LeapSecondRecord(jd: 2439004.5, leapSeconds: 3.8401300, baseMJD: 38761, coefficient: 0.001296),
    LeapSecondRecord(jd: 2439126.5, leapSeconds: 4.3131700, baseMJD: 39126, coefficient: 0.002592),
    LeapSecondRecord(jd: 2439887.5, leapSeconds: 4.2131700, baseMJD: 39126, coefficient: 0.002592),
    LeapSecondRecord(jd: 2441317.5, leapSeconds: 10.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2441499.5, leapSeconds: 11.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2441683.5, leapSeconds: 12.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2442048.5, leapSeconds: 13.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2442413.5, leapSeconds: 14.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2442778.5, leapSeconds: 15.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2443144.5, leapSeconds: 16.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2443509.5, leapSeconds: 17.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2443874.5, leapSeconds: 18.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2444239.5, leapSeconds: 19.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2444786.5, leapSeconds: 20.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2445151.5, leapSeconds: 21.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2445516.5, leapSeconds: 22.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2446247.5, leapSeconds: 23.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2447161.5, leapSeconds: 24.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2447892.5, leapSeconds: 25.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2448257.5, leapSeconds: 26.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2448804.5, leapSeconds: 27.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2449169.5, leapSeconds: 28.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2449534.5, leapSeconds: 29.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2450083.5, leapSeconds: 30.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2450630.5, leapSeconds: 31.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2451179.5, leapSeconds: 32.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2453736.5, leapSeconds: 33.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2454832.5, leapSeconds: 34.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2456109.5, leapSeconds: 35.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2457204.5, leapSeconds: 36.0, baseMJD: 41317, coefficient: 0.0),
    LeapSecondRecord(jd: 2457754.5, leapSeconds: 37.0, baseMJD: 41317, coefficient: 0.0)
]

public enum CAADynamicalTime: Sendable {
    public static func DeltaT(_ JD: Double) -> Double {
        if let lookupDelta = DeltaTLookupTable.lookup(jd: JD) {
            return lookupDelta
        }

        let date = CAADate(JD, CAADate.AfterPapalReform(JD))
        let y = date.FractionalYear()

        if y < -500 {
            let u = (y - 1820.0) / 100.0
            return -20.0 + (32.0 * u * u)
        } else if y < 500 {
            let u = y / 100.0
            let u2 = u * u; let u3 = u2 * u; let u4 = u3 * u; let u5 = u4 * u; let u6 = u5 * u
            return 10583.6 + (-1014.41 * u) + (33.78311 * u2) + (-5.952053 * u3) + (-0.1798452 * u4) + (0.022174192 * u5) + (0.0090316521 * u6)
        } else if y < 1600 {
            let u = (y - 1000.0) / 100.0
            let u2 = u * u; let u3 = u2 * u; let u4 = u3 * u; let u5 = u4 * u; let u6 = u5 * u
            return 1574.2 + (-556.01 * u) + (71.23472 * u2) + (0.319781 * u3) + (-0.8503463 * u4) + (-0.005050998 * u5) + (0.0083572073 * u6)
        } else if y < 1700 {
            let u = (y - 1600.0) / 100.0
            let u2 = u * u; let u3 = u2 * u
            return 120.0 + (-98.08 * u) + (-153.2 * u2) + (u3 / 0.007129)
        } else if y < 1800 {
            let u = (y - 1700.0) / 100.0
            let u2 = u * u; let u3 = u2 * u; let u4 = u3 * u
            return 8.83 + (16.03 * u) + (-59.285 * u2) + (133.36 * u3) + (-u4 / 0.01174)
        } else if y < 1860 {
            let u = (y - 1800.0) / 100.0
            let u2 = u * u; let u3 = u2 * u; let u4 = u3 * u; let u5 = u4 * u; let u6 = u5 * u; let u7 = u6 * u
            return 13.72 + (-33.2447 * u) + (68.612 * u2) + (4111.6 * u3) + (-37436.0 * u4) + (121272.0 * u5) + (-169900.0 * u6) + (87500.0 * u7)
        } else if y < 1900 {
            let u = (y - 1860.0) / 100.0
            let u2 = u * u; let u3 = u2 * u; let u4 = u3 * u; let u5 = u4 * u
            return 7.62 + (57.37 * u) + (-2517.54 * u2) + (16806.68 * u3) + (-44736.24 * u4) + (u5 / 0.0000233174)
        } else if y < 1920 {
            let u = (y - 1900.0) / 100.0
            let u2 = u * u; let u3 = u2 * u; let u4 = u3 * u
            return -2.79 + (149.4119 * u) + (-598.939 * u2) + (6196.6 * u3) + (-19700.0 * u4)
        } else if y < 1941 {
            let u = (y - 1920.0) / 100.0
            let u2 = u * u; let u3 = u2 * u
            return 21.20 + (84.493 * u) + (-761.00 * u2) + (2093.6 * u3)
        } else if y < 1961 {
            let u = (y - 1950.0) / 100.0
            let u2 = u * u; let u3 = u2 * u
            return 29.07 + (40.7 * u) + (-u2 / 0.0233) + (u3 / 0.002547)
        } else if y < 1986 {
            let u = (y - 1975.0) / 100.0
            let u2 = u * u; let u3 = u2 * u
            return 45.45 + 106.7 * u - u2 / 0.026 - u3 / 0.000718
        } else if y < 2005 {
            let u = (y - 2000.0) / 100.0
            let u2 = u * u; let u3 = u2 * u; let u4 = u3 * u; let u5 = u4 * u
            return 63.86 + (33.45 * u) + (-603.74 * u2) + (1727.5 * u3) + (65181.4 * u4) + (237359.9 * u5)
        } else if y < 2050 {
            let u = (y - 2000.0) / 100.0
            let u2 = u * u
            return 62.92 + (32.217 * u) + (55.89 * u2)
        } else if y < 2150 {
            let u = (y - 1820.0) / 100.0
            let u2 = u * u
            return -205.72 + (56.28 * u) + (32.0 * u2)
        } else {
            let u = (y - 1820.0) / 100.0
            return -20.0 + (32.0 * u * u)
        }
    }

    public static func CumulativeLeapSeconds(_ JD: Double) -> Double {
        guard JD >= gLeapSeconds[0].jd else { return 0.0 }
        let last = gLeapSeconds[gLeapSeconds.count - 1]
        if JD >= last.jd {
            return last.leapSeconds + (JD - 2400000.5 - last.baseMJD) * last.coefficient
        }
        var foundIndex = 0
        for (i, rec) in gLeapSeconds.enumerated() {
            if rec.jd > JD {
                foundIndex = i
                break
            }
        }
        let prev = gLeapSeconds[max(0, foundIndex - 1)]
        return prev.leapSeconds + (JD - 2400000.5 - prev.baseMJD) * prev.coefficient
    }

    public static func TT2UTC(_ JD: Double) -> Double {
        let count = gLeapSeconds.count
        if JD < gLeapSeconds[0].jd || JD > (gLeapSeconds[count - 1].jd + 500.0) {
            return TT2UT1(JD)
        }
        let dt = DeltaT(JD)
        let ut1 = JD - (dt / 86400.0)
        let leapSeconds = CumulativeLeapSeconds(JD)
        return ((dt - leapSeconds - 32.184) / 86400.0) + ut1
    }

    public static func UTC2TT(_ JD: Double) -> Double {
        let count = gLeapSeconds.count
        if JD < gLeapSeconds[0].jd || JD > (gLeapSeconds[count - 1].jd + 500.0) {
            return UT12TT(JD)
        }
        let dt = DeltaT(JD)
        let leapSeconds = CumulativeLeapSeconds(JD)
        let ut1 = JD - ((dt - leapSeconds - 32.184) / 86400.0)
        return ut1 + (dt / 86400.0)
    }

    public static func TT2TAI(_ JD: Double) -> Double {
        JD - (32.184 / 86400.0)
    }

    public static func TAI2TT(_ JD: Double) -> Double {
        JD + (32.184 / 86400.0)
    }

    public static func TT2UT1(_ JD: Double) -> Double {
        JD - (DeltaT(JD) / 86400.0)
    }

    public static func UT12TT(_ JD: Double) -> Double {
        JD + (DeltaT(JD) / 86400.0)
    }

    public static func UT1MinusUTC(_ JD: Double) -> Double {
        let jdUTC = JD + ((DeltaT(JD) - CumulativeLeapSeconds(JD) - 32.184) / 86400.0)
        return (JD - jdUTC) * 86400.0
    }
    @inlinable public static func deltaT(_ JD: Double) -> Double {
        DeltaT(JD)
    }
}

// MARK: - Sidereal Time Engine (CAASidereal)

public enum SiderealTimeEngine: Sendable {
    public static func meanGreenwichSiderealTime(jd: Double) -> Double {
        var year = 0, month = 0, day = 0, hour = 0, minute = 0
        var second = 0.0
        let date = CAADate(jd, CAADate.AfterPapalReform(jd))
        date.Get(&year, &month, &day, &hour, &minute, &second)

        let jdMidnight = CAADate.DateToJD(year, month, Double(day), date.InGregorianCalendar())
        let t = (jdMidnight - 2451545.0) / 36525.0
        let tSquared = t * t
        let tCubed = tSquared * t

        var value = 100.46061837 + (36000.770053608 * t) + (0.000387933 * tSquared) - (tCubed / 38710000.0)
        value += (((Double(hour) * 15.0) + (Double(minute) * 0.25) + (second * 0.0041666666666666666666666666666667)) * 1.00273790935)
        value = SphericalTrigonometry.degreesToHours(value)
        return SphericalTrigonometry.mapTo0To24Range(value)
    }

    public static func apparentGreenwichSiderealTime(jd: Double) -> Double {
        let meanObliquity = CAANutation.MeanObliquityOfEcliptic(jd)
        let trueObliquity = meanObliquity + (CAANutation.NutationInObliquity(jd) / 3600.0)
        let nutationInLongitude = CAANutation.NutationInLongitude(jd)

        let value = meanGreenwichSiderealTime(jd: jd) + (nutationInLongitude * cos(SphericalTrigonometry.degreesToRadians(trueObliquity)) / 54000.0)
        return SphericalTrigonometry.mapTo0To24Range(value)
    }
}

public enum CAASidereal: Sendable {
    @inlinable public static func meanGreenwichSiderealTime(_ JD: Double) -> Double {
        SiderealTimeEngine.meanGreenwichSiderealTime(jd: JD)
    }
    @inlinable public static func MeanGreenwichSiderealTime(_ JD: Double) -> Double {
        SiderealTimeEngine.meanGreenwichSiderealTime(jd: JD)
    }
    @inlinable public static func apparentGreenwichSiderealTime(_ JD: Double) -> Double {
        SiderealTimeEngine.apparentGreenwichSiderealTime(jd: JD)
    }
    @inlinable public static func ApparentGreenwichSiderealTime(_ JD: Double) -> Double {
        SiderealTimeEngine.apparentGreenwichSiderealTime(jd: JD)
    }
}

// MARK: - Equation of Time Engine (CAAEquationOfTime)

public enum CAAEquationOfTime: Sendable {
    public static func Calculate(_ JD: Double, _ bHighPrecision: Bool = true) -> Double {
        let rho = (JD - 2451545.0) / 365250.0
        let rho2 = rho * rho
        let rho3 = rho2 * rho
        let rho4 = rho3 * rho
        let rho5 = rho4 * rho

        let l0 = SphericalTrigonometry.mapTo0To360Range(280.4664567 + (360007.6982779 * rho) + (0.03032028 * rho2) + (rho3 / 49931.0) - (rho4 / 15300.0) - (rho5 / 2000000.0))

        let sunLong = CAASun.ApparentEclipticLongitude(JD, bHighPrecision)
        let sunLat = CAASun.ApparentEclipticLatitude(JD, bHighPrecision)
        var epsilon = CAANutation.TrueObliquityOfEcliptic(JD)
        let equatorial = SphericalTrigonometry.eclipticToEquatorial(sunLong, sunLat, epsilon)

        epsilon = SphericalTrigonometry.degreesToRadians(epsilon)
        var e = l0 - 0.0057183 - (equatorial.X * 15.0) + SphericalTrigonometry.dmsToDegrees(0, 0, CAANutation.NutationInLongitude(JD)) * cos(epsilon)
        if e > 180.0 {
            e = -(360.0 - e)
        }
        e *= 4.0 // Convert to minutes of time
        return e
    }
}

// MARK: - Easter Calculation (CAAEaster)

public enum CAAEaster: Sendable {
    @inlinable
    public static func Calculate(_ nYear: Int32, _ GregorianCalendar: Bool) -> CAAEasterDetails {
        Calculate(Int(nYear), GregorianCalendar)
    }

    public static func Calculate(_ nYear: Int, _ GregorianCalendar: Bool) -> CAAEasterDetails {
        var details = CAAEasterDetails()
        if GregorianCalendar {
            let a = nYear % 19
            let b = nYear / 100
            let c = nYear % 100
            let d = b / 4
            let e = b % 4
            let f = (b + 8) / 25
            let g = (b - f + 1) / 3
            let h = ((19 * a) + b - d - g + 15) % 30
            let i = c / 4
            let k = c % 4
            let l = (32 + (2 * e) + (2 * i) - h - k) % 7
            let m = (a + (11 * h) + (22 * l)) / 451
            let n = (h + l - (7 * m) + 114) / 31
            let p = (h + l - (7 * m) + 114) % 31
            details.Month = n
            details.Day = p + 1
        } else {
            let a = nYear % 4
            let b = nYear % 7
            let c = nYear % 19
            let d = ((19 * c) + 15) % 30
            let e = ((2 * a) + (4 * b) - d + 34) % 7
            let f = (d + e + 114) / 31
            let g = (d + e + 114) % 31
            details.Month = f
            details.Day = g + 1
        }
        return details
    }
}

// MARK: - Jewish Calendar (CAAJewishCalendar)

public enum CAAJewishCalendar: Sendable {
    public static func DateOfPesach(_ Year: Int, _ bGregorianCalendar: Bool = true) -> CAACalendarDate {
        var pesach = CAACalendarDate()
        let c = CAADate.int(Double(Year) / 100.0)
        var s = CAADate.int(((3.0 * Double(c)) - 5.0) / 4.0)
        if !bGregorianCalendar {
            s = 0
        }
        let a = ((12 * Year) + 12) % 19
        let b = Year % 4
        let q = -1.904412361576 + (1.554241796621 * Double(a)) + (0.25 * Double(b)) - (0.003177794022 * Double(Year)) + Double(s)
        let intQ = CAADate.int(q)
        let j = (intQ + (3 * Year) + (5 * b) + 2 - s) % 7
        let r = q - Double(intQ)

        if j == 2 || j == 4 || j == 6 {
            pesach.Day = intQ + 23
        } else if j == 1 && a > 6 && r >= 0.632870370 {
            pesach.Day = intQ + 24
        } else if j == 0 && a > 11 && r >= 0.897723765 {
            pesach.Day = intQ + 23
        } else {
            pesach.Day = intQ + 22
        }

        if pesach.Day > 31 {
            pesach.Month = 4
            pesach.Day -= 31
        } else {
            pesach.Month = 3
        }
        pesach.Year = Year
        return pesach
    }

    public static func IsLeap(_ Year: Int) -> Bool {
        let ymod19 = Year % 19
        return ymod19 == 0 || ymod19 == 3 || ymod19 == 6 || ymod19 == 8 || ymod19 == 11 || ymod19 == 14 || ymod19 == 17
    }

    public static func DaysInYear(_ Year: Int) -> Int {
        let civilYear = Year - 3761
        let currentPesach = DateOfPesach(civilYear)
        let bGregorian = CAADate.AfterPapalReform(civilYear, currentPesach.Month, Double(currentPesach.Day))
        let currentYear = CAADate(civilYear, currentPesach.Month, Double(currentPesach.Day), bGregorian)

        let nextPesach = DateOfPesach(civilYear + 1)
        let nextYear = CAADate(civilYear + 1, nextPesach.Month, Double(nextPesach.Day), bGregorian)

        return Int(round(nextYear - currentYear))
    }
}

// MARK: - Islamic/Moslem Calendar (CAAMoslemCalendar)

public enum CAAMoslemCalendar: Sendable {
    public static func IsLeap(_ Year: Int) -> Bool {
        let r = Year % 30
        return [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29].contains(r)
    }

    public static func MoslemToJulian(_ Year: Int, _ Month: Int, _ Day: Int) -> CAACalendarDate {
        var julianDate = CAACalendarDate()
        let n = Day + CAADate.int(29.5001 * Double(Month - 1) + 0.99)
        let q = CAADate.int(Double(Year) / 30.0)
        let r = Year % 30
        let a = CAADate.int(((11.0 * Double(r)) + 3.0) / 30.0)
        let w = (404 * q) + (354 * r) + 208 + a
        let q1 = CAADate.int(Double(w) / 1461.0)
        let q2 = w % 1461
        let g = 621 + (4 * CAADate.int((7.0 * Double(q)) + Double(q1)))
        let k = CAADate.int(Double(q2) / 365.2422)
        let e = CAADate.int(365.2422 * Double(k))
        var j = q2 - e + n - 1
        var x = g + k

        let xMod4 = x % 4
        if j > 366 && xMod4 == 0 {
            j -= 366
            x += 1
        }
        if j > 365 && xMod4 > 0 {
            j -= 365
            x += 1
        }

        julianDate.Year = x
        CAADate.DayOfYearToDayAndMonth(j, CAADate.IsLeap(x, false), &julianDate.Day, &julianDate.Month)
        return julianDate
    }

    public static func JulianToMoslem(_ Year: Int, _ Month: Int, _ Day: Int) -> CAACalendarDate {
        var moslemDate = CAACalendarDate()
        let w = (Year % 4 != 0) ? 2 : 1
        let n = CAADate.int((275.0 * Double(Month)) / 9.0) - (w * CAADate.int(Double(Month + 9) / 12.0)) + Day - 30
        let a = Year - 623
        let b = CAADate.int(Double(a) / 4.0)
        let c = a % 4
        let c1 = 365.2501 * Double(c)
        var c2 = CAADate.int(c1)
        if (c1 - Double(c2)) > 0.5 {
            c2 += 1
        }

        let ddash = (1461 * b) + 170 + c2
        let q = CAADate.int(Double(ddash) / 10631.0)
        let r = ddash % 10631
        let j = CAADate.int(Double(r) / 354.0)
        let k = r % 354
        let o = CAADate.int(Double((11 * j) + 14) / 30.0)
        var h = (30 * q) + j + 1
        var jj = k - o + n - 1

        if jj > 354 {
            let cl = h % 30
            let dl = ((11 * cl) + 3) % 30
            if dl < 19 {
                jj -= 354
                h += 1
            } else {
                jj -= 355
                h += 1
            }
            if jj == 0 {
                jj = 355
                h -= 1
            }
        }

        let s = CAADate.int(Double(jj - 1) / 29.5)
        moslemDate.Month = 1 + s
        moslemDate.Day = CAADate.int(Double(jj) - (29.5 * Double(s)))
        moslemDate.Year = h

        if jj == 355 {
            moslemDate.Month = 12
            moslemDate.Day = 30
        }

        return moslemDate
    }
}
