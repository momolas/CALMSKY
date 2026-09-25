//
//  VSOP2013Reader.swift
//  AstronomyKit
//
//  Pure Swift VSOP2013 ephemerides reader and Chebyshev polynomial evaluator.
//  Replaces CAAVSOP2013 from AAplus.
//

import Foundation

// MARK: - VSOP2013 Data Structures

public struct CAAVSOP2013Position: Sendable, Codable, Hashable {
    public var X: Double = 0
    public var Y: Double = 0
    public var Z: Double = 0
    public var X_DASH: Double = 0
    public var Y_DASH: Double = 0
    public var Z_DASH: Double = 0

    public init(X: Double = 0, Y: Double = 0, Z: Double = 0, X_DASH: Double = 0, Y_DASH: Double = 0, Z_DASH: Double = 0) {
        self.X = X
        self.Y = Y
        self.Z = Z
        self.X_DASH = X_DASH
        self.Y_DASH = Y_DASH
        self.Z_DASH = Z_DASH
    }
}

public struct CAAVSOP2013Orbit: Sendable, Codable, Hashable {
    public var a: Double = 0
    public var lambda: Double = 0
    public var k: Double = 0
    public var h: Double = 0
    public var q: Double = 0
    public var p: Double = 0

    public init(a: Double = 0, lambda: Double = 0, k: Double = 0, h: Double = 0, q: Double = 0, p: Double = 0) {
        self.a = a
        self.lambda = lambda
        self.k = k
        self.h = h
        self.q = q
        self.p = p
    }
}

import os

// MARK: - Ephemerides File Reader

private struct VSOP2013EphemeridesFile: Sendable {
    static let sizeBasicInterval: Double = 32.0
    static let identificationIndex: Int = 2013
    static let chebyshevTables: Int = 17122
    static let coefficientsPerTable: Int = 978
    static let recordFloats: Int = coefficientsPerTable + 2 // 980 doubles per table

    var startJD: Double = 0
    var endJD: Double = 0
    var firstCoefficientRank: [Int32] = Array(repeating: 0, count: 9)
    var coefficientsPerCoordinate: [Int32] = Array(repeating: 0, count: 9)
    var subIntervals: [Int32] = Array(repeating: 0, count: 9)
    var mappedData: Data?

    mutating func readBinaryFile(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe), data.count >= 125 else {
            return false
        }

        var offset = 0
        let version = data[offset]
        offset += 1
        guard version == 1 else { return false }

        startJD = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: Double.self) }
        offset += 8
        endJD = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: Double.self) }
        offset += 8

        for i in 0..<9 {
            let bigEndianVal = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self) }
            firstCoefficientRank[i] = Int32(bitPattern: UInt32(bigEndian: bigEndianVal))
            offset += 4
        }
        for i in 0..<9 {
            let bigEndianVal = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self) }
            coefficientsPerCoordinate[i] = Int32(bitPattern: UInt32(bigEndian: bigEndianVal))
            offset += 4
        }
        for i in 0..<9 {
            let bigEndianVal = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self) }
            subIntervals[i] = Int32(bitPattern: UInt32(bigEndian: bigEndianVal))
            offset += 4
        }

        let expectedTableBytes = Self.chebyshevTables * Self.recordFloats * MemoryLayout<Double>.size
        guard data.count >= offset + expectedTableBytes else {
            return false
        }

        self.mappedData = data
        return true
    }

    var isLoaded: Bool {
        return mappedData != nil
    }

    func getTableRecord(at index: Int) -> UnsafeBufferPointer<Double>? {
        guard let data = mappedData, index >= 0, index < Self.chebyshevTables else { return nil }
        let headerOffset = 125
        let recordByteOffset = headerOffset + (index * Self.recordFloats * MemoryLayout<Double>.size)
        return data.withUnsafeBytes { rawBuffer -> UnsafeBufferPointer<Double>? in
            guard let baseAddress = rawBuffer.baseAddress,
                  recordByteOffset + Self.recordFloats * MemoryLayout<Double>.size <= rawBuffer.count else {
                return nil
            }
            let base = baseAddress.advanced(by: recordByteOffset).assumingMemoryBound(to: Double.self)
            return UnsafeBufferPointer(start: base, count: Self.recordFloats)
        }
    }
}

