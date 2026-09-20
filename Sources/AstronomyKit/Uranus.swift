//
//  Uranus.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 19/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// The Uranus planet
public final class Uranus: Planet, @unchecked Sendable {
    
    /// The average color of the planet
    public class override var averageColor: CelestialColor {
        get { return CelestialColor(red: 0.639, green:0.804, blue:0.839, alpha: 1.0) }
    } 
}
