//
//  Asteroids.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 17/12/2016.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

/// See AA p. 391. AA+ result is given in kilometers
public func asteroidDiameter(magnitude: Magnitude, albedo: Double) -> Kilometer {
    return Kilometer(CAADiameters.AsteroidDiameter(magnitude.value, albedo))
}

/// See AA p. 391. AA+ result is given in kilometers
public func apparentAsteroidDiameter(magnitude: Magnitude, albedo: Double) -> ArcSecond {
    return ArcSecond(CAADiameters.ApparentAsteroidDiameter(magnitude.value, albedo))
}
