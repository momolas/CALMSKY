//
//  Formatting.swift
//  SwiftAA
//
//  Created for SwiftAA.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Format style for Degrees in sexagesimal notation (e.g. `+12° 34' 56.78"`).
public struct SexagesimalFormatStyle: FormatStyle, Sendable {
    public typealias FormatInput = Degree
    public typealias FormatOutput = String
    
    public var includeSign: Bool
    public var fractionDigits: Int
    
    public init(includeSign: Bool = true, fractionDigits: Int = 2) {
        self.includeSign = includeSign
        self.fractionDigits = fractionDigits
    }
    
    public func format(_ value: Degree) -> String {
        let isNegative = value.value < 0
        let absVal = abs(value.value)
        let deg = Int(absVal)
        let remMinutes = (absVal - Double(deg)) * 60.0
        let minutes = Int(remMinutes)
        let seconds = (remMinutes - Double(minutes)) * 60.0
        
        let signPrefix: String
        if isNegative {
            signPrefix = "-"
        } else if includeSign {
            signPrefix = "+"
        } else {
            signPrefix = ""
        }
        
        let secFormatted = String(format: "%0*.*f", fractionDigits > 0 ? fractionDigits + 3 : 2, fractionDigits, seconds)
        return "\(signPrefix)\(deg)° \(String(format: "%02d", minutes))' \(secFormatted)\""
    }
}

/// Format style for Hours in Right Ascension notation (e.g. `12h 34m 56.78s`).
public struct RightAscensionFormatStyle: FormatStyle, Sendable {
    public typealias FormatInput = Hour
    public typealias FormatOutput = String
    
    public var fractionDigits: Int
    
    public init(fractionDigits: Int = 2) {
        self.fractionDigits = fractionDigits
    }
    
    public func format(_ value: Hour) -> String {
        let absVal = abs(value.value)
        let hours = Int(absVal)
        let remMinutes = (absVal - Double(hours)) * 60.0
        let minutes = Int(remMinutes)
        let seconds = (remMinutes - Double(minutes)) * 60.0
        
        let secFormatted = String(format: "%0*.*f", fractionDigits > 0 ? fractionDigits + 3 : 2, fractionDigits, seconds)
        return "\(hours)h \(String(format: "%02d", minutes))m \(secFormatted)s"
    }
}

public extension FormatStyle where Self == SexagesimalFormatStyle {
    static var sexagesimal: SexagesimalFormatStyle {
        SexagesimalFormatStyle()
    }
    
    static func sexagesimal(includeSign: Bool = true, fractionDigits: Int = 2) -> SexagesimalFormatStyle {
        SexagesimalFormatStyle(includeSign: includeSign, fractionDigits: fractionDigits)
    }
}

public extension FormatStyle where Self == RightAscensionFormatStyle {
    static var rightAscension: RightAscensionFormatStyle {
        RightAscensionFormatStyle()
    }
    
    static func rightAscension(fractionDigits: Int = 2) -> RightAscensionFormatStyle {
        RightAscensionFormatStyle(fractionDigits: fractionDigits)
    }
}

public extension Degree {
    func formatted(_ style: SexagesimalFormatStyle = .sexagesimal) -> String {
        style.format(self)
    }
}

public extension Hour {
    func formatted(_ style: RightAscensionFormatStyle = .rightAscension) -> String {
        style.format(self)
    }
}
