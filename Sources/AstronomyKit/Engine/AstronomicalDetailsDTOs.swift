//
//  AstronomicalDetailsDTOs.swift
//  AstronomyKit
//
//  Pure Swift data transfer types replacing legacy C++ AAplus struct headers.
//  Conforms to Sendable, Codable, Hashable with strict Swift 6 actor-isolation safety.
//

import Foundation
import simd

// MARK: - 2D & 3D Coordinates

public struct CAA2DCoordinate: Sendable, Codable, Hashable {
    public var X: Double
    public var Y: Double

    @inlinable public var x: Double {
        get { X }
        set { X = newValue }
    }
    @inlinable public var y: Double {
        get { Y }
        set { Y = newValue }
    }

    public init(X: Double = 0, Y: Double = 0) {
        self.X = X
        self.Y = Y
    }

    public init(_ x: Double, _ y: Double) {
        self.X = x
        self.Y = y
    }

    public init(x: Double, y: Double) {
        self.X = x
        self.Y = y
    }
}

public struct CAA3DCoordinate: Sendable, Codable, Hashable {
    public var X: Double
    public var Y: Double
    public var Z: Double

    @inlinable public var x: Double {
        get { X }
        set { X = newValue }
    }
    @inlinable public var y: Double {
        get { Y }
        set { Y = newValue }
    }
    @inlinable public var z: Double {
        get { Z }
        set { Z = newValue }
    }

    @inlinable
    public init(X: Double = 0, Y: Double = 0, Z: Double = 0) {
        self.X = X
        self.Y = Y
        self.Z = Z
    }

    @inlinable
    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.X = x
        self.Y = y
        self.Z = z
    }

    @inlinable
    public init(x: Double, y: Double, z: Double) {
        self.X = x
        self.Y = y
        self.Z = z
    }

    @inlinable
    public init(_ vector: Vector3D) {
        self.X = vector.x
        self.Y = vector.y
        self.Z = vector.z
    }

    @inlinable
    public init(_ simd: simd_double3) {
        self.X = simd.x
        self.Y = simd.y
        self.Z = simd.z
    }

    @inlinable
    public var vector3D: Vector3D {
        Vector3D(x: X, y: Y, z: Z)
    }

    @inlinable
    public var simd: simd_double3 {
        simd_double3(X, Y, Z)
    }
}

// MARK: - Calendar Dates & Easter

public struct CAACalendarDate: Sendable, Codable, Hashable {
    public var Year: Int
    public var Month: Int
    public var Day: Int

    public init(Year: Int = 0, Month: Int = 0, Day: Int = 0) {
        self.Year = Year
        self.Month = Month
        self.Day = Day
    }
}

public struct CAAEasterDetails: Sendable, Codable, Hashable {
    public var Month: Int
    public var Day: Int

    public init(Month: Int = 0, Day: Int = 0) {
        self.Month = Month
        self.Day = Day
    }
}

// MARK: - Lunar Details

public struct LunarPhysicalDetails: Sendable, Codable, Hashable {
    public var ldash: Double
    public var bdash: Double
    public var ldash2: Double
    public var bdash2: Double
    public var l: Double
    public var b: Double
    public var P: Double

    public init(ldash: Double = 0, bdash: Double = 0, ldash2: Double = 0, bdash2: Double = 0, l: Double = 0, b: Double = 0, P: Double = 0) {
        self.ldash = ldash
        self.bdash = bdash
        self.ldash2 = ldash2
        self.bdash2 = bdash2
        self.l = l
        self.b = b
        self.P = P
    }
}
public typealias CAAPhysicalMoonDetails = LunarPhysicalDetails

public struct SelenographicMoonDetails: Sendable, Codable, Hashable {
    public var l0: Double
    public var b0: Double
    public var c0: Double

    public init(l0: Double = 0, b0: Double = 0, c0: Double = 0) {
        self.l0 = l0
        self.b0 = b0
        self.c0 = c0
    }
}
public typealias CAASelenographicMoonDetails = SelenographicMoonDetails

// MARK: - Eclipses

public struct CAASolarEclipseDetails: Sendable, Codable, Hashable {
    public static let TOTAL_ECLIPSE: UInt32 = 0x01
    public static let ANNULAR_ECLIPSE: UInt32 = 0x02
    public static let ANNULAR_TOTAL_ECLIPSE: UInt32 = 0x04
    public static let CENTRAL_ECLIPSE: UInt32 = 0x08
    public static let PARTIAL_ECLIPSE: UInt32 = 0x10
    public static let NON_CENTRAL_ECLIPSE: UInt32 = 0x20

