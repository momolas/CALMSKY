//
//  MoonsAndRingsEngine.swift
//  AstronomyKit
//
//  Pure Swift engines for:
//  - Planetary illuminated fractions & magnitudes (CAAIlluminatedFraction)
//  - Stellar magnitudes (CAAStellarMagnitudes)
//  - Jupiter physical ephemeris (CAAPhysicalJupiter)
//  - Mars physical ephemeris (CAAPhysicalMars)
//  - Saturn rings geometry (CAASaturnRings)
//  - Galilean moons (CAAGalileanMoons)
//  - Saturnian moons (CAASaturnMoons)
//

import Foundation

// MARK: - Planetary Illuminated Fraction & Magnitudes (CAAIlluminatedFraction)

public enum CAAIlluminatedFraction: Sendable {
    public static func PhaseAngle(_ r: Double, _ R: Double, _ Delta: Double) -> Double {
        let arg = ((r * r) + (Delta * Delta) - (R * R)) / (2.0 * r * Delta)
        let clamped = min(max(arg, -1.0), 1.0)
        return SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(acos(clamped)))
    }

    public static func PhaseAngle(_ R: Double, _ R0: Double, _ B: Double, _ L: Double, _ L0: Double, _ Delta: Double) -> Double {
        let Brad = SphericalTrigonometry.degreesToRadians(B)
        let Lrad = SphericalTrigonometry.degreesToRadians(L)
        let L0rad = SphericalTrigonometry.degreesToRadians(L0)
        let arg = (R - (R0 * cos(Brad) * cos(Lrad - L0rad))) / Delta
        let clamped = min(max(arg, -1.0), 1.0)
        return SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(acos(clamped)))
    }

    public static func PhaseAngleRectangular(_ x: Double, _ y: Double, _ z: Double, _ B: Double, _ L: Double, _ Delta: Double) -> Double {
        let Brad = SphericalTrigonometry.degreesToRadians(B)
        let Lrad = SphericalTrigonometry.degreesToRadians(L)
        let cosB = cos(Brad)
        let arg = ((x * cosB * cos(Lrad)) + (y * cosB * sin(Lrad)) + (z * sin(Brad))) / Delta
        let clamped = min(max(arg, -1.0), 1.0)
        return SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(acos(clamped)))
    }

    public static func IlluminatedFraction(_ PhaseAngle: Double) -> Double {
        let PhaseAngleRad = SphericalTrigonometry.degreesToRadians(PhaseAngle)
        return (1.0 + cos(PhaseAngleRad)) / 2.0
    }

    public static func IlluminatedFraction(_ r: Double, _ R: Double, _ Delta: Double) -> Double {
        return (((r + Delta) * (r + Delta) - (R * R)) / (4.0 * r * Delta))
    }

    public static func MercuryMagnitudeMuller(_ r: Double, _ Delta: Double, _ i: Double) -> Double {
        let I_50 = i - 50.0
        return 1.16 + (5.0 * log10(r * Delta)) + (0.02838 * I_50) + (0.0001023 * I_50 * I_50)
    }

    public static func VenusMagnitudeMuller(_ r: Double, _ Delta: Double, _ i: Double) -> Double {
        return -4.00 + (5.0 * log10(r * Delta)) + (0.01322 * i) + (0.0000004247 * i * i * i)
    }

    public static func MarsMagnitudeMuller(_ r: Double, _ Delta: Double, _ i: Double) -> Double {
        return -1.3 + (5.0 * log10(r * Delta)) + (0.01486 * i)
    }

    public static func JupiterMagnitudeMuller(_ r: Double, _ Delta: Double) -> Double {
        return -8.93 + (5.0 * log10(r * Delta))
    }

    public static func SaturnMagnitudeMuller(_ r: Double, _ Delta: Double, _ DeltaU: Double, _ B: Double) -> Double {
        let Brad = SphericalTrigonometry.degreesToRadians(B)
        let sinB = sin(Brad)
        return -8.68 + (5.0 * log10(r * Delta)) + (0.044 * abs(DeltaU)) - (2.60 * sin(abs(Brad))) + (1.25 * sinB * sinB)
    }

    public static func UranusMagnitudeMuller(_ r: Double, _ Delta: Double) -> Double {
        return -6.85 + (5.0 * log10(r * Delta))
    }

    public static func NeptuneMagnitudeMuller(_ r: Double, _ Delta: Double) -> Double {
        return -7.05 + (5.0 * log10(r * Delta))
    }

    public static func MercuryMagnitudeAA(_ r: Double, _ Delta: Double, _ i: Double) -> Double {
        let i2 = i * i
        let i3 = i2 * i
        return -0.42 + (5.0 * log10(r * Delta)) + (0.0380 * i) - (0.000273 * i2) + (0.000002 * i3)
    }

    public static func VenusMagnitudeAA(_ r: Double, _ Delta: Double, _ i: Double) -> Double {
        let i2 = i * i
        let i3 = i2 * i
        return -4.40 + (5.0 * log10(r * Delta)) + (0.0009 * i) + (0.000239 * i2) - (0.00000065 * i3)
    }

    public static func MarsMagnitudeAA(_ r: Double, _ Delta: Double, _ i: Double) -> Double {
        return -1.52 + (5.0 * log10(r * Delta)) + (0.016 * i)
    }

    public static func JupiterMagnitudeAA(_ r: Double, _ Delta: Double, _ i: Double) -> Double {
        return -9.40 + (5.0 * log10(r * Delta)) + (0.005 * i)
    }

    public static func SaturnMagnitudeAA(_ r: Double, _ Delta: Double, _ DeltaU: Double, _ B: Double) -> Double {
        let Brad = SphericalTrigonometry.degreesToRadians(B)
        let sinB = sin(Brad)
        return -8.88 + (5.0 * log10(r * Delta)) + (0.044 * abs(DeltaU)) - (2.60 * sin(abs(Brad))) + (1.25 * sinB * sinB)
    }

    public static func UranusMagnitudeAA(_ r: Double, _ Delta: Double) -> Double {
        return -7.19 + (5.0 * log10(r * Delta))
    }

    public static func NeptuneMagnitudeAA(_ r: Double, _ Delta: Double) -> Double {
        return -6.87 + (5.0 * log10(r * Delta))
    }

    public static func PlutoMagnitudeAA(_ r: Double, _ Delta: Double) -> Double {
        return -1.00 + (5.0 * log10(r * Delta)) + (0.041 * (PhaseAngle(r, 1.0, Delta) - 1.0))
    }
}

// MARK: - Stellar Magnitudes (CAAStellarMagnitudes)

public enum CAAStellarMagnitudes: Sendable {
    public static func CombinedMagnitude(_ m1: Double, _ m2: Double) -> Double {
        let x = 0.4 * (m2 - m1)
        return m2 - (2.5 * log10(pow(10.0, x) + 1.0))
    }

    public static func CombinedMagnitude(_ magnitudes: [Double]) -> Double {
        var value = 0.0
        for m in magnitudes {
            value += pow(10.0, -0.4 * m)
        }
        return -2.5 * log10(value)
    }

    public static func BrightnessRatio(_ m1: Double, _ m2: Double) -> Double {
        let x = 0.4 * (m2 - m1)
        return pow(10.0, x)
    }

    public static func MagnitudeDifference(_ brightnessRatio: Double) -> Double {
        return 2.5 * log10(brightnessRatio)
    }
}

// MARK: - Physical Ephemeris of Jupiter (CAAPhysicalJupiter)

public enum CAAPhysicalJupiter: Sendable {
    public static func Calculate(_ JD: Double, _ bHighPrecision: Bool) -> CAAPhysicalJupiterDetails {
        var details = CAAPhysicalJupiterDetails()

        // Step 1
        let d = JD - 2433282.5
        let T1 = d / 36525.0
        let alpha0 = 268.00 + (0.1061 * T1)
        let alpha0rad = SphericalTrigonometry.degreesToRadians(alpha0)
        let delta0 = 64.50 - (0.0164 * T1)
        let delta0rad = SphericalTrigonometry.degreesToRadians(delta0)
        let cosdelta0rad = cos(delta0rad)
        let sindelta0rad = sin(delta0rad)

        // Step 2
        let W1 = SphericalTrigonometry.mapTo0To360Range(17.710 + (877.90003539 * d))
        let W2 = SphericalTrigonometry.mapTo0To360Range(16.838 + (870.27003539 * d))

        // Step 3
        let l0 = CAAEarth.EclipticLongitude(JD, bHighPrecision)
        let l0rad = SphericalTrigonometry.degreesToRadians(l0)
        let cosl0rad = cos(l0rad)
        let sinl0rad = sin(l0rad)
        let b0 = CAAEarth.EclipticLatitude(JD, bHighPrecision)
        let b0rad = SphericalTrigonometry.degreesToRadians(b0)
        let sinb0rad = sin(b0rad)
        let R = CAAEarth.RadiusVector(JD, bHighPrecision)

        // Step 4
        var l = CAAJupiter.EclipticLongitude(JD, bHighPrecision)
        var lrad = SphericalTrigonometry.degreesToRadians(l)
        var coslrad = cos(lrad)
        var sinlrad = sin(lrad)
        let b = CAAJupiter.EclipticLatitude(JD, bHighPrecision)
        let brad = SphericalTrigonometry.degreesToRadians(b)
        let cosbrad = cos(brad)
        let sinbrad = sin(brad)
        let r = CAAJupiter.RadiusVector(JD, bHighPrecision)

        // Step 5
        var x = (r * cosbrad * coslrad) - (R * cosl0rad)
        let x2 = x * x
        var y = (r * cosbrad * sinlrad) - (R * sinl0rad)
        let y2 = y * y
        var z = (r * sinbrad) - (R * sinb0rad)
        let z2 = z * z
        var DELTA = sqrt(x2 + y2 + z2)

        // Step 6
        l -= 0.012990 * DELTA / (r * r)
        lrad = SphericalTrigonometry.degreesToRadians(l)
        sinlrad = sin(lrad)
        coslrad = cos(lrad)

        // Step 7
        x = (r * cosbrad * coslrad) - (R * cosl0rad)
        y = (r * cosbrad * sinlrad) - (R * sinl0rad)
        z = (r * sinbrad) - (R * sinb0rad)
        DELTA = sqrt(x * x + y * y + z * z)

        // Step 8
        var e0 = CAANutation.MeanObliquityOfEcliptic(JD)
        var e0rad = SphericalTrigonometry.degreesToRadians(e0)
        var cose0rad = cos(e0rad)
        let sine0rad = sin(e0rad)

        // Step 9
        let alphas = atan2((cose0rad * sinlrad) - (sine0rad * tan(brad)), coslrad)
        let deltas = asin((cose0rad * sinbrad) + (sine0rad * cosbrad * sinlrad))

        // Step 10
        details.DS = SphericalTrigonometry.radiansToDegrees(asin(-sindelta0rad * sin(deltas) - cosdelta0rad * cos(deltas) * cos(alpha0rad - alphas)))

        // Step 11
        let u = (y * cose0rad) - (z * sine0rad)
        let v = (y * sine0rad) + (z * cose0rad)
        let alpharad = atan2(u, x)
        var alpha = SphericalTrigonometry.radiansToDegrees(alpharad)
        let deltarad = atan2(v, sqrt((x * x) + (u * u)))
        let sindeltarad = sin(deltarad)
        let cosdeltarad = cos(deltarad)
        var delta = SphericalTrigonometry.radiansToDegrees(deltarad)
        let xi = atan2((sindelta0rad * cosdeltarad * cos(alpha0rad - alpharad)) - (sindeltarad * cosdelta0rad), cosdeltarad * sin(alpha0rad - alpharad))

        // Step 12
        details.DE = SphericalTrigonometry.radiansToDegrees(asin((-sindelta0rad * sindeltarad) - (cosdelta0rad * cosdeltarad * cos(alpha0rad - alpharad))))

        // Step 13
        details.Geometricw1 = SphericalTrigonometry.mapTo0To360Range(W1 - SphericalTrigonometry.radiansToDegrees(xi) - (5.07033 * DELTA))
        details.Geometricw2 = SphericalTrigonometry.mapTo0To360Range(W2 - SphericalTrigonometry.radiansToDegrees(xi) - (5.02626 * DELTA))

        // Step 14
        let C = 57.2958 * ((2.0 * r * DELTA) + (R * R) - (r * r) - (DELTA * DELTA)) / (4.0 * r * DELTA)
        if sin(lrad - l0rad) > 0 {
            details.Apparentw1 = SphericalTrigonometry.mapTo0To360Range(details.Geometricw1 + C)
            details.Apparentw2 = SphericalTrigonometry.mapTo0To360Range(details.Geometricw2 + C)
        } else {
            details.Apparentw1 = SphericalTrigonometry.mapTo0To360Range(details.Geometricw1 - C)
            details.Apparentw2 = SphericalTrigonometry.mapTo0To360Range(details.Geometricw2 - C)
        }

        // Step 15
        let NutationInLongitude = CAANutation.NutationInLongitude(JD)
        let NutationInObliquity = CAANutation.NutationInObliquity(JD)
        e0 += NutationInObliquity / 3600.0
        e0rad = SphericalTrigonometry.degreesToRadians(e0)
        cose0rad = cos(e0rad)

        // Step 16
        let cosalpharad = cos(alpharad)
        let sinalpharad = sin(alpharad)
        alpha += 0.005693 * ((cosalpharad * cosl0rad * cose0rad) + (sinalpharad * sinl0rad)) / cosdeltarad
        alpha = SphericalTrigonometry.mapTo0To360Range(alpha)
        delta += 0.005693 * (cosl0rad * cose0rad * (tan(e0rad) * cosdeltarad - sinalpharad * sindeltarad) + cosalpharad * sindeltarad * sinl0rad)

        // Step 17
        var NutationRA = CAANutation.NutationInRightAscension(alpha / 15.0, delta, e0, NutationInLongitude, NutationInObliquity)
        let alphadash = alpha + (NutationRA / 3600.0)
        let alphadashrad = SphericalTrigonometry.degreesToRadians(alphadash)
        var NutationDec = CAANutation.NutationInDeclination(alpha / 15.0, e0, NutationInLongitude, NutationInObliquity)
        let deltadash = delta + (NutationDec / 3600.0)
        let deltadashrad = SphericalTrigonometry.degreesToRadians(deltadash)
        NutationRA = CAANutation.NutationInRightAscension(alpha0 / 15.0, delta0, e0, NutationInLongitude, NutationInObliquity)
        let alpha0dash = alpha0 + (NutationRA / 3600.0)
        let alpha0dashrad = SphericalTrigonometry.degreesToRadians(alpha0dash)
        NutationDec = CAANutation.NutationInDeclination(alpha0 / 15.0, e0, NutationInLongitude, NutationInObliquity)
        let delta0dash = delta0 + (NutationDec / 3600.0)
        let delta0dashrad = SphericalTrigonometry.degreesToRadians(delta0dash)
        let cosdelta0dashrad = cos(delta0dashrad)

        // Step 18
        details.P = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(atan2(cosdelta0dashrad * sin(alpha0dashrad - alphadashrad), sin(delta0dashrad) * cos(deltadashrad) - cosdelta0dashrad * sin(deltadashrad) * cos(alpha0dashrad - alphadashrad))))

