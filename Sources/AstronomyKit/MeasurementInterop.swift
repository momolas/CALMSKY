//
//  MeasurementInterop.swift
//  SwiftAA
//
//  Created for SwiftAA.
//  MIT Licence. See LICENCE file.
//

import Foundation

// MARK: - UnitAngle Interoperability
public extension Degree {
    /// Convert to Foundation `Measurement<UnitAngle>` in degrees.
    var measurement: Measurement<UnitAngle> {
        Measurement(value: self.value, unit: .degrees)
    }
    
    /// Initialize from a Foundation `Measurement<UnitAngle>`.
    init(_ measurement: Measurement<UnitAngle>) {
        self.init(measurement.converted(to: .degrees).value)
    }
}

public extension ArcSecond {
    /// Convert to Foundation `Measurement<UnitAngle>` in arc seconds.
    var measurement: Measurement<UnitAngle> {
        Measurement(value: self.value, unit: .arcSeconds)
    }
    
    /// Initialize from a Foundation `Measurement<UnitAngle>`.
    init(_ measurement: Measurement<UnitAngle>) {
        self.init(measurement.converted(to: .arcSeconds).value)
    }
}

public extension ArcMinute {
    /// Convert to Foundation `Measurement<UnitAngle>` in arc minutes.
    var measurement: Measurement<UnitAngle> {
        Measurement(value: self.value, unit: .arcMinutes)
    }
    
    /// Initialize from a Foundation `Measurement<UnitAngle>`.
    init(_ measurement: Measurement<UnitAngle>) {
        self.init(measurement.converted(to: .arcMinutes).value)
    }
}

// MARK: - UnitLength Interoperability
public extension AstronomicalUnit {
    /// Convert to Foundation `Measurement<UnitLength>` in astronomical units.
    var measurement: Measurement<UnitLength> {
        Measurement(value: self.value, unit: .astronomicalUnits)
    }
    
    /// Initialize from a Foundation `Measurement<UnitLength>`.
    init(_ measurement: Measurement<UnitLength>) {
        self.init(measurement.converted(to: .astronomicalUnits).value)
    }
}

public extension Kilometer {
    /// Convert to Foundation `Measurement<UnitLength>` in kilometers.
    var measurement: Measurement<UnitLength> {
        Measurement(value: self.value, unit: .kilometers)
    }
    
    /// Initialize from a Foundation `Measurement<UnitLength>`.
    init(_ measurement: Measurement<UnitLength>) {
        self.init(measurement.converted(to: .kilometers).value)
    }
}

// MARK: - UnitDuration Interoperability
public extension Day {
    /// Convert to Foundation `Measurement<UnitDuration>` in hours/seconds.
    var measurement: Measurement<UnitDuration> {
        Measurement(value: self.value * 24.0 * 3600.0, unit: .seconds)
    }
}