    public var Flags: UInt32
    public var TimeOfMaximumEclipse: Double
    public var F: Double
    public var u: Double
    public var gamma: Double
    public var GreatestMagnitude: Double

    public init(Flags: UInt32 = 0, TimeOfMaximumEclipse: Double = 0, F: Double = 0, u: Double = 0, gamma: Double = 0, GreatestMagnitude: Double = 0) {
        self.Flags = Flags
        self.TimeOfMaximumEclipse = TimeOfMaximumEclipse
        self.F = F
        self.u = u
        self.gamma = gamma
        self.GreatestMagnitude = GreatestMagnitude
    }
}

public struct CAALunarEclipseDetails: Sendable, Codable, Hashable {
    public var bEclipse: Bool
    public var TimeOfMaximumEclipse: Double
    public var F: Double
    public var u: Double
    public var gamma: Double
    public var PenumbralRadii: Double
    public var UmbralRadii: Double
    public var PenumbralMagnitude: Double
    public var UmbralMagnitude: Double
    public var PartialPhaseSemiDuration: Double
    public var TotalPhaseSemiDuration: Double
    public var PartialPhasePenumbraSemiDuration: Double

    public init(bEclipse: Bool = false, TimeOfMaximumEclipse: Double = 0, F: Double = 0, u: Double = 0, gamma: Double = 0, PenumbralRadii: Double = 0, UmbralRadii: Double = 0, PenumbralMagnitude: Double = 0, UmbralMagnitude: Double = 0, PartialPhaseSemiDuration: Double = 0, TotalPhaseSemiDuration: Double = 0, PartialPhasePenumbraSemiDuration: Double = 0) {
        self.bEclipse = bEclipse
        self.TimeOfMaximumEclipse = TimeOfMaximumEclipse
        self.F = F
        self.u = u
        self.gamma = gamma
        self.PenumbralRadii = PenumbralRadii
        self.UmbralRadii = UmbralRadii
        self.PenumbralMagnitude = PenumbralMagnitude
        self.UmbralMagnitude = UmbralMagnitude
        self.PartialPhaseSemiDuration = PartialPhaseSemiDuration
        self.TotalPhaseSemiDuration = TotalPhaseSemiDuration
        self.PartialPhasePenumbraSemiDuration = PartialPhasePenumbraSemiDuration
    }
}

// MARK: - Solar Physical Details

public struct PhysicalSunDetails: Sendable, Codable, Hashable {
    public var P: Double
    public var B0: Double
    public var L0: Double

    public init(P: Double = 0, B0: Double = 0, L0: Double = 0) {
        self.P = P
        self.B0 = B0
        self.L0 = L0
    }
}
public typealias CAAPhysicalSunDetails = PhysicalSunDetails

// MARK: - Planetary Physical Details

public struct PhysicalJupiterDetails: Sendable, Codable, Hashable {
    public var DE: Double
    public var DS: Double
    public var Geometricw1: Double
    public var Geometricw2: Double
    public var Apparentw1: Double
    public var Apparentw2: Double
    public var P: Double

    public init(DE: Double = 0, DS: Double = 0, Geometricw1: Double = 0, Geometricw2: Double = 0, Apparentw1: Double = 0, Apparentw2: Double = 0, P: Double = 0) {
        self.DE = DE
        self.DS = DS
        self.Geometricw1 = Geometricw1
        self.Geometricw2 = Geometricw2
        self.Apparentw1 = Apparentw1
        self.Apparentw2 = Apparentw2
        self.P = P
    }
}
public typealias CAAPhysicalJupiterDetails = PhysicalJupiterDetails

// MARK: - Binary Star Details

public struct CAABinaryStarDetails: Sendable, Codable, Hashable {
    public var r: Double = 0
    public var Theta: Double = 0
    public var Rho: Double = 0
    public var x: Double = 0
    public var y: Double = 0

    public init(r: Double = 0, Theta: Double = 0, Rho: Double = 0, x: Double = 0, y: Double = 0) {
        self.r = r
        self.Theta = Theta
        self.Rho = Rho
        self.x = x
        self.y = y
    }
}

// MARK: - Precession & Nutation Details