        return details
    }
}

// MARK: - Physical Ephemeris of Mars (CAAPhysicalMars)

public enum CAAPhysicalMars: Sendable {
    public static func Calculate(_ JD: Double, _ bHighPrecision: Bool) -> CAAPhysicalMarsDetails {
        var details = CAAPhysicalMarsDetails()

        // Step 1
        let T = (JD - 2451545.0) / 36525.0
        var Lambda0 = 352.9065 + (1.17330 * T)
        let Lambda0rad = SphericalTrigonometry.degreesToRadians(Lambda0)
        let Beta0 = 63.2818 - (0.00394 * T)
        let Beta0rad = SphericalTrigonometry.degreesToRadians(Beta0)
        let cosBeta0rad = cos(Beta0rad)
        let sinBeta0rad = sin(Beta0rad)

        // Step 2
        let l0 = CAAEarth.EclipticLongitude(JD, bHighPrecision)
        let l0rad = SphericalTrigonometry.degreesToRadians(l0)
        let b0 = CAAEarth.EclipticLatitude(JD, bHighPrecision)
        let b0rad = SphericalTrigonometry.degreesToRadians(b0)
        let R = CAAEarth.RadiusVector(JD, bHighPrecision)

        var PreviousLightTravelTime = 0.0
        var LightTravelTime = 0.0
        var x = 0.0
        var y = 0.0
        var z = 0.0
        var bIterate = true
        var DELTA = 0.0
        var l = 0.0
        var lrad = 0.0
        var b = 0.0
        var r = 0.0

        while bIterate {
            let JD2 = JD - LightTravelTime

            // Step 3
            l = CAAMars.EclipticLongitude(JD2, bHighPrecision)
            lrad = SphericalTrigonometry.degreesToRadians(l)
            b = CAAMars.EclipticLatitude(JD2, bHighPrecision)
            let brad = SphericalTrigonometry.degreesToRadians(b)
            let cosbrad = cos(brad)
            r = CAAMars.RadiusVector(JD2, bHighPrecision)

            // Step 4
            x = (r * cosbrad * cos(lrad)) - (R * cos(l0rad))
            y = (r * cosbrad * sin(lrad)) - (R * sin(l0rad))
            z = (r * sin(brad)) - (R * sin(b0rad))
            DELTA = sqrt((x * x) + (y * y) + (z * z))
            LightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)

            bIterate = (abs(LightTravelTime - PreviousLightTravelTime) > 2e-6)
            if bIterate {
                PreviousLightTravelTime = LightTravelTime
            }
        }

        // Step 5
        let lambdarad = atan2(y, x)
        var lambda = SphericalTrigonometry.radiansToDegrees(lambdarad)
        let betarad = atan2(z, sqrt((x * x) + (y * y)))
        var beta = SphericalTrigonometry.radiansToDegrees(betarad)

        // Step 6
        details.DE = SphericalTrigonometry.radiansToDegrees(asin((-sinBeta0rad * sin(betarad)) - (cosBeta0rad * cos(betarad) * cos(Lambda0rad - lambdarad))))

        // Step 7
        let N = 49.5581 + (0.7721 * T)
        let Nrad = SphericalTrigonometry.degreesToRadians(N)
        let ldash = l - (0.00697 / r)
        let ldashrad = SphericalTrigonometry.degreesToRadians(ldash)
        let bdash = b - (0.000225 * (cos(lrad - Nrad) / r))
        let bdashrad = SphericalTrigonometry.degreesToRadians(bdash)

        // Step 8
        details.DS = SphericalTrigonometry.radiansToDegrees(asin((-sinBeta0rad * sin(bdashrad)) - (cosBeta0rad * cos(bdashrad) * cos(Lambda0rad - ldashrad))))

        // Step 9
        let W = SphericalTrigonometry.mapTo0To360Range(11.504 + (350.89200025 * (JD - LightTravelTime - 2433282.5)))

        // Step 10
        var e0 = CAANutation.MeanObliquityOfEcliptic(JD)
        let e0rad = SphericalTrigonometry.degreesToRadians(e0)
        let cose0rad = cos(e0rad)
        let sine0rad = sin(e0rad)
        let PoleEquatorial = SphericalTrigonometry.eclipticToEquatorial(Lambda0, Beta0, e0)
        let alpha0rad = SphericalTrigonometry.hoursToRadians(PoleEquatorial.X)
        let delta0rad = SphericalTrigonometry.degreesToRadians(PoleEquatorial.Y)

        // Step 11
        let u = (y * cose0rad) - (z * sine0rad)
        let v = (y * sine0rad) + (z * cose0rad)
        let alpharad = atan2(u, x)
        let alpha = SphericalTrigonometry.radiansToHours(alpharad)
        let deltarad = atan2(v, sqrt((x * x) + (u * u)))
        let cosdeltarad = cos(deltarad)
        let delta = SphericalTrigonometry.radiansToDegrees(deltarad)
        let alpha0radminusalpharad = alpha0rad - alpharad
        let xi = atan2((sin(delta0rad) * cosdeltarad * cos(alpha0radminusalpharad)) - (sin(deltarad) * cos(delta0rad)), cosdeltarad * sin(alpha0radminusalpharad))

        // Step 12
        details.w = SphericalTrigonometry.mapTo0To360Range(W - SphericalTrigonometry.radiansToDegrees(xi))

        // Step 13
        let NutationInLongitude = CAANutation.NutationInLongitude(JD)
        let NutationInObliquity = CAANutation.NutationInObliquity(JD)

        // Step 14
        let l0radminuslambdarad = l0rad - lambdarad
        lambda += (0.005693 * cos(l0radminuslambdarad) / cos(betarad))
        beta += (0.005693 * sin(l0radminuslambdarad) * sin(betarad))

        // Step 15
        let NutationInLongitude3600 = NutationInLongitude / 3600.0
        Lambda0 += NutationInLongitude3600
        lambda += NutationInLongitude3600
        e0 += (NutationInObliquity / 3600.0)

        // Step 16
        let ApparentPoleEquatorial = SphericalTrigonometry.eclipticToEquatorial(Lambda0, Beta0, e0)
        let alpha0dash = SphericalTrigonometry.hoursToRadians(ApparentPoleEquatorial.X)
        let delta0dash = SphericalTrigonometry.degreesToRadians(ApparentPoleEquatorial.Y)
        let cosdelta0dash = cos(delta0dash)
        let ApparentMars = SphericalTrigonometry.eclipticToEquatorial(lambda, beta, e0)
        let alphadash = SphericalTrigonometry.hoursToRadians(ApparentMars.X)
        let alpha0dashminusalphadash = alpha0dash - alphadash
        let deltadash = SphericalTrigonometry.degreesToRadians(ApparentMars.Y)

        // Step 17
        details.P = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(atan2(cosdelta0dash * sin(alpha0dashminusalphadash), sin(delta0dash) * cos(deltadash) - cosdelta0dash * sin(deltadash) * cos(alpha0dashminusalphadash))))

        // Step 18
        let SunLambda = CAASun.GeometricEclipticLongitude(JD, bHighPrecision)
        let SunBeta = CAASun.GeometricEclipticLatitude(JD, bHighPrecision)
        let SunEquatorial = SphericalTrigonometry.eclipticToEquatorial(SunLambda, SunBeta, e0)
        details.X = CAAMoonIlluminatedFraction.PositionAngle(SunEquatorial.X, SunEquatorial.Y, alpha, delta)

        // Step 19
        details.d = 9.36 / DELTA
        details.k = CAAIlluminatedFraction.IlluminatedFraction(r, R, DELTA)
        details.q = (1.0 - details.k) * details.d

        return details
    }
}

// MARK: - Saturn Rings Geometry (CAASaturnRings)

public enum CAASaturnRings: Sendable {
    public static func Calculate(_ JD: Double, _ bHighPrecision: Bool) -> CAASaturnRingDetails {
        var details = CAASaturnRingDetails()

        let T = (JD - 2451545.0) / 36525.0
        let T2 = T * T

        // Step 1
        let i = 28.075216 - (0.012998 * T) + (0.000004 * T2)
        let irad = SphericalTrigonometry.degreesToRadians(i)
        let sinirad = sin(irad)
        let cosirad = cos(irad)
        let omega = 169.508470 + (1.394681 * T) + (0.000412 * T2)
        let omegarad = SphericalTrigonometry.degreesToRadians(omega)

        // Step 2
        var l0 = CAAEarth.EclipticLongitude(JD, bHighPrecision)
        var b0 = CAAEarth.EclipticLatitude(JD, bHighPrecision)
        l0 += CAAFK5.CorrectionInLongitude(l0, b0, JD)
        let l0rad = SphericalTrigonometry.degreesToRadians(l0)
        b0 += CAAFK5.CorrectionInLatitude(l0, JD)
        let b0rad = SphericalTrigonometry.degreesToRadians(b0)
        let R = CAAEarth.RadiusVector(JD, bHighPrecision)

        // Step 3
        var DELTA = 9.0
        var PreviousEarthLightTravelTime = 0.0
        var EarthLightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)
        var JD1 = JD - EarthLightTravelTime
        var bIterate = true
        var x = 0.0
        var y = 0.0
        var z = 0.0
        var l = 0.0
        var b = 0.0
        var r = 0.0

        while bIterate {
            l = CAASaturn.EclipticLongitude(JD1, bHighPrecision)
            b = CAASaturn.EclipticLatitude(JD1, bHighPrecision)
            l += CAAFK5.CorrectionInLongitude(l, b, JD1)
            b += CAAFK5.CorrectionInLatitude(l, JD1)

            let lrad = SphericalTrigonometry.degreesToRadians(l)
            let brad = SphericalTrigonometry.degreesToRadians(b)
            let cosbrad = cos(brad)
            r = CAASaturn.RadiusVector(JD1, bHighPrecision)

            x = (r * cosbrad * cos(lrad)) - (R * cos(l0rad))
            y = (r * cosbrad * sin(lrad)) - (R * sin(l0rad))
            z = (r * sin(brad)) - (R * sin(b0rad))
            DELTA = sqrt((x * x) + (y * y) + (z * z))
            EarthLightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)

            bIterate = (abs(EarthLightTravelTime - PreviousEarthLightTravelTime) > 2e-6)
            if bIterate {
                JD1 = JD - EarthLightTravelTime
                PreviousEarthLightTravelTime = EarthLightTravelTime
            }
        }

        // Step 5
        var lambda = atan2(y, x)
        var beta = atan2(z, sqrt((x * x) + (y * y)))
        let cosbeta = cos(beta)
        let sinbeta = sin(beta)

        // Step 6
        let sinlambdaminusomegarad = sin(lambda - omegarad)
        details.B = asin((sinirad * cosbeta * sinlambdaminusomegarad) - (cosirad * sinbeta))
        details.a = 375.35 / DELTA
        details.b = details.a * sin(abs(details.B))
        details.B = SphericalTrigonometry.radiansToDegrees(details.B)

        // Step 7
        let N = 113.6655 + (0.8771 * T)
        let Nrad = SphericalTrigonometry.degreesToRadians(N)
        let ldash = l - (0.01759 / r)
        let ldashrad = SphericalTrigonometry.degreesToRadians(ldash)
        let bdash = b - (0.000764 * cos(ldashrad - Nrad) / r)
        let bdashrad = SphericalTrigonometry.degreesToRadians(bdash)
        let sinbdashrad = sin(bdashrad)
        let cosbdashrad = cos(bdashrad)
        let sinldashradminusomegarad = sin(ldashrad - omegarad)

        // Step 8
        details.Bdash = SphericalTrigonometry.radiansToDegrees(asin((sinirad * cosbdashrad * sinldashradminusomegarad) - (cosirad * sinbdashrad)))

        // Step 9
        details.U1 = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(atan2((sinirad * sinbdashrad) + (cosirad * cosbdashrad * sinldashradminusomegarad), cosbdashrad * cos(ldashrad - omegarad))))
        details.U2 = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(atan2((sinirad * sinbeta) + (cosirad * cosbeta * sinlambdaminusomegarad), cosbeta * cos(lambda - omegarad))))
        details.DeltaU = abs(details.U1 - details.U2)
        if details.DeltaU > 180.0 {
            details.DeltaU = 360.0 - details.DeltaU
        }

        // Step 10
        let Obliquity = CAANutation.TrueObliquityOfEcliptic(JD)
        let NutationInLongitude = CAANutation.NutationInLongitude(JD)

        // Step 11
        var lambda0 = omega - 90.0
        let beta0 = 90.0 - i

        // Step 12
        lambda += SphericalTrigonometry.degreesToRadians(0.005693 * cos(l0rad - lambda) / cosbeta)
        beta += SphericalTrigonometry.degreesToRadians(0.005693 * sin(l0rad - lambda) * sinbeta)

        // Step 13
        lambda = SphericalTrigonometry.radiansToDegrees(lambda)
        lambda += NutationInLongitude / 3600.0
        lambda = SphericalTrigonometry.mapTo0To360Range(lambda)
        lambda0 += NutationInLongitude / 3600.0
        lambda0 = SphericalTrigonometry.mapTo0To360Range(lambda0)

        // Step 14
        beta = SphericalTrigonometry.radiansToDegrees(beta)
        let GeocentricEclipticSaturn = SphericalTrigonometry.eclipticToEquatorial(lambda, beta, Obliquity)
        let alpha = SphericalTrigonometry.hoursToRadians(GeocentricEclipticSaturn.X)
        let delta = SphericalTrigonometry.degreesToRadians(GeocentricEclipticSaturn.Y)
        let GeocentricEclipticNorthPole = SphericalTrigonometry.eclipticToEquatorial(lambda0, beta0, Obliquity)
        let alpha0 = SphericalTrigonometry.hoursToRadians(GeocentricEclipticNorthPole.X)
        let delta0 = SphericalTrigonometry.degreesToRadians(GeocentricEclipticNorthPole.Y)
        let cosdelta0 = cos(delta0)
        let alpha0minusalpha = alpha0 - alpha

        // Step 15
        details.P = SphericalTrigonometry.radiansToDegrees(atan2(cosdelta0 * sin(alpha0minusalpha), sin(delta0) * cos(delta) - cosdelta0 * sin(delta) * cos(alpha0minusalpha)))

        return details
    }
}

