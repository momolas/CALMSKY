//
//  AstronomyTestingSupport.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

@_exported import Testing
@_exported import Foundation
@testable import AstronomyKit

/// Type-safe floating point tolerance assertion for NumericType values in Swift Testing.
public func expectEqual<T: NumericType>(
    _ value1: T,
    _ value2: T,
    accuracy: T? = nil,
    _ comment: Comment? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    if let acc = accuracy {
        #expect(abs(value1.value - value2.value) <= acc.value, comment, sourceLocation: sourceLocation)
    } else {
        #expect(value1.value == value2.value, comment, sourceLocation: sourceLocation)
    }
}

/// Floating point equality check with accuracy tolerance for standard BinaryFloatingPoint types.
public func expectEqual<T: BinaryFloatingPoint>(
    _ value1: T,
    _ value2: T,
    accuracy: T,
    _ comment: Comment? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(abs(value1 - value2) <= accuracy, comment, sourceLocation: sourceLocation)
}

/// Convenience alias maintaining full backward-compatibility with legacy test calls while forwarding sourceLocation.
public func AssertEqual<T: NumericType>(
    _ value1: T,
    _ value2: T,
    accuracy: T? = nil,
    _ comment: String = "",
    sourceLocation: SourceLocation = #_sourceLocation
) {
    if let acc = accuracy {
        #expect(abs(value1.value - value2.value) <= acc.value, Comment(rawValue: comment), sourceLocation: sourceLocation)
    } else {
        #expect(value1.value == value2.value, Comment(rawValue: comment), sourceLocation: sourceLocation)
    }
}

/// Convenience alias for BinaryFloatingPoint types with accuracy tolerance and sourceLocation forwarding.
public func AssertEqual<T: BinaryFloatingPoint>(
    _ value1: T,
    _ value2: T,
    accuracy: T,
    _ comment: String = "",
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(abs(value1 - value2) <= accuracy, Comment(rawValue: comment), sourceLocation: sourceLocation)
}