public struct PhysicalMarsDetails: Sendable, Codable, Hashable {
    public var DE: Double
    public var DS: Double
    public var w: Double
    public var P: Double
    public var X: Double
    public var k: Double
    public var q: Double
    public var d: Double

    public init(DE: Double = 0, DS: Double = 0, w: Double = 0, P: Double = 0, X: Double = 0, k: Double = 0, q: Double = 0, d: Double = 0) {
        self.DE = DE
        self.DS = DS
        self.w = w
        self.P = P
        self.X = X
        self.k = k
        self.q = q
        self.d = d
    }
}
public typealias CAAPhysicalMarsDetails = PhysicalMarsDetails

// MARK: - Elliptical & Parabolic Planetary and Object Details

public struct EllipticalPlanetaryDetails: Sendable, Codable, Hashable {
    public var ApparentGeocentricEclipticalLongitude: Double = 0
    public var ApparentGeocentricEclipticalLatitude: Double = 0
    public var ApparentGeocentricDistance: Double = 0
    public var ApparentLightTime: Double = 0
    public var ApparentGeocentricRA: Double = 0
    public var ApparentGeocentricDeclination: Double = 0
    public var TrueGeocentricRectangularEcliptical: CAA3DCoordinate = CAA3DCoordinate()
    public var TrueHeliocentricEclipticalLongitude: Double = 0
    public var TrueHeliocentricEclipticalLatitude: Double = 0
    public var TrueHeliocentricDistance: Double = 0
    public var TrueGeocentricEclipticalLongitude: Double = 0
    public var TrueGeocentricEclipticalLatitude: Double = 0
    public var TrueGeocentricDistance: Double = 0
    public var TrueLightTime: Double = 0
    public var TrueGeocentricRA: Double = 0
    public var TrueGeocentricDeclination: Double = 0

    public init() {}
}
public typealias CAAEllipticalPlanetaryDetails = EllipticalPlanetaryDetails

public struct EllipticalObjectDetails: Sendable, Codable, Hashable {
    public var HeliocentricRectangularEquatorial: CAA3DCoordinate = CAA3DCoordinate()
    public var HeliocentricRectangularEcliptical: CAA3DCoordinate = CAA3DCoordinate()
    public var HeliocentricEclipticLongitude: Double = 0
    public var HeliocentricEclipticLatitude: Double = 0
    public var TrueGeocentricRA: Double = 0
    public var TrueGeocentricDeclination: Double = 0
    public var TrueGeocentricDistance: Double = 0
    public var TrueGeocentricLightTime: Double = 0
    public var AstrometricGeocentricRA: Double = 0
    public var AstrometricGeocentricDeclination: Double = 0
    public var AstrometricGeocentricDistance: Double = 0
    public var AstrometricGeocentricLightTime: Double = 0
    public var Elongation: Double = 0
    public var PhaseAngle: Double = 0

    public init() {}
}
public typealias CAAEllipticalObjectDetails = EllipticalObjectDetails

public struct EllipticalObjectElements: Sendable, Codable, Hashable {
    public var a: Double
    public var e: Double
    public var i: Double
    public var w: Double
    public var omega: Double
    public var JDEquinox: Double
    public var T: Double

    public init(a: Double = 0, e: Double = 0, i: Double = 0, w: Double = 0, omega: Double = 0, JDEquinox: Double = 0, T: Double = 0) {
        self.a = a
        self.e = e
        self.i = i
        self.w = w
        self.omega = omega
        self.JDEquinox = JDEquinox
        self.T = T
    }
}
public typealias CAAEllipticalObjectElements = EllipticalObjectElements

public struct ParabolicObjectElements: Sendable, Codable, Hashable {
    public var q: Double
    public var i: Double
    public var w: Double
    public var omega: Double
    public var JDEquinox: Double
    public var T: Double

    public init(q: Double = 0, i: Double = 0, w: Double = 0, omega: Double = 0, JDEquinox: Double = 0, T: Double = 0) {
        self.q = q
        self.i = i
        self.w = w
        self.omega = omega
        self.JDEquinox = JDEquinox
        self.T = T
    }
}
public typealias CAAParabolicObjectElements = ParabolicObjectElements