// MARK: - Galilean Moons of Jupiter (CAAGalileanMoons)

public enum CAAGalileanMoons: Sendable {
    private static func Rotations(_ X: Double, _ Y: Double, _ Z: Double, _ I: Double, _ psi: Double, _ i: Double, _ omega: Double, _ lambda0: Double, _ beta0: Double) -> (A6: Double, B6: Double, C6: Double) {
        let phi = psi - omega

        // Rotation towards Jupiter's orbital plane
        let A1 = X
        let cosI = cos(I)
        let sinI = sin(I)
        let B1 = (Y * cosI) - (Z * sinI)
        let C1 = (Y * sinI) + (Z * cosI)

        // Rotation towards ascending node of orbit of Jupiter
        let cosphi = cos(phi)
        let sinphi = sin(phi)
        let A2 = (A1 * cosphi) - (B1 * sinphi)
        let B2 = (A1 * sinphi) + (B1 * cosphi)
        let C2 = C1

        // Rotation towards plane of ecliptic
        let A3 = A2
        let cosi = cos(i)
        let sini = sin(i)
        let B3 = (B2 * cosi) - (C2 * sini)
        let C3 = (B2 * sini) + (C2 * cosi)

        // Rotation towards vernal equinox
        let cosomega = cos(omega)
        let sinomega = sin(omega)
        let A4 = (A3 * cosomega) - (B3 * sinomega)
        let B4 = (A3 * sinomega) + (B3 * cosomega)
        let C4 = C3

        let coslambda0 = cos(lambda0)
        let sinlambda0 = sin(lambda0)
        let A5 = (A4 * sinlambda0) - (B4 * coslambda0)
        let B5 = (A4 * coslambda0) + (B4 * sinlambda0)
        let C5 = C4

        let A6 = A5
        let cosbeta0 = cos(beta0)
        let sinbeta0 = sin(beta0)
        let B6 = (C5 * sinbeta0) + (B5 * cosbeta0)
        let C6 = (C5 * cosbeta0) - (B5 * sinbeta0)

        return (A6, B6, C6)
    }

    private static func FillInPhenomenaDetails(_ detail: inout CAAGalileanMoonDetail) {
        let Y1 = 1.071374 * detail.ApparentRectangularCoordinates.Y
        let r = (Y1 * Y1) + (detail.ApparentRectangularCoordinates.X * detail.ApparentRectangularCoordinates.X)

        if r < 1.0 {
            if detail.ApparentRectangularCoordinates.Z < 0 {
                detail.bInTransit = true
                detail.bInOccultation = false
            } else {
                detail.bInTransit = false
                detail.bInOccultation = true
            }
        } else {
            detail.bInTransit = false
            detail.bInOccultation = false
        }
    }

    private static func CalculateHelper(_ JD: Double, _ sunlongrad: Double, _ betarad: Double, _ R: Double, _ bHighPrecision: Bool) -> CAAGalileanMoonsDetails {
        var details = CAAGalileanMoonsDetails()

        var DELTA = 5.0
        var PreviousLightTravelTime = 0.0
        var LightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)
        var x = 0.0
        var y = 0.0
        var z = 0.0
        var JD1 = JD - LightTravelTime
        var bIterate = true

        while bIterate {
            let l = CAAJupiter.EclipticLongitude(JD1, bHighPrecision)
            let lrad = SphericalTrigonometry.degreesToRadians(l)
            let b = CAAJupiter.EclipticLatitude(JD1, bHighPrecision)
            let brad = SphericalTrigonometry.degreesToRadians(b)
            let r = CAAJupiter.RadiusVector(JD1, bHighPrecision)

            x = (r * cos(brad) * cos(lrad)) + (R * cos(sunlongrad))
            y = (r * cos(brad) * sin(lrad)) + (R * sin(sunlongrad))
            z = (r * sin(brad)) + (R * sin(betarad))
            DELTA = sqrt((x * x) + (y * y) + (z * z))
            LightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)

