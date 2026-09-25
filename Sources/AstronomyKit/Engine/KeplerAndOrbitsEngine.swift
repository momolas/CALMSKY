//
//  KeplerAndOrbitsEngine.swift
//  AstronomyKit
//
//  Pure Swift celestial mechanics, Kepler solver, orbital elements,
//  parabolic/elliptical orbits, binary stars, planetary phenomena & perihelion/aphelion.
//  Replaces AAKepler, AAFK5, AAParabolic, AABinaryStar, AAElliptical,
//  AAPlanetaryPhenomena, AAElementsPlanetaryOrbit, and AAPlanetPerihelionAphelion from AAplus.
//

import Foundation

// MARK: - Kepler Solver (CAAKepler)

public enum CAAKepler: Sendable {
    public static func Calculate(_ M: Double, _ e: Double, _ nIterations: Int = 53) -> Double {
        var m = SphericalTrigonometry.degreesToRadians(M)
        let pi = Double.pi

        var f = 1.0
        if m < 0 { f = -1.0 }
        m = abs(m) / (2.0 * pi)
        m = (m - floor(m)) * 2.0 * pi * f
        if m < 0 { m += 2.0 * pi }
        f = 1.0
        if m > pi {
            m = (2.0 * pi) - m
            f = -1.0
        }

        var capitalE = pi / 2.0
        var d = pi / 4.0
        for _ in 0..<nIterations {
            let m1 = capitalE - (e * sin(capitalE))
            if m > m1 {
                capitalE += d
            } else {
                capitalE -= d
            }
            d /= 2.0
        }

        return SphericalTrigonometry.radiansToDegrees(capitalE) * f
    }
}

// MARK: - Binary Star Orbit Engine (CAABinaryStar)

public enum CAABinaryStar: Sendable {
    public static func Calculate(_ t: Double, _ P: Double, _ T: Double, _ e: Double, _ a: Double, _ i: Double, _ omega: Double, _ w: Double) -> CAABinaryStarDetails {
        let n = 360.0 / P
        let M = SphericalTrigonometry.mapTo0To360Range(n * (t - T))
        let E = SphericalTrigonometry.degreesToRadians(CAAKepler.Calculate(M, e))
        let iRad = SphericalTrigonometry.degreesToRadians(i)
        let wRad = SphericalTrigonometry.degreesToRadians(w)
        let omegaRad = SphericalTrigonometry.degreesToRadians(omega)

        let cosi = cos(iRad)
        let cosomega = cos(omegaRad)
        let sinomega = sin(omegaRad)
        let cosw = cos(wRad)
        let sinw = sin(wRad)

        // Thiele-Innes elements
        let A = a * ((cosw * cosomega) - (sinw * sinomega * cosi))
        let B = a * ((cosw * sinomega) + (sinw * cosomega * cosi))
        let F = a * ((-sinw * cosomega) - (cosw * sinomega * cosi))
        let G = a * ((-sinw * sinomega) + (cosw * cosomega * cosi))

        let cosE = cos(E)
        let X = cosE - e
        let Y = sqrt(1.0 - (e * e)) * sin(E)

        var details = CAABinaryStarDetails()
        details.x = A * X + F * Y
        details.y = B * X + G * Y
        details.r = a * (1.0 - e * cosE)
        details.Theta = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(atan2(details.y, details.x)))
        details.Rho = sqrt((details.x * details.x) + (details.y * details.y))
        return details
    }

    public static func ApparentEccentricity(_ e: Double, _ i: Double, _ w: Double) -> Double {
        let iRad = SphericalTrigonometry.degreesToRadians(i)
        let wRad = SphericalTrigonometry.degreesToRadians(w)

        let cosi = cos(iRad)
        let cosw = cos(wRad)
        let sinw = sin(wRad)
        let esquared = e * e
        let A = (1.0 - (esquared * cosw * cosw)) * cosi * cosi
        let B = esquared * sinw * cosw * cosi
        let C = 1.0 - (esquared * sinw * sinw)
        let D = (A - C) * (A - C) + (4.0 * B * B)

        let sqrtD = sqrt(D)
        return sqrt((2.0 * sqrtD) / (A + C + sqrtD))
    }
}

// MARK: - Parabolic Orbit Engine (CAAParabolic)

public enum CAAParabolic: Sendable {
    public static func CalculateBarkers(_ W: Double, _ epsilon: Double = 0.000001) -> Double {
        var S = W / 3.0
        var bRecalc = true
        while bRecalc {
            let S2 = S * S
            let NextS = ((2.0 * S2 * S) + W) / (3.0 * (S2 + 1.0))
            bRecalc = abs(NextS - S) > epsilon
            S = NextS
        }
        return S
    }

    public static func Calculate(_ JD: Double, _ elements: CAAParabolicObjectElements, _ bHighPrecision: Bool = true, _ epsilon: Double = 0.000001) -> CAAParabolicObjectDetails {
        var Epsilon = CAANutation.MeanObliquityOfEcliptic(elements.JDEquinox)
        var JD0 = JD

        var details = CAAParabolicObjectDetails()

        Epsilon = SphericalTrigonometry.degreesToRadians(Epsilon)
        let omega = SphericalTrigonometry.degreesToRadians(elements.omega)
        let w = SphericalTrigonometry.degreesToRadians(elements.w)
        let i = SphericalTrigonometry.degreesToRadians(elements.i)

        let sinEpsilon = sin(Epsilon)
        let cosEpsilon = cos(Epsilon)
        let sinOmega = sin(omega)
        let cosOmega = cos(omega)
        let cosi = cos(i)
        let sini = sin(i)

        let F = cosOmega
        let G = sinOmega * cosEpsilon
        let H = sinOmega * sinEpsilon
        let P = -sinOmega * cosi
        let Q = (cosOmega * cosi * cosEpsilon) - (sini * sinEpsilon)
        let R = (cosOmega * cosi * sinEpsilon) + (sini * cosEpsilon)
        let a = sqrt((F * F) + (P * P))
        let b = sqrt((G * G) + (Q * Q))
        let c = sqrt((H * H) + (R * R))
        let A = atan2(F, P)
        let B = atan2(G, Q)
        let C = atan2(H, R)

        let SunCoord = CAASun.EquatorialRectangularCoordinatesAnyEquinox(JD, elements.JDEquinox, bHighPrecision)

        for j in 0..<2 {
            let W = 0.03649116245 / ((elements.q * sqrt(elements.q)) * (JD0 - elements.T))
            let s = CalculateBarkers(W, epsilon)
            let v = 2.0 * atan(s)
            let r = elements.q * (1.0 + (s * s))
            let x = r * a * sin(A + w + v)
            let y = r * b * sin(B + w + v)
            let z = r * c * sin(C + w + v)

            if j == 0 {
                details.HeliocentricRectangularEquatorial.X = x
                details.HeliocentricRectangularEquatorial.Y = y
                details.HeliocentricRectangularEquatorial.Z = z

                let u = w + v
                let cosu = cos(u)
                let sinu = sin(u)

                details.HeliocentricRectangularEcliptical.X = r * ((cosOmega * cosu) - (sinOmega * sinu * cosi))
                details.HeliocentricRectangularEcliptical.Y = r * ((sinOmega * cosu) + (cosOmega * sinu * cosi))
                details.HeliocentricRectangularEcliptical.Z = r * sini * sinu

                details.HeliocentricEclipticLongitude = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(atan2(details.HeliocentricRectangularEcliptical.Y, details.HeliocentricRectangularEcliptical.X)))
                details.HeliocentricEclipticLatitude = SphericalTrigonometry.radiansToDegrees(asin(details.HeliocentricRectangularEcliptical.Z / r))
            }

            let psi = SunCoord.X + x
            let psi2 = psi * psi
            let nu = SunCoord.Y + y
            let nu2 = nu * nu
            let sigma = SunCoord.Z + z

            let Alpha = SphericalTrigonometry.radiansToDegrees(atan2(nu, psi))
            let Delta = SphericalTrigonometry.radiansToDegrees(atan2(sigma, sqrt(psi2 + nu2)))
            let Distance = sqrt(psi2 + nu2 + (sigma * sigma))

            if j == 0 {
                details.TrueGeocentricRA = SphericalTrigonometry.mapTo0To24Range(Alpha / 15.0)
                details.TrueGeocentricDeclination = Delta
                details.TrueGeocentricDistance = Distance
                details.TrueGeocentricLightTime = CAAElliptical.DistanceToLightTime(Distance)
            } else {
                details.AstrometricGeocentricRA = SphericalTrigonometry.mapTo0To24Range(Alpha / 15.0)
                details.AstrometricGeocentricDeclination = Delta
                details.AstrometricGeocentricDistance = Distance
                details.AstrometricGeocentricLightTime = CAAElliptical.DistanceToLightTime(Distance)

                let RES = sqrt((SunCoord.X * SunCoord.X) + (SunCoord.Y * SunCoord.Y) + (SunCoord.Z * SunCoord.Z))
                let RES2 = RES * RES
                let r2 = r * r

                details.Elongation = SphericalTrigonometry.radiansToDegrees(acos(((RES2 + Distance * Distance - r2) / (2.0 * RES * Distance))))
                details.PhaseAngle = SphericalTrigonometry.radiansToDegrees(acos(((r2 + Distance * Distance - RES2) / (2.0 * r * Distance))))
            }

            if j == 0 {
                JD0 = JD - details.TrueGeocentricLightTime
            }
        }

        return details
    }
}

// MARK: - Elliptical Motion Engine (CAAElliptical)

public enum CAAElliptical: Sendable {
    public enum Object: Int, Sendable, CaseIterable {
        case SUN = 0
        case MERCURY = 1
        case VENUS = 2
        case MARS = 3
        case JUPITER = 4
        case SATURN = 5
        case URANUS = 6
        case NEPTUNE = 7
    }

    @inlinable
    public static func DistanceToLightTime(_ Distance: Double) -> Double {
        Distance * 0.0057755183
    }

    @inlinable
    public static func SemiMajorAxisFromPerihelionDistance(_ q: Double, _ e: Double) -> Double {
        q / (1.0 - e)
    }

    @inlinable
    public static func MeanMotionFromSemiMajorAxis(_ a: Double) -> Double {
        0.9856076686 / (a * sqrt(a))
    }

    @inlinable
    public static func InstantaneousVelocity(_ r: Double, _ a: Double) -> Double {
        42.1219 * sqrt((1.0 / r) - (1.0 / (2.0 * a)))
    }

    @inlinable
    public static func VelocityAtPerihelion(_ e: Double, _ a: Double) -> Double {
        29.7847 / sqrt(a) * sqrt((1.0 + e) / (1.0 - e))
    }

    @inlinable
    public static func VelocityAtAphelion(_ e: Double, _ a: Double) -> Double {
        29.7847 / sqrt(a) * sqrt((1.0 - e) / (1.0 + e))
    }

    public static func LengthOfEllipse(_ e: Double, _ a: Double) -> Double {
        let b = a * sqrt(1.0 - (e * e))
        return Double.pi * ((3.0 * (a + b)) - sqrt(((3.0 * a) + b) * (a + (3.0 * b))))
    }

    public static func CometMagnitude(_ g: Double, _ delta: Double, _ k: Double, _ r: Double) -> Double {
        g + (5.0 * log10(delta)) + (k * log10(r))
    }

