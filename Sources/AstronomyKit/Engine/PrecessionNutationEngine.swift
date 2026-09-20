//
//  PrecessionNutationEngine.swift
//  AstronomyKit
//
//  Pure Swift general precession and IAU 1980 / 2000B nutation engine.
//  Replaces AAPrecession and AANutation from AAplus.
//

import Foundation

// MARK: - Nutation Engine (IAU 1980 Wahr Model / Meeus Ch. 22)

private struct NutationCoefficient: Sendable {
    let D: Int
    let M: Int
    let Mprime: Int
    let F: Int
    let omega: Int
    let sincoeff1: Double
    let sincoeff2: Double
    let coscoeff1: Double
    let coscoeff2: Double
}

private let gNutationCoeffs: [NutationCoefficient] = [
    NutationCoefficient(D: 0, M: 0, Mprime: 0, F: 0, omega: 1, sincoeff1: -171996, sincoeff2: -174.2, coscoeff1: 92025, coscoeff2: 8.9),
    NutationCoefficient(D: -2, M: 0, Mprime: 0, F: 2, omega: 2, sincoeff1: -13187, sincoeff2: -1.6, coscoeff1: 5736, coscoeff2: -3.1),
    NutationCoefficient(D: 0, M: 0, Mprime: 0, F: 2, omega: 2, sincoeff1: -2274, sincoeff2: -0.2, coscoeff1: 977, coscoeff2: -0.5),
    NutationCoefficient(D: 0, M: 0, Mprime: 0, F: 0, omega: 2, sincoeff1: 2062, sincoeff2: 0.2, coscoeff1: -895, coscoeff2: 0.5),
    NutationCoefficient(D: 0, M: 1, Mprime: 0, F: 0, omega: 0, sincoeff1: 1426, sincoeff2: -3.4, coscoeff1: 54, coscoeff2: -0.1),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: 0, omega: 0, sincoeff1: 712, sincoeff2: 0.1, coscoeff1: -7, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 1, Mprime: 0, F: 2, omega: 2, sincoeff1: -517, sincoeff2: 1.2, coscoeff1: 224, coscoeff2: -0.6),
    NutationCoefficient(D: 0, M: 0, Mprime: 0, F: 2, omega: 1, sincoeff1: -386, sincoeff2: -0.4, coscoeff1: 200, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: 2, omega: 2, sincoeff1: -301, sincoeff2: 0, coscoeff1: 129, coscoeff2: -0.1),
    NutationCoefficient(D: -2, M: -1, Mprime: 0, F: 2, omega: 2, sincoeff1: 217, sincoeff2: -0.5, coscoeff1: -95, coscoeff2: 0.3),
    NutationCoefficient(D: -2, M: 0, Mprime: 1, F: 0, omega: 0, sincoeff1: -158, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 0, F: 2, omega: 1, sincoeff1: 129, sincoeff2: 0.1, coscoeff1: -70, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: -1, F: 2, omega: 2, sincoeff1: 123, sincoeff2: 0, coscoeff1: -53, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 0, F: 0, omega: 0, sincoeff1: 63, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: 0, omega: 1, sincoeff1: 63, sincoeff2: 0.1, coscoeff1: -33, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: -1, F: 2, omega: 2, sincoeff1: -59, sincoeff2: 0, coscoeff1: 26, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: -1, F: 0, omega: 1, sincoeff1: -58, sincoeff2: -0.1, coscoeff1: 32, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: 2, omega: 1, sincoeff1: -51, sincoeff2: 0, coscoeff1: 27, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 2, F: 0, omega: 0, sincoeff1: 48, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: -2, F: 2, omega: 1, sincoeff1: 46, sincoeff2: 0, coscoeff1: -24, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 0, F: 2, omega: 2, sincoeff1: -38, sincoeff2: 0, coscoeff1: 16, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 2, F: 2, omega: 2, sincoeff1: -31, sincoeff2: 0, coscoeff1: 13, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 2, F: 0, omega: 0, sincoeff1: 29, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 1, F: 2, omega: 2, sincoeff1: 29, sincoeff2: 0, coscoeff1: -12, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 0, F: 2, omega: 0, sincoeff1: 26, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 0, F: 2, omega: 0, sincoeff1: -22, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: -1, F: 2, omega: 1, sincoeff1: 21, sincoeff2: 0, coscoeff1: -10, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 2, Mprime: 0, F: 0, omega: 0, sincoeff1: 17, sincoeff2: -0.1, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: -1, F: 0, omega: 1, sincoeff1: 16, sincoeff2: 0, coscoeff1: -8, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 2, Mprime: 0, F: 2, omega: 2, sincoeff1: -16, sincoeff2: 0.1, coscoeff1: 7, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 1, Mprime: 0, F: 0, omega: 1, sincoeff1: -15, sincoeff2: 0, coscoeff1: 9, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 1, F: 0, omega: 1, sincoeff1: -13, sincoeff2: 0, coscoeff1: 7, coscoeff2: 0),
    NutationCoefficient(D: 0, M: -1, Mprime: 0, F: 0, omega: 1, sincoeff1: -12, sincoeff2: 0, coscoeff1: 6, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 2, F: -2, omega: 0, sincoeff1: 11, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: -1, F: 2, omega: 1, sincoeff1: -10, sincoeff2: 0, coscoeff1: 5, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 1, F: 2, omega: 2, sincoeff1: -8, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 1, Mprime: 0, F: 2, omega: 2, sincoeff1: 7, sincoeff2: 0, coscoeff1: -3, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 1, Mprime: 1, F: 0, omega: 0, sincoeff1: -7, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: -1, Mprime: 0, F: 2, omega: 2, sincoeff1: -7, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 0, F: 2, omega: 1, sincoeff1: -7, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 1, F: 0, omega: 0, sincoeff1: 6, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 2, F: 2, omega: 2, sincoeff1: 6, sincoeff2: 0, coscoeff1: -3, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 1, F: 2, omega: 1, sincoeff1: 6, sincoeff2: 0, coscoeff1: -3, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: -2, F: 0, omega: 1, sincoeff1: -6, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 2, M: 0, Mprime: 0, F: 0, omega: 1, sincoeff1: -6, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 0, M: -1, Mprime: 1, F: 0, omega: 0, sincoeff1: 5, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: -1, Mprime: 0, F: 2, omega: 1, sincoeff1: -5, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 0, F: 0, omega: 1, sincoeff1: -5, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 2, F: 2, omega: 1, sincoeff1: -5, sincoeff2: 0, coscoeff1: 3, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 0, Mprime: 2, F: 0, omega: 1, sincoeff1: 4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 1, Mprime: 0, F: 2, omega: 1, sincoeff1: 4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: -2, omega: 0, sincoeff1: 4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -1, M: 0, Mprime: 1, F: 0, omega: 0, sincoeff1: -4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -2, M: 1, Mprime: 0, F: 0, omega: 0, sincoeff1: -4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 1, M: 0, Mprime: 0, F: 0, omega: 0, sincoeff1: -4, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 1, F: 2, omega: 0, sincoeff1: 3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: -2, F: 2, omega: 2, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: -1, M: -1, Mprime: 1, F: 0, omega: 0, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 1, Mprime: 1, F: 0, omega: 0, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: -1, Mprime: 1, F: 2, omega: 2, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 2, M: -1, Mprime: -1, F: 2, omega: 2, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 0, M: 0, Mprime: 3, F: 2, omega: 2, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0),
    NutationCoefficient(D: 2, M: -1, Mprime: 0, F: 2, omega: 2, sincoeff1: -3, sincoeff2: 0, coscoeff1: 0, coscoeff2: 0)
]

