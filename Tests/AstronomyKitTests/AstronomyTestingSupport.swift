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

/// Legacy compatibility shims mapping to modern Swift Testing #expect
public func XCTAssertEqual<T: Equatable>(_ a: T, _ b: T, _ comment: String = "", sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(a == b, Comment(rawValue: comment), sourceLocation: sourceLocation)
}

public func XCTAssertNotEqual<T: Equatable>(_ a: T, _ b: T, _ comment: String = "", sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(a != b, Comment(rawValue: comment), sourceLocation: sourceLocation)
}

public func XCTAssertTrue(_ condition: Bool, _ comment: String = "", sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(condition, Comment(rawValue: comment), sourceLocation: sourceLocation)
}

public func XCTAssertFalse(_ condition: Bool, _ comment: String = "", sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(!condition, Comment(rawValue: comment), sourceLocation: sourceLocation)
}

public func XCTAssertNil(_ value: Any?, _ comment: String = "", sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(value == nil, Comment(rawValue: comment), sourceLocation: sourceLocation)
}

public func XCTAssertNotNil(_ value: Any?, _ comment: String = "", sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(value != nil, Comment(rawValue: comment), sourceLocation: sourceLocation)
}

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

/// Convenience alias maintaining full backward-compatibility with legacy test calls.
public func AssertEqual<T: NumericType>(
    _ value1: T,
    _ value2: T,
    accuracy: T? = nil,
    _ comment: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    if let acc = accuracy {
        #expect(abs(value1.value - value2.value) <= acc.value, Comment(rawValue: comment))
    } else {
        #expect(value1.value == value2.value, Comment(rawValue: comment))
    }
}