    public static func MinorPlanetMagnitude(_ H: Double, _ delta: Double, _ G: Double, _ r: Double, _ PhaseAngle: Double) -> Double {
        let phi1 = exp(-3.33 * pow(tan(SphericalTrigonometry.degreesToRadians(PhaseAngle / 2.0)), 0.63))
        let phi2 = exp(-1.87 * pow(tan(SphericalTrigonometry.degreesToRadians(PhaseAngle / 2.0)), 1.22))
        return H + (5.0 * log10(r * delta)) - (2.5 * log10(((1.0 - G) * phi1) + (G * phi2)))
    }

    public static func Calculate(_ JD: Double, _ elements: CAAEllipticalObjectElements, _ bHighPrecision: Bool) -> CAAEllipticalObjectDetails {
        var Epsilon = CAANutation.MeanObliquityOfEcliptic(elements.JDEquinox)
        var JD0 = JD

        var details = CAAEllipticalObjectDetails()

        Epsilon = SphericalTrigonometry.degreesToRadians(Epsilon)
        let omega = SphericalTrigonometry.degreesToRadians(elements.omega)
        let w = SphericalTrigonometry.degreesToRadians(elements.w)
        let i = SphericalTrigonometry.degreesToRadians(elements.i)

        let sinEpsilon = sin(Epsilon)
        let cosEpsilon = cos(Epsilon)
        let sinOmega = sin(omega)
        let cosOmega = cos(omega)
        let cosi = cos(i)
        let sini = sin(i)

        let F = cosOmega
        let G = sinOmega * cosEpsilon
        let H = sinOmega * sinEpsilon
        let P = -sinOmega * cosi
        let Q = (cosOmega * cosi * cosEpsilon) - (sini * sinEpsilon)
        let R = (cosOmega * cosi * sinEpsilon) + (sini * cosEpsilon)
        let a = sqrt((F * F) + (P * P))
        let b = sqrt((G * G) + (Q * Q))
        let c = sqrt((H * H) + (R * R))
        let A = atan2(F, P)
        let B = atan2(G, Q)
        let C = atan2(H, R)
        let n = MeanMotionFromSemiMajorAxis(elements.a)

        let SunCoord = CAASun.EquatorialRectangularCoordinatesAnyEquinox(JD, elements.JDEquinox, bHighPrecision)

        for j in 0..<2 {
            let M = n * (JD0 - elements.T)
            var E = CAAKepler.Calculate(M, elements.e)
            E = SphericalTrigonometry.degreesToRadians(E)
            let v = 2.0 * atan(sqrt((1.0 + elements.e) / (1.0 - elements.e)) * tan(E / 2.0))
            let r = elements.a * (1.0 - (elements.e * cos(E)))
            let x = r * a * sin(A + w + v)
            let y = r * b * sin(B + w + v)
            let z = r * c * sin(C + w + v)

            if j == 0 {
                details.HeliocentricRectangularEquatorial.X = x
                details.HeliocentricRectangularEquatorial.Y = y
                details.HeliocentricRectangularEquatorial.Z = z

                let u = w + v
                let cosu = cos(u)
                let sinu = sin(u)

                details.HeliocentricRectangularEcliptical.X = r * ((cosOmega * cosu) - (sinOmega * sinu * cosi))
                details.HeliocentricRectangularEcliptical.Y = r * ((sinOmega * cosu) + (cosOmega * sinu * cosi))
                details.HeliocentricRectangularEcliptical.Z = r * sini * sinu

                details.HeliocentricEclipticLongitude = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(atan2(details.HeliocentricRectangularEcliptical.Y, details.HeliocentricRectangularEcliptical.X)))
                details.HeliocentricEclipticLatitude = SphericalTrigonometry.radiansToDegrees(asin(details.HeliocentricRectangularEcliptical.Z / r))
            }

            let psi = SunCoord.X + x
            let nu = SunCoord.Y + y
            let sigma = SunCoord.Z + z
            let psisquared = psi * psi
            let nusquared = nu * nu

            let Alpha = SphericalTrigonometry.radiansToDegrees(atan2(nu, psi))
            let Delta = SphericalTrigonometry.radiansToDegrees(atan2(sigma, sqrt(psisquared + nusquared)))
            let Distance = sqrt(psisquared + nusquared + (sigma * sigma))

            if j == 0 {
                details.TrueGeocentricRA = SphericalTrigonometry.mapTo0To24Range(Alpha / 15.0)
                details.TrueGeocentricDeclination = Delta
                details.TrueGeocentricDistance = Distance
                details.TrueGeocentricLightTime = DistanceToLightTime(Distance)
            } else {
                details.AstrometricGeocentricRA = SphericalTrigonometry.mapTo0To24Range(Alpha / 15.0)
                details.AstrometricGeocentricDeclination = Delta
                details.AstrometricGeocentricDistance = Distance
                details.AstrometricGeocentricLightTime = DistanceToLightTime(Distance)

                let RES = sqrt((SunCoord.X * SunCoord.X) + (SunCoord.Y * SunCoord.Y) + (SunCoord.Z * SunCoord.Z))
                let rsquared = r * r
                let Distancesquared = Distance * Distance
                details.Elongation = SphericalTrigonometry.radiansToDegrees(acos(((RES * RES) + Distancesquared - rsquared) / (2.0 * RES * Distance)))
                details.PhaseAngle = SphericalTrigonometry.radiansToDegrees(acos(((rsquared + Distancesquared - (RES * RES)) / (2.0 * r * Distance))))
            }

            if j == 0 {
                JD0 = JD - details.TrueGeocentricLightTime
            }
        }

        return details
    }

    public static func Calculate(_ JD: Double, _ object: Object, _ bHighPrecision: Bool) -> CAAEllipticalPlanetaryDetails {
        var details = CAAEllipticalPlanetaryDetails()

        var JD0 = JD
        var L0 = CAAEarth.EclipticLongitude(JD0, bHighPrecision)
        var B0 = CAAEarth.EclipticLatitude(JD0, bHighPrecision)
        let R0 = CAAEarth.RadiusVector(JD0, bHighPrecision)
        L0 = SphericalTrigonometry.degreesToRadians(L0)
        B0 = SphericalTrigonometry.degreesToRadians(B0)
        let cosB0 = cos(B0)

        var L = 0.0
        var B = 0.0
        var R = 0.0

        if object != .SUN {
            var bRecalc = true
            var bFirstRecalc = true
            var LPrevious = 0.0
            var BPrevious = 0.0
            var RPrevious = 0.0

            while bRecalc {
                switch object {
                case .MERCURY:
                    L = CAAMercury.EclipticLongitude(JD0, bHighPrecision)
                    B = CAAMercury.EclipticLatitude(JD0, bHighPrecision)
                    R = CAAMercury.RadiusVector(JD0, bHighPrecision)
                case .VENUS:
                    L = CAAVenus.EclipticLongitude(JD0, bHighPrecision)
                    B = CAAVenus.EclipticLatitude(JD0, bHighPrecision)
                    R = CAAVenus.RadiusVector(JD0, bHighPrecision)
                case .MARS:
                    L = CAAMars.EclipticLongitude(JD0, bHighPrecision)
                    B = CAAMars.EclipticLatitude(JD0, bHighPrecision)
                    R = CAAMars.RadiusVector(JD0, bHighPrecision)
                case .JUPITER:
                    L = CAAJupiter.EclipticLongitude(JD0, bHighPrecision)
                    B = CAAJupiter.EclipticLatitude(JD0, bHighPrecision)
                    R = CAAJupiter.RadiusVector(JD0, bHighPrecision)
                case .SATURN:
                    L = CAASaturn.EclipticLongitude(JD0, bHighPrecision)
                    B = CAASaturn.EclipticLatitude(JD0, bHighPrecision)
                    R = CAASaturn.RadiusVector(JD0, bHighPrecision)
                case .URANUS:
                    L = CAAUranus.EclipticLongitude(JD0, bHighPrecision)
                    B = CAAUranus.EclipticLatitude(JD0, bHighPrecision)
                    R = CAAUranus.RadiusVector(JD0, bHighPrecision)
                case .NEPTUNE:
                    L = CAANeptune.EclipticLongitude(JD0, bHighPrecision)
                    B = CAANeptune.EclipticLatitude(JD0, bHighPrecision)
                    R = CAANeptune.RadiusVector(JD0, bHighPrecision)
                default:
                    break
                }

                var bFirstCalc = false
                if !bFirstRecalc {
                    bRecalc = (abs(L - LPrevious) > 0.00001) || (abs(B - BPrevious) > 0.00001) || (abs(R - RPrevious) > 0.000001)
                    LPrevious = L
                    BPrevious = B
                    RPrevious = R
                } else {
                    bFirstCalc = true
                    bFirstRecalc = false
                    details.TrueHeliocentricEclipticalLongitude = L
                    details.TrueHeliocentricEclipticalLatitude = B
                    details.TrueHeliocentricDistance = R
                }

                let Lrad = SphericalTrigonometry.degreesToRadians(L)
                let Brad = SphericalTrigonometry.degreesToRadians(B)
                let cosB = cos(Brad)
                let cosL = cos(Lrad)
                let x = (R * cosB * cosL) - (R0 * cosB0 * cos(L0))
                let y = (R * cosB * sin(Lrad)) - (R0 * cosB0 * sin(L0))
                let z = (R * sin(Brad)) - (R0 * sin(B0))
                let distance = sqrt((x * x) + (y * y) + (z * z))
                if bFirstCalc {
                    details.TrueGeocentricRectangularEcliptical.X = x
                    details.TrueGeocentricRectangularEcliptical.Y = y
                    details.TrueGeocentricRectangularEcliptical.Z = z
                }

                if bRecalc {
                    JD0 = JD - DistanceToLightTime(distance)
                }
            }
        } else {
            var bRecalc = true
            var bFirstRecalc = true
            var LPrevious = 0.0
            var BPrevious = 0.0
            var RPrevious = 0.0

            while bRecalc {
                L = CAAEarth.EclipticLongitude(JD0, bHighPrecision)
                B = CAAEarth.EclipticLatitude(JD0, bHighPrecision)
                R = CAAEarth.RadiusVector(JD0, bHighPrecision)

                var bFirstCalc = false
                if !bFirstRecalc {
                    bRecalc = (abs(L - LPrevious) > 0.00001) || (abs(B - BPrevious) > 0.00001) || (abs(R - RPrevious) > 0.000001)
                    LPrevious = L
                    BPrevious = B
                    RPrevious = R
                } else {
                    bFirstCalc = true
                    bFirstRecalc = false
                }

                if bFirstCalc {
                    let Lrad = SphericalTrigonometry.degreesToRadians(L)
                    let Brad = SphericalTrigonometry.degreesToRadians(B)
                    let cosB = cos(Brad)
                    let cosL = cos(Lrad)
                    details.TrueGeocentricRectangularEcliptical.X = -R * cosB * cosL
                    details.TrueGeocentricRectangularEcliptical.Y = -R * cosB * sin(Lrad)
                    details.TrueGeocentricRectangularEcliptical.Z = -R * sin(Brad)
                }

                if bRecalc {
                    JD0 = JD - DistanceToLightTime(R)
                }
            }
        }

        var x = 0.0
        var y = 0.0
        var z = 0.0
        if object != .SUN {
            let Lrad = SphericalTrigonometry.degreesToRadians(L)
            let Brad = SphericalTrigonometry.degreesToRadians(B)
            let cosB = cos(Brad)
            let cosL = cos(Lrad)
            x = (R * cosB * cosL) - (R0 * cosB0 * cos(L0))
            y = (R * cosB * sin(Lrad)) - (R0 * cosB0 * sin(L0))
            z = (R * sin(Brad)) - (R0 * sin(B0))
        } else {
            let Lrad = SphericalTrigonometry.degreesToRadians(L)
            let Brad = SphericalTrigonometry.degreesToRadians(B)
            let cosB = cos(Brad)
            let cosL = cos(Lrad)
            x = -R * cosB * cosL
            y = -R * cosB * sin(Lrad)
            z = -R * sin(Brad)
        }

        var x2 = x * x
        var y2 = y * y
        details.ApparentGeocentricEclipticalLatitude = SphericalTrigonometry.radiansToDegrees(atan2(z, sqrt(x2 + y2)))
        details.ApparentGeocentricDistance = sqrt(x2 + y2 + (z * z))
        details.ApparentGeocentricEclipticalLongitude = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(atan2(y, x)))
        details.ApparentLightTime = DistanceToLightTime(details.ApparentGeocentricDistance)

        x2 = details.TrueGeocentricRectangularEcliptical.X * details.TrueGeocentricRectangularEcliptical.X
        y2 = details.TrueGeocentricRectangularEcliptical.Y * details.TrueGeocentricRectangularEcliptical.Y
        details.TrueGeocentricEclipticalLatitude = SphericalTrigonometry.radiansToDegrees(atan2(details.TrueGeocentricRectangularEcliptical.Z, sqrt(x2 + y2)))
        details.TrueGeocentricDistance = sqrt(x2 + y2 + (details.TrueGeocentricRectangularEcliptical.Z * details.TrueGeocentricRectangularEcliptical.Z))
        details.TrueGeocentricEclipticalLongitude = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(atan2(details.TrueGeocentricRectangularEcliptical.Y, details.TrueGeocentricRectangularEcliptical.X)))
        details.TrueLightTime = DistanceToLightTime(details.TrueGeocentricDistance)

        // Adjust for Aberration
        let aberration = CAAAberration.EclipticAberration(details.ApparentGeocentricEclipticalLongitude, details.ApparentGeocentricEclipticalLatitude, JD, bHighPrecision)
        details.ApparentGeocentricEclipticalLongitude += aberration.X
        details.ApparentGeocentricEclipticalLatitude += aberration.Y

        // Convert to FK5 system
        let deltaLong = CAAFK5.CorrectionInLongitude(details.ApparentGeocentricEclipticalLongitude, details.ApparentGeocentricEclipticalLatitude, JD)
        details.ApparentGeocentricEclipticalLatitude += CAAFK5.CorrectionInLatitude(details.ApparentGeocentricEclipticalLongitude, JD)
        details.ApparentGeocentricEclipticalLongitude += deltaLong

        // Correct for nutation
        let nutationInLongitude = CAANutation.NutationInLongitude(JD)
        details.ApparentGeocentricEclipticalLongitude += SphericalTrigonometry.dmsToDegrees(0, 0, nutationInLongitude)

        // Convert to RA and Dec
        let epsilon = CAANutation.TrueObliquityOfEcliptic(JD)
        let apparentEqu = SphericalTrigonometry.eclipticToEquatorial(details.ApparentGeocentricEclipticalLongitude, details.ApparentGeocentricEclipticalLatitude, epsilon)
        details.ApparentGeocentricRA = apparentEqu.X
        details.ApparentGeocentricDeclination = apparentEqu.Y

        let trueEqu = SphericalTrigonometry.eclipticToEquatorial(details.TrueGeocentricEclipticalLongitude, details.TrueGeocentricEclipticalLatitude, epsilon)
        details.TrueGeocentricRA = trueEqu.X
        details.TrueGeocentricDeclination = trueEqu.Y

        return details
    }
}

