//
//  VSOP2013Reader.swift
//  AstronomyKit
//
//  Pure Swift VSOP2013 ephemerides reader and Chebyshev polynomial evaluator.
//  Replaces CAAVSOP2013 from AAplus.
//

import Foundation
import Accelerate
import simd
import os

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

    func withTableRecord<R>(at index: Int, _ body: (UnsafeBufferPointer<Double>) -> R) -> R? {
        guard let data = mappedData, index >= 0, index < Self.chebyshevTables else { return nil }
        let headerOffset = 125
        let recordByteOffset = headerOffset + (index * Self.recordFloats * MemoryLayout<Double>.size)
        return data.withUnsafeBytes { rawBuffer -> R? in
            guard let baseAddress = rawBuffer.baseAddress,
                  recordByteOffset + Self.recordFloats * MemoryLayout<Double>.size <= rawBuffer.count else {
                return nil
            }
            let base = baseAddress.advanced(by: recordByteOffset).assumingMemoryBound(to: Double.self)
            let buffer = UnsafeBufferPointer(start: base, count: Self.recordFloats)
            return body(buffer)
        }
    }
}

// MARK: - Main CAAVSOP2013 Engine

private struct VSOP2013InternalState: Sendable {
    var binaryFilesDirectory: String = "."
    var ephemerideFiles: [VSOP2013EphemeridesFile] = (0..<6).map { _ in VSOP2013EphemeridesFile() }
}

@available(*, deprecated, message: "CAAVSOP2013 analytical reader is deprecated. Use SPKReader with numerical SPK kernels (DE442s, INPOP21a, etc.).")
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
            return file.withTableRecord(at: iper) { aperiod in
                let pIdx = planet.rawValue
                let iad = Int(file.firstCoefficientRank[pIdx]) - 1
                let ncf = Int(file.coefficientsPerCoordinate[pIdx])
                let nsi = Int(file.subIntervals[pIdx])
                guard nsi > 0, ncf > 0, let aperiodBase = aperiod.baseAddress else {
                    return CAAVSOP2013Position()
                }
                let delta2 = VSOP2013EphemeridesFile.sizeBasicInterval / Double(nsi)

                var ik = Int((JD - aperiod[0]) / delta2)
                if ik == nsi {
                    ik -= 1
                }

                let iloc = iad + (6 * ncf * ik)
                let dj0 = aperiod[0] + (Double(ik) * delta2)
                let x = (2.0 * (JD - dj0) / delta2) - 1.0

                return withUnsafeTemporaryAllocation(of: Double.self, capacity: max(32, ncf)) { tnBuffer in
                    guard let tn = tnBuffer.baseAddress else {
                        return CAAVSOP2013Position()
                    }
                    tn[0] = 1.0
                    if ncf > 1 {
                        tn[1] = x
                        let twoX = 2.0 * x
                        for i in 2..<ncf {
                            tn[i] = (twoX * tn[i - 1]) - tn[i - 2]
                        }
                    }

                    var r0 = 0.0, r1 = 0.0, r2 = 0.0, r3 = 0.0, r4 = 0.0, r5 = 0.0
                    let len = vDSP_Length(ncf)

                    let jt0 = iloc + 2
                    if jt0 + ncf <= aperiod.count { vDSP_dotprD(tn, 1, aperiodBase + jt0, 1, &r0, len) }
                    let jt1 = iloc + ncf + 2
                    if jt1 + ncf <= aperiod.count { vDSP_dotprD(tn, 1, aperiodBase + jt1, 1, &r1, len) }
                    let jt2 = iloc + 2 * ncf + 2
                    if jt2 + ncf <= aperiod.count { vDSP_dotprD(tn, 1, aperiodBase + jt2, 1, &r2, len) }
                    let jt3 = iloc + 3 * ncf + 2
                    if jt3 + ncf <= aperiod.count { vDSP_dotprD(tn, 1, aperiodBase + jt3, 1, &r3, len) }
                    let jt4 = iloc + 4 * ncf + 2
                    if jt4 + ncf <= aperiod.count { vDSP_dotprD(tn, 1, aperiodBase + jt4, 1, &r4, len) }
                    let jt5 = iloc + 5 * ncf + 2
                    if jt5 + ncf <= aperiod.count { vDSP_dotprD(tn, 1, aperiodBase + jt5, 1, &r5, len) }

                    return CAAVSOP2013Position(
                        X: r0, Y: r1, Z: r2,
                        X_DASH: r3, Y_DASH: r4, Z_DASH: r5
                    )
                }
            } ?? CAAVSOP2013Position()
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

    @usableFromInline
    internal static let eclipticToEquatorialMatrix = simd_double3x3(rows: [
        simd_double3(0.99999999999996836, 2.3076633339445195e-07, -1.0004940139786859e-07),
        simd_double3(-2.5152133775962465e-07, 0.91748213272857493, -0.39777699295429642),
        simd_double3(0.0, 0.39777699295430902, 0.91748213272860391)
    ])

    @inlinable
    public static func Ecliptic2Equatorial(_ value: CAAVSOP2013Position) -> CAAVSOP2013Position {
        let pos = eclipticToEquatorialMatrix * simd_double3(value.X, value.Y, value.Z)
        let vel = eclipticToEquatorialMatrix * simd_double3(value.X_DASH, value.Y_DASH, value.Z_DASH)
        return CAAVSOP2013Position(
            X: pos.x, Y: pos.y, Z: pos.z,
            X_DASH: vel.x, Y_DASH: vel.y, Z_DASH: vel.z
        )
    }
}
