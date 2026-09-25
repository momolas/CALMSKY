//
//  Venus.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 18/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// The Venus planet
public final class Venus: Planet, @unchecked Sendable {
    
    public override var name: String { "Venus" }
    public override var planet: KPCAAPlanet { .KPCAAPlanetVenus }
    public override var planetStrict: KPCAAPlanetStrict { .KPCAAPlanetStrictVenus }
    public override var planetaryObject: KPCPlanetaryObject { .KPCPlanetaryObjectVENUS }
    public override var ellipticalObject: KPCAAEllipticalObject { .KPCAAEllipticalObjectVENUS }

    /// The average color of the planet.
    public class override var averageColor: CelestialColor {
        get { return CelestialColor(red: 0.784, green:0.471, blue:0.137, alpha: 1.0) }
    }
}