// MARK: - Planetary Phenomena (CAAPlanetaryPhenomena)

public enum CAAPlanetaryPhenomena: Sendable {
    public enum Planet: Int, Sendable, CaseIterable {
        case MERCURY = 0
        case VENUS = 1
        case MARS = 2
        case JUPITER = 3
        case SATURN = 4
        case URANUS = 5
        case NEPTUNE = 6
    }

    public enum TypeEnum: Int, Sendable, CaseIterable {
        case INFERIOR_CONJUNCTION = 0
        case SUPERIOR_CONJUNCTION = 1
        case OPPOSITION = 2
        case CONJUNCTION = 3
        case EASTERN_ELONGATION = 4
        case WESTERN_ELONGATION = 5
        case STATION1 = 6
        case STATION2 = 7
    }
    public typealias EventType = TypeEnum

    private struct PhenomenaCoeff: Sendable {
        let A: Double
        let B: Double
        let M0: Double
        let M1: Double
    }

    private static let g_PlanetaryPhenomenaCoefficient1: [PhenomenaCoeff] = [
        PhenomenaCoeff(A: 2451612.023, B: 115.8774771, M0: 63.5867, M1: 114.2088742),
        PhenomenaCoeff(A: 2451554.084, B: 115.8774771, M0: 6.4822, M1: 114.2088742),
        PhenomenaCoeff(A: 2451996.706, B: 583.921361, M0: 82.7311, M1: 215.513058),
        PhenomenaCoeff(A: 2451704.746, B: 583.921361, M0: 154.9745, M1: 215.513058),
        PhenomenaCoeff(A: 2452097.382, B: 779.936104, M0: 181.9573, M1: 48.705244),
        PhenomenaCoeff(A: 2451707.414, B: 779.936104, M0: 157.6047, M1: 48.705244),
        PhenomenaCoeff(A: 2451870.628, B: 398.884046, M0: 318.4681, M1: 33.140229),
        PhenomenaCoeff(A: 2451671.186, B: 398.884046, M0: 121.8980, M1: 33.140229),
        PhenomenaCoeff(A: 2451870.170, B: 378.091904, M0: 318.0172, M1: 12.647487),
        PhenomenaCoeff(A: 2451681.124, B: 378.091904, M0: 131.6934, M1: 12.647487),
        PhenomenaCoeff(A: 2451764.317, B: 369.656035, M0: 213.6884, M1: 4.333093),
        PhenomenaCoeff(A: 2451579.489, B: 369.656035, M0: 31.5219, M1: 4.333093),
        PhenomenaCoeff(A: 2451753.122, B: 367.486703, M0: 202.6544, M1: 2.194998),
        PhenomenaCoeff(A: 2451569.379, B: 367.486703, M0: 21.5569, M1: 2.194998)
    ]

    public static func K(_ Year: Double, _ planet: Planet, _ type: EventType) -> Double {
        var nCoefficient = 0
        if planet.rawValue >= Planet.MARS.rawValue {
            if type == .OPPOSITION {
                nCoefficient = planet.rawValue * 2
            } else {
                nCoefficient = (planet.rawValue * 2) + 1
            }
        } else {
            if type == .INFERIOR_CONJUNCTION {
                nCoefficient = planet.rawValue * 2
            } else {
                nCoefficient = (planet.rawValue * 2) + 1
            }
        }
        let coeff = g_PlanetaryPhenomenaCoefficient1[nCoefficient]
        return ((365.2425 * Year) + 1721060.0 - coeff.A) / coeff.B
    }

    public static func Mean(_ k: Double, _ planet: Planet, _ type: EventType) -> Double {
        var nCoefficient = 0
        if planet.rawValue >= Planet.MARS.rawValue {
            if type == .OPPOSITION {
                nCoefficient = planet.rawValue * 2
            } else {
                nCoefficient = (planet.rawValue * 2) + 1
            }
        } else {
            if type == .INFERIOR_CONJUNCTION {
                nCoefficient = planet.rawValue * 2
            } else {
                nCoefficient = (planet.rawValue * 2) + 1
            }
        }
        let coeff = g_PlanetaryPhenomenaCoefficient1[nCoefficient]
        return coeff.A + (coeff.B * k)
    }

