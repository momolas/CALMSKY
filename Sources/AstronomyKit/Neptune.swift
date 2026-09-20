//
//  Neptune.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 19/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// The Neptune planet
public final class Neptune: Planet, @unchecked Sendable {
    
    /// The average color of the planet
    public class override var averageColor: CelestialColor {
        get { return CelestialColor(red: 0.392, green:0.518, blue:0.871, alpha: 1.0) }
    }
}