            bIterate = (abs(LightTravelTime - PreviousLightTravelTime) > 2e-6)
            if bIterate {
                JD1 = JD - LightTravelTime
                PreviousLightTravelTime = LightTravelTime
            }
        }

        let lambda0 = atan2(y, x)
        let beta0 = atan(z / sqrt((x * x) + (y * y)))

        let t = JD - 2443000.5 - LightTravelTime

        // Mean longitudes
        let l1 = 106.07719 + (203.488955790 * t)
        let l1rad = SphericalTrigonometry.degreesToRadians(l1)
        let l2 = 175.73161 + (101.374724735 * t)
        let l2rad = SphericalTrigonometry.degreesToRadians(l2)
        let l3 = 120.55883 + (50.317609207 * t)
        let l3rad = SphericalTrigonometry.degreesToRadians(l3)
        let l4 = 84.44459 + (21.571071177 * t)
        let l4rad = SphericalTrigonometry.degreesToRadians(l4)

        // Perijoves
        let pi1 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(97.0881 + (0.16138586 * t)))
        let pi2 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(154.8663 + (0.04726307 * t)))
        let pi3 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(188.1840 + (0.00712734 * t)))
        let pi4 = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(335.2868 + (0.00184000 * t)))

        // Nodes on equatorial plane of Jupiter
        let w1 = 312.3346 - (0.13279386 * t)
        let w1rad = SphericalTrigonometry.degreesToRadians(w1)
        let w2 = 100.4411 - (0.03263064 * t)
        let w2rad = SphericalTrigonometry.degreesToRadians(w2)
        let w3 = 119.1942 - (0.00717703 * t)
        let w3rad = SphericalTrigonometry.degreesToRadians(w3)
        let w4 = 322.6186 - (0.00175934 * t)
        let w4rad = SphericalTrigonometry.degreesToRadians(w4)

        // Principal inequality
        let GAMMA = 0.33033 * sin(SphericalTrigonometry.degreesToRadians(163.679 + (0.0010512 * t))) +
                    0.03439 * sin(SphericalTrigonometry.degreesToRadians(34.486 - (0.0161731 * t)))

        let philambda = SphericalTrigonometry.degreesToRadians(199.6766 + (0.17379190 * t))
        var psi = SphericalTrigonometry.degreesToRadians(316.5182 - (0.00000208 * t))

        let G = SphericalTrigonometry.degreesToRadians(30.23756 + (0.0830925701 * t) + GAMMA)
        let Gdash = SphericalTrigonometry.degreesToRadians(31.97853 + (0.0334597339 * t))

        let PI = SphericalTrigonometry.degreesToRadians(13.469942)
        let twoPI = 2.0 * PI
        let twoG = 2.0 * G
        let threeG = 3.0 * G
        let twol3rad = 2.0 * l3rad
        let twopsi = 2.0 * psi
        let l1radminusl3rad = l1rad - l3rad
        let l1radminuspi3 = l1rad - pi3
        let l1radminusl2rad = l1rad - l2rad
        let l2radminusl3rad = l2rad - l3rad
        let twol2rad = 2.0 * l2rad
        let threel3rad = 3.0 * l3rad
        let twol4rad = 2.0 * l4rad
        let sevenl4rad = 7.0 * l4rad

        let Sigma1 = 0.47259 * sin(2.0 * l1radminusl2rad) +
                    -0.03478 * sin(pi3 - pi4) +
                     0.01081 * sin(l2rad - twol3rad + pi3) +
                     0.00738 * sin(philambda) +
                     0.00713 * sin(l2rad - twol3rad + pi2) +
                    -0.00674 * sin(pi1 + pi3 - twoPI - twoG) +
                     0.00666 * sin(l2rad - twol3rad + pi4) +
                     0.00445 * sin(l1radminuspi3) +
                    -0.00354 * sin(l1radminusl2rad) +
                    -0.00317 * sin(twopsi - twoPI) +
                     0.00265 * sin(l1rad - pi4) +
                    -0.00186 * sin(G) +
                     0.00162 * sin(pi2 - pi3) +
                     0.00158 * sin(4.0 * l1radminusl2rad) +
                    -0.00155 * sin(l1radminusl3rad) +
                    -0.00138 * sin(psi + w3rad - twoPI - twoG) +
                    -0.00115 * sin(2.0 * (l1rad - twol2rad + w2rad)) +
                     0.00089 * sin(pi2 - pi4) +
                     0.00085 * sin(l1rad + pi3 - twoPI - twoG) +
                     0.00083 * sin(w2rad - w3rad) +
                     0.00053 * sin(psi - w2rad)
        let Sigma1rad = SphericalTrigonometry.degreesToRadians(Sigma1)

        let Sigma2 = 1.06476 * sin(2.0 * l2radminusl3rad) +
                     0.04256 * sin(l1rad - twol2rad + pi3) +
                     0.03581 * sin(l2rad - pi3) +
                     0.02395 * sin(l1rad - twol2rad + pi4) +
                     0.01984 * sin(l2rad - pi4) +
                    -0.01778 * sin(philambda) +
                     0.01654 * sin(l2rad - pi2) +
                     0.01334 * sin(l2rad - twol3rad + pi2) +
                     0.01294 * sin(pi3 - pi4) +
                    -0.01142 * sin(l2radminusl3rad) +
                    -0.01057 * sin(G) +
                    -0.00775 * sin(2.0 * (psi - PI)) +
                     0.00524 * sin(2.0 * l1radminusl2rad) +
                    -0.00460 * sin(l1radminusl3rad) +
                     0.00316 * sin(psi - twoG + w3rad - twoPI) +
                    -0.00203 * sin(pi1 + pi3 - twoPI - twoG) +
                     0.00146 * sin(psi - w3rad) +
                    -0.00145 * sin(twoG) +
                     0.00125 * sin(psi - w4rad) +
                    -0.00115 * sin(l1rad - twol3rad + pi3) +
                    -0.00094 * sin(2.0 * (l2rad - w2rad)) +
                     0.00086 * sin(2.0 * (l1rad - twol2rad + w2rad)) +
                    -0.00086 * sin((5.0 * Gdash) - twoG + SphericalTrigonometry.degreesToRadians(52.225)) +
                    -0.00078 * sin(l2rad - l4rad) +
                    -0.00064 * sin(threel3rad - sevenl4rad + (4.0 * pi4)) +
                     0.00064 * sin(pi1 - pi4) +
                    -0.00063 * sin(l1rad - twol3rad + pi4) +
                     0.00058 * sin(w3rad - w4rad) +
                     0.00056 * sin(2.0 * (psi - PI - G)) +
                     0.00056 * sin(2.0 * (l2rad - l4rad)) +
                     0.00055 * sin(2.0 * l1radminusl3rad) +
                     0.00052 * sin(threel3rad - sevenl4rad + pi3 + (3.0 * pi4)) +
                    -0.00043 * sin(l1radminuspi3) +
                     0.00041 * sin(5.0 * l2radminusl3rad) +
                     0.00041 * sin(pi4 - PI) +
                     0.00032 * sin(w2rad - w3rad) +
                     0.00032 * sin(2.0 * (l3rad - G - PI))
        let Sigma2rad = SphericalTrigonometry.degreesToRadians(Sigma2)

        let Sigma3 = 0.16490 * sin(l3rad - pi3) +
                     0.09081 * sin(l3rad - pi4) +
                    -0.06907 * sin(l2radminusl3rad) +
                     0.03784 * sin(pi3 - pi4) +
                     0.01846 * sin(2.0 * (l3rad - l4rad)) +
                    -0.01340 * sin(G) +
                    -0.01014 * sin(2.0 * (psi - PI)) +
                     0.00704 * sin(l2rad - twol3rad + pi3) +
                    -0.00620 * sin(l2rad - twol3rad + pi2) +
                    -0.00541 * sin(l3rad - l4rad) +
                     0.00381 * sin(l2rad - twol3rad + pi4) +
                     0.00235 * sin(psi - w3rad) +
                     0.00198 * sin(psi - w4rad) +
                     0.00176 * sin(philambda) +
                     0.00130 * sin(3.0 * (l3rad - l4rad)) +
                     0.00125 * sin(l1radminusl3rad) +
                    -0.00119 * sin((5.0 * Gdash) - twoG + SphericalTrigonometry.degreesToRadians(52.225)) +
                     0.00109 * sin(l1radminusl2rad) +
                    -0.00100 * sin(threel3rad - sevenl4rad + (4.0 * pi4)) +
                     0.00091 * sin(w3rad - w4rad) +
                     0.00080 * sin(threel3rad - sevenl4rad + pi3 + (3.0 * pi4)) +
                    -0.00075 * sin(twol2rad - threel3rad + pi3) +
                     0.00072 * sin(pi1 + pi3 - twoPI - twoG) +
                     0.00069 * sin(pi4 - PI) +
                    -0.00058 * sin(twol3rad - (3.0 * l4rad) + pi4) +
                    -0.00057 * sin(l3rad - twol4rad + pi4) +
                     0.00056 * sin(l3rad + pi3 - twoPI - twoG) +
                    -0.00052 * sin(l2rad - twol3rad + pi1) +
                    -0.00050 * sin(pi2 - pi3) +
                     0.00048 * sin(l3rad - twol4rad + pi3) +
                    -0.00045 * sin(twol2rad - threel3rad + pi4) +
                    -0.00041 * sin(pi2 - pi4) +
                    -0.00038 * sin(twoG) +
                    -0.00037 * sin(pi3 - pi4 + w3rad - w4rad) +
                    -0.00032 * sin(threel3rad - sevenl4rad + (2.0 * pi3) + (2.0 * pi4)) +
                     0.00030 * sin(4.0 * (l3rad - l4rad)) +
                     0.00029 * sin(l3rad + pi4 - twoPI - twoG) +
                    -0.00028 * sin(w3rad + psi - twoPI - twoG) +
                     0.00026 * sin(l3rad - PI - G) +
                     0.00024 * sin(l2rad - threel3rad + twol4rad) +
                     0.00021 * sin(l3rad - PI - G) +
                    -0.00021 * sin(l3rad - pi2) +
                     0.00017 * sin(2.0 * (l3rad - pi3))
        let Sigma3rad = SphericalTrigonometry.degreesToRadians(Sigma3)

        let Sigma4 = 0.84287 * sin(l4rad - pi4) +
                     0.03431 * sin(pi4 - pi3) +
                    -0.03305 * sin(2.0 * (psi - PI)) +
                    -0.03211 * sin(G) +
                    -0.01862 * sin(l4rad - pi3) +
                     0.01186 * sin(psi - w4rad) +
                     0.00623 * sin(l4rad + pi4 - twoG - twoPI) +
                     0.00387 * sin(2.0 * (l4rad - pi4)) +
                    -0.00284 * sin((5.0 * Gdash) - twoG + SphericalTrigonometry.degreesToRadians(52.225)) +
                    -0.00234 * sin(2.0 * (psi - pi4)) +
                    -0.00223 * sin(l3rad - l4rad) +
                    -0.00208 * sin(l4rad - PI) +
                     0.00178 * sin(psi + w4rad - (2.0 * pi4)) +
                     0.00134 * sin(pi4 - PI) +
                     0.00125 * sin(2.0 * (l4rad - G - PI)) +
                    -0.00117 * sin(twoG) +
                    -0.00112 * sin(2.0 * (l3rad - l4rad)) +
                     0.00107 * sin(threel3rad - sevenl4rad + (4.0 * pi4)) +
                     0.00102 * sin(l4rad - G - PI) +
                     0.00096 * sin(twol4rad - psi - w4rad) +
                     0.00087 * sin(2.0 * (psi - w4rad)) +
                    -0.00085 * sin(threel3rad - sevenl4rad + pi3 + (3.0 * pi4)) +
                     0.00085 * sin(l3rad - twol4rad + pi4) +
                    -0.00081 * sin(2.0 * (l4rad - psi)) +
                     0.00071 * sin(l4rad + pi4 - twoPI - threeG) +
                     0.00061 * sin(l1rad - l4rad) +
                    -0.00056 * sin(psi - w3rad) +
                    -0.00054 * sin(l3rad - twol4rad + pi3) +
                     0.00051 * sin(l2rad - l4rad) +
                     0.00042 * sin(2.0 * (psi - G - PI)) +
                     0.00039 * sin(2.0 * (pi4 - w4rad)) +
                     0.00036 * sin(psi + PI - pi4 - w4rad) +
                     0.00035 * sin((2.0 * Gdash) - G + SphericalTrigonometry.degreesToRadians(188.37)) +
                    -0.00035 * sin(l4rad - pi4 + twoPI - twopsi) +
                    -0.00032 * sin(l4rad + pi4 - twoPI - G) +
                     0.00030 * sin((2.0 * Gdash) - twoG + SphericalTrigonometry.degreesToRadians(149.15)) +
                     0.00029 * sin(threel3rad - sevenl4rad + (2.0 * pi3) + (2.0 * pi4)) +
                     0.00028 * sin(l4rad - pi4 + twopsi - twoPI) +
                    -0.00028 * sin(2.0 * (l4rad - w4rad)) +
                    -0.00027 * sin(pi3 - pi4 + w3rad - w4rad) +
                    -0.00026 * sin((5.0 * Gdash) - threeG + SphericalTrigonometry.degreesToRadians(188.37)) +
                     0.00025 * sin(w4rad - w3rad) +
                    -0.00025 * sin(l2rad - threel3rad + twol4rad) +
                    -0.00023 * sin(3.0 * (l3rad - l4rad)) +
                     0.00021 * sin(twol4rad - twoPI - threeG) +
                    -0.00021 * sin(twol3rad - (3.0 * l4rad) + pi4) +
                     0.00019 * sin(l4rad - pi4 - G) +
                    -0.00019 * sin(twol4rad - pi3 - pi4) +
                    -0.00018 * sin(l4rad - pi4 + G) +
                    -0.00016 * sin(l4rad + pi3 - twoPI - twoG)

        details.Satellite1.MeanLongitude = SphericalTrigonometry.mapTo0To360Range(l1)
        details.Satellite1.TrueLongitude = SphericalTrigonometry.mapTo0To360Range(l1 + Sigma1)
        var L1 = SphericalTrigonometry.degreesToRadians(details.Satellite1.TrueLongitude)

        details.Satellite2.MeanLongitude = SphericalTrigonometry.mapTo0To360Range(l2)
        details.Satellite2.TrueLongitude = SphericalTrigonometry.mapTo0To360Range(l2 + Sigma2)
        var L2 = SphericalTrigonometry.degreesToRadians(details.Satellite2.TrueLongitude)

        details.Satellite3.MeanLongitude = SphericalTrigonometry.mapTo0To360Range(l3)
        details.Satellite3.TrueLongitude = SphericalTrigonometry.mapTo0To360Range(l3 + Sigma3)
        var L3 = SphericalTrigonometry.degreesToRadians(details.Satellite3.TrueLongitude)

        details.Satellite4.MeanLongitude = SphericalTrigonometry.mapTo0To360Range(l4)
        details.Satellite4.TrueLongitude = SphericalTrigonometry.mapTo0To360Range(l4 + Sigma4)
        var L4 = SphericalTrigonometry.degreesToRadians(details.Satellite4.TrueLongitude)

        // Latitudes
        let B1 = atan(0.0006393 * sin(L1 - w1rad) +
                      0.0001825 * sin(L1 - w2rad) +
                      0.0000329 * sin(L1 - w3rad) +
                     -0.0000311 * sin(L1 - psi) +
                      0.0000093 * sin(L1 - w4rad) +
                      0.0000075 * sin((3.0 * L1) - (4.0 * l2rad) - (1.9927 * Sigma1rad) + w2rad) +
                      0.0000046 * sin(L1 + psi - twoPI - twoG))
        details.Satellite1.EquatorialLatitude = SphericalTrigonometry.radiansToDegrees(B1)

        let B2 = atan(0.0081004 * sin(L2 - w2rad) +
                      0.0004512 * sin(L2 - w3rad) +
                     -0.0003284 * sin(L2 - psi) +
                      0.0001160 * sin(L2 - w4rad) +
                      0.0000272 * sin(l1rad - twol3rad + (1.0146 * Sigma2rad) + w2rad) +
                     -0.0000144 * sin(L2 - w1rad) +
                      0.0000143 * sin(L2 + psi - twoPI - twoG) +
                      0.0000035 * sin(L2 - psi + G) +
                     -0.0000028 * sin(l1rad - twol3rad + (1.0146 * Sigma2rad) + w3rad))
        details.Satellite2.EquatorialLatitude = SphericalTrigonometry.radiansToDegrees(B2)

        let threeL3 = 3.0 * L3
        let four0threeSigma3rad = 4.03 * Sigma3rad
        let B3 = atan(0.0032402 * sin(L3 - w3rad) +
                     -0.0016911 * sin(L3 - psi) +
                      0.0006847 * sin(L3 - w4rad) +
                     -0.0002797 * sin(L3 - w2rad) +
                      0.0000321 * sin(L3 + psi - twoPI - twoG) +
                      0.0000051 * sin(L3 - psi + G) +
                     -0.0000045 * sin(L3 - psi - G) +
                     -0.0000045 * sin(L3 + psi - twoPI) +
                      0.0000037 * sin(L3 + psi - twoPI - threeG) +
                      0.0000030 * sin(twol2rad - threeL3 + four0threeSigma3rad + w2rad) +
                     -0.0000021 * sin(twol2rad - threeL3 + four0threeSigma3rad + w3rad))
        details.Satellite3.EquatorialLatitude = SphericalTrigonometry.radiansToDegrees(B3)

        let B4 = atan(-0.0076579 * sin(L4 - psi) +
                       0.0044134 * sin(L4 - w4rad) +
                      -0.0005112 * sin(L4 - w3rad) +
                       0.0000773 * sin(L4 + psi - twoPI - twoG) +
                       0.0000104 * sin(L4 - psi + G) +
                      -0.0000102 * sin(L4 - psi - G) +
                       0.0000088 * sin(L4 + psi - twoPI - threeG) +
                      -0.0000038 * sin(L4 + psi - twoPI - G))
        details.Satellite4.EquatorialLatitude = SphericalTrigonometry.radiansToDegrees(B4)

        // Radius vectors
        details.Satellite1.r = 5.90569 * (1.0 + (-0.0041339 * cos(2.0 * l1radminusl2rad) +
                                                 -0.0000387 * cos(l1radminuspi3) +
                                                 -0.0000214 * cos(l1rad - pi4) +
                                                  0.0000170 * cos(l1radminusl2rad) +
                                                 -0.0000131 * cos(4.0 * l1radminusl2rad) +
                                                  0.0000106 * cos(l1radminusl3rad) +
                                                 -0.0000066 * cos(l1rad + pi3 - twoPI - twoG)))

        details.Satellite2.r = 9.39657 * (1.0 + (0.0093848 * cos(l1radminusl2rad) +
                                                -0.0003116 * cos(l2rad - pi3) +
                                                -0.0001744 * cos(l2rad - pi4) +
                                                -0.0001442 * cos(l2rad - pi2) +
                                                 0.0000553 * cos(l2radminusl3rad) +
                                                 0.0000523 * cos(l1radminusl3rad) +
                                                -0.0000290 * cos(2.0 * l1radminusl2rad) +
                                                 0.0000164 * cos(2.0 * (l2rad - w2rad)) +
                                                 0.0000107 * cos(l1rad - twol3rad + pi3) +
                                                -0.0000102 * cos(l2rad - pi1) +
                                                -0.0000091 * cos(2.0 * l1radminusl3rad)))

        details.Satellite3.r = 14.98832 * (1.0 + (-0.0014388 * cos(l3rad - pi3) +
                                                  -0.0007919 * cos(l3rad - pi4) +
                                                   0.0006342 * cos(l2radminusl3rad) +
                                                  -0.0001761 * cos(2.0 * (l3rad - l4rad)) +
                                                   0.0000294 * cos(l3rad - l4rad) +
                                                  -0.0000156 * cos(3.0 * (l3rad - l4rad)) +
                                                   0.0000156 * cos(l1radminusl3rad) +
                                                  -0.0000153 * cos(l1radminusl2rad) +
                                                   0.0000070 * cos(twol2rad - threel3rad + pi3) +
                                                  -0.0000051 * cos(l3rad + pi3 - twoPI - twoG)))

        details.Satellite4.r = 26.36273 * (1.0 + (-0.0073546 * cos(l4rad - pi4) +
                                                   0.0001621 * cos(l4rad - pi3) +
                                                   0.0000974 * cos(l3rad - l4rad) +
                                                  -0.0000543 * cos(l4rad + pi4 - twoPI - twoG) +
                                                  -0.0000271 * cos(2.0 * (l4rad - pi4)) +
                                                   0.0000182 * cos(l4rad - PI) +
                                                   0.0000177 * cos(2.0 * (l3rad - l4rad)) +
                                                  -0.0000167 * cos(twol4rad - psi - w4rad) +
                                                   0.0000167 * cos(psi - w4rad) +
                                                  -0.0000155 * cos(2.0 * (l4rad - PI - G)) +
                                                   0.0000142 * cos(2.0 * (l4rad - psi)) +
                                                   0.0000105 * cos(l1rad - l4rad) +
                                                   0.0000092 * cos(l2rad - l4rad) +
                                                  -0.0000089 * cos(l4rad - PI - G) +
                                                  -0.0000062 * cos(l4rad + pi4 - twoPI - threeG) +
                                                   0.0000048 * cos(2.0 * (l4rad - w4rad))))

        // Precession from Epoch B1950 to date
        let T0 = (JD - 2433282.423) / 36525.0
        let P = SphericalTrigonometry.degreesToRadians((1.3966626 * T0) + (0.0003088 * T0 * T0))

        L1 += P
        details.Satellite1.TropicalLongitude = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(L1))
        L2 += P
        details.Satellite2.TropicalLongitude = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(L2))
        L3 += P
        details.Satellite3.TropicalLongitude = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(L3))
        L4 += P
        details.Satellite4.TropicalLongitude = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(L4))
        psi += P

        // Inclination of Jupiter's axis of rotation on orbital plane
        let TJup = (JD - 2415020.5) / 36525.0
        let I = 3.120262 + (0.0006 * TJup)
        let Irad = SphericalTrigonometry.degreesToRadians(I)

        let X1 = details.Satellite1.r * cos(L1 - psi) * cos(B1)
        let X2 = details.Satellite2.r * cos(L2 - psi) * cos(B2)
        let X3 = details.Satellite3.r * cos(L3 - psi) * cos(B3)
        let X4 = details.Satellite4.r * cos(L4 - psi) * cos(B4)
        let X5 = 0.0

        let Y1 = details.Satellite1.r * sin(L1 - psi) * cos(B1)
        let Y2 = details.Satellite2.r * sin(L2 - psi) * cos(B2)
        let Y3 = details.Satellite3.r * sin(L3 - psi) * cos(B3)
        let Y4 = details.Satellite4.r * sin(L4 - psi) * cos(B4)
        let Y5 = 0.0

        let Z1 = details.Satellite1.r * sin(B1)
        let Z2 = details.Satellite2.r * sin(B2)
        let Z3 = details.Satellite3.r * sin(B3)
        let Z4 = details.Satellite4.r * sin(B4)
        let Z5 = 1.0

        // Rotations
        let omega = SphericalTrigonometry.degreesToRadians(CAAElementsPlanetaryOrbit.JupiterLongitudeAscendingNode(JD))
        let iInc = SphericalTrigonometry.degreesToRadians(CAAElementsPlanetaryOrbit.JupiterInclination(JD))

        let rot5 = Rotations(X5, Y5, Z5, Irad, psi, iInc, omega, lambda0, beta0)
        let D = atan2(rot5.A6, rot5.C6)
        let cosD = cos(D)
        let sinD = sin(D)

        let rot1 = Rotations(X1, Y1, Z1, Irad, psi, iInc, omega, lambda0, beta0)
        details.Satellite1.TrueRectangularCoordinates.X = (rot1.A6 * cosD) - (rot1.C6 * sinD)
        details.Satellite1.TrueRectangularCoordinates.Y = (rot1.A6 * sinD) + (rot1.C6 * cosD)
        details.Satellite1.TrueRectangularCoordinates.Z = rot1.B6

        let rot2 = Rotations(X2, Y2, Z2, Irad, psi, iInc, omega, lambda0, beta0)
        details.Satellite2.TrueRectangularCoordinates.X = (rot2.A6 * cosD) - (rot2.C6 * sinD)
        details.Satellite2.TrueRectangularCoordinates.Y = (rot2.A6 * sinD) + (rot2.C6 * cosD)
        details.Satellite2.TrueRectangularCoordinates.Z = rot2.B6

        let rot3 = Rotations(X3, Y3, Z3, Irad, psi, iInc, omega, lambda0, beta0)
        details.Satellite3.TrueRectangularCoordinates.X = (rot3.A6 * cosD) - (rot3.C6 * sinD)
        details.Satellite3.TrueRectangularCoordinates.Y = (rot3.A6 * sinD) + (rot3.C6 * cosD)
        details.Satellite3.TrueRectangularCoordinates.Z = rot3.B6

        let rot4 = Rotations(X4, Y4, Z4, Irad, psi, iInc, omega, lambda0, beta0)
        details.Satellite4.TrueRectangularCoordinates.X = (rot4.A6 * cosD) - (rot4.C6 * sinD)
        details.Satellite4.TrueRectangularCoordinates.Y = (rot4.A6 * sinD) + (rot4.C6 * cosD)
        details.Satellite4.TrueRectangularCoordinates.Z = rot4.B6

        // Differential light-time correction
        let r1Term = details.Satellite1.TrueRectangularCoordinates.X / details.Satellite1.r
        details.Satellite1.ApparentRectangularCoordinates.X = details.Satellite1.TrueRectangularCoordinates.X + abs(details.Satellite1.TrueRectangularCoordinates.Z) / 17295.0 * sqrt(max(0.0, 1.0 - r1Term * r1Term))
        details.Satellite1.ApparentRectangularCoordinates.Y = details.Satellite1.TrueRectangularCoordinates.Y
        details.Satellite1.ApparentRectangularCoordinates.Z = details.Satellite1.TrueRectangularCoordinates.Z

        let r2Term = details.Satellite2.TrueRectangularCoordinates.X / details.Satellite2.r
        details.Satellite2.ApparentRectangularCoordinates.X = details.Satellite2.TrueRectangularCoordinates.X + abs(details.Satellite2.TrueRectangularCoordinates.Z) / 21819.0 * sqrt(max(0.0, 1.0 - r2Term * r2Term))
        details.Satellite2.ApparentRectangularCoordinates.Y = details.Satellite2.TrueRectangularCoordinates.Y
        details.Satellite2.ApparentRectangularCoordinates.Z = details.Satellite2.TrueRectangularCoordinates.Z

        let r3Term = details.Satellite3.TrueRectangularCoordinates.X / details.Satellite3.r
        details.Satellite3.ApparentRectangularCoordinates.X = details.Satellite3.TrueRectangularCoordinates.X + abs(details.Satellite3.TrueRectangularCoordinates.Z) / 27558.0 * sqrt(max(0.0, 1.0 - r3Term * r3Term))
        details.Satellite3.ApparentRectangularCoordinates.Y = details.Satellite3.TrueRectangularCoordinates.Y
        details.Satellite3.ApparentRectangularCoordinates.Z = details.Satellite3.TrueRectangularCoordinates.Z

        let r4Term = details.Satellite4.TrueRectangularCoordinates.X / details.Satellite4.r
        details.Satellite4.ApparentRectangularCoordinates.X = details.Satellite4.TrueRectangularCoordinates.X + abs(details.Satellite4.TrueRectangularCoordinates.Z) / 36548.0 * sqrt(max(0.0, 1.0 - r4Term * r4Term))
        details.Satellite4.ApparentRectangularCoordinates.Y = details.Satellite4.TrueRectangularCoordinates.Y
        details.Satellite4.ApparentRectangularCoordinates.Z = details.Satellite4.TrueRectangularCoordinates.Z

        // Perspective effect correction
        var W = DELTA / (DELTA + details.Satellite1.TrueRectangularCoordinates.Z / 2095.0)
        details.Satellite1.ApparentRectangularCoordinates.X *= W
        details.Satellite1.ApparentRectangularCoordinates.Y *= W

        W = DELTA / (DELTA + details.Satellite2.TrueRectangularCoordinates.Z / 2095.0)
        details.Satellite2.ApparentRectangularCoordinates.X *= W
        details.Satellite2.ApparentRectangularCoordinates.Y *= W

        W = DELTA / (DELTA + details.Satellite3.TrueRectangularCoordinates.Z / 2095.0)
        details.Satellite3.ApparentRectangularCoordinates.X *= W
        details.Satellite3.ApparentRectangularCoordinates.Y *= W

        W = DELTA / (DELTA + details.Satellite4.TrueRectangularCoordinates.Z / 2095.0)
        details.Satellite4.ApparentRectangularCoordinates.X *= W
        details.Satellite4.ApparentRectangularCoordinates.Y *= W

        return details
    }

    public static func Calculate(_ JD: Double, _ bHighPrecision: Bool) -> CAAGalileanMoonsDetails {
        let sunlong = CAASun.GeometricEclipticLongitude(JD, bHighPrecision)
        let sunlongrad = SphericalTrigonometry.degreesToRadians(sunlong)
        let beta = CAASun.GeometricEclipticLatitude(JD, bHighPrecision)
        let betarad = SphericalTrigonometry.degreesToRadians(beta)
        let R = CAAEarth.RadiusVector(JD, bHighPrecision)

        var DELTA = 5.0
        var PreviousEarthLightTravelTime = 0.0
        var EarthLightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)
        var JD1 = JD - EarthLightTravelTime
        var bIterate = true
        var x = 0.0
        var y = 0.0
        var z = 0.0

        while bIterate {
            let l = CAAJupiter.EclipticLongitude(JD1, bHighPrecision)
            let lrad = SphericalTrigonometry.degreesToRadians(l)
            let b = CAAJupiter.EclipticLatitude(JD1, bHighPrecision)
            let brad = SphericalTrigonometry.degreesToRadians(b)
            let cosbrad = cos(brad)
            let r = CAAJupiter.RadiusVector(JD1, bHighPrecision)

            x = (r * cosbrad * cos(lrad)) + (R * cos(sunlongrad))
            y = (r * cosbrad * sin(lrad)) + (R * sin(sunlongrad))
            z = (r * sin(brad)) + (R * sin(betarad))
            DELTA = sqrt(x * x + y * y + z * z)
            EarthLightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)

            bIterate = (abs(EarthLightTravelTime - PreviousEarthLightTravelTime) > 2e-6)
            if bIterate {
                JD1 = JD - EarthLightTravelTime
                PreviousEarthLightTravelTime = EarthLightTravelTime
            }
        }

        var details1 = CalculateHelper(JD, sunlongrad, betarad, R, bHighPrecision)
        FillInPhenomenaDetails(&details1.Satellite1)
        FillInPhenomenaDetails(&details1.Satellite2)
        FillInPhenomenaDetails(&details1.Satellite3)
        FillInPhenomenaDetails(&details1.Satellite4)

        JD1 = JD - EarthLightTravelTime
        let l = CAAJupiter.EclipticLongitude(JD1, bHighPrecision)
        let lrad = SphericalTrigonometry.degreesToRadians(l)
        let b = CAAJupiter.EclipticLatitude(JD1, bHighPrecision)
        let brad = SphericalTrigonometry.degreesToRadians(b)
        let r = CAAJupiter.RadiusVector(JD1, bHighPrecision)
        let cosbrad = cos(brad)
        x = r * cosbrad * cos(lrad)
        y = r * cosbrad * sin(lrad)
        z = r * sin(brad)
        DELTA = sqrt((x * x) + (y * y) + (z * z))
        let SunLightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)

        var details2 = CalculateHelper(JD + SunLightTravelTime - EarthLightTravelTime, sunlongrad, betarad, 0, bHighPrecision)
        FillInPhenomenaDetails(&details2.Satellite1)
        FillInPhenomenaDetails(&details2.Satellite2)
        FillInPhenomenaDetails(&details2.Satellite3)
        FillInPhenomenaDetails(&details2.Satellite4)

        details1.Satellite1.bInEclipse = details2.Satellite1.bInOccultation
        details1.Satellite2.bInEclipse = details2.Satellite2.bInOccultation
        details1.Satellite3.bInEclipse = details2.Satellite3.bInOccultation
        details1.Satellite4.bInEclipse = details2.Satellite4.bInOccultation
        details1.Satellite1.bInShadowTransit = details2.Satellite1.bInTransit
        details1.Satellite2.bInShadowTransit = details2.Satellite2.bInTransit
        details1.Satellite3.bInShadowTransit = details2.Satellite3.bInTransit
        details1.Satellite4.bInShadowTransit = details2.Satellite4.bInTransit

        return details1
    }
}