    public static func True(_ k: Double, _ planet: Planet, _ type: EventType) -> Double {
        var JDE0 = 0.0
        if type == .WESTERN_ELONGATION || type == .EASTERN_ELONGATION || type == .STATION1 || type == .STATION2 {
            if planet.rawValue >= Planet.MARS.rawValue {
                JDE0 = Mean(k, planet, .OPPOSITION)
            } else {
                JDE0 = Mean(k, planet, .INFERIOR_CONJUNCTION)
            }
        } else {
            JDE0 = Mean(k, planet, type)
        }

        var nCoefficient = 0
        if planet.rawValue >= Planet.MARS.rawValue {
            if type == .OPPOSITION || type == .STATION1 || type == .STATION2 {
                nCoefficient = planet.rawValue * 2
            } else {
                nCoefficient = (planet.rawValue * 2) + 1
            }
        } else {
            if type == .INFERIOR_CONJUNCTION || type == .EASTERN_ELONGATION || type == .WESTERN_ELONGATION || type == .STATION1 || type == .STATION2 {
                nCoefficient = planet.rawValue * 2
            } else {
                nCoefficient = (planet.rawValue * 2) + 1
            }
        }

        let coeff = g_PlanetaryPhenomenaCoefficient1[nCoefficient]
        let Mdeg = SphericalTrigonometry.mapTo0To360Range(coeff.M0 + (coeff.M1 * k))
        let M = SphericalTrigonometry.degreesToRadians(Mdeg)
        let twoM = 2.0 * M
        let threeM = 3.0 * M
        let fourM = 4.0 * M
        let fiveM = 5.0 * M

        let T = (JDE0 - 2451545.0) / 36525.0
        let T2 = T * T

        var a = 0.0, b = 0.0, c = 0.0, d = 0.0, e = 0.0, f = 0.0, g = 0.0

        if planet == .JUPITER {
            a = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(82.74 + (40.76 * T)))
        } else if planet == .SATURN {
            a = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(82.74 + (40.76 * T)))
            b = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(29.86 + (1181.36 * T)))
            c = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(14.13 + (590.68 * T)))
            d = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(220.02 + (1262.87 * T)))
        } else if planet == .URANUS {
            e = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(207.83 + (8.51 * T)))
            f = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(108.84 + (419.96 * T)))
        } else if planet == .NEPTUNE {
            e = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(207.83 + (8.51 * T)))
            g = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(276.74 + (209.98 * T)))
        }

        var delta = 0.0
        switch planet {
        case .MERCURY:
            switch type {
            case .INFERIOR_CONJUNCTION:
                delta = (0.0545 + (0.0002 * T)) +
                    (sin(M) * (-6.2008 + (0.0074 * T) + (0.00003 * T2))) +
                    (cos(M) * (-3.2750 - (0.0197 * T) + (0.00001 * T2))) +
                    (sin(twoM) * (0.4737 - (0.0052 * T) - (0.00001 * T2))) +
                    (cos(twoM) * (0.8111 + (0.0033 * T) - (0.00002 * T2))) +
                    (sin(threeM) * (0.0037 + (0.0018 * T))) +
                    (cos(threeM) * (-0.1768 + (0.00001 * T2))) +
                    (sin(fourM) * (-0.0211 - (0.0004 * T))) +
                    (cos(fourM) * (0.0326 - (0.0003 * T))) +
                    (sin(fiveM) * (0.0083 + (0.0001 * T))) +
                    (cos(fiveM) * (-0.0040 + (0.0001 * T)))
            case .SUPERIOR_CONJUNCTION:
                delta = (-0.0548 - (0.0002 * T)) +
                    (sin(M) * (7.3894 - (0.0100 * T) - (0.00003 * T2))) +
                    (cos(M) * (3.2200 + (0.0197 * T) - (0.00001 * T2))) +
                    (sin(twoM) * (0.8383 - (0.0064 * T) - (0.00001 * T2))) +
                    (cos(twoM) * (0.9666 + (0.0039 * T) - (0.00003 * T2))) +
                    (sin(threeM) * (0.0770 - (0.0026 * T))) +
                    (cos(threeM) * (0.2758 + (0.0002 * T) - (0.00002 * T2))) +
                    (sin(fourM) * (-0.0128 - (0.0008 * T))) +
                    (cos(fourM) * (0.0734 - (0.0004 * T) - (0.00001 * T2))) +
                    (sin(fiveM) * (-0.0122 - (0.0002 * T))) +
                    (cos(fiveM) * (0.0173 - (0.0002 * T)))
            case .EASTERN_ELONGATION:
                delta = (-21.6101 + (0.0002 * T)) +
                    (sin(M) * (-1.9803 - (0.0060 * T) + (0.00001 * T2))) +
                    (cos(M) * (1.4151 - (0.0072 * T) - (0.00001 * T2))) +
                    (sin(twoM) * (0.5528 - (0.0005 * T) - (0.00001 * T2))) +
                    (cos(twoM) * (0.2905 + (0.0034 * T) + (0.00001 * T2))) +
                    (sin(threeM) * (-0.1121 - (0.0001 * T) + (0.00001 * T2))) +
                    (cos(threeM) * (-0.0098 - (0.0015 * T))) +
                    (sin(fourM) * 0.0192) +
                    (cos(fourM) * (0.0111 + (0.0004 * T))) +
                    (sin(fiveM) * -0.0061) +
                    (cos(fiveM) * (-0.0032 - (0.0001 * T2)))
            case .WESTERN_ELONGATION:
                delta = (21.6249 - (0.0002 * T)) +
                    (sin(M) * (0.1306 + 0.0065 * T)) +
                    (cos(M) * (-2.7661 - (0.0011 * T) + (0.00001 * T2))) +
                    (sin(twoM) * (0.2438 - (0.0024 * T) - (0.00001 * T2))) +
                    (cos(twoM) * (0.5767 + (0.0023 * T))) +
                    (sin(threeM) * 0.1041) +
                    (cos(threeM) * (-0.0184 + (0.0007 * T))) +
                    (sin(fourM) * (-0.0051 - (0.0001 * T))) +
                    (cos(fourM) * (0.0048 + (0.0001 * T))) +
                    (sin(fiveM) * 0.0026) +
                    (cos(fiveM) * 0.0037)
            case .STATION1:
                delta = (-11.0761 + (0.0003 * T)) +
                    (sin(M) * (-4.7321 + (0.0023 * T) + (0.00002 * T2))) +
                    (cos(M) * (-1.3230 - (0.0156 * T))) +
                    (sin(twoM) * (0.2270 - (0.0046 * T))) +
                    (cos(twoM) * (0.7184 + (0.0013 * T) - (0.00002 * T2))) +
                    (sin(threeM) * (0.0638 + (0.0016 * T))) +
                    (cos(threeM) * (-0.1655 + (0.0007 * T))) +
                    (sin(fourM) * (-0.0395 - (0.0003 * T))) +
                    (cos(fourM) * (0.0247 - (0.0006 * T))) +
                    (sin(fiveM) * 0.0131) +
                    (cos(fiveM) * (0.0008 + (0.0002 * T)))
            case .STATION2:
                delta = (11.1343 - (0.0001 * T)) +
                    (sin(M) * (-3.9137 + (0.0073 * T) + (0.00002 * T2))) +
                    (cos(M) * (-3.3861 - (0.0128 * T) + (0.00001 * T2))) +
                    (sin(twoM) * (0.5222 - (0.0040 * T) - (0.00002 * T2))) +
                    (cos(twoM) * (0.5929 + (0.0039 * T) - (0.00002 * T2))) +
                    (sin(threeM) * (-0.0593 + (0.0018 * T))) +
                    (cos(threeM) * (-0.1733 - (0.0007 * T) + (0.00001 * T2))) +
                    (sin(fourM) * (-0.0053 - (0.0006 * T))) +
                    (cos(fourM) * (0.0476 - (0.0001 * T))) +
                    (sin(fiveM) * (0.0070 + (0.0002 * T))) +
                    (cos(fiveM) * (-0.0115 + (0.0001 * T)))
            default: break
            }
        case .VENUS:
            switch type {
            case .INFERIOR_CONJUNCTION:
                delta = (-0.0096 + (0.0002 * T) - (0.00001 * T2)) +
                    (sin(M) * (2.0009 - (0.0033 * T) - (0.00001 * T2))) +
                    (cos(M) * (0.5980 - (0.0104 * T) + (0.00001 * T2))) +
                    (sin(twoM) * (0.0967 - (0.0018 * T) - (0.00003 * T2))) +
                    (cos(twoM) * (0.0913 + (0.0009 * T) - (0.00002 * T2))) +
                    (sin(threeM) * (0.0046 - (0.0002 * T))) +
                    (cos(threeM) * (0.0079 + (0.0001 * T)))
            case .SUPERIOR_CONJUNCTION:
                delta = (0.0099 - (0.0002 * T) - (0.00001 * T2)) +
                    (sin(M) * (4.1991 - (0.0121 * T) - (0.00003 * T2))) +
                    (cos(M) * (-0.6095 + (0.0102 * T) - (0.00002 * T2))) +
                    (sin(twoM) * (0.2500 - (0.0028 * T) - (0.00003 * T2))) +
                    (cos(twoM) * (0.0063 + (0.0025 * T) - (0.00002 * T2))) +
                    (sin(threeM) * (0.0232 - (0.0005 * T) - (0.00001 * T2))) +
                    (cos(threeM) * (0.0031 + (0.0004 * T)))
            case .EASTERN_ELONGATION:
                delta = (-70.7600 + (0.0002 * T) - (0.00001 * T2)) +
                    (sin(M) * (1.0282 - (0.0010 * T) - (0.00001 * T2))) +
                    (cos(M) * (0.2761 - (0.0060 * T))) +
                    (sin(twoM) * (-0.0438 - (0.0023 * T) + (0.00002 * T2))) +
                    (cos(twoM) * (0.1660 - (0.0037 * T) - (0.00004 * T2))) +
                    (sin(threeM) * (0.0036 + (0.0001 * T))) +
                    (cos(threeM) * (-0.0011 + (0.00001 * T2)))
            case .WESTERN_ELONGATION:
                delta = (70.7462 - (0.00001 * T2)) +
                    (sin(M) * (1.1218 - (0.0025 * T) - (0.00001 * T2))) +
                    (cos(M) * (0.4538 - (0.0066 * T))) +
                    (sin(twoM) * (0.1320 + (0.0020 * T) - (0.00003 * T2))) +
                    (cos(twoM) * (-0.0702 + (0.0022 * T) + (0.00004 * T2))) +
                    (sin(threeM) * (0.0062 - (0.0001 * T))) +
                    (cos(threeM) * (0.0015 - (0.00001 * T2)))
            case .STATION1:
                delta = (-21.0672 + (0.0002 * T) - (0.00001 * T2)) +
                    (sin(M) * (1.9396 - (0.0029 * T) - (0.00001 * T2))) +
                    (cos(M) * (1.0727 - (0.0102 * T))) +
                    (sin(twoM) * (0.0404 - (0.0023 * T) - (0.00001 * T2))) +
                    (cos(twoM) * (0.1305 - (0.0004 * T) - (0.00003 * T2))) +
                    (sin(threeM) * (-0.0007 - (0.0002 * T))) +
                    (cos(threeM) * 0.0098)
            case .STATION2:
                delta = (21.0623 - (0.00001 * T2)) +
                    (sin(M) * (1.9913 - (0.0040 * T) - (0.00001 * T2))) +
                    (cos(M) * (-0.0407 - (0.0077 * T))) +
                    (sin(twoM) * (0.1351 - (0.0009 * T) - (0.00004 * T2))) +
                    (cos(twoM) * (0.0303 + (0.0019 * T))) +
                    (sin(threeM) * (0.0089 - (0.0002 * T))) +
                    (cos(threeM) * (0.0043 + (0.0001 * T)))
            default: break
            }
        case .MARS:
            switch type {
            case .OPPOSITION:
                delta = (-0.3088 + (0.00002 * T2)) +
                    (sin(M) * (-17.6965 + (0.0363 * T) + (0.00005 * T2))) +
                    (cos(M) * (18.3131 + (0.0467 * T) - (0.00006 * T2))) +
                    (sin(twoM) * (-0.2162 - (0.0198 * T) - (0.00001 * T2))) +
                    (cos(twoM) * (-4.5028 - (0.0019 * T) + (0.00007 * T2))) +
                    (sin(threeM) * (0.8987 + (0.0058 * T) - (0.00002 * T2))) +
                    (cos(threeM) * (0.7666 - (0.0050 * T) - (0.00003 * T2))) +
                    (sin(fourM) * (-0.3636 - (0.0001 * T) + (0.00002 * T2))) +
                    (cos(fourM) * (0.0402 + (0.0032 * T))) +
                    (sin(fiveM) * (0.0737 - (0.0008 * T))) +
                    (cos(fiveM) * (-0.0980 - (0.0011 * T)))
            case .CONJUNCTION:
                delta = (0.3102 - (0.0001 * T) + (0.00001 * T2)) +
                    (sin(M) * (9.7273 - (0.0156 * T) + (0.00001 * T2))) +
                    (cos(M) * (-18.3195 - (0.0467 * T) + (0.00009 * T2))) +
                    (sin(twoM) * (-1.6488 - (0.0133 * T) + (0.00001 * T2))) +
                    (cos(twoM) * (-2.6117 - (0.0020 * T) + (0.00004 * T2))) +
                    (sin(threeM) * (-0.6827 - (0.0026 * T) + (0.00001 * T2))) +
                    (cos(threeM) * (0.0281 + (0.0035 * T) + (0.00001 * T2))) +
                    (sin(fourM) * (-0.0823 + (0.0006 * T) + (0.00001 * T2))) +
                    (cos(fourM) * (0.1584 + (0.0013 * T))) +
                    (sin(fiveM) * (0.0270 + (0.0005 * T))) +
                    (cos(fiveM) * 0.0433)
            case .STATION1:
                delta = (-37.0790 - (0.0009 * T) + (0.00002 * T2)) +
                    (sin(M) * (-20.0651 + (0.0228 * T) + (0.00004 * T2))) +
                    (cos(M) * (14.5205 + (0.0504 * T) - (0.00001 * T2))) +
                    (sin(twoM) * (1.1737 - (0.0169 * T))) +
                    (cos(twoM) * (-4.2550 - (0.0075 * T) + (0.00008 * T2))) +
                    (sin(threeM) * (0.4897 + (0.0074 * T) - (0.00001 * T2))) +
                    (cos(threeM) * (1.1151 - (0.0021 * T) - (0.00005 * T2))) +
                    (sin(fourM) * (-0.3636 - (0.0020 * T) + (0.00001 * T2))) +
                    (cos(fourM) * (-0.1769 + (0.0028 * T) + (0.00002 * T2))) +
                    (sin(fiveM) * (0.1437 - (0.0004 * T))) +
                    (cos(fiveM) * (-0.0383 - (0.0016 * T)))
            case .STATION2:
                delta = (36.7191 + (0.0016 * T) + (0.00003 * T2)) +
                    (sin(M) * (-12.6163 + (0.0417 * T) - (0.00001 * T2))) +
                    (cos(M) * (20.1218 + (0.0379 * T) - (0.00006 * T2))) +
                    (sin(twoM) * (-1.6360 - (0.0190 * T))) +
                    (cos(twoM) * (-3.9657 + (0.0045 * T) + (0.00007 * T2))) +
                    (sin(threeM) * (1.1546 + (0.0029 * T) - (0.00003 * T2))) +
                    (cos(threeM) * (0.2888 - (0.0073 * T) - (0.00002 * T2))) +
                    (sin(fourM) * (-0.3128 + (0.0017 * T) + (0.00002 * T2))) +
                    (cos(fourM) * (0.2513 + (0.0026 * T) - (0.00002 * T2))) +
                    (sin(fiveM) * (-0.0021 - (0.0016 * T))) +
                    (cos(fiveM) * (-0.1497 - (0.0006 * T)))
            default: break
            }
        case .JUPITER:
            switch type {
            case .OPPOSITION:
                delta = (-0.1029 - (0.00009 * T2)) +
                    (sin(M) * (-1.9658 - (0.0056 * T) + (0.00007 * T2))) +
                    (cos(M) * (6.1537 + (0.0210 * T) - (0.00006 * T2))) +
                    (sin(twoM) * (-0.2081 - (0.0013 * T))) +
                    (cos(twoM) * (-0.1116 - (0.0010 * T))) +
                    (sin(threeM) * (0.0074 + (0.0001 * T))) +
                    (cos(threeM) * (-0.0097 - (0.0001 * T))) +
                    (sin(a) * (0.0144 * T - (0.00008 * T2))) +
                    (cos(a) * (0.3642 - (0.0019 * T) - (0.00029 * T2)))
            case .CONJUNCTION:
                delta = (0.1027 + (0.0002 * T) - (0.00009 * T2)) +
                    (sin(M) * (-2.2637 + (0.0163 * T) - (0.00003 * T2))) +
                    (cos(M) * (-6.1540 - (0.0210 * T) + (0.00008 * T2))) +
                    (sin(twoM) * (-0.2021 - (0.0017 * T) + (0.00001 * T2))) +
                    (cos(twoM) * (0.1310 - (0.0008 * T))) +
                    (sin(threeM) * 0.0086) +
                    (cos(threeM) * (0.0087 + (0.0002 * T))) +
                    (sin(a) * (0.0144 * T - (0.00008 * T2))) +
                    (cos(a) * (0.3642 - (0.0019 * T) - (0.00029 * T2)))
            case .STATION1:
                delta = (-60.3670 - (0.0001 * T) - (0.00009 * T2)) +
                    (sin(M) * (-2.3144 - (0.0124 * T) + (0.00007 * T2))) +
                    (cos(M) * (6.7439 + (0.0166 * T) - (0.00006 * T2))) +
                    (sin(twoM) * (-0.2259 - (0.0010 * T))) +
                    (cos(twoM) * (-0.1497 - (0.0014 * T))) +
                    (sin(threeM) * (0.0105 + (0.0001 * T))) +
                    (cos(threeM) * -0.0098) +
                    (sin(a) * (0.0144 * T - (0.00008 * T2))) +
                    (cos(a) * (0.3642 - (0.0019 * T) - (0.00029 * T2)))
            case .STATION2:
                delta = (60.3023 + (0.0002 * T) - (0.00009 * T2)) +
                    (sin(M) * (0.3506 - (0.0034 * T) + (0.00004 * T2))) +
                    (cos(M) * (5.3635 + (0.0247 * T) - (0.00007 * T2))) +
                    (sin(twoM) * (-0.1872 - (0.0016 * T))) +
                    (cos(twoM) * (-0.0037 - (0.0005 * T))) +
                    (sin(threeM) * (0.0012 + (0.0001 * T))) +
                    (cos(threeM) * (-0.0096 - (0.0001 * T))) +
                    (sin(a) * ((0.0144 * T) - (0.00008 * T2))) +
                    (cos(a) * (0.3642 - (0.0019 * T) - (0.00029 * T2)))
            default: break
            }
        case .SATURN:
            switch type {
            case .OPPOSITION:
                delta = (-0.0209 + (0.0006 * T) + (0.00023 * T2)) +
                    (sin(M) * (4.5795 - (0.0312 * T) - (0.00017 * T2))) +
                    (cos(M) * (1.1462 - (0.0351 * T) + (0.00011 * T2))) +
                    (sin(twoM) * (0.0985 - (0.0015 * T))) +
                    (cos(twoM) * (0.0733 - (0.0031 * T) + (0.00001 * T2))) +
                    (sin(threeM) * (0.0025 - (0.0001 * T))) +
                    (cos(threeM) * (0.0050 - (0.0002 * T))) +
                    (sin(a) * (-0.0337 * T + (0.00018 * T2))) +
                    (cos(a) * (-0.8510 + (0.0044 * T) + (0.00068 * T2))) +
                    (sin(b) * (-0.0064 * T + (0.00004 * T2))) +
                    (cos(b) * (0.2397 - (0.0012 * T) - (0.00008 * T2))) +
                    (sin(c) * (-0.0010 * T)) +
                    (cos(c) * (0.1245 + (0.0006 * T))) +
                    (sin(d) * ((0.0024 * T) - (0.00003 * T2))) +
                    (cos(d) * (0.0477 - (0.0005 * T) - (0.00006 * T2)))
            case .CONJUNCTION:
                delta = (0.0172 - (0.0006 * T) + (0.00023 * T2)) +
                    (sin(M) * (-8.5885 + (0.0411 * T) + (0.00020 * T2))) +
                    (cos(M) * (-1.1470 + (0.0352 * T) - (0.00011 * T2))) +
                    (sin(twoM) * (0.3331 - (0.0034 * T) - (0.00001 * T2))) +
                    (cos(twoM) * (0.1145 - (0.0045 * T) + (0.00002 * T2))) +
                    (sin(threeM) * (-0.0169 + (0.0002 * T))) +
                    (cos(threeM) * (-0.0109 + (0.0004 * T))) +
                    (sin(a) * ((-0.0337 * T) + (0.00018 * T2))) +
                    (cos(a) * (-0.8510 + (0.0044 * T) + (0.00068 * T2))) +
                    (sin(b) * ((-0.0064 * T) + (0.00004 * T2))) +
                    (cos(b) * (0.2397 - (0.0012 * T) - (0.00008 * T2))) +
                    (sin(c) * (-0.0010 * T)) +
                    (cos(c) * (0.1245 + (0.0006 * T))) +
                    (sin(d) * ((0.0024 * T) - (0.00003 * T2))) +
                    (cos(d) * (0.0477 - (0.0005 * T) - (0.00006 * T2)))
            case .STATION1:
                delta = (-68.8840 + (0.0009 * T) + (0.00023 * T2)) +
                    (sin(M) * (5.5452 - (0.0279 * T) - (0.00020 * T2))) +
                    (cos(M) * (3.0727 - (0.0430 * T) + (0.00007 * T2))) +
                    (sin(twoM) * (0.1101 - (0.0006 * T) - (0.00001 * T2))) +
                    (cos(twoM) * (0.1654 - (0.0043 * T) + (0.00001 * T2))) +
                    (sin(threeM) * (0.0010 + (0.0001 * T))) +
                    (cos(threeM) * (0.0095 - (0.0003 * T))) +
                    (sin(a) * (-0.0337 * T + (0.00018 * T2))) +
                    (cos(a) * (-0.8510 + (0.0044 * T) + (0.00068 * T2))) +
                    (sin(b) * ((-0.0064 * T) + (0.00004 * T2))) +
                    (cos(b) * (0.2397 - (0.0012 * T) - (0.00008 * T2))) +
                    (sin(c) * (-0.0010 * T)) +
                    (cos(c) * (0.1245 + (0.0006 * T))) +
                    (sin(d) * ((0.0024 * T) - (0.00003 * T2))) +
                    (cos(d) * (0.0477 - (0.0005 * T) - (0.00006 * T2)))
            case .STATION2:
                delta = (68.8720 - (0.0007 * T) + (0.00023 * T2)) +
                    (sin(M) * (5.9399 - (0.0400 * T) - (0.00015 * T2))) +
                    (cos(M) * (-0.7998 - (0.0266 * T) + (0.00014 * T2))) +
                    (sin(twoM) * (0.1738 - (0.0032 * T))) +
                    (cos(twoM) * (-0.0039 - (0.0024 * T) + (0.00001 * T2))) +
                    (sin(threeM) * (0.0073 - (0.0002 * T))) +
                    (cos(threeM) * (0.0020 - (0.0002 * T))) +
                    (sin(a) * (-0.0337 * T + (0.00018 * T2))) +
                    (cos(a) * (-0.8510 + (0.0044 * T) + (0.00068 * T2))) +
                    (sin(b) * (-0.0064 * T + (0.00004 * T2))) +
                    (cos(b) * (0.2397 - (0.0012 * T) - (0.00008 * T2))) +
                    (sin(c) * -0.0010 * T) +
                    (cos(c) * (0.1245 + (0.0006 * T))) +
                    (sin(d) * (0.0024 * T - (0.00003 * T2))) +
                    (cos(d) * (0.0477 - (0.0005 * T) - (0.00006 * T2)))
            default: break
            }
        case .URANUS:
            if type == .OPPOSITION {
                delta = (0.0844 - (0.0006 * T)) +
                    (sin(M) * (-0.1048 + (0.0246 * T))) +
                    (cos(M) * (-5.1221 + (0.0104 * T) + (0.00003 * T2))) +
                    (sin(twoM) * (-0.1428 - (0.0005 * T))) +
                    (cos(twoM) * (-0.0148 - (0.0013 * T))) +
                    (cos(threeM) * 0.0055) +
                    (cos(e) * 0.8850) +
                    (cos(f) * 0.2153)
            } else {
                delta = (-0.0859 + (0.0003 * T)) +
                    (sin(M) * (-3.8179 - (0.0148 * T) + (0.00003 * T2))) +
                    (cos(M) * (5.1228 - (0.0105 * T) - (0.00002 * T2))) +
                    (sin(twoM) * (-0.0803 + (0.0011 * T))) +
                    (cos(twoM) * (-0.1905 - (0.0006 * T))) +
                    (sin(threeM) * (0.0088 + (0.0001 * T))) +
                    (cos(e) * 0.8850) +
                    (cos(f) * 0.2153)
            }
        case .NEPTUNE:
            if type == .OPPOSITION {
                delta = (-0.0140 + (0.00001 * T2)) +
                    (sin(M) * (-1.3486 + (0.0010 * T) + (0.00001 * T2))) +
                    (cos(M) * (0.8597 + (0.0037 * T))) +
                    (sin(twoM) * (-0.0082 - (0.0002 * T) + (0.00001 * T2))) +
                    (cos(twoM) * (0.0037 - (0.0003 * T))) +
                    (cos(e) * -0.5964) +
                    (cos(g) * 0.0728)
            } else {
                delta = 0.0168 +
                    (sin(M) * (-2.5606 + (0.0088 * T) + (0.00002 * T2))) +
                    (cos(M) * (-0.8611 - (0.0037 * T) + (0.00002 * T2))) +
                    (sin(twoM) * (0.0118 - (0.0004 * T) + (0.00001 * T2))) +
                    (cos(twoM) * (0.0307 - (0.0003 * T))) +
                    (cos(e) * -0.5964) +
                    (cos(g) * 0.0728)
            }
        }

        return JDE0 + delta
    }

    public static func ElongationValue(_ k: Double, _ planet: Planet, _ bEastern: Bool) -> Double {
        let JDE0 = Mean(k, planet, .INFERIOR_CONJUNCTION)
        guard planet.rawValue < Planet.MARS.rawValue else { return 0.0 }

        let nCoefficient = planet.rawValue * 2
        let coeff = g_PlanetaryPhenomenaCoefficient1[nCoefficient]
        let Mdeg = SphericalTrigonometry.mapTo0To360Range(coeff.M0 + (coeff.M1 * k))
        let M = SphericalTrigonometry.degreesToRadians(Mdeg)
        let twoM = 2.0 * M
        let threeM = 3.0 * M
        let fourM = 4.0 * M
        let fiveM = 5.0 * M

        let T = (JDE0 - 2451545.0) / 36525.0
        let T2 = T * T

        var value = 0.0
        if planet == .MERCURY {
            if bEastern {
                value = 22.4697 +
                    (sin(M) * (-4.2666 + (0.0054 * T) + (0.00002 * T2))) +
                    (cos(M) * (-1.8537 - (0.0137 * T))) +
                    (sin(twoM) * (0.3598 + (0.0008 * T) - (0.00001 * T2))) +
                    (cos(twoM) * (-0.0680 + (0.0026 * T))) +
                    (sin(threeM) * (-0.0524 - (0.0003 * T))) +
                    (cos(threeM) * (0.0052 - (0.0006 * T))) +
                    (sin(fourM) * (0.0107 + (0.0001 * T))) +
                    (cos(fourM) * (-0.0013 + (0.0001 * T))) +
                    (sin(fiveM) * -0.0021) +
                    (cos(fiveM) * 0.0003)
            } else {
                value = (22.4143 - (0.0001 * T)) +
                    (sin(M) * (4.3651 - (0.0048 * T) - (0.00002 * T2))) +
                    (cos(M) * (2.3787 + (0.0121 * T) - (0.00001 * T2))) +
                    (sin(twoM) * (0.2674 + (0.0022 * T))) +
                    (cos(twoM) * (-0.3873 + (0.0008 * T) + (0.00001 * T2))) +
                    (sin(threeM) * (-0.0369 - (0.0001 * T))) +
                    (cos(threeM) * (0.0017 - (0.0001 * T))) +
                    (sin(fourM) * 0.0059) +
                    (cos(fourM) * (0.0061 + (0.0001 * T))) +
                    (sin(fiveM) * 0.0007) +
                    (cos(fiveM) * -0.0011)
            }
        } else if planet == .VENUS {
            if bEastern {
                value = (46.3173 + (0.0001 * T)) +
                    (sin(M) * (0.6916 - (0.0024 * T))) +
                    (cos(M) * (0.6676 - (0.0045 * T))) +
                    (sin(twoM) * (0.0309 - (0.0002 * T))) +
                    (cos(twoM) * (0.0036 - (0.0001 * T)))
            } else {
                value = 46.3245 +
                    (sin(M) * (-0.5366 - (0.0003 * T) + (0.00001 * T2))) +
                    (cos(M) * (0.3097 + (0.0016 * T) - (0.00001 * T2))) +
                    (sin(twoM) * -0.0163) +
                    (cos(twoM) * (-0.0075 + (0.0001 * T)))
            }
        }

        return value
    }
}