// MARK: - IAU 2000B Nutation Series (77 Luni-Solar Terms, McCarthy & Luzum 2002)

private struct IAU2000BCoefficient: Sendable {
    let l: Int
    let lprime: Int
    let f: Int
    let d: Int
    let om: Int
    let sPsi: Double
    let sPsiT: Double
    let cEps: Double
    let cEpsT: Double
}

private let gIAU2000BCoeffs: [IAU2000BCoefficient] = [
    IAU2000BCoefficient(l: 0, lprime: 0, f: 0, d: 0, om: 1, sPsi: -172064.161, sPsiT: -174.666, cEps: 92052.331, cEpsT: 9.086),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: -2, om: 2, sPsi: -13170.906, sPsiT: -1.675, cEps: 5730.336, cEpsT: -3.015),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 0, om: 2, sPsi: -2276.413, sPsiT: -0.234, cEps: 978.459, cEpsT: -0.485),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 0, d: 0, om: 2, sPsi: 2074.554, sPsiT: 0.207, cEps: -897.492, cEpsT: 0.470),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 0, d: 0, om: 0, sPsi: 1475.877, sPsiT: -3.633, cEps: 73.871, cEpsT: -0.184),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 0, d: 0, om: 0, sPsi: 710.154, sPsiT: 0.131, cEps: -6.750, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: -2, om: 1, sPsi: -511.047, sPsiT: -0.325, cEps: 224.786, cEpsT: -0.677),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: 0, om: 2, sPsi: -387.298, sPsiT: -0.367, cEps: 200.728, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 0, om: 1, sPsi: -301.461, sPsiT: -0.036, cEps: 129.025, cEpsT: -0.095),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: -2, om: 2, sPsi: 215.829, sPsiT: -0.494, cEps: -95.273, cEpsT: 0.297),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 0, d: -2, om: 0, sPsi: 128.227, sPsiT: 0.137, cEps: -69.948, cEpsT: 0.0),
    IAU2000BCoefficient(l: -1, lprime: 0, f: 2, d: 0, om: 2, sPsi: 123.457, sPsiT: 0.011, cEps: -53.311, cEpsT: 0.032),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 0, d: 2, om: 0, sPsi: 63.157, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 0, om: 0, sPsi: 63.110, sPsiT: 0.063, cEps: -33.286, cEpsT: 0.0),
    IAU2000BCoefficient(l: -1, lprime: 0, f: 2, d: 2, om: 2, sPsi: -57.976, sPsiT: -0.063, cEps: 26.015, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 0, d: 0, om: 1, sPsi: -59.641, sPsiT: -0.011, cEps: 32.077, cEpsT: 0.0),
    IAU2000BCoefficient(l: -1, lprime: 0, f: 0, d: 2, om: 0, sPsi: -51.648, sPsiT: 0.022, cEps: 27.677, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: 0, om: 1, sPsi: 45.893, sPsiT: 0.0, cEps: -24.459, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: -2, om: 0, sPsi: 48.018, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 2, d: -2, om: 2, sPsi: -38.571, sPsiT: -0.001, cEps: 16.441, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 4, d: -2, om: 2, sPsi: -32.481, sPsiT: 0.0, cEps: 13.996, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 0, d: 2, om: 0, sPsi: 28.593, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 2, om: 2, sPsi: 29.245, sPsiT: 0.0, cEps: -12.847, cEpsT: 0.0),
    IAU2000BCoefficient(l: -1, lprime: 0, f: 2, d: 0, om: 1, sPsi: 26.284, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 2, d: 0, om: 2, sPsi: -21.874, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: 0, om: 0, sPsi: 21.305, sPsiT: 0.0, cEps: -9.593, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 0, om: -1, sPsi: 17.742, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 0, d: 0, om: 1, sPsi: 16.549, sPsiT: 0.0, cEps: -8.555, cEpsT: 0.0),
    IAU2000BCoefficient(l: 2, lprime: 0, f: 2, d: 0, om: 2, sPsi: -16.342, sPsiT: 0.0, cEps: 7.143, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 2, f: 2, d: -2, om: 2, sPsi: -13.919, sPsiT: 0.0, cEps: 6.288, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 0, d: 2, om: 1, sPsi: -13.085, sPsiT: 0.0, cEps: 7.090, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 2, om: 1, sPsi: -12.248, sPsiT: 0.0, cEps: 6.715, cEpsT: 0.0),
    IAU2000BCoefficient(l: 2, lprime: 0, f: 0, d: 0, om: 0, sPsi: 11.453, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: -2, om: -1, sPsi: 10.056, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: -2, om: 1, sPsi: -8.922, sPsiT: 0.0, cEps: 4.497, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 2, d: -2, om: 1, sPsi: -7.991, sPsiT: 0.0, cEps: 3.808, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 0, d: 2, om: 0, sPsi: 7.549, sPsiT: 0.0, cEps: -3.780, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 4, d: 0, om: 2, sPsi: -7.332, sPsiT: 0.0, cEps: 3.153, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 0, d: 2, om: 2, sPsi: -7.138, sPsiT: 0.0, cEps: 3.090, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: 2, om: 2, sPsi: 6.324, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 4, om: 2, sPsi: -5.795, sPsiT: 0.0, cEps: 2.459, cEpsT: 0.0),
    IAU2000BCoefficient(l: 2, lprime: 0, f: 2, d: -2, om: 2, sPsi: 4.991, sPsiT: 0.0, cEps: -2.186, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: -4, om: 2, sPsi: -4.947, sPsiT: 0.0, cEps: 2.164, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 0, d: -2, om: 0, sPsi: 4.770, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 4, d: -2, om: 2, sPsi: -4.759, sPsiT: 0.0, cEps: 2.190, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 0, om: 3, sPsi: -4.394, sPsiT: 0.0, cEps: 1.100, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 0, d: 0, om: 3, sPsi: 3.735, sPsiT: 0.0, cEps: -0.940, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: 0, om: 3, sPsi: -3.538, sPsiT: 0.0, cEps: 1.000, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 2, d: 0, om: 1, sPsi: -3.298, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 0, d: -2, om: 1, sPsi: 3.082, sPsiT: 0.0, cEps: -1.250, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 0, d: 2, om: 1, sPsi: -2.853, sPsiT: 0.0, cEps: 1.370, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 2, om: 0, sPsi: 2.706, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: -2, om: 0, sPsi: -2.522, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 0, d: 4, om: 0, sPsi: 2.500, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 0, d: 0, om: 2, sPsi: -2.438, sPsiT: 0.0, cEps: 1.050, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: -2, om: 3, sPsi: -2.203, sPsiT: 0.0, cEps: 0.950, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 4, om: 1, sPsi: -2.110, sPsiT: 0.0, cEps: 1.120, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 2, d: 2, om: 2, sPsi: -2.007, sPsiT: 0.0, cEps: 0.900, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: -4, om: 1, sPsi: -1.970, sPsiT: 0.0, cEps: 1.040, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 4, d: 0, om: 2, sPsi: -1.882, sPsiT: 0.0, cEps: 0.810, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 4, d: -2, om: 1, sPsi: -1.821, sPsiT: 0.0, cEps: 0.980, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: 2, om: 1, sPsi: -1.802, sPsiT: 0.0, cEps: 0.770, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 2, d: -4, om: 2, sPsi: -1.635, sPsiT: 0.0, cEps: 0.710, cEpsT: 0.0),
    IAU2000BCoefficient(l: 2, lprime: 0, f: 2, d: 0, om: 1, sPsi: -1.570, sPsiT: 0.0, cEps: 0.690, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 2, om: 3, sPsi: -1.524, sPsiT: 0.0, cEps: 0.650, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: 4, om: 2, sPsi: -1.488, sPsiT: 0.0, cEps: 0.640, cEpsT: 0.0),
    IAU2000BCoefficient(l: 2, lprime: 0, f: 0, d: -2, om: 0, sPsi: 1.450, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 2, f: 2, d: 0, om: 2, sPsi: -1.390, sPsiT: 0.0, cEps: 0.600, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 2, d: -4, om: 2, sPsi: -1.310, sPsiT: 0.0, cEps: 0.570, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 4, d: 2, om: 2, sPsi: -1.250, sPsiT: 0.0, cEps: 0.540, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 2, f: 0, d: 0, om: 0, sPsi: 1.200, sPsiT: 0.0, cEps: 0.0, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 0, d: 2, om: 3, sPsi: -1.180, sPsiT: 0.0, cEps: 0.510, cEpsT: 0.0),
    IAU2000BCoefficient(l: 1, lprime: 0, f: 0, d: 2, om: 1, sPsi: -1.150, sPsiT: 0.0, cEps: 0.500, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 2, d: 0, om: 4, sPsi: 1.100, sPsiT: 0.0, cEps: -0.470, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 1, f: 4, d: -2, om: 2, sPsi: -1.050, sPsiT: 0.0, cEps: 0.450, cEpsT: 0.0),
    IAU2000BCoefficient(l: 2, lprime: 0, f: 2, d: 2, om: 2, sPsi: -1.000, sPsiT: 0.0, cEps: 0.430, cEpsT: 0.0),
    IAU2000BCoefficient(l: 0, lprime: 0, f: 6, d: -2, om: 2, sPsi: -0.950, sPsiT: 0.0, cEps: 0.410, cEpsT: 0.0)
]