// MARK: - Saturnian Moons (CAASaturnMoons)

public enum CAASaturnMoons: Sendable {
    private static func HelperSubroutine(_ e: Double, _ lambdadash: Double, _ p: Double, _ a: Double, _ omega: Double, _ i: Double, _ c1: Double, _ s1: Double) -> (r: Double, lambda: Double, gamma: Double, w: Double) {
        let e2 = e * e
        let e3 = e2 * e
        let e4 = e3 * e
        let e5 = e4 * e
        let M = SphericalTrigonometry.degreesToRadians(lambdadash - p)

        let Crad = ((2.0 * e) - (0.25 * e3) + (0.0520833333 * e5)) * sin(M) +
                   ((1.25 * e2) - (0.458333333 * e4)) * sin(2.0 * M) +
                   ((1.083333333 * e3) - (0.671875 * e5)) * sin(3.0 * M) +
                   (1.072917 * e4 * sin(4.0 * M)) +
                   (1.142708 * e5 * sin(5.0 * M))
        let C = SphericalTrigonometry.radiansToDegrees(Crad)
        let r = a * (1.0 - e2) / (1.0 + (e * cos(M + Crad)))
        let g = omega - 168.8112
        let grad = SphericalTrigonometry.degreesToRadians(g)
        let cosgrad = cos(grad)
        let singrad = sin(grad)
        let irad = SphericalTrigonometry.degreesToRadians(i)
        let sinirad = sin(irad)
        let cosirad = cos(irad)
        let a1 = sinirad * singrad
        let a2 = (c1 * sinirad * cosgrad) - (s1 * cosirad)
        let gamma = SphericalTrigonometry.radiansToDegrees(asin(sqrt((a1 * a1) + (a2 * a2))))
        let urad = atan2(a1, a2)
        let u = SphericalTrigonometry.radiansToDegrees(urad)
        let w = SphericalTrigonometry.mapTo0To360Range(168.8112 + u)
        let h = (c1 * sinirad) - (s1 * cosirad * cosgrad)
        let psirad = atan2(s1 * singrad, h)
        let psi = SphericalTrigonometry.radiansToDegrees(psirad)
        let lambda = lambdadash + C + u - g - psi

        return (r, lambda, gamma, w)
    }