// MARK: - Planetary Orbital Elements Data Types

/// Comprehensive snapshot of planetary orbital elements for equinox of date.
public struct PlanetaryOrbitalElements: Sendable, Equatable {
    public let meanLongitude: Double
    public let semimajorAxis: Double
    public let eccentricity: Double
    public let inclination: Double
    public let longitudeAscendingNode: Double
    public let longitudePerihelion: Double

    public init(
        meanLongitude: Double,
        semimajorAxis: Double,
        eccentricity: Double,
        inclination: Double,
        longitudeAscendingNode: Double,
        longitudePerihelion: Double
    ) {
        self.meanLongitude = meanLongitude
        self.semimajorAxis = semimajorAxis
        self.eccentricity = eccentricity
        self.inclination = inclination
        self.longitudeAscendingNode = longitudeAscendingNode
        self.longitudePerihelion = longitudePerihelion
    }
}

/// Comprehensive snapshot of planetary orbital elements for J2000 equinox.
public struct PlanetaryOrbitalElementsJ2000: Sendable, Equatable {
    public let meanLongitude: Double
    public let inclination: Double
    public let longitudeAscendingNode: Double
    public let longitudePerihelion: Double

    public init(
        meanLongitude: Double,
        inclination: Double,
        longitudeAscendingNode: Double,
        longitudePerihelion: Double
    ) {
        self.meanLongitude = meanLongitude
        self.inclination = inclination
        self.longitudeAscendingNode = longitudeAscendingNode
        self.longitudePerihelion = longitudePerihelion
    }
}