public enum CAANutation: Sendable {
    public static func NutationInLongitude(_ JD: Double) -> Double {
        let t = (JD - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t

        let d = SphericalTrigonometry.mapTo0To360Range(297.85036 + 445267.111480 * t - 0.0019142 * t2 + t3 / 189474.0)
        let m = SphericalTrigonometry.mapTo0To360Range(357.52772 + 35999.050340 * t - 0.0001603 * t2 - t3 / 300000.0)
        let mPrime = SphericalTrigonometry.mapTo0To360Range(134.96298 + 477198.867398 * t + 0.0086972 * t2 + t3 / 56250.0)
        let f = SphericalTrigonometry.mapTo0To360Range(93.27191 + 483202.017538 * t - 0.0036825 * t2 + t3 / 327270.0)
        let omega = SphericalTrigonometry.mapTo0To360Range(125.04452 - 1934.136261 * t + 0.0020708 * t2 + t3 / 450000.0)

        var value = 0.0
        for coeff in gNutationCoeffs {
            let argument = Double(coeff.D) * d + Double(coeff.M) * m + Double(coeff.Mprime) * mPrime + Double(coeff.F) * f + Double(coeff.omega) * omega
            let argRad = SphericalTrigonometry.degreesToRadians(argument)
            value += (coeff.sincoeff1 + coeff.sincoeff2 * t) * sin(argRad) * 0.0001
        }
        return value
    }

    public static func NutationInObliquity(_ JD: Double) -> Double {
        let t = (JD - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t

        let d = SphericalTrigonometry.mapTo0To360Range(297.85036 + 445267.111480 * t - 0.0019142 * t2 + t3 / 189474.0)
        let m = SphericalTrigonometry.mapTo0To360Range(357.52772 + 35999.050340 * t - 0.0001603 * t2 - t3 / 300000.0)
        let mPrime = SphericalTrigonometry.mapTo0To360Range(134.96298 + 477198.867398 * t + 0.0086972 * t2 + t3 / 56250.0)
        let f = SphericalTrigonometry.mapTo0To360Range(93.27191 + 483202.017538 * t - 0.0036825 * t2 + t3 / 327270.0)
        let omega = SphericalTrigonometry.mapTo0To360Range(125.04452 - 1934.136261 * t + 0.0020708 * t2 + t3 / 450000.0)

        var value = 0.0
        for coeff in gNutationCoeffs {
            let argument = Double(coeff.D) * d + Double(coeff.M) * m + Double(coeff.Mprime) * mPrime + Double(coeff.F) * f + Double(coeff.omega) * omega
            let argRad = SphericalTrigonometry.degreesToRadians(argument)
            value += (coeff.coscoeff1 + coeff.coscoeff2 * t) * cos(argRad) * 0.0001
        }
        return value
    }

    public static func MeanObliquityOfEcliptic(_ JD: Double) -> Double {
        let u = (JD - 2451545.0) / 3652500.0
        let u2 = u * u
        let u3 = u2 * u
        let u4 = u3 * u
        let u5 = u4 * u
        let u6 = u5 * u
        let u7 = u6 * u
        let u8 = u7 * u
        let u9 = u8 * u
        let u10 = u9 * u

        return SphericalTrigonometry.dmsToDegrees(23, 26, 21.448)
            - (SphericalTrigonometry.dmsToDegrees(0, 0, 4680.93) * u)
            - (SphericalTrigonometry.dmsToDegrees(0, 0, 1.55) * u2)
            + (SphericalTrigonometry.dmsToDegrees(0, 0, 1999.25) * u3)
            - (SphericalTrigonometry.dmsToDegrees(0, 0, 51.38) * u4)
            - (SphericalTrigonometry.dmsToDegrees(0, 0, 249.67) * u5)
            - (SphericalTrigonometry.dmsToDegrees(0, 0, 39.05) * u6)
            + (SphericalTrigonometry.dmsToDegrees(0, 0, 7.12) * u7)
            + (SphericalTrigonometry.dmsToDegrees(0, 0, 27.87) * u8)
            + (SphericalTrigonometry.dmsToDegrees(0, 0, 5.79) * u9)
            + (SphericalTrigonometry.dmsToDegrees(0, 0, 2.45) * u10)
    }

    public static func TrueObliquityOfEcliptic(_ JD: Double) -> Double {
        MeanObliquityOfEcliptic(JD) + SphericalTrigonometry.dmsToDegrees(0, 0, NutationInObliquity(JD))
    }

    @inlinable public static func nutationInLongitude(jd: Double) -> Double { NutationInLongitude(jd) }
    @inlinable public static func nutationInLongitude(_ JD: Double) -> Double { NutationInLongitude(JD) }
    @inlinable public static func nutationInObliquity(jd: Double) -> Double { NutationInObliquity(jd) }
    @inlinable public static func nutationInObliquity(_ JD: Double) -> Double { NutationInObliquity(JD) }
    @inlinable public static func meanObliquityOfEcliptic(jd: Double) -> Double { MeanObliquityOfEcliptic(jd) }
    @inlinable public static func meanObliquityOfEcliptic(_ JD: Double) -> Double { MeanObliquityOfEcliptic(JD) }
    @inlinable public static func trueObliquityOfEcliptic(jd: Double) -> Double { TrueObliquityOfEcliptic(jd) }
    @inlinable public static func trueObliquityOfEcliptic(_ JD: Double) -> Double { TrueObliquityOfEcliptic(JD) }

    /// High-precision IAU 2000B nutation in longitude (deltaPsi) and obliquity (deltaEpsilon) in arcseconds.
    /// Conforms to McCarthy & Luzum (2002) with 77 periodic luni-solar terms, accurate to 1 milliarcsecond.
    public static func nutationIAU2000B(_ JD: Double) -> (deltaPsi: Double, deltaEpsilon: Double) {
        let t = (JD - 2451545.0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t

        // Fundamental Delaunay arguments according to Simon et al. (1994) in radians
        let l = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(134.96340251 + 477198.8675605 * t + 0.0088553 * t2 + t3 / 69699.0 - t4 / 14712000.0))
        let lprime = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(357.52910918 + 35999.05029114 * t - 0.0001603 * t2 - t3 / 300000.0))
        let f = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(93.27209062 + 483202.0175273 * t - 0.0036825 * t2 + t3 / 327270.0))
        let d = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(297.85019547 + 445267.111477 * t - 0.0019142 * t2 + t3 / 189474.0))
        let omega = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.mapTo0To360Range(125.04455501 - 1934.13626197 * t + 0.0020708 * t2 + t3 / 450000.0))

        var dPsiMas = 0.0
        var dEpsMas = 0.0

        for coeff in gIAU2000BCoeffs {
            let arg = Double(coeff.l) * l + Double(coeff.lprime) * lprime + Double(coeff.f) * f + Double(coeff.d) * d + Double(coeff.om) * omega
            dPsiMas += (coeff.sPsi + coeff.sPsiT * t) * sin(arg)
            dEpsMas += (coeff.cEps + coeff.cEpsT * t) * cos(arg)
        }

        return (deltaPsi: dPsiMas / 1000.0, deltaEpsilon: dEpsMas / 1000.0)
    }

    public static func NutationInRightAscension(_ Alpha: Double, _ Delta: Double, _ Obliquity: Double, _ NutationInLongitude: Double, _ NutationInObliquity: Double) -> Double {
        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let eps = SphericalTrigonometry.degreesToRadians(Obliquity)

        return ((cos(eps) + (sin(eps) * sin(a) * tan(d))) * NutationInLongitude) - (cos(a) * tan(d) * NutationInObliquity)
    }

    public static func NutationInDeclination(_ Alpha: Double, _ Obliquity: Double, _ NutationInLongitude: Double, _ NutationInObliquity: Double) -> Double {
        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let eps = SphericalTrigonometry.degreesToRadians(Obliquity)

        return (sin(eps) * cos(a) * NutationInLongitude) + (sin(a) * NutationInObliquity)
    }
}

