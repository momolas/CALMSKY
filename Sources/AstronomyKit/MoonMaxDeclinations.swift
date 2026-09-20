//
//  MoonMaxDeclinations.swift
//  SwiftAA
//
//  Created for SwiftAA.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

/// Lunar standstill (maximum declination) details.
public struct MoonMaxDeclinationDetails: Sendable, Codable, Hashable {
    /// Julian Day of greatest declination
    public let julianDay: JulianDay
    /// Value of greatest declination
    public let declination: Degree
    /// Northerly (maximum positive) or Southerly (maximum negative)
    public let isNortherly: Bool
    
    public init(julianDay: JulianDay, declination: Degree, isNortherly: Bool) {
        self.julianDay = julianDay
        self.declination = declination
        self.isNortherly = isNortherly
    }
}

public extension Moon {
    
    /// Calculate the Julian Day and declination value of the Moon's greatest declination (lunar standstill) near a given decimal year.
    /// - Parameters:
    ///   - decimalYear: The year (e.g. 2024.5)
    ///   - northerly: If true, calculates greatest Northern declination (+). If false, greatest Southern declination (-).
    /// - Returns: MoonMaxDeclinationDetails
    static func greatestDeclination(nearYear decimalYear: Double, northerly: Bool = true) -> MoonMaxDeclinationDetails {
        let k = CAAMoonMaxDeclinations.K(decimalYear)
        let jd = CAAMoonMaxDeclinations.TrueGreatestDeclination(k, northerly)
        let decValue = CAAMoonMaxDeclinations.TrueGreatestDeclinationValue(k, northerly)
        let signedDec = northerly ? decValue : -decValue
        return MoonMaxDeclinationDetails(
            julianDay: JulianDay(jd),
            declination: Degree(signedDec),
            isNortherly: northerly
        )
    }
}