public struct ParabolicObjectDetails: Sendable, Codable, Hashable {
    public var HeliocentricRectangularEquatorial: CAA3DCoordinate = CAA3DCoordinate()
    public var HeliocentricRectangularEcliptical: CAA3DCoordinate = CAA3DCoordinate()
    public var HeliocentricEclipticLongitude: Double = 0
    public var HeliocentricEclipticLatitude: Double = 0
    public var TrueGeocentricRA: Double = 0
    public var TrueGeocentricDeclination: Double = 0
    public var TrueGeocentricDistance: Double = 0
    public var TrueGeocentricLightTime: Double = 0
    public var AstrometricGeocentricRA: Double = 0
    public var AstrometricGeocentricDeclination: Double = 0
    public var AstrometricGeocentricDistance: Double = 0
    public var AstrometricGeocentricLightTime: Double = 0
    public var Elongation: Double = 0
    public var PhaseAngle: Double = 0

    public init() {}
}
public typealias CAAParabolicObjectDetails = ParabolicObjectDetails

// MARK: - Moons & Rings

public struct GalileanMoonDetail: Sendable, Codable, Hashable {
    public var MeanLongitude: Double = 0
    public var TrueLongitude: Double = 0
    public var TropicalLongitude: Double = 0
    public var EquatorialLatitude: Double = 0
    public var r: Double = 0
    public var TrueRectangularCoordinates: CAA3DCoordinate = CAA3DCoordinate()
    public var ApparentRectangularCoordinates: CAA3DCoordinate = CAA3DCoordinate()
    public var bInTransit: Bool = false
    public var bInOccultation: Bool = false
    public var bInEclipse: Bool = false
    public var bInShadowTransit: Bool = false

    public init() {}
}
public typealias CAAGalileanMoonDetail = GalileanMoonDetail

public struct GalileanMoonsDetails: Sendable, Codable, Hashable {
    public var Satellite1: CAAGalileanMoonDetail = CAAGalileanMoonDetail()
    public var Satellite2: CAAGalileanMoonDetail = CAAGalileanMoonDetail()
    public var Satellite3: CAAGalileanMoonDetail = CAAGalileanMoonDetail()
    public var Satellite4: CAAGalileanMoonDetail = CAAGalileanMoonDetail()

    public init() {}
}
public typealias CAAGalileanMoonsDetails = GalileanMoonsDetails

public struct SaturnianMoonDetail: Sendable, Codable, Hashable {
    public var TrueRectangularCoordinates: CAA3DCoordinate = CAA3DCoordinate()
    public var ApparentRectangularCoordinates: CAA3DCoordinate = CAA3DCoordinate()
    public var bInTransit: Bool = false
    public var bInOccultation: Bool = false
    public var bInEclipse: Bool = false
    public var bInShadowTransit: Bool = false

    public init() {}
}
public typealias CAASaturnMoonDetail = SaturnianMoonDetail

public struct SaturnMoonsDetails: Sendable, Codable, Hashable {
    public var Satellite1: CAASaturnMoonDetail = CAASaturnMoonDetail()
    public var Satellite2: CAASaturnMoonDetail = CAASaturnMoonDetail()
    public var Satellite3: CAASaturnMoonDetail = CAASaturnMoonDetail()
    public var Satellite4: CAASaturnMoonDetail = CAASaturnMoonDetail()
    public var Satellite5: CAASaturnMoonDetail = CAASaturnMoonDetail()
    public var Satellite6: CAASaturnMoonDetail = CAASaturnMoonDetail()
    public var Satellite7: CAASaturnMoonDetail = CAASaturnMoonDetail()
    public var Satellite8: CAASaturnMoonDetail = CAASaturnMoonDetail()

    public init() {}
}
public typealias CAASaturnMoonsDetails = SaturnMoonsDetails

public struct SaturnRingDetails: Sendable, Codable, Hashable {
    public var B: Double = 0
    public var Bdash: Double = 0
    public var P: Double = 0
    public var a: Double = 0
    public var b: Double = 0
    public var DeltaU: Double = 0
    public var U1: Double = 0
    public var U2: Double = 0

    public init() {}
}
public typealias CAASaturnRingDetails = SaturnRingDetails

// MARK: - Rise, Transit & Set

public struct CAARiseTransitSetDetails: Sendable, Codable, Hashable {
    public var bValid: Bool = false
    public var bRiseValid: Bool = false
    public var Rise: Double = 0
    public var bTransitValid: Bool = false
    public var bTransitAboveHorizon: Bool = false
    public var Transit: Double = 0
    public var bSetValid: Bool = false
    public var Set: Double = 0

    public init() {}
}