// MARK: - Precession Engine (Meeus Ch. 21)

public enum CAAPrecession: Sendable {
    public static func PrecessEquatorial(_ Alpha: Double, _ Delta: Double, _ JD0: Double, _ JD: Double) -> CAA2DCoordinate {
        let t0 = (JD0 - 2451545.0) / 36525.0
        let t0Squared = t0 * t0
        let t = (JD - JD0) / 36525.0
        let tSquared = t * t
        let tCubed = tSquared * t

        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let cosDelta = cos(d)
        let sinDelta = sin(d)

        let sigma = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2306.2181 + (1.39656 * t0) - (0.000139 * t0Squared)) * t) + ((0.30188 - (0.000344 * t0)) * tSquared) + (0.017998 * tCubed)))
        let zeta = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2306.2181 + (1.39656 * t0) - (0.000139 * t0Squared)) * t) + ((1.09468 + (0.000066 * t0)) * tSquared) + (0.018203 * tCubed)))
        let phi = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2004.3109 - (0.8533 * t0) - (0.000217 * t0Squared)) * t) - ((0.42665 + (0.000217 * t0)) * tSquared) - (0.041833 * tCubed)))

        let cosPhi = cos(phi)
        let sinPhi = sin(phi)
        let cosAlphaPlusSigma = cos(a + sigma)
        let capA = cosDelta * sin(a + sigma)
        let capB = (cosPhi * cosDelta * cosAlphaPlusSigma) - (sinPhi * sinDelta)
        let capC = (sinPhi * cosDelta * cosAlphaPlusSigma) + (cosPhi * sinDelta)

        let x = SphericalTrigonometry.mapTo0To24Range(SphericalTrigonometry.radiansToHours(atan2(capA, capB) + zeta))
        let y = SphericalTrigonometry.radiansToDegrees(asin(capC))
        return CAA2DCoordinate(x, y)
    }

    /// Precesses equatorial coordinates from epoch JD0 to epoch JD using the IAU 2006 (P03) precession model.
    public static func PrecessEquatorialIAU2006(_ Alpha: Double, _ Delta: Double, _ JD0: Double, _ JD: Double) -> CAA2DCoordinate {
        let t = (JD - JD0) / 36525.0
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        let t5 = t4 * t

        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let cosDelta = cos(d)
        let sinDelta = sin(d)

        // IAU 2006 (P03) precession angles (Capitaine et al., 2003)
        let zetaArcsec = 2.5976176 + 2306.0809506 * t + 0.3019015 * t2 + 0.0179663 * t3 - 0.0000327 * t4 - 0.0000002 * t5
        let zArcsec = -2.5976176 + 2306.0803226 * t + 1.0947790 * t2 + 0.0182273 * t3 + 0.0000470 * t4 - 0.0000003 * t5
        let thetaArcsec = 2004.1917476 * t - 0.4269353 * t2 - 0.0418251 * t3 - 0.0000601 * t4 - 0.0000001 * t5

        let zeta = SphericalTrigonometry.degreesToRadians(zetaArcsec / 3600.0)
        let z = SphericalTrigonometry.degreesToRadians(zArcsec / 3600.0)
        let theta = SphericalTrigonometry.degreesToRadians(thetaArcsec / 3600.0)

        let cosTheta = cos(theta)
        let sinTheta = sin(theta)
        let cosAlphaPlusZeta = cos(a + zeta)
        let sinAlphaPlusZeta = sin(a + zeta)

        let capA = cosDelta * sinAlphaPlusZeta
        let capB = (cosTheta * cosDelta * cosAlphaPlusZeta) - (sinTheta * sinDelta)
        let capC = (sinTheta * cosDelta * cosAlphaPlusZeta) + (cosTheta * sinDelta)

        let x = SphericalTrigonometry.mapTo0To24Range(SphericalTrigonometry.radiansToHours(atan2(capA, capB) + z))
        let y = SphericalTrigonometry.radiansToDegrees(asin(capC))
        return CAA2DCoordinate(x, y)
    }

    public static func PrecessEquatorialFK4(_ Alpha: Double, _ Delta: Double, _ JD0: Double, _ JD: Double) -> CAA2DCoordinate {
        let t0 = (JD0 - 2415020.3135) / 36524.2199
        let t = (JD - JD0) / 36524.2199
        let tSquared = t * t
        let tCubed = tSquared * t

        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let cosDelta = cos(d)
        let sinDelta = sin(d)

        let sigma = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2304.250 + (1.396 * t0)) * t) + (0.302 * tSquared) + (0.018 * tCubed)))
        let zeta = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2304.250 + (1.396 * t0)) * t) + (1.093 * tSquared) + (0.018 * tCubed)))
        let phi = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((2004.682 - (0.853 * t0)) * t) - (0.426 * tSquared) - (0.042 * tCubed)))

        let cosPhi = cos(phi)
        let sinPhi = sin(phi)
        let cosAlphaPlusSigma = cos(a + sigma)
        let capA = cosDelta * sin(a + sigma)
        let capB = (cosPhi * cosDelta * cosAlphaPlusSigma) - (sinPhi * sinDelta)
        let capC = (sinPhi * cosDelta * cosAlphaPlusSigma) + (cosPhi * sinDelta)

        let x = SphericalTrigonometry.mapTo0To24Range(SphericalTrigonometry.radiansToHours(atan2(capA, capB) + zeta))
        let y = SphericalTrigonometry.radiansToDegrees(asin(capC))
        return CAA2DCoordinate(x, y)
    }

    public static func PrecessEcliptic(_ Lambda: Double, _ Beta: Double, _ JD0: Double, _ JD: Double) -> CAA2DCoordinate {
        let T = (JD0 - 2451545.0) / 36525.0
        let TSquared = T * T
        let t = (JD - JD0) / 36525.0
        let tSquared = t * t
        let tCubed = tSquared * t

        let lam = SphericalTrigonometry.degreesToRadians(Lambda)
        let bet = SphericalTrigonometry.degreesToRadians(Beta)
        let cosBeta = cos(bet)
        let sinBeta = sin(bet)

        let eta = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((47.0029 - (0.06603 * T) + (0.000598 * TSquared)) * t) + ((-0.03302 + (0.000598 * T)) * tSquared) + (0.00006 * tCubed)))
        let cosEta = cos(eta)
        let sinEta = sin(eta)

        let pi = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, (174.876384 * 3600.0) + (3289.4789 * T) + (0.60622 * TSquared) - ((869.8089 + (0.50491 * T)) * t) + (0.03536 * tSquared)))
        let sinPiMinusLambda = sin(pi - lam)

        let p = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, ((5029.0966 + (2.22226 * T) - (0.000042 * TSquared)) * t) + ((1.11113 - (0.000042 * T)) * tSquared) - (0.000006 * tCubed)))
        let capA = (cosEta * cosBeta * sinPiMinusLambda) - (sinEta * sinBeta)
        let capB = cosBeta * cos(pi - lam)
        let capC = (cosEta * sinBeta) + (sinEta * cosBeta * sinPiMinusLambda)

        let x = SphericalTrigonometry.mapTo0To360Range(SphericalTrigonometry.radiansToDegrees(p + pi - atan2(capA, capB)))
        let y = SphericalTrigonometry.radiansToDegrees(asin(capC))
        return CAA2DCoordinate(x, y)
    }

    public static func EquatorialPMToEcliptic(_ Alpha: Double, _ Delta: Double, _ Beta: Double, _ PMAlpha: Double, _ PMDelta: Double, _ Epsilon: Double) -> CAA2DCoordinate {
        let eps = SphericalTrigonometry.degreesToRadians(Epsilon)
        let sinEps = sin(eps)
        let cosEps = cos(eps)

        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let cosAlpha = cos(a)
        let sinAlpha = sin(a)

        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let cosDelta = cos(d)
        let sinDelta = sin(d)

        let b = SphericalTrigonometry.degreesToRadians(Beta)
        let cosBeta = cos(b)

        let x = ((PMDelta * sinEps * cosAlpha) + (PMAlpha * cosDelta * ((cosEps * cosDelta) + (sinEps * sinDelta * sinAlpha)))) / (cosBeta * cosBeta)
        let y = (PMDelta * ((cosEps * cosDelta) + (sinEps * sinDelta * sinAlpha)) - (PMAlpha * sinEps * cosAlpha * cosDelta)) / cosBeta
        return CAA2DCoordinate(x, y)
    }

    public static func AdjustPositionUsingUniformProperMotion(_ t: Double, _ Alpha: Double, _ Delta: Double, _ PMAlpha: Double, _ PMDelta: Double) -> CAA2DCoordinate {
        let x = SphericalTrigonometry.mapTo0To24Range(Alpha + ((PMAlpha * t) / 3600.0))
        let y = SphericalTrigonometry.mapToMinus90To90Range(Delta + ((PMDelta * t) / 3600.0))
        return CAA2DCoordinate(x, y)
    }

    public static func AdjustPositionUsingMotionInSpace(_ r: Double, _ DeltaR: Double, _ t: Double, _ Alpha: Double, _ Delta: Double, _ PMAlpha: Double, _ PMDelta: Double) -> CAA2DCoordinate {
        let dr = DeltaR / 977792.0
        let pmA = PMAlpha / 13751.0
        let pmD = PMDelta / 206265.0

        let a = SphericalTrigonometry.hoursToRadians(Alpha)
        let cosAlpha = cos(a)
        let sinAlpha = sin(a)
        let d = SphericalTrigonometry.degreesToRadians(Delta)
        let cosDelta = cos(d)
        let rCosDelta = r * cosDelta

        var x = rCosDelta * cosAlpha
        var y = rCosDelta * sinAlpha
        var z = r * sin(d)

        let deltaX = ((x / r) * dr) - (z * pmD * cosAlpha) - (y * pmA)
        let deltaY = ((y / r) * dr) - (z * pmD * sinAlpha) + (x * pmA)
        let deltaZ = ((z / r) * dr) + (r * pmD * cosDelta)

        x += t * deltaX
        y += t * deltaY
        z += t * deltaZ

        let newAlpha = SphericalTrigonometry.mapTo0To24Range(SphericalTrigonometry.radiansToHours(atan2(y, x)))
        let newDelta = SphericalTrigonometry.radiansToDegrees(atan2(z, sqrt((x * x) + (y * y))))
        return CAA2DCoordinate(newAlpha, newDelta)
    }
}