    private static func Rotations(_ X: Double, _ Y: Double, _ Z: Double, _ c1: Double, _ s1: Double, _ c2: Double, _ s2: Double, _ lambda0: Double, _ beta0: Double) -> (A4: Double, B4: Double, C4: Double) {
        let A1 = X
        let B1 = (c1 * Y) - (s1 * Z)
        let C1 = (s1 * Y) + (c1 * Z)

        let A2 = (c2 * A1) - (s2 * B1)
        let B2 = (s2 * A1) + (c2 * B1)
        let C2 = C1

        let sinlambda0 = sin(lambda0)
        let coslambda0 = cos(lambda0)
        let A3 = (A2 * sinlambda0) - (B2 * coslambda0)
        let B3 = (A2 * coslambda0) + (B2 * sinlambda0)
        let C3 = C2

        let cosbeta0 = cos(beta0)
        let sinbeta0 = sin(beta0)
        let A4 = A3
        let B4 = (B3 * cosbeta0) + (C3 * sinbeta0)
        let C4 = (C3 * cosbeta0) - (B3 * sinbeta0)

        return (A4, B4, C4)
    }

    private static func FillInPhenomenaDetails(_ detail: inout CAASaturnMoonDetail) {
        let Y1 = 1.108601 * detail.ApparentRectangularCoordinates.Y
        let r = (Y1 * Y1) + (detail.ApparentRectangularCoordinates.X * detail.ApparentRectangularCoordinates.X)

        if r < 1.0 {
            if detail.ApparentRectangularCoordinates.Z < 0 {
                detail.bInTransit = true
                detail.bInOccultation = false
            } else {
                detail.bInTransit = false
                detail.bInOccultation = true
            }
        } else {
            detail.bInTransit = false
            detail.bInOccultation = false
        }
    }

    private static func CalculateHelper(_ JD: Double, _ sunlongrad: Double, _ betarad: Double, _ R: Double, _ bHighPrecision: Bool) -> CAASaturnMoonsDetails {
        var details = CAASaturnMoonsDetails()

        var DELTA = 9.0
        var PreviousLightTravelTime = 0.0
        var LightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)
        var x = 0.0
        var y = 0.0
        var z = 0.0
        var JD1 = JD - LightTravelTime
        var bIterate = true

        while bIterate {
            let l = CAASaturn.EclipticLongitude(JD1, bHighPrecision)
            let lrad = SphericalTrigonometry.degreesToRadians(l)
            let b = CAASaturn.EclipticLatitude(JD1, bHighPrecision)
            let brad = SphericalTrigonometry.degreesToRadians(b)
            let cosbrad = cos(brad)
            let r = CAASaturn.RadiusVector(JD1, bHighPrecision)

            x = (r * cosbrad * cos(lrad)) + (R * cos(sunlongrad))
            y = (r * cosbrad * sin(lrad)) + (R * sin(sunlongrad))
            z = (r * sin(brad)) + (R * sin(betarad))
            DELTA = sqrt((x * x) + (y * y) + (z * z))
            LightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)