// MARK: - Main CAAVSOP2013 Engine

private struct VSOP2013InternalState: Sendable {
    var binaryFilesDirectory: String = "."
    var ephemerideFiles: [VSOP2013EphemeridesFile] = (0..<6).map { _ in VSOP2013EphemeridesFile() }
}

public final class CAAVSOP2013: Sendable {
    public enum Planet: Int, Sendable, CaseIterable {
        case MERCURY = 0
        case VENUS = 1
        case EARTH_MOON_BARYCENTER = 2
        case MARS = 3
        case JUPITER = 4
        case SATURN = 5
        case URANUS = 6
        case NEPTUNE = 7
        case PLUTO = 8
    }

    public enum ExceptionReason: Sendable {
        case undefined
        case failedToOpenFile
        case planetIsInvalid
        case dateIsInvalid
        case couldNotLoadBinaryFile
    }

    public struct Exception: Error, Sendable {
        public let reason: ExceptionReason
        public init(_ reason: ExceptionReason) {
            self.reason = reason
        }
    }

    private let internalState: OSAllocatedUnfairLock<VSOP2013InternalState> = OSAllocatedUnfairLock(initialState: VSOP2013InternalState())

    private let dateRange: [Double] = [
        77294.5, 625198.5, 1173102.5, 1721006.5, 2268910.5, 2816814.5, 3364718.5
    ]

    private let ephemeridesFilenames: [String] = [
        "VSOP2013.M4000.bin", "VSOP2013.M2000.bin", "VSOP2013.M1000.bin",
        "VSOP2013.P1000.bin", "VSOP2013.P2000.bin", "VSOP2013.P4000.bin"
    ]

    public init() {}

    public func SetBinaryFilesDirectory(_ directory: String) {
        internalState.withLock { state in
            state.binaryFilesDirectory = directory
        }
    }

    public func GetBinaryFilesDirectory() -> String {
        internalState.withLock { state in
            state.binaryFilesDirectory
        }
    }

    public func Calculate(_ planet: Planet, _ JD: Double) -> CAAVSOP2013Position {
        if JD < 77294.5 || JD > 3364718.5 {
            return CAAVSOP2013Position()
        }
        if planet == .PLUTO && (JD < 2268910.5 || JD > 2816814.5) {
            return CAAVSOP2013Position()
        }

        return internalState.withLock { state in
            // Find file index
            var nIndex = 0
            for i in 1..<dateRange.count {
                if JD < dateRange[i] {
                    nIndex = i - 1
                    break
                }
            }
            if nIndex >= state.ephemerideFiles.count {
                nIndex = state.ephemerideFiles.count - 1
            }

            if !state.ephemerideFiles[nIndex].isLoaded {
                let fullPath = (state.binaryFilesDirectory as NSString).appendingPathComponent(ephemeridesFilenames[nIndex])
                if !state.ephemerideFiles[nIndex].readBinaryFile(at: fullPath) {
                    return CAAVSOP2013Position()
                }
            }

            let file = state.ephemerideFiles[nIndex]
            let iper = Int((JD - file.startJD) / VSOP2013EphemeridesFile.sizeBasicInterval)
            guard let aperiod = file.getTableRecord(at: iper) else {
                return CAAVSOP2013Position()
            }

        let pIdx = planet.rawValue
        let iad = Int(file.firstCoefficientRank[pIdx]) - 1
        let ncf = Int(file.coefficientsPerCoordinate[pIdx])
        let nsi = Int(file.subIntervals[pIdx])
        let delta2 = VSOP2013EphemeridesFile.sizeBasicInterval / Double(nsi)

        var ik = Int((JD - aperiod[0]) / delta2)
        if ik == nsi {
            ik -= 1
        }

        let iloc = iad + (6 * ncf * ik)
        let dj0 = aperiod[0] + (Double(ik) * delta2)
        let x = (2.0 * (JD - dj0) / delta2) - 1.0

        // Chebyshev terms
        var tn = Array(repeating: 0.0, count: max(20, ncf))
        tn[0] = 1.0
        tn[1] = x
        for i in 2..<ncf {
            tn[i] = (2.0 * x * tn[i - 1]) - tn[i - 2]
        }

        // Calculate position and velocity
        var r = Array(repeating: 0.0, count: 6)
        for i in 0..<6 {
            var sum = 0.0
            for j in 0..<ncf {
                let jp = ncf - j - 1
                let jt = iloc + (ncf * i) + jp + 2
                if jt < aperiod.count {
                    sum += tn[jp] * aperiod[jt]
                }
            }
            r[i] = sum
        }

        return CAAVSOP2013Position(
            X: r[0], Y: r[1], Z: r[2],
            X_DASH: r[3], Y_DASH: r[4], Z_DASH: r[5]
        )
        }
    }