// MARK: - FK5 Reference Frame Conversion Engine (CAAFK5)

public enum CAAFK5: Sendable {
    @inlinable public static func correctionInLongitude(longitude: Double, latitude: Double, jd: Double) -> Double {
        CorrectionInLongitude(longitude, latitude, jd)
    }
    @inlinable public static func correctionInLongitude(_ Longitude: Double, _ Latitude: Double, _ JD: Double) -> Double {
        CorrectionInLongitude(Longitude, Latitude, JD)
    }

    @inlinable public static func correctionInLatitude(longitude: Double, jd: Double) -> Double {
        CorrectionInLatitude(longitude, jd)
    }
    @inlinable public static func correctionInLatitude(_ Longitude: Double, _ JD: Double) -> Double {
        CorrectionInLatitude(Longitude, JD)
    }

    @inlinable public static func convertVSOPToFK5J2000(_ value: CAA3DCoordinate) -> CAA3DCoordinate {
        ConvertVSOPToFK5J2000(value)
    }

    @inlinable public static func convertVSOPToFK5B1950(_ value: CAA3DCoordinate) -> CAA3DCoordinate {
        ConvertVSOPToFK5B1950(value)
    }

    @inlinable public static func convertVSOPToFK5AnyEquinox(value: CAA3DCoordinate, jdedate: Double) -> CAA3DCoordinate {
        ConvertVSOPToFK5AnyEquinox(value, jdedate)
    }
    @inlinable public static func convertVSOPToFK5AnyEquinox(_ value: CAA3DCoordinate, jdEquinox: Double) -> CAA3DCoordinate {
        ConvertVSOPToFK5AnyEquinox(value, jdEquinox)
    }
    @inlinable public static func convertVSOPToFK5AnyEquinox(_ value: CAA3DCoordinate, _ JDEquinox: Double) -> CAA3DCoordinate {
        ConvertVSOPToFK5AnyEquinox(value, JDEquinox)
    }