            bIterate = (abs(LightTravelTime - PreviousLightTravelTime) > 2e-6)
            if bIterate {
                JD1 = JD - LightTravelTime
                PreviousLightTravelTime = LightTravelTime
            }
        }

        var lambda0 = SphericalTrigonometry.radiansToDegrees(atan2(y, x))
        var beta0 = SphericalTrigonometry.radiansToDegrees(atan(z / sqrt((x * x) + (y * y))))

        let Saturn1950 = CAAPrecession.PrecessEcliptic(lambda0, beta0, JD, 2433282.4235)
        lambda0 = Saturn1950.X
        let lambda0rad = SphericalTrigonometry.degreesToRadians(lambda0)
        beta0 = Saturn1950.Y
        let beta0rad = SphericalTrigonometry.degreesToRadians(beta0)

        let JDE = JD - LightTravelTime
        let t1 = JDE - 2411093.0
        let t2 = t1 / 365.25
        let t3 = ((JDE - 2433282.423) / 365.25) + 1950.0
        let t4 = JDE - 2411368.0
        let t5 = t4 / 365.25
        let t6 = JDE - 2415020.0
        let t7 = t6 / 36525.0
        let t8 = t6 / 365.25
        let t9 = (JDE - 2442000.5) / 365.25
        let t10 = JDE - 2409786.0
        let t11 = t10 / 36525.0
        let t112 = t11 * t11
        let t113 = t112 * t11

        let W0 = SphericalTrigonometry.mapTo0To360Range(5.095 * (t3 - 1866.39))
        let W0rad = SphericalTrigonometry.degreesToRadians(W0)
        let W1 = SphericalTrigonometry.mapTo0To360Range(74.4 + (32.39 * t2))
        let W1rad = SphericalTrigonometry.degreesToRadians(W1)
        let W2 = SphericalTrigonometry.mapTo0To360Range(134.3 + (92.62 * t2))
        let W2rad = SphericalTrigonometry.degreesToRadians(W2)
        let W3 = SphericalTrigonometry.mapTo0To360Range(42.0 - (0.5118 * t5))
        let W3rad = SphericalTrigonometry.degreesToRadians(W3)
        let W4 = SphericalTrigonometry.mapTo0To360Range(276.59 + (0.5118 * t5))
        let W4rad = SphericalTrigonometry.degreesToRadians(W4)
        let W5 = SphericalTrigonometry.mapTo0To360Range(267.2635 + (1222.1136 * t7))
        let W5rad = SphericalTrigonometry.degreesToRadians(W5)
        let W6 = SphericalTrigonometry.mapTo0To360Range(175.4762 + (1221.5515 * t7))
        let W6rad = SphericalTrigonometry.degreesToRadians(W6)
        let W7 = SphericalTrigonometry.mapTo0To360Range(2.4891 + (0.002435 * t7))
        let W7rad = SphericalTrigonometry.degreesToRadians(W7)
        let sinW7rad = sin(W7rad)
        let W8 = SphericalTrigonometry.mapTo0To360Range(113.35 - (0.2597 * t7))
        let W8rad = SphericalTrigonometry.degreesToRadians(W8)

        let s1 = sin(SphericalTrigonometry.degreesToRadians(28.0817))
        let s2 = sin(SphericalTrigonometry.degreesToRadians(168.8112))
        let c1 = cos(SphericalTrigonometry.degreesToRadians(28.0817))
        let c2 = cos(SphericalTrigonometry.degreesToRadians(168.8112))
        let e1 = 0.05589 - (0.000346 * t7)

        // Satellite 1
        var L = SphericalTrigonometry.mapTo0To360Range(127.64 + (381.994497 * t1) - (43.57 * sin(W0rad)) - (0.720 * sin(3.0 * W0rad)) - (0.02144 * sin(5.0 * W0rad)))
        var p = 106.1 + (365.549 * t2)
        var M = L - p
        var Mrad = SphericalTrigonometry.degreesToRadians(M)
        var C = (2.18287 * sin(Mrad)) + (0.025988 * sin(2.0 * Mrad)) + (0.00043 * sin(3.0 * Mrad))
        var Crad = SphericalTrigonometry.degreesToRadians(C)
        let lambda1 = SphericalTrigonometry.mapTo0To360Range(L + C)
        let r1 = 3.06879 / (1.0 + (0.01905 * cos(Mrad + Crad)))
        let gamma1 = 1.563
        let omega1 = SphericalTrigonometry.mapTo0To360Range(54.5 - (365.072 * t2))

        // Satellite 2
        L = SphericalTrigonometry.mapTo0To360Range(200.317 + (262.7319002 * t1) + (0.25667 * sin(W1rad)) + (0.20883 * sin(W2rad)))
        p = 309.107 + (123.44121 * t2)
        M = L - p
        Mrad = SphericalTrigonometry.degreesToRadians(M)
        C = (0.55577 * sin(Mrad)) + (0.00168 * sin(2.0 * Mrad))
        Crad = SphericalTrigonometry.degreesToRadians(C)
        let lambda2 = SphericalTrigonometry.mapTo0To360Range(L + C)
        let r2 = 3.94118 / (1.0 + (0.00485 * cos(Mrad + Crad)))
        let gamma2 = 0.0262
        let omega2 = SphericalTrigonometry.mapTo0To360Range(348.0 - (151.95 * t2))

        // Satellite 3
        let lambda3 = SphericalTrigonometry.mapTo0To360Range(285.306 + (190.69791226 * t1) + (2.063 * sin(W0rad)) + (0.03409 * sin(3.0 * W0rad)) + (0.001015 * sin(5.0 * W0rad)))
        let r3 = 4.880998
        let gamma3 = 1.0976
        let omega3 = SphericalTrigonometry.mapTo0To360Range(111.33 - (72.2441 * t2))

        // Satellite 4
        L = SphericalTrigonometry.mapTo0To360Range(254.712 + (131.53493193 * t1) - (0.0215 * sin(W1rad)) - (0.01733 * sin(W2rad)))
        p = 174.8 + (30.820 * t2)
        M = L - p
        Mrad = SphericalTrigonometry.degreesToRadians(M)
        C = (0.24717 * sin(Mrad)) + (0.00033 * sin(2.0 * Mrad))
        Crad = SphericalTrigonometry.degreesToRadians(C)
        let lambda4 = SphericalTrigonometry.mapTo0To360Range(L + C)
        let r4 = 6.24871 / (1.0 + (0.002157 * cos(Mrad + Crad)))
        let gamma4 = 0.0139
        let omega4 = SphericalTrigonometry.mapTo0To360Range(232.0 - (30.27 * t2))

        // Satellite 5
        let pdash = 342.7 + (10.057 * t2)
        let pdashrad = SphericalTrigonometry.degreesToRadians(pdash)
        var a1 = (0.000265 * sin(pdashrad)) + (0.001 * sin(W4rad))
        var a2 = (0.000265 * cos(pdashrad)) + (0.001 * cos(W4rad))
        var e = sqrt((a1 * a1) + (a2 * a2))
        p = SphericalTrigonometry.radiansToDegrees(atan2(a1, a2))
        let N = 345.0 - (10.057 * t2)
        let Nrad = SphericalTrigonometry.degreesToRadians(N)
        var lambdadash = SphericalTrigonometry.mapTo0To360Range(359.244 + (79.69004720 * t1) + (0.086754 * sin(Nrad)))
        var iInc = 28.0362 + (0.346898 * cos(Nrad)) + (0.01930 * cos(W3rad))
        var omega = 168.8034 + (0.736936 * sin(Nrad)) + (0.041 * sin(W3rad))
        var a = 8.725924
        let res5 = HelperSubroutine(e, lambdadash, p, a, omega, iInc, c1, s1)
        let r5 = res5.r
        let lambda5 = res5.lambda
        let gamma5 = res5.gamma
        let omega5 = res5.w

        // Satellite 6
        L = 261.1582 + (22.57697855 * t4) + (0.074025 * sin(W3rad))
        let idash = 27.45141 + (0.295999 * cos(W3rad))
        let idashrad = SphericalTrigonometry.degreesToRadians(idash)
        let sinidashrad = sin(idashrad)
        let cosidashrad = cos(idashrad)
        let omegadash = 168.66925 + (0.628808 * sin(W3rad))
        let omegadashrad = SphericalTrigonometry.degreesToRadians(omegadash)
        a1 = sinW7rad * sin(omegadashrad - W8rad)
        a2 = (cos(W7rad) * sinidashrad) - (sinW7rad * cosidashrad * cos(omegadashrad - W8rad))
        let g0 = SphericalTrigonometry.degreesToRadians(102.8623)
        var psi = atan2(a1, a2)
        if a2 < 0 {
            psi += .pi
        }
        let psideg = SphericalTrigonometry.radiansToDegrees(psi)
        let s = sqrt((a1 * a1) + (a2 * a2))
        var g = W4 - omegadash - psideg
        var w_ = 0.0
        for _ in 0..<3 {
            w_ = W4 + 0.37515 * (sin(2.0 * SphericalTrigonometry.degreesToRadians(g)) - sin(2.0 * g0))
            g = w_ - omegadash - psideg
        }
        let grad = SphericalTrigonometry.degreesToRadians(g)
        var edash = 0.029092 + (0.00019048 * (cos(2.0 * grad) - cos(2.0 * g0)))
        let q = SphericalTrigonometry.degreesToRadians(2.0 * (W5 - w_))
        let b1 = sinidashrad * sin(omegadashrad - W8rad)
        let b2 = (cos(W7rad) * sinidashrad * cos(omegadashrad - W8rad)) - (sinW7rad * cosidashrad)
        let atanb1b2 = atan2(b1, b2)
        var theta = atanb1b2 + W8rad
        e = edash + (0.002778797 * edash * cos(q))
        p = w_ + (0.159215 * sin(q))
        var u = (2.0 * W5rad) - (2.0 * theta) + psi
        let h = (0.9375 * edash * edash * sin(q)) + (0.1875 * s * s * sin(2.0 * (W5rad - theta)))
        lambdadash = SphericalTrigonometry.mapTo0To360Range(L - 0.254744 * ((e1 * sin(W6rad)) + (0.75 * e1 * e1 * sin(2.0 * W6rad)) + h))
        iInc = idash + (0.031843 * s * cos(u))
        omega = omegadash + ((0.031843 * s * sin(u)) / sinidashrad)
        a = 20.216193
        let res6 = HelperSubroutine(e, lambdadash, p, a, omega, iInc, c1, s1)
        let r6 = res6.r
        let lambda6 = res6.lambda
        let gamma6 = res6.gamma
        let omega6 = res6.w

        // Satellite 7
        let eta = 92.39 + (0.5621071 * t6)
        let etarad = SphericalTrigonometry.degreesToRadians(eta)
        let zeta = 148.19 - (19.18 * t8)
        let zetarad = SphericalTrigonometry.degreesToRadians(zeta)
        theta = SphericalTrigonometry.degreesToRadians(184.8 - (35.41 * t9))
        let thetadash = theta - SphericalTrigonometry.degreesToRadians(7.5)
        let asAng = SphericalTrigonometry.degreesToRadians(176.0 + (12.22 * t8))
        let bsAng = SphericalTrigonometry.degreesToRadians(8.0 + (24.44 * t8))
        let csAng = bsAng + SphericalTrigonometry.degreesToRadians(5.0)
        w_ = 69.898 - (18.67088 * t8)
        let phi = 2.0 * (w_ - W5)
        let phirad = SphericalTrigonometry.degreesToRadians(phi)
        let chi = 94.9 - (2.292 * t8)
        let chirad = SphericalTrigonometry.degreesToRadians(chi)
        a = 24.50601 - (0.08686 * cos(etarad)) - (0.00166 * cos(zetarad + etarad)) + (0.00175 * cos(zetarad - etarad))
        e = 0.103458 - (0.004099 * cos(etarad)) - (0.000167 * cos(zetarad + etarad)) + (0.000235 * cos(zetarad - etarad)) +
            (0.02303 * cos(zetarad)) - (0.00212 * cos(2.0 * zetarad)) + (0.000151 * cos(3.0 * zetarad)) + (0.00013 * cos(phirad))
        p = w_ + (0.15648 * sin(chirad)) - (0.4457 * sin(etarad)) - (0.2657 * sin(zetarad + etarad)) -
            (0.3573 * sin(zetarad - etarad)) - (12.872 * sin(zetarad)) + (1.668 * sin(2.0 * zetarad)) -
            (0.2419 * sin(3.0 * zetarad)) - (0.07 * sin(phirad))
        lambdadash = SphericalTrigonometry.mapTo0To360Range(177.047 + (16.91993829 * t6) + (0.15648 * sin(chirad)) + (9.142 * sin(etarad)) +
                     (0.007 * sin(2.0 * etarad)) - (0.014 * sin(3.0 * etarad)) + (0.2275 * sin(zetarad + etarad)) +
                     (0.2112 * sin(zetarad - etarad)) - (0.26 * sin(zetarad)) - (0.0098 * sin(2.0 * zetarad)) -
                     (0.013 * sin(asAng)) + (0.017 * sin(bsAng)) - (0.0303 * sin(phirad)))
        iInc = 27.3347 + (0.643486 * cos(chirad)) + (0.315 * cos(W3rad)) + (0.018 * cos(theta)) - (0.018 * cos(csAng))
        omega = 168.6812 + (1.40136 * cos(chirad)) + (0.68599 * sin(W3rad)) - (0.0392 * sin(csAng)) + (0.0366 * sin(thetadash))
        let res7 = HelperSubroutine(e, lambdadash, p, a, omega, iInc, c1, s1)
        let r7 = res7.r
        let lambda7 = res7.lambda
        let gamma7 = res7.gamma
        let omega7 = res7.w

        // Satellite 8
        L = SphericalTrigonometry.mapTo0To360Range(261.1582 + (22.57697855 * t4))
        let w_dash = 91.796 + (0.562 * t7)
        psi = 4.367 - (0.195 * t7)
        let psirad = SphericalTrigonometry.degreesToRadians(psi)
        theta = 146.819 - (3.198 * t7)
        let phiSat8 = 60.470 + (1.521 * t7)
        let phiradSat8 = SphericalTrigonometry.degreesToRadians(phiSat8)
        let PHI = 205.055 - (2.091 * t7)
        edash = 0.028298 + (0.001156 * t11)
        let w_0 = 352.91 + (11.71 * t11)
        let mu = SphericalTrigonometry.mapTo0To360Range(76.3852 + (4.53795125 * t10))
        let idashSat8 = 18.4602 - (0.9518 * t11) - (0.072 * t112) + (0.0054 * t113)
        let idashradSat8 = SphericalTrigonometry.degreesToRadians(idashSat8)
        let omegadashSat8 = 143.198 - (3.919 * t11) + (0.116 * t112) + (0.008 * t113)
        let lSat8 = SphericalTrigonometry.degreesToRadians(mu - w_0)
        g = SphericalTrigonometry.degreesToRadians(w_0 - omegadashSat8 - psi)
        let g1 = SphericalTrigonometry.degreesToRadians(w_0 - omegadashSat8 - phiSat8)
        let ls = SphericalTrigonometry.degreesToRadians(W5 - w_dash)
        let gs = SphericalTrigonometry.degreesToRadians(w_dash - theta)
        let lt = SphericalTrigonometry.degreesToRadians(L - W4)
        let gt = SphericalTrigonometry.degreesToRadians(W4 - PHI)
        let u1 = 2.0 * (lSat8 + g - ls - gs)
        let u2 = lSat8 + g1 - lt - gt
        let u3 = lSat8 + 2.0 * (g - ls - gs)
        let u4 = lt + gt - g1
        let u5 = 2.0 * (ls + gs)
        a = 58.935028 + (0.004638 * cos(u1)) + (0.058222 * cos(u2))
        e = edash - (0.0014097 * cos(g1 - gt)) + (0.0003733 * cos(u5 - (2.0 * g))) +
            (0.0001180 * cos(u3)) + (0.0002408 * cos(lSat8)) +
            (0.0002849 * cos(lSat8 + u2)) + (0.0006190 * cos(u4))
        let wVal = (0.08077 * sin(g1 - gt)) + (0.02139 * sin(u5 - (2.0 * g))) - (0.00676 * sin(u3)) +
                   (0.01380 * sin(lSat8)) + (0.01632 * sin(lSat8 + u2)) + (0.03547 * sin(u4))
        p = w_0 + (wVal / edash)
        lambdadash = mu - (0.04299 * sin(u2)) - (0.00789 * sin(u1)) - (0.06312 * sin(ls)) -
                     (0.00295 * sin(2.0 * ls)) - (0.02231 * sin(u5)) + (0.00650 * sin(u5 + psirad))
        iInc = idashSat8 + (0.04204 * cos(u5 + psirad)) + (0.00235 * cos(lSat8 + g1 + lt + gt + phiradSat8)) +
               (0.00360 * cos(u2 + phiradSat8))
        let wdash = (0.04204 * sin(u5 + psirad)) + (0.00235 * sin(lSat8 + g1 + lt + gt + phiradSat8)) +
                    (0.00358 * sin(u2 + phiradSat8))
        omega = omegadashSat8 + (wdash / sin(idashradSat8))
        let res8 = HelperSubroutine(e, lambdadash, p, a, omega, iInc, c1, s1)
        let r8 = res8.r
        let lambda8 = res8.lambda
        let gamma8 = res8.gamma
        let omega8 = res8.w

        u = SphericalTrigonometry.degreesToRadians(lambda1 - omega1)
        var cosu = cos(u)
        var sinu = sin(u)
        var wAngle = SphericalTrigonometry.degreesToRadians(omega1 - 168.8112)
        var sinw = sin(wAngle)
        var cosw = cos(wAngle)
        let gamma1rad = SphericalTrigonometry.degreesToRadians(gamma1)
        let cosgamma1rad = cos(gamma1rad)
        let X1 = r1 * ((cosu * cosw) - (sinu * cosgamma1rad * sinw))
        let Y1 = r1 * ((sinu * cosw * cosgamma1rad) + (cosu * sinw))
        let Z1 = r1 * sinu * sin(gamma1rad)

        u = SphericalTrigonometry.degreesToRadians(lambda2 - omega2)
        cosu = cos(u)
        sinu = sin(u)
        wAngle = SphericalTrigonometry.degreesToRadians(omega2 - 168.8112)
        sinw = sin(wAngle)
        cosw = cos(wAngle)
        let gamma2rad = SphericalTrigonometry.degreesToRadians(gamma2)
        let cosgamma2rad = cos(gamma2rad)
        let X2 = r2 * ((cosu * cosw) - (sinu * cosgamma2rad * sinw))
        let Y2 = r2 * ((sinu * cosw * cosgamma2rad) + (cosu * sinw))
        let Z2 = r2 * sinu * sin(gamma2rad)

        u = SphericalTrigonometry.degreesToRadians(lambda3 - omega3)
        cosu = cos(u)
        sinu = sin(u)
        wAngle = SphericalTrigonometry.degreesToRadians(omega3 - 168.8112)
        sinw = sin(wAngle)
        cosw = cos(wAngle)
        let gamma3rad = SphericalTrigonometry.degreesToRadians(gamma3)
        let cosgamma3rad = cos(gamma3rad)
        let X3 = r3 * ((cosu * cosw) - (sinu * cosgamma3rad * sinw))
        let Y3 = r3 * ((sinu * cosw * cosgamma3rad) + (cosu * sinw))
        let Z3 = r3 * sinu * sin(gamma3rad)

        u = SphericalTrigonometry.degreesToRadians(lambda4 - omega4)
        cosu = cos(u)
        sinu = sin(u)
        wAngle = SphericalTrigonometry.degreesToRadians(omega4 - 168.8112)
        sinw = sin(wAngle)
        cosw = cos(wAngle)
        let gamma4rad = SphericalTrigonometry.degreesToRadians(gamma4)
        let cosgamma4rad = cos(gamma4rad)
        let X4 = r4 * ((cosu * cosw) - (sinu * cosgamma4rad * sinw))
        let Y4 = r4 * ((sinu * cosw * cosgamma4rad) + (cosu * sinw))
        let Z4 = r4 * sinu * sin(gamma4rad)

        u = SphericalTrigonometry.degreesToRadians(lambda5 - omega5)
        cosu = cos(u)
        sinu = sin(u)
        wAngle = SphericalTrigonometry.degreesToRadians(omega5 - 168.8112)
        sinw = sin(wAngle)
        cosw = cos(wAngle)
        let gamma5rad = SphericalTrigonometry.degreesToRadians(gamma5)
        let cosgamma5rad = cos(gamma5rad)
        let X5 = r5 * ((cosu * cosw) - (sinu * cosgamma5rad * sinw))
        let Y5 = r5 * ((sinu * cosw * cosgamma5rad) + (cosu * sinw))
        let Z5 = r5 * sinu * sin(gamma5rad)

        u = SphericalTrigonometry.degreesToRadians(lambda6 - omega6)
        cosu = cos(u)
        sinu = sin(u)
        wAngle = SphericalTrigonometry.degreesToRadians(omega6 - 168.8112)
        sinw = sin(wAngle)
        cosw = cos(wAngle)
        let gamma6rad = SphericalTrigonometry.degreesToRadians(gamma6)
        let cosgamma6rad = cos(gamma6rad)
        let X6 = r6 * ((cosu * cosw) - (sinu * cosgamma6rad * sinw))
        let Y6 = r6 * ((sinu * cosw * cosgamma6rad) + (cosu * sinw))
        let Z6 = r6 * sinu * sin(gamma6rad)

        u = SphericalTrigonometry.degreesToRadians(lambda7 - omega7)
        cosu = cos(u)
        sinu = sin(u)
        wAngle = SphericalTrigonometry.degreesToRadians(omega7 - 168.8112)
        sinw = sin(wAngle)
        cosw = cos(wAngle)
        let gamma7rad = SphericalTrigonometry.degreesToRadians(gamma7)
        let cosgamma7rad = cos(gamma7rad)
        let X7 = r7 * ((cosu * cosw) - (sinu * cosgamma7rad * sinw))
        let Y7 = r7 * ((sinu * cosw * cosgamma7rad) + (cosu * sinw))
        let Z7 = r7 * sinu * sin(gamma7rad)

        u = SphericalTrigonometry.degreesToRadians(lambda8 - omega8)
        cosu = cos(u)
        sinu = sin(u)
        wAngle = SphericalTrigonometry.degreesToRadians(omega8 - 168.8112)
        sinw = sin(wAngle)
        cosw = cos(wAngle)
        let gamma8rad = SphericalTrigonometry.degreesToRadians(gamma8)
        let cosgamma8rad = cos(gamma8rad)
        let X8 = r8 * ((cosu * cosw) - (sinu * cosgamma8rad * sinw))
        let Y8 = r8 * ((sinu * cosw * cosgamma8rad) + (cosu * sinw))
        let Z8 = r8 * sinu * sin(gamma8rad)

        let X9 = 0.0
        let Y9 = 0.0
        let Z9 = 1.0

        let rot9 = Rotations(X9, Y9, Z9, c1, s1, c2, s2, lambda0rad, beta0rad)
        let D = atan2(rot9.A4, rot9.C4)
        let cosD = cos(D)
        let sinD = sin(D)

        let rot1 = Rotations(X1, Y1, Z1, c1, s1, c2, s2, lambda0rad, beta0rad)
        details.Satellite1.TrueRectangularCoordinates.X = (rot1.A4 * cosD) - (rot1.C4 * sinD)
        details.Satellite1.TrueRectangularCoordinates.Y = (rot1.A4 * sinD) + (rot1.C4 * cosD)
        details.Satellite1.TrueRectangularCoordinates.Z = rot1.B4

        let rot2 = Rotations(X2, Y2, Z2, c1, s1, c2, s2, lambda0rad, beta0rad)
        details.Satellite2.TrueRectangularCoordinates.X = (rot2.A4 * cosD) - (rot2.C4 * sinD)
        details.Satellite2.TrueRectangularCoordinates.Y = (rot2.A4 * sinD) + (rot2.C4 * cosD)
        details.Satellite2.TrueRectangularCoordinates.Z = rot2.B4

        let rot3 = Rotations(X3, Y3, Z3, c1, s1, c2, s2, lambda0rad, beta0rad)
        details.Satellite3.TrueRectangularCoordinates.X = (rot3.A4 * cosD) - (rot3.C4 * sinD)
        details.Satellite3.TrueRectangularCoordinates.Y = (rot3.A4 * sinD) + (rot3.C4 * cosD)
        details.Satellite3.TrueRectangularCoordinates.Z = rot3.B4

        let rot4 = Rotations(X4, Y4, Z4, c1, s1, c2, s2, lambda0rad, beta0rad)
        details.Satellite4.TrueRectangularCoordinates.X = (rot4.A4 * cosD) - (rot4.C4 * sinD)
        details.Satellite4.TrueRectangularCoordinates.Y = (rot4.A4 * sinD) + (rot4.C4 * cosD)
        details.Satellite4.TrueRectangularCoordinates.Z = rot4.B4

        let rot5 = Rotations(X5, Y5, Z5, c1, s1, c2, s2, lambda0rad, beta0rad)
        details.Satellite5.TrueRectangularCoordinates.X = (rot5.A4 * cosD) - (rot5.C4 * sinD)
        details.Satellite5.TrueRectangularCoordinates.Y = (rot5.A4 * sinD) + (rot5.C4 * cosD)
        details.Satellite5.TrueRectangularCoordinates.Z = rot5.B4

        let rot6 = Rotations(X6, Y6, Z6, c1, s1, c2, s2, lambda0rad, beta0rad)
        details.Satellite6.TrueRectangularCoordinates.X = (rot6.A4 * cosD) - (rot6.C4 * sinD)
        details.Satellite6.TrueRectangularCoordinates.Y = (rot6.A4 * sinD) + (rot6.C4 * cosD)
        details.Satellite6.TrueRectangularCoordinates.Z = rot6.B4

        let rot7 = Rotations(X7, Y7, Z7, c1, s1, c2, s2, lambda0rad, beta0rad)
        details.Satellite7.TrueRectangularCoordinates.X = (rot7.A4 * cosD) - (rot7.C4 * sinD)
        details.Satellite7.TrueRectangularCoordinates.Y = (rot7.A4 * sinD) + (rot7.C4 * cosD)
        details.Satellite7.TrueRectangularCoordinates.Z = rot7.B4

        let rot8 = Rotations(X8, Y8, Z8, c1, s1, c2, s2, lambda0rad, beta0rad)
        details.Satellite8.TrueRectangularCoordinates.X = (rot8.A4 * cosD) - (rot8.C4 * sinD)
        details.Satellite8.TrueRectangularCoordinates.Y = (rot8.A4 * sinD) + (rot8.C4 * cosD)
        details.Satellite8.TrueRectangularCoordinates.Z = rot8.B4

        // Differential light-time correction
        let r1Term = details.Satellite1.TrueRectangularCoordinates.X / r1
        details.Satellite1.ApparentRectangularCoordinates.X = details.Satellite1.TrueRectangularCoordinates.X + abs(details.Satellite1.TrueRectangularCoordinates.Z) / 20947.0 * sqrt(max(0.0, 1.0 - r1Term * r1Term))
        details.Satellite1.ApparentRectangularCoordinates.Y = details.Satellite1.TrueRectangularCoordinates.Y
        details.Satellite1.ApparentRectangularCoordinates.Z = details.Satellite1.TrueRectangularCoordinates.Z

        let r2Term = details.Satellite2.TrueRectangularCoordinates.X / r2
        details.Satellite2.ApparentRectangularCoordinates.X = details.Satellite2.TrueRectangularCoordinates.X + abs(details.Satellite2.TrueRectangularCoordinates.Z) / 23715.0 * sqrt(max(0.0, 1.0 - r2Term * r2Term))
        details.Satellite2.ApparentRectangularCoordinates.Y = details.Satellite2.TrueRectangularCoordinates.Y
        details.Satellite2.ApparentRectangularCoordinates.Z = details.Satellite2.TrueRectangularCoordinates.Z

        let r3Term = details.Satellite3.TrueRectangularCoordinates.X / r3
        details.Satellite3.ApparentRectangularCoordinates.X = details.Satellite3.TrueRectangularCoordinates.X + abs(details.Satellite3.TrueRectangularCoordinates.Z) / 26382.0 * sqrt(max(0.0, 1.0 - r3Term * r3Term))
        details.Satellite3.ApparentRectangularCoordinates.Y = details.Satellite3.TrueRectangularCoordinates.Y
        details.Satellite3.ApparentRectangularCoordinates.Z = details.Satellite3.TrueRectangularCoordinates.Z

        let r4Term = details.Satellite4.TrueRectangularCoordinates.X / r4
        details.Satellite4.ApparentRectangularCoordinates.X = details.Satellite4.TrueRectangularCoordinates.X + abs(details.Satellite4.TrueRectangularCoordinates.Z) / 29876.0 * sqrt(max(0.0, 1.0 - r4Term * r4Term))
        details.Satellite4.ApparentRectangularCoordinates.Y = details.Satellite4.TrueRectangularCoordinates.Y
        details.Satellite4.ApparentRectangularCoordinates.Z = details.Satellite4.TrueRectangularCoordinates.Z

        let r5Term = details.Satellite5.TrueRectangularCoordinates.X / r5
        details.Satellite5.ApparentRectangularCoordinates.X = details.Satellite5.TrueRectangularCoordinates.X + abs(details.Satellite5.TrueRectangularCoordinates.Z) / 35313.0 * sqrt(max(0.0, 1.0 - r5Term * r5Term))
        details.Satellite5.ApparentRectangularCoordinates.Y = details.Satellite5.TrueRectangularCoordinates.Y
        details.Satellite5.ApparentRectangularCoordinates.Z = details.Satellite5.TrueRectangularCoordinates.Z

        let r6Term = details.Satellite6.TrueRectangularCoordinates.X / r6
        details.Satellite6.ApparentRectangularCoordinates.X = details.Satellite6.TrueRectangularCoordinates.X + abs(details.Satellite6.TrueRectangularCoordinates.Z) / 53800.0 * sqrt(max(0.0, 1.0 - r6Term * r6Term))
        details.Satellite6.ApparentRectangularCoordinates.Y = details.Satellite6.TrueRectangularCoordinates.Y
        details.Satellite6.ApparentRectangularCoordinates.Z = details.Satellite6.TrueRectangularCoordinates.Z

        let r7Term = details.Satellite7.TrueRectangularCoordinates.X / r7
        details.Satellite7.ApparentRectangularCoordinates.X = details.Satellite7.TrueRectangularCoordinates.X + abs(details.Satellite7.TrueRectangularCoordinates.Z) / 59222.0 * sqrt(max(0.0, 1.0 - r7Term * r7Term))
        details.Satellite7.ApparentRectangularCoordinates.Y = details.Satellite7.TrueRectangularCoordinates.Y
        details.Satellite7.ApparentRectangularCoordinates.Z = details.Satellite7.TrueRectangularCoordinates.Z

        let r8Term = details.Satellite8.TrueRectangularCoordinates.X / r8
        details.Satellite8.ApparentRectangularCoordinates.X = details.Satellite8.TrueRectangularCoordinates.X + abs(details.Satellite8.TrueRectangularCoordinates.Z) / 91820.0 * sqrt(max(0.0, 1.0 - r8Term * r8Term))
        details.Satellite8.ApparentRectangularCoordinates.Y = details.Satellite8.TrueRectangularCoordinates.Y
        details.Satellite8.ApparentRectangularCoordinates.Z = details.Satellite8.TrueRectangularCoordinates.Z

        // Perspective effect correction
        var W = DELTA / (DELTA + (details.Satellite1.TrueRectangularCoordinates.Z / 2475.0))
        details.Satellite1.ApparentRectangularCoordinates.X *= W
        details.Satellite1.ApparentRectangularCoordinates.Y *= W

        W = DELTA / (DELTA + (details.Satellite2.TrueRectangularCoordinates.Z / 2475.0))
        details.Satellite2.ApparentRectangularCoordinates.X *= W
        details.Satellite2.ApparentRectangularCoordinates.Y *= W

        W = DELTA / (DELTA + (details.Satellite3.TrueRectangularCoordinates.Z / 2475.0))
        details.Satellite3.ApparentRectangularCoordinates.X *= W
        details.Satellite3.ApparentRectangularCoordinates.Y *= W

        W = DELTA / (DELTA + (details.Satellite4.TrueRectangularCoordinates.Z / 2475.0))
        details.Satellite4.ApparentRectangularCoordinates.X *= W
        details.Satellite4.ApparentRectangularCoordinates.Y *= W

        W = DELTA / (DELTA + (details.Satellite5.TrueRectangularCoordinates.Z / 2475.0))
        details.Satellite5.ApparentRectangularCoordinates.X *= W
        details.Satellite5.ApparentRectangularCoordinates.Y *= W

        W = DELTA / (DELTA + (details.Satellite6.TrueRectangularCoordinates.Z / 2475.0))
        details.Satellite6.ApparentRectangularCoordinates.X *= W
        details.Satellite6.ApparentRectangularCoordinates.Y *= W

        W = DELTA / (DELTA + (details.Satellite7.TrueRectangularCoordinates.Z / 2475.0))
        details.Satellite7.ApparentRectangularCoordinates.X *= W
        details.Satellite7.ApparentRectangularCoordinates.Y *= W

        W = DELTA / (DELTA + (details.Satellite8.TrueRectangularCoordinates.Z / 2475.0))
        details.Satellite8.ApparentRectangularCoordinates.X *= W
        details.Satellite8.ApparentRectangularCoordinates.Y *= W

        return details
    }

    public static func Calculate(_ JD: Double, _ bHighPrecision: Bool) -> CAASaturnMoonsDetails {
        let sunlong = CAASun.GeometricEclipticLongitude(JD, bHighPrecision)
        let sunlongrad = SphericalTrigonometry.degreesToRadians(sunlong)
        let beta = CAASun.GeometricEclipticLatitude(JD, bHighPrecision)
        let betarad = SphericalTrigonometry.degreesToRadians(beta)
        let R = CAAEarth.RadiusVector(JD, bHighPrecision)

        var DELTA = 9.0
        var PreviousEarthLightTravelTime = 0.0
        var EarthLightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)
        var JD1 = JD - EarthLightTravelTime
        var bIterate = true
        var x = 0.0
        var y = 0.0
        var z = 0.0

        while bIterate {
            let l = CAASaturn.EclipticLongitude(JD1, bHighPrecision)
            let lrad = SphericalTrigonometry.degreesToRadians(l)
            let b = CAASaturn.EclipticLatitude(JD1, bHighPrecision)
            let brad = SphericalTrigonometry.degreesToRadians(b)
            let cosbrad = cos(brad)
            let r = CAASaturn.RadiusVector(JD1, bHighPrecision)

            x = (r * cosbrad * cos(lrad)) + (R * cos(sunlongrad))
            y = (r * cosbrad * sin(lrad)) + (R * sin(sunlongrad))
            z = (r * sin(brad)) + (R * sin(betarad))
            DELTA = sqrt((x * x) + (y * y) + (z * z))
            EarthLightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)

            bIterate = (abs(EarthLightTravelTime - PreviousEarthLightTravelTime) > 2e-6)
            if bIterate {
                JD1 = JD - EarthLightTravelTime
                PreviousEarthLightTravelTime = EarthLightTravelTime
            }
        }

        var details1 = CalculateHelper(JD, sunlongrad, betarad, R, bHighPrecision)
        FillInPhenomenaDetails(&details1.Satellite1)
        FillInPhenomenaDetails(&details1.Satellite2)
        FillInPhenomenaDetails(&details1.Satellite3)
        FillInPhenomenaDetails(&details1.Satellite4)
        FillInPhenomenaDetails(&details1.Satellite5)
        FillInPhenomenaDetails(&details1.Satellite6)
        FillInPhenomenaDetails(&details1.Satellite7)
        FillInPhenomenaDetails(&details1.Satellite8)

        JD1 = JD - EarthLightTravelTime
        let l = CAASaturn.EclipticLongitude(JD1, bHighPrecision)
        let lrad = SphericalTrigonometry.degreesToRadians(l)
        let b = CAASaturn.EclipticLatitude(JD1, bHighPrecision)
        let brad = SphericalTrigonometry.degreesToRadians(b)
        let cosbrad = cos(brad)
        let r = CAASaturn.RadiusVector(JD1, bHighPrecision)
        x = r * cosbrad * cos(lrad)
        y = r * cosbrad * sin(lrad)
        z = r * sin(brad)
        DELTA = sqrt((x * x) + (y * y) + (z * z))
        let SunLightTravelTime = CAAElliptical.DistanceToLightTime(DELTA)

        var details2 = CalculateHelper(JD + SunLightTravelTime - EarthLightTravelTime, sunlongrad, betarad, 0, bHighPrecision)
        FillInPhenomenaDetails(&details2.Satellite1)
        FillInPhenomenaDetails(&details2.Satellite2)
        FillInPhenomenaDetails(&details2.Satellite3)
        FillInPhenomenaDetails(&details2.Satellite4)
        FillInPhenomenaDetails(&details2.Satellite5)
        FillInPhenomenaDetails(&details2.Satellite6)
        FillInPhenomenaDetails(&details2.Satellite7)
        FillInPhenomenaDetails(&details2.Satellite8)

        details1.Satellite1.bInEclipse = details2.Satellite1.bInOccultation
        details1.Satellite2.bInEclipse = details2.Satellite2.bInOccultation
        details1.Satellite3.bInEclipse = details2.Satellite3.bInOccultation
        details1.Satellite4.bInEclipse = details2.Satellite4.bInOccultation
        details1.Satellite5.bInEclipse = details2.Satellite5.bInOccultation
        details1.Satellite6.bInEclipse = details2.Satellite6.bInOccultation
        details1.Satellite7.bInEclipse = details2.Satellite7.bInOccultation
        details1.Satellite8.bInEclipse = details2.Satellite8.bInOccultation

        details1.Satellite1.bInShadowTransit = details2.Satellite1.bInTransit
        details1.Satellite2.bInShadowTransit = details2.Satellite2.bInTransit
        details1.Satellite3.bInShadowTransit = details2.Satellite3.bInTransit
        details1.Satellite4.bInShadowTransit = details2.Satellite4.bInTransit
        details1.Satellite5.bInShadowTransit = details2.Satellite5.bInTransit
        details1.Satellite6.bInShadowTransit = details2.Satellite6.bInTransit
        details1.Satellite7.bInShadowTransit = details2.Satellite7.bInTransit
        details1.Satellite8.bInShadowTransit = details2.Satellite8.bInTransit

        return details1
    }
}
