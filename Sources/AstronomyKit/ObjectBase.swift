//
//  ObjectBase.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 18/07/16.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Base protocol used by all types of astronomical objects considered in SwiftAA,
/// planets, moons, the Earth, the Sun etc.
public protocol ObjectBase: Sendable {
    
    /// The julian day at which one considers the object.
    var julianDay: JulianDay { get }
    
    /// A boolean indicating whether high precision algorithms must be used.
    var highPrecision: Bool { get }
    
    /// The object name
    var name: String { get }

    /// Creates an object instance
    ///
    /// - Parameters:
    ///   - julianDay: The julian day at which one will consider the object
    ///   - highPrecision: If true (default), high precision algorithms are used when relevant to increase precision.
    init(julianDay: JulianDay, highPrecision: Bool)
}

/// The base class of all objects (Planets, Sun, Moons etc.).
open class Object : ObjectBase, @unchecked Sendable {
    /// The Julian Day at which the object is considered.
    public let julianDay: JulianDay
    
    /// The precision flag.
    public let highPrecision: Bool
    
    /// A convenience accesor returning the name of the object class.
    public var name: String {
         return String(describing: type(of: self)) 
    }

    /// Creates a new instance of the object.
    ///
    /// - Parameters:
    ///   - julianDay: The julian day at which one will consider the object
    ///   - highPrecision: An optional boolean indicating whether high precision must be used. Default is true.
    public required init(julianDay: JulianDay, highPrecision: Bool = true) {
        self.julianDay = julianDay
        self.highPrecision = highPrecision
    }
}