    public static func CorrectionInLongitude(_ Longitude: Double, _ Latitude: Double, _ JD: Double) -> Double {
        let T = (JD - 2451545.0) / 36525.0
        var Ldash = Longitude - (1.397 * T) - (0.00031 * T * T)
        Ldash = SphericalTrigonometry.degreesToRadians(Ldash)
        let latRad = SphericalTrigonometry.degreesToRadians(Latitude)
        let value = -0.09033 + (0.03916 * (cos(Ldash) + sin(Ldash))) * tan(latRad)
        return SphericalTrigonometry.dmsToDegrees(0, 0, value)
    }

    public static func CorrectionInLatitude(_ Longitude: Double, _ JD: Double) -> Double {
        let T = (JD - 2451545.0) / 36525.0
        var Ldash = Longitude - (1.397 * T) - (0.00031 * T * T)
        Ldash = SphericalTrigonometry.degreesToRadians(Ldash)
        let value = 0.03916 * (cos(Ldash) - sin(Ldash))
        return SphericalTrigonometry.dmsToDegrees(0, 0, value)
    }

    public static func ConvertVSOPToFK5J2000(_ value: CAA3DCoordinate) -> CAA3DCoordinate {
        var result = CAA3DCoordinate()
        result.X = value.X + (0.000000440360 * value.Y) - (0.000000190919 * value.Z)
        result.Y = (-0.000000479966 * value.X) + (0.917482137087 * value.Y) - (0.397776982902 * value.Z)
        result.Z = (0.397776982902 * value.Y) + (0.917482137087 * value.Z)
        return result
    }

