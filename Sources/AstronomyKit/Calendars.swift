//
//  Calendars.swift
//  SwiftAA
//
//  Created for SwiftAA.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

/// Represents a date in the Islamic (Hijri / Moslem) calendar.
public struct HijriDate: Sendable, Codable, Hashable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int
    
    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
    
    public var description: String {
        return "\(year) AH, Month \(month), Day \(day)"
    }
    
    /// Converts this Hijri date to a Julian Date in the Julian calendar.
    public func toJulianCalendarDate() -> DateComponents {
        let d = CAAMoslemCalendar.MoslemToJulian(self.year, self.month, self.day)
        var comp = DateComponents()
        comp.year = Int(d.Year)
        comp.month = Int(d.Month)
        comp.day = Int(d.Day)
        return comp
    }
    
    /// Converts this Hijri date to a Gregorian calendar date via Julian Day conversion.
    public func toGregorianCalendarDate() -> DateComponents {
        let jd = JulianDay(hijri: self)
        let d = jd.date
        var comp = DateComponents()
        comp.year = d.year
        comp.month = d.month
        comp.day = d.day
        return comp
    }
    
    /// True if the specified Hijri year is a leap year (355 days instead of 354 days).
    public var isLeapYear: Bool {
        return CAAMoslemCalendar.IsLeap(self.year)
    }
}

/// Represents a date in the Jewish (Hebrew) calendar.
public struct JewishDate: Sendable, Codable, Hashable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int
    
    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
    
    public var description: String {
        return "\(year) AM, Month \(month), Day \(day)"
    }
    
    /// True if the specified Jewish year is a leap year (13 months instead of 12).
    public var isLeapYear: Bool {
        return CAAJewishCalendar.IsLeap(self.year)
    }
    
    /// Number of days in the specified Jewish year (353, 354, 355, 383, 384, or 385).
    public var daysInYear: Int {
        return Int(CAAJewishCalendar.DaysInYear(self.year))
    }
    
    /// Returns the Gregorian/Julian date of Pesach (Passover, 15 Nisan) for a given civil year.
    /// - Parameters:
    ///   - civilYear: The civil Gregorian year (e.g. 1990 for Jewish year 5750 AM).
    ///   - inGregorianCalendar: If true, returns date in Gregorian calendar; if false, in Julian calendar.
    public static func dateOfPesach(civilYear: Int, inGregorianCalendar: Bool = true) -> DateComponents {
        let d = CAAJewishCalendar.DateOfPesach(civilYear, inGregorianCalendar)
        var comp = DateComponents()
        comp.year = civilYear
        comp.month = Int(d.Month)
        comp.day = Int(d.Day)
        return comp
    }
}

/// Easter calculation utilities.
public struct Easter: Sendable {
    
    /// Computes the date of Easter Sunday for a given year.
    /// - Parameters:
    ///   - year: The civil year.
    ///   - inGregorianCalendar: If true, calculates Western Easter (Gregorian). If false, calculates Orthodox Easter (Julian).
    /// - Returns: DateComponents with month and day of Easter Sunday.
    public static func calculate(year: Int, inGregorianCalendar: Bool = true) -> DateComponents {
        let details = CAAEaster.Calculate(Int32(year), inGregorianCalendar)
        var comp = DateComponents()
        comp.year = year
        comp.month = Int(details.Month)
        comp.day = Int(details.Day)
        return comp
    }
}

// MARK: - JulianDay Calendar Extensions
public extension JulianDay {
    
    /// Convert a Julian calendar date to the equivalent Hijri date.
    func toHijri() -> HijriDate {
        let d = self.date
        let moslem = CAAMoslemCalendar.JulianToMoslem(d.year, d.month, d.day)
        return HijriDate(year: Int(moslem.Year), month: Int(moslem.Month), day: Int(moslem.Day))
    }
    
    /// Create a JulianDay from a Hijri (Islamic) calendar date.
    init(hijri: HijriDate) {
        let julianDate = CAAMoslemCalendar.MoslemToJulian(hijri.year, hijri.month, hijri.day)
        let aaDate = CAADate(Int(julianDate.Year), Int(julianDate.Month), Double(julianDate.Day), 0.0, 0.0, 0.0, false)
        self.init(aaDate.Julian())
    }
}