    public static func CalculateMeanMotion(_ planet: Planet, _ a: Double) -> Double {
        let gmsol = 2.9591220836841438269E-04
        let gmp: [Double] = [
            4.9125474514508118699E-11,
            7.2434524861627027000E-10,
            8.9970116036316091182E-10,
            9.5495351057792580598E-11,
            2.8253458420837780000E-07,
            8.4597151856806587398E-08,
            1.2920249167819693900E-08,
            1.5243589007842762800E-08,
            2.1886997654259696800E-12
        ]
        return SphericalTrigonometry.radiansToDegrees(sqrt(gmp[planet.rawValue] + gmsol) / pow(a, 1.5))
    }

    public static func OrbitToElements(_ JD: Double, _ planet: Planet, _ orbit: CAAVSOP2013Orbit) -> CAAEllipticalObjectElements {
        var elements = CAAEllipticalObjectElements()
        elements.a = orbit.a
        elements.e = sqrt((orbit.k * orbit.k) + (orbit.h * orbit.h))
        elements.i = SphericalTrigonometry.radiansToDegrees(2.0 * asin(sqrt((orbit.q * orbit.q) + (orbit.p * orbit.p))))
        let w = atan2(orbit.h, orbit.k)
        elements.omega = atan2(orbit.p, orbit.q)
        elements.w = SphericalTrigonometry.radiansToDegrees(SphericalTrigonometry.mapTo0To2PIRange(w - elements.omega))
        elements.omega = SphericalTrigonometry.radiansToDegrees(elements.omega)
        elements.JDEquinox = JD
        let meanMotion = CalculateMeanMotion(planet, orbit.a)
        elements.T = JD - SphericalTrigonometry.radiansToDegrees(orbit.lambda / meanMotion) + SphericalTrigonometry.radiansToDegrees(w / meanMotion)
        return elements
    }

    public static func Ecliptic2Equatorial(_ value: CAAVSOP2013Position) -> CAAVSOP2013Position {
        let coeff11 = 0.99999999999996836
        let coeff12 = 2.3076633339445195e-07
        let coeff13 = -1.0004940139786859e-07
        let coeff21 = -2.5152133775962465e-07
        let coeff22 = 0.91748213272857493
        let coeff23 = -0.39777699295429642
        let coeff32 = 0.39777699295430902
        let coeff33 = 0.91748213272860391

        var eq = CAAVSOP2013Position()
        eq.X = (coeff11 * value.X) + (coeff12 * value.Y) + (coeff13 * value.Z)
        eq.Y = (coeff21 * value.X) + (coeff22 * value.Y) + (coeff23 * value.Z)
        eq.Z = (coeff32 * value.Y) + (coeff33 * value.Z)
        eq.X_DASH = (coeff11 * value.X_DASH) + (coeff12 * value.Y_DASH) + (coeff13 * value.Z_DASH)
        eq.Y_DASH = (coeff21 * value.X_DASH) + (coeff22 * value.Y_DASH) + (coeff23 * value.Z_DASH)
        eq.Z_DASH = (coeff32 * value.Y_DASH) + (coeff33 * value.Z_DASH)
        return eq
    }
}