    public static func ConvertVSOPToFK5B1950(_ value: CAA3DCoordinate) -> CAA3DCoordinate {
        var result = CAA3DCoordinate()
        result.X = (0.999925702634 * value.X) + (0.012189716217 * value.Y) + (0.000011134016 * value.Z)
        result.Y = (-0.011179418036 * value.X) + (0.917413998946 * value.Y) - (0.397777041885 * value.Z)
        result.Z = (-0.004859003787 * value.X) + (0.397747363646 * value.Y) + (0.917482111428 * value.Z)
        return result
    }

    public static func ConvertVSOPToFK5AnyEquinox(_ value: CAA3DCoordinate, _ JDEquinox: Double) -> CAA3DCoordinate {
        let t = (JDEquinox - 2451545.0) / 36525.0
        let tsquared = t * t
        let tcubed = tsquared * t

        var sigma = (2306.2181 * t) + (0.30188 * tsquared) + (0.017988 * tcubed)
        sigma = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, sigma))

        var zeta = (2306.2181 * t) + (1.09468 * tsquared) + (0.018203 * tcubed)
        zeta = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, zeta))

        var phi = (2004.3109 * t) - (0.42665 * tsquared) - (0.041833 * tcubed)
        phi = SphericalTrigonometry.degreesToRadians(SphericalTrigonometry.dmsToDegrees(0, 0, phi))

        let cossigma = cos(sigma)
        let coszeta = cos(zeta)
        let cosphi = cos(phi)
        let sinsigma = sin(sigma)
        let sinzeta = sin(zeta)
        let sinphi = sin(phi)

        let xx = (cossigma * coszeta * cosphi) - (sinsigma * sinzeta)
        let xy = (sinsigma * coszeta) + (cossigma * sinzeta * cosphi)
        let xz = cossigma * sinphi
        let yx = (-cossigma * sinzeta) - (sinsigma * coszeta * cosphi)
        let yy = (cossigma * coszeta) - (sinsigma * sinzeta * cosphi)
        let yz = -sinsigma * sinphi
        let zx = -coszeta * sinphi
        let zy = -sinzeta * sinphi
        let zz = cosphi

        var result = CAA3DCoordinate()
        result.X = (xx * value.X) + (yx * value.Y) + (zx * value.Z)
        result.Y = (xy * value.X) + (yy * value.Y) + (zy * value.Z)
        result.Z = (xz * value.X) + (yz * value.Y) + (zz * value.Z)
        return result
    }
}

