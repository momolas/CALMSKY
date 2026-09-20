//
//  Mercury.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 19/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// The Mercury planet.
public final class Mercury: Planet, @unchecked Sendable {
    
    /// An average color of the planet
    public class override var averageColor: CelestialColor {
        get { return CelestialColor(red: 0.569, green:0.545, blue:0.506, alpha: 1.0) }
    }
}