// MARK: - Planetary Orbital Elements (CAAElementsPlanetaryOrbit)

public enum CAAElementsPlanetaryOrbit: Sendable {
    @usableFromInline
    internal static func T(_ JD: Double) -> (T: Double, T2: Double, T3: Double) {
        let t = (JD - 2451545.0) / 36525.0
        let t2 = t * t
        return (t, t2, t2 * t)
    }

    /// Joint evaluation of planetary orbital elements for equinox of date in a single pass.
    @inlinable
    public static func elements(for planet: KPCAAPlanetStrict, jd: Double) -> PlanetaryOrbitalElements {
        let t = T(jd)
        switch planet {
        case .KPCAAPlanetStrictMercury:
            return PlanetaryOrbitalElements(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(252.250906 + (149474.0722491 * t.T) + (0.00030350 * t.T2) + (0.000000018 * t.T3)),
                semimajorAxis: 0.387098310,
                eccentricity: 0.20563175 + (0.000020407 * t.T) - (0.0000000283 * t.T2) - (0.00000000018 * t.T3),
                inclination: SphericalTrigonometry.mapTo0To360Range(7.004986 + (0.0018215 * t.T) - (0.00001810 * t.T2) + (0.000000056 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(48.330893 + (1.1861883 * t.T) + (0.00017542 * t.T2) + (0.000000215 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(77.456119 + (1.5564776 * t.T) + (0.00029544 * t.T2) + (0.000000009 * t.T3))
            )
        case .KPCAAPlanetStrictVenus:
            return PlanetaryOrbitalElements(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(181.979801 + (58519.2130302 * t.T) + (0.00031014 * t.T2) + (0.000000015 * t.T3)),
                semimajorAxis: 0.723329820,
                eccentricity: 0.00677192 - (0.000047765 * t.T) + (0.0000000981 * t.T2) + (0.00000000046 * t.T3),
                inclination: SphericalTrigonometry.mapTo0To360Range(3.394662 + (0.0010037 * t.T) - (0.00000088 * t.T2) - (0.000000007 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(76.679920 + (0.9011206 * t.T) + (0.00040618 * t.T2) - (0.000000093 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(131.563707 + (1.4022288 * t.T) - (0.00107618 * t.T2) - (0.000005678 * t.T3))
            )
        case .KPCAAPlanetStrictEarth:
            return PlanetaryOrbitalElements(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(100.466449 + (36000.7698231 * t.T) + (0.00030368 * t.T2) + (0.000000002 * t.T3)),
                semimajorAxis: 1.000001018,
                eccentricity: 0.01670863 - (0.000042037 * t.T) - (0.0000001267 * t.T2) + (0.00000000014 * t.T3),
                inclination: 0.0,
                longitudeAscendingNode: 0.0,
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(102.937348 + (1.7195269 * t.T) + (0.00045962 * t.T2) + (0.000000499 * t.T3))
            )
        case .KPCAAPlanetStrictMars:
            return PlanetaryOrbitalElements(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(355.433000 + (19141.6964471 * t.T) + (0.00031052 * t.T2) + (0.000000016 * t.T3)),
                semimajorAxis: 1.523679342,
                eccentricity: 0.09340065 + (0.000090484 * t.T) - (0.0000000806 * t.T2) - (0.00000000025 * t.T3),
                inclination: SphericalTrigonometry.mapTo0To360Range(1.849726 - (0.0006011 * t.T) + (0.00001276 * t.T2) - (0.000000007 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(49.558093 + (0.7720959 * t.T) + (0.00001557 * t.T2) + (0.000002267 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(336.060234 + (1.8410449 * t.T) + (0.00013477 * t.T2) + (0.000000536 * t.T3))
            )
        case .KPCAAPlanetStrictJupiter:
            return PlanetaryOrbitalElements(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(34.351519 + (3034.9056616 * t.T) - (0.00008501 * t.T2) + (0.000000004 * t.T3)),
                semimajorAxis: 5.202603209 + (0.0000001913 * t.T),
                eccentricity: 0.04849793 + (0.000163225 * t.T) - (0.0000004714 * t.T2) - (0.00000000201 * t.T3),
                inclination: SphericalTrigonometry.mapTo0To360Range(1.303267 - (0.0054965 * t.T) + (0.00000466 * t.T2) - (0.000000002 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(100.464407 + (1.0209774 * t.T) + (0.00040315 * t.T2) + (0.000000404 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(14.331209 + (1.6126352 * t.T) + (0.00103042 * t.T2) - (0.000004464 * t.T3))
            )
        case .KPCAAPlanetStrictSaturn:
            return PlanetaryOrbitalElements(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(50.077444 + (1222.1138488 * t.T) + (0.00021004 * t.T2) - (0.000000019 * t.T3)),
                semimajorAxis: 9.554909192 - (0.0000021390 * t.T) + (0.000000004 * t.T2),
                eccentricity: 0.05554814 - (0.0003446641 * t.T) - (0.0000006436 * t.T2) + (0.00000000340 * t.T3),
                inclination: SphericalTrigonometry.mapTo0To360Range(2.488879 - (0.0037362 * t.T) - (0.00001519 * t.T2) + (0.000000087 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(113.665503 + (0.8770880 * t.T) - (0.00012176 * t.T2) - (0.000002249 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(93.057237 + (1.9637613 * t.T) + (0.00083753 * t.T2) + (0.000004928 * t.T3))
            )
        case .KPCAAPlanetStrictUranus:
            return PlanetaryOrbitalElements(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(314.055005 + (428.4669983 * t.T) - (0.00000486 * t.T2) - (0.000000006 * t.T3)),
                semimajorAxis: 19.218446062 - (0.0000000372 * t.T) + (0.00000000098 * t.T2),
                eccentricity: 0.04638122 - (0.000027293 * t.T) + (0.0000000789 * t.T2) + (0.00000000024 * t.T3),
                inclination: SphericalTrigonometry.mapTo0To360Range(0.773197 + (0.0007744 * t.T) + (0.00003749 * t.T2) - (0.000000092 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(74.005957 + (0.5211278 * t.T) + (0.00133947 * t.T2) + (0.000001848 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(173.005291 + (1.4863790 * t.T) + (0.00021444 * t.T2) + (0.000000434 * t.T3))
            )
        case .KPCAAPlanetStrictNeptune:
            return PlanetaryOrbitalElements(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(304.348665 + (218.4862002 * t.T) + (0.00005927 * t.T2) - (0.000000002 * t.T3)),
                semimajorAxis: 30.110386869 - (0.0000001663 * t.T) + (0.00000000069 * t.T2),
                eccentricity: 0.00945575 + (0.000006033 * t.T) - (0.00000000005 * t.T3),
                inclination: SphericalTrigonometry.mapTo0To360Range(1.769953 - (0.0093082 * t.T) - (0.00000708 * t.T2) + (0.000000027 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(131.784057 + (1.1022039 * t.T) + (0.00025952 * t.T2) - (0.000000637 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(48.120276 + (1.4262957 * t.T) + (0.00038434 * t.T2) + (0.000000020 * t.T3))
            )
        default:
            return PlanetaryOrbitalElements(
                meanLongitude: 0.0,
                semimajorAxis: 0.0,
                eccentricity: 0.0,
                inclination: 0.0,
                longitudeAscendingNode: 0.0,
                longitudePerihelion: 0.0
            )
        }
    }

    /// Joint evaluation of planetary orbital elements for J2000 equinox in a single pass.
    @inlinable
    public static func elementsJ2000(for planet: KPCAAPlanetStrict, jd: Double) -> PlanetaryOrbitalElementsJ2000 {
        let t = T(jd)
        switch planet {
        case .KPCAAPlanetStrictMercury:
            return PlanetaryOrbitalElementsJ2000(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(252.250906 + (149472.6746358 * t.T) - (0.00000535 * t.T2) + (0.000000002 * t.T3)),
                inclination: SphericalTrigonometry.mapTo0To360Range(7.004986 + (0.0059015 * t.T) - (0.00001928 * t.T2) - (0.000000014 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(48.330893 - (0.1254229 * t.T) - (0.00008833 * t.T2) - (0.000000196 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(77.456119 + (0.1588643 * t.T) - (0.00001343 * t.T2) + (0.000000039 * t.T3))
            )
        case .KPCAAPlanetStrictVenus:
            return PlanetaryOrbitalElementsJ2000(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(181.979801 + (58517.8156760 * t.T) + (0.00000165 * t.T2) - (0.000000002 * t.T3)),
                inclination: SphericalTrigonometry.mapTo0To360Range(3.394662 + (0.0004343 * t.T) - (0.00000288 * t.T2) - (0.000000003 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(76.679920 - (0.2780080 * t.T) - (0.00014256 * t.T2) - (0.000000198 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(131.563707 + (0.0048646 * t.T) - (0.00138349 * t.T2) - (0.000005672 * t.T3))
            )
        case .KPCAAPlanetStrictEarth:
            return PlanetaryOrbitalElementsJ2000(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(100.466449 + (35999.3730633 * t.T) - (0.00000529 * t.T2) - (0.000000016 * t.T3)),
                inclination: (0.0130548 * t.T) - (0.00000931 * t.T2) - (0.000000034 * t.T3),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(174.873174 - (8.679270 * t.T) + (0.00013 * t.T2)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(102.937348 + (0.3225934 * t.T) + (0.00015037 * t.T2) + (0.000000479 * t.T3))
            )
        case .KPCAAPlanetStrictMars:
            return PlanetaryOrbitalElementsJ2000(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(355.433000 + (19140.2993424 * t.T) + (0.00000261 * t.T2) - (0.000000003 * t.T3)),
                inclination: SphericalTrigonometry.mapTo0To360Range(1.849726 - (0.0081479 * t.T) - (0.00002235 * t.T2) - (0.000000032 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(49.558093 - (0.2949846 * t.T) - (0.00063993 * t.T2) - (0.000002143 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(336.060234 + (0.4438902 * t.T) - (0.00017348 * t.T2) + (0.000000523 * t.T3))
            )
        case .KPCAAPlanetStrictJupiter:
            return PlanetaryOrbitalElementsJ2000(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(34.351519 + (3033.5076412 * t.T) - (0.00038848 * t.T2) - (0.000000015 * t.T3)),
                inclination: SphericalTrigonometry.mapTo0To360Range(1.303267 - (0.0057202 * t.T) + (0.00000414 * t.T2) + (0.000000004 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(100.464407 - (0.1820786 * t.T) + (0.00003883 * t.T2) + (0.000000599 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(14.331209 + (0.2155523 * t.T) + (0.00072252 * t.T2) - (0.000004590 * t.T3))
            )
        case .KPCAAPlanetStrictSaturn:
            return PlanetaryOrbitalElementsJ2000(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(50.077444 + (1220.7143997 * t.T) - (0.00009385 * t.T2) - (0.000000038 * t.T3)),
                inclination: SphericalTrigonometry.mapTo0To360Range(2.488879 - (0.0016499 * t.T) - (0.00002573 * t.T2) + (0.000000067 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(113.665503 - (0.2566732 * t.T) - (0.00018408 * t.T2) - (0.000002341 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(93.057237 + (0.5665487 * t.T) + (0.00052865 * t.T2) + (0.000004882 * t.T3))
            )
        case .KPCAAPlanetStrictUranus:
            return PlanetaryOrbitalElementsJ2000(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(314.055005 + (427.0694158 * t.T) - (0.00030855 * t.T2) - (0.000000025 * t.T3)),
                inclination: SphericalTrigonometry.mapTo0To360Range(0.773197 - (0.0024293 * t.T) + (0.00003449 * t.T2) - (0.000000113 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(74.005957 - (0.0423049 * t.T) + (0.00070086 * t.T2) + (0.000001662 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(173.005291 + (0.0892994 * t.T) + (0.00009405 * t.T2) + (0.000000413 * t.T3))
            )
        case .KPCAAPlanetStrictNeptune:
            return PlanetaryOrbitalElementsJ2000(
                meanLongitude: SphericalTrigonometry.mapTo0To360Range(304.348665 + (217.0877995 * t.T) - (0.00024442 * t.T2) - (0.000000020 * t.T3)),
                inclination: SphericalTrigonometry.mapTo0To360Range(1.769953 + (0.0003537 * t.T) - (0.00000911 * t.T2) + (0.000000009 * t.T3)),
                longitudeAscendingNode: SphericalTrigonometry.mapTo0To360Range(131.784057 - (0.0060938 * t.T) - (0.00002573 * t.T2) - (0.000000732 * t.T3)),
                longitudePerihelion: SphericalTrigonometry.mapTo0To360Range(48.120276 + (0.0272097 * t.T) + (0.00007993 * t.T2) - (0.000000002 * t.T3))
            )
        default:
            return PlanetaryOrbitalElementsJ2000(
                meanLongitude: 0.0,
                inclination: 0.0,
                longitudeAscendingNode: 0.0,
                longitudePerihelion: 0.0
            )
        }
    }


    // Mercury
    public static func MercuryMeanLongitude(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(252.250906 + (149474.0722491 * t.T) + (0.00030350 * t.T2) + (0.000000018 * t.T3))
    }
    public static func MercurySemimajorAxis(_ JD: Double) -> Double { 0.387098310 }
    public static func MercuryEccentricity(_ JD: Double) -> Double {
        let t = T(JD)
        return 0.20563175 + (0.000020407 * t.T) - (0.0000000283 * t.T2) - (0.00000000018 * t.T3)
    }
    public static func MercuryInclination(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(7.004986 + (0.0018215 * t.T) - (0.00001810 * t.T2) + (0.000000056 * t.T3))
    }
    public static func MercuryLongitudeAscendingNode(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(48.330893 + (1.1861883 * t.T) + (0.00017542 * t.T2) + (0.000000215 * t.T3))
    }
    public static func MercuryLongitudePerihelion(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(77.456119 + (1.5564776 * t.T) + (0.00029544 * t.T2) + (0.000000009 * t.T3))
    }

    // Venus
    public static func VenusMeanLongitude(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(181.979801 + (58519.2130302 * t.T) + (0.00031014 * t.T2) + (0.000000015 * t.T3))
    }
    public static func VenusSemimajorAxis(_ JD: Double) -> Double { 0.723329820 }
    public static func VenusEccentricity(_ JD: Double) -> Double {
        let t = T(JD)
        return 0.00677192 - (0.000047765 * t.T) + (0.0000000981 * t.T2) + (0.00000000046 * t.T3)
    }
    public static func VenusInclination(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(3.394662 + (0.0010037 * t.T) - (0.00000088 * t.T2) - (0.000000007 * t.T3))
    }
    public static func VenusLongitudeAscendingNode(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(76.679920 + (0.9011206 * t.T) + (0.00040618 * t.T2) - (0.000000093 * t.T3))
    }
    public static func VenusLongitudePerihelion(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(131.563707 + (1.4022288 * t.T) - (0.00107618 * t.T2) - (0.000005678 * t.T3))
    }

    // Earth
    public static func EarthMeanLongitude(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(100.466449 + (36000.7698231 * t.T) + (0.00030368 * t.T2) + (0.000000002 * t.T3))
    }
    public static func EarthSemimajorAxis(_ JD: Double) -> Double { 1.000001018 }
    public static func EarthEccentricity(_ JD: Double) -> Double {
        let t = T(JD)
        return 0.01670863 - (0.000042037 * t.T) - (0.0000001267 * t.T2) + (0.00000000014 * t.T3)
    }
    public static func EarthInclination(_ JD: Double) -> Double { 0.0 }
    public static func EarthLongitudePerihelion(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(102.937348 + (1.7195269 * t.T) + (0.00045962 * t.T2) + (0.000000499 * t.T3))
    }

    // Mars
    public static func MarsMeanLongitude(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(355.433000 + (19141.6964471 * t.T) + (0.00031052 * t.T2) + (0.000000016 * t.T3))
    }
    public static func MarsSemimajorAxis(_ JD: Double) -> Double { 1.523679342 }
    public static func MarsEccentricity(_ JD: Double) -> Double {
        let t = T(JD)
        return 0.09340065 + (0.000090484 * t.T) - (0.0000000806 * t.T2) - (0.00000000025 * t.T3)
    }
    public static func MarsInclination(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(1.849726 - (0.0006011 * t.T) + (0.00001276 * t.T2) - (0.000000007 * t.T3))
    }
    public static func MarsLongitudeAscendingNode(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(49.558093 + (0.7720959 * t.T) + (0.00001557 * t.T2) + (0.000002267 * t.T3))
    }
    public static func MarsLongitudePerihelion(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(336.060234 + (1.8410449 * t.T) + (0.00013477 * t.T2) + (0.000000536 * t.T3))
    }

    // Jupiter
    public static func JupiterMeanLongitude(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(34.351519 + (3034.9056616 * t.T) - (0.00008501 * t.T2) + (0.000000004 * t.T3))
    }
    public static func JupiterSemimajorAxis(_ JD: Double) -> Double {
        let t = T(JD)
        return 5.202603209 + (0.0000001913 * t.T)
    }
    public static func JupiterEccentricity(_ JD: Double) -> Double {
        let t = T(JD)
        return 0.04849793 + (0.000163225 * t.T) - (0.0000004714 * t.T2) - (0.00000000201 * t.T3)
    }
    public static func JupiterInclination(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(1.303267 - (0.0054965 * t.T) + (0.00000466 * t.T2) - (0.000000002 * t.T3))
    }
    public static func JupiterLongitudeAscendingNode(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(100.464407 + (1.0209774 * t.T) + (0.00040315 * t.T2) + (0.000000404 * t.T3))
    }
    public static func JupiterLongitudePerihelion(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(14.331209 + (1.6126352 * t.T) + (0.00103042 * t.T2) - (0.000004464 * t.T3))
    }

    // Saturn
    public static func SaturnMeanLongitude(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(50.077444 + (1222.1138488 * t.T) + (0.00021004 * t.T2) - (0.000000019 * t.T3))
    }
    public static func SaturnSemimajorAxis(_ JD: Double) -> Double {
        let t = T(JD)
        return 9.554909192 - (0.0000021390 * t.T) + (0.000000004 * t.T2)
    }
    public static func SaturnEccentricity(_ JD: Double) -> Double {
        let t = T(JD)
        return 0.05554814 - (0.0003446641 * t.T) - (0.0000006436 * t.T2) + (0.00000000340 * t.T3)
    }
    public static func SaturnInclination(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(2.488879 - (0.0037362 * t.T) - (0.00001519 * t.T2) + (0.000000087 * t.T3))
    }
    public static func SaturnLongitudeAscendingNode(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(113.665503 + (0.8770880 * t.T) - (0.00012176 * t.T2) - (0.000002249 * t.T3))
    }
    public static func SaturnLongitudePerihelion(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(93.057237 + (1.9637613 * t.T) + (0.00083753 * t.T2) + (0.000004928 * t.T3))
    }

    // Uranus
    public static func UranusMeanLongitude(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(314.055005 + (428.4669983 * t.T) - (0.00000486 * t.T2) - (0.000000006 * t.T3))
    }
    public static func UranusSemimajorAxis(_ JD: Double) -> Double {
        let t = T(JD)
        return 19.218446062 - (0.0000000372 * t.T) + (0.00000000098 * t.T2)
    }
    public static func UranusEccentricity(_ JD: Double) -> Double {
        let t = T(JD)
        return 0.04638122 - (0.000027293 * t.T) + (0.0000000789 * t.T2) + (0.00000000024 * t.T3)
    }
    public static func UranusInclination(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(0.773197 + (0.0007744 * t.T) + (0.00003749 * t.T2) - (0.000000092 * t.T3))
    }
    public static func UranusLongitudeAscendingNode(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(74.005957 + (0.5211278 * t.T) + (0.00133947 * t.T2) + (0.000001848 * t.T3))
    }
    public static func UranusLongitudePerihelion(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(173.005291 + (1.4863790 * t.T) + (0.00021444 * t.T2) + (0.000000434 * t.T3))
    }

    // Neptune
    public static func NeptuneMeanLongitude(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(304.348665 + (218.4862002 * t.T) + (0.00005927 * t.T2) - (0.000000002 * t.T3))
    }
    public static func NeptuneSemimajorAxis(_ JD: Double) -> Double {
        let t = T(JD)
        return 30.110386869 - (0.0000001663 * t.T) + (0.00000000069 * t.T2)
    }
    public static func NeptuneEccentricity(_ JD: Double) -> Double {
        let t = T(JD)
        return 0.00945575 + (0.000006033 * t.T) - (0.00000000005 * t.T3)
    }
    public static func NeptuneInclination(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(1.769953 - (0.0093082 * t.T) - (0.00000708 * t.T2) + (0.000000027 * t.T3))
    }
    public static func NeptuneLongitudeAscendingNode(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(131.784057 + (1.1022039 * t.T) + (0.00025952 * t.T2) - (0.000000637 * t.T3))
    }
    public static func NeptuneLongitudePerihelion(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(48.120276 + (1.4262957 * t.T) + (0.00038434 * t.T2) + (0.000000020 * t.T3))
    }

    // J2000 versions
    public static func MercuryMeanLongitudeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(252.250906 + (149472.6746358 * t.T) - (0.00000535 * t.T2) + (0.000000002 * t.T3))
    }
    public static func MercuryInclinationJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(7.004986 + (0.0059015 * t.T) - (0.00001928 * t.T2) - (0.000000014 * t.T3))
    }
    public static func MercuryLongitudeAscendingNodeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(48.330893 - (0.1254229 * t.T) - (0.00008833 * t.T2) - (0.000000196 * t.T3))
    }
    public static func MercuryLongitudePerihelionJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(77.456119 + (0.1588643 * t.T) - (0.00001343 * t.T2) + (0.000000039 * t.T3))
    }

    public static func VenusMeanLongitudeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(181.979801 + (58517.8156760 * t.T) + (0.00000165 * t.T2) - (0.000000002 * t.T3))
    }
    public static func VenusInclinationJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(3.394662 + (0.0004343 * t.T) - (0.00000288 * t.T2) - (0.000000003 * t.T3))
    }
    public static func VenusLongitudeAscendingNodeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(76.679920 - (0.2780080 * t.T) - (0.00014256 * t.T2) - (0.000000198 * t.T3))
    }
    public static func VenusLongitudePerihelionJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(131.563707 + (0.0048646 * t.T) - (0.00138349 * t.T2) - (0.000005672 * t.T3))
    }

    public static func EarthMeanLongitudeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(100.466449 + (35999.3730633 * t.T) - (0.00000529 * t.T2) - (0.000000016 * t.T3))
    }
    public static func EarthInclinationJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return (0.0130548 * t.T) - (0.00000931 * t.T2) - (0.000000034 * t.T3)
    }
    public static func EarthLongitudeAscendingNodeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(174.873174 - (8.679270 * t.T) + (0.00013 * t.T2))
    }
    public static func EarthLongitudePerihelionJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(102.937348 + (0.3225934 * t.T) + (0.00015037 * t.T2) + (0.000000479 * t.T3))
    }

    public static func MarsMeanLongitudeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(355.433000 + (19140.2993424 * t.T) + (0.00000261 * t.T2) - (0.000000003 * t.T3))
    }
    public static func MarsInclinationJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(1.849726 - (0.0081479 * t.T) - (0.00002235 * t.T2) - (0.000000032 * t.T3))
    }
    public static func MarsLongitudeAscendingNodeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(49.558093 - (0.2949846 * t.T) - (0.00063993 * t.T2) - (0.000002143 * t.T3))
    }
    public static func MarsLongitudePerihelionJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(336.060234 + (0.4438902 * t.T) - (0.00017348 * t.T2) + (0.000000523 * t.T3))
    }

    public static func JupiterMeanLongitudeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(34.351519 + (3033.5076412 * t.T) - (0.00038848 * t.T2) - (0.000000015 * t.T3))
    }
    public static func JupiterInclinationJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(1.303267 - (0.0057202 * t.T) + (0.00000414 * t.T2) + (0.000000004 * t.T3))
    }
    public static func JupiterLongitudeAscendingNodeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(100.464407 - (0.1820786 * t.T) + (0.00003883 * t.T2) + (0.000000599 * t.T3))
    }
    public static func JupiterLongitudePerihelionJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(14.331209 + (0.2155523 * t.T) + (0.00072252 * t.T2) - (0.000004590 * t.T3))
    }

    public static func SaturnMeanLongitudeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(50.077444 + (1220.7143997 * t.T) - (0.00009385 * t.T2) - (0.000000038 * t.T3))
    }
    public static func SaturnInclinationJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(2.488879 - (0.0016499 * t.T) - (0.00002573 * t.T2) + (0.000000067 * t.T3))
    }
    public static func SaturnLongitudeAscendingNodeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(113.665503 - (0.2566732 * t.T) - (0.00018408 * t.T2) - (0.000002341 * t.T3))
    }
    public static func SaturnLongitudePerihelionJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(93.057237 + (0.5665487 * t.T) + (0.00052865 * t.T2) + (0.000004882 * t.T3))
    }

    public static func UranusMeanLongitudeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(314.055005 + (427.0694158 * t.T) - (0.00030855 * t.T2) - (0.000000025 * t.T3))
    }
    public static func UranusInclinationJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(0.773197 - (0.0024293 * t.T) + (0.00003449 * t.T2) - (0.000000113 * t.T3))
    }
    public static func UranusLongitudeAscendingNodeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(74.005957 - (0.0423049 * t.T) + (0.00070086 * t.T2) + (0.000001662 * t.T3))
    }
    public static func UranusLongitudePerihelionJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(173.005291 + (0.0892994 * t.T) + (0.00009405 * t.T2) + (0.000000413 * t.T3))
    }

    public static func NeptuneMeanLongitudeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(304.348665 + (217.0877995 * t.T) - (0.00024442 * t.T2) - (0.000000020 * t.T3))
    }
    public static func NeptuneInclinationJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(1.769953 + (0.0003537 * t.T) - (0.00000911 * t.T2) + (0.000000009 * t.T3))
    }
    public static func NeptuneLongitudeAscendingNodeJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(131.784057 - (0.0060938 * t.T) - (0.00002573 * t.T2) - (0.000000732 * t.T3))
    }
    public static func NeptuneLongitudePerihelionJ2000(_ JD: Double) -> Double {
        let t = T(JD)
        return SphericalTrigonometry.mapTo0To360Range(48.120276 + (0.0272097 * t.T) + (0.00007993 * t.T2) - (0.000000002 * t.T3))
    }
}

// MARK: - Planet Perihelion & Aphelion Engine (CAAPlanetPerihelionAphelion)

public enum CAAPlanetPerihelionAphelion: Sendable {
    @inlinable public static func MercuryK(_ Year: Double) -> Double { 4.15201 * (Year - 2000.12) }
    @inlinable public static func Mercury(_ k: Double) -> Double { 2451590.257 + (87.96934963 * k) }

    @inlinable public static func VenusK(_ Year: Double) -> Double { 1.62549 * (Year - 2000.53) }
    @inlinable public static func Venus(_ k: Double) -> Double {
        2451738.233 + (224.7008188 * k) - (0.0000000327 * k * k)
    }

    @inlinable public static func EarthK(_ Year: Double) -> Double { 0.99997 * (Year - 2000.01) }

    public static func EarthPerihelion(_ k: Double, _ bBarycentric: Bool = false) -> Double {
        let ksquared = k * k
        var JD = 2451547.507 + (365.2596358 * k) + (0.0000000156 * ksquared)
        if !bBarycentric {
            let A1 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(328.41 + (132.788585 * k)))
            let A2 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(316.13 + (584.903153 * k)))
            let A3 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(346.20 + (450.380738 * k)))
            let A4 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(136.95 + (659.306737 * k)))
            let A5 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(249.52 + (329.653368 * k)))

            JD += (1.278 * sin(A1))
            JD -= (0.055 * sin(A2))
            JD -= (0.091 * sin(A3))
            JD -= (0.056 * sin(A4))
            JD -= (0.045 * sin(A5))
        }
        return JD
    }

    public static func EarthAphelion(_ k: Double, _ bBarycentric: Bool = false) -> Double {
        let ksquared = k * k
        var JD = 2451547.507 + (365.2596358 * k) + (0.0000000156 * ksquared)
        if !bBarycentric {
            let A1 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(328.41 + (132.788585 * k)))
            let A2 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(316.13 + (584.903153 * k)))
            let A3 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(346.20 + (450.380738 * k)))
            let A4 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(136.95 + (659.306737 * k)))
            let A5 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(249.52 + (329.653368 * k)))

            JD -= (1.352 * sin(A1))
            JD += (0.061 * sin(A2))
            JD += (0.062 * sin(A3))
            JD += (0.029 * sin(A4))
            JD += (0.031 * sin(A5))
        }
        return JD
    }

    @inlinable public static func MarsK(_ Year: Double) -> Double { 0.53166 * (Year - 2001.78) }
    @inlinable public static func Mars(_ k: Double) -> Double {
        2452195.026 + (686.9957857 * k) - (0.0000001187 * k * k)
    }

    @inlinable public static func JupiterK(_ Year: Double) -> Double { 0.08430 * (Year - 2011.20) }
    @inlinable public static func Jupiter(_ k: Double) -> Double {
        2455636.936 + (4332.897065 * k) + (0.0001367 * k * k)
    }

    @inlinable public static func SaturnK(_ Year: Double) -> Double { 0.03393 * (Year - 2003.52) }
    @inlinable public static func Saturn(_ k: Double) -> Double {
        2452830.12 + (10764.21676 * k) + (0.000827 * k * k)
    }

    @inlinable public static func UranusK(_ Year: Double) -> Double { 0.01190 * (Year - 2051.1) }
    @inlinable public static func Uranus(_ k: Double) -> Double {
        2470213.5 + (30694.8767 * k) - (0.00541 * k * k)
    }

    @inlinable public static func NeptuneK(_ Year: Double) -> Double { 0.00607 * (Year - 2047.5) }
    @inlinable public static func Neptune(_ k: Double) -> Double {
        2468895.1 + (60190.33 * k) + (0.03429 * k * k)
    }
}
