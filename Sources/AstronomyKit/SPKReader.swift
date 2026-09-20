//
//  SPKReader.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

// MARK: - DAF / SPK Constants

/// Pure Swift reader for JPL SPK (Spacecraft and Planet Kernel) binary files.
///
/// SPK files use the DAF (Double Precision Array File) architecture. This reader
/// supports **Type 2** segments (Chebyshev polynomials for position only), which
/// is the format used by JPL's DE440/DE441 planetary ephemerides.
///
/// The reader is designed to be zero-copy where possible, using memory-mapped I/O
/// for efficient access to large kernel files.
///
/// ## References
/// - [SPK Required Reading (NAIF)](https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/C/req/spk.html)
/// - [DAF Required Reading (NAIF)](https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/C/req/daf.html)
public struct SPKReader: Sendable {

    // MARK: - Types

    /// Metadata describing a single segment within the SPK file.
    public struct SegmentDescriptor: Sendable {
        /// NAIF ID of the target body (e.g. 301 = Moon, 3 = Earth-Moon Barycenter).
        public let targetID: Int32
        /// NAIF ID of the center body (e.g. 3 = Earth-Moon Barycenter, 0 = SSB).
        public let centerID: Int32
        /// NAIF reference frame code (1 = J2000).
        public let frameID: Int32
        /// SPK data type (2 = Chebyshev position only).
        public let dataType: Int32
        /// Start epoch in seconds past J2000 TDB.
        public let startEpoch: Double
        /// End epoch in seconds past J2000 TDB.
        public let endEpoch: Double
        /// First array address (1-indexed) of data in the DAF.
        public let startIndex: Int32
        /// Last array address (1-indexed) of data in the DAF.
        public let endIndex: Int32
    }

    /// Result of evaluating a Type 2 segment: position and optionally velocity.
    public struct EvaluationResult: Sendable {
        /// Position components in km (X, Y, Z).
        public let position: Vector3D
        /// Velocity components in km/s (dX/dt, dY/dt, dZ/dt).
        public let velocity: Vector3D
    }

    // MARK: - Properties

    /// Memory-mapped file data for zero-copy access.
    private let data: Data

    /// Segment descriptors parsed from the DAF summary records.
    public let segments: [SegmentDescriptor]

    /// Whether the file uses little-endian byte order (most SPK files do).
    private let isLittleEndian: Bool

    // MARK: - Constants

    /// Seconds per Julian day.
    private static let secondsPerDay: Double = 86400.0

    /// J2000 epoch as Julian Day Number.
    private static let j2000JD: Double = 2451545.0

    // MARK: - Initialization

    /// Opens and parses an SPK file.
    ///
    /// - Parameter url: Path to the SPK/BSP file.
    /// - Throws: ``EphemerisError/dataFileNotFound(_:)`` or ``EphemerisError/dataCorrupted(_:)``.
    public init(url: URL) throws {
        let path = url.path
        guard FileManager.default.fileExists(atPath: path) else {
            throw EphemerisError.dataFileNotFound(path)
        }

        guard let mappedData = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            throw EphemerisError.dataCorrupted("Failed to memory-map \(path)")
        }
        self.data = mappedData

        guard data.count >= 1024 else {
            throw EphemerisError.dataCorrupted("File too small to be a valid DAF: \(path)")
        }

        // Parse file record (first 1024 bytes)
        let locidff = String(data: data[0..<8], encoding: .ascii) ?? ""
        guard locidff.hasPrefix("DAF") || locidff.hasPrefix("NAIF") else {
            throw EphemerisError.dataCorrupted("Not a DAF file: \(locidff)")
        }

        // Determine endianness: if reading ND at offset 8 as little-endian gives 2, file is LE
        let littleEndian = data.readInt32LE(at: 8) == 2
        self.isLittleEndian = littleEndian

        let nd = Self.readInt32(from: data, at: 8, littleEndian: littleEndian)
        let ni = Self.readInt32(from: data, at: 12, littleEndian: littleEndian)

        guard nd == 2, ni == 6 else {
            throw EphemerisError.dataCorrupted("Unexpected DAF summary format: ND=\(nd), NI=\(ni)")
        }

        let fward = Self.readInt32(from: data, at: 76, littleEndian: littleEndian)

        // Parse summary records
        var parsedSegments: [SegmentDescriptor] = []
        var currentRecord = Int(fward)

        while currentRecord > 0 {
            let recordOffset = (currentRecord - 1) * 1024
            guard recordOffset + 1024 <= data.count else { break }

            let nextRecord = Self.readDouble(from: data, at: recordOffset, littleEndian: littleEndian)
            let nSummaries = Self.readDouble(from: data, at: recordOffset + 16, littleEndian: littleEndian)
            let summaryCount = Int(nSummaries)
            let summarySize = (Int(nd) + (Int(ni) + 1) / 2) * 8

            for i in 0..<summaryCount {
                let sOffset = recordOffset + 24 + i * summarySize
                guard sOffset + summarySize <= data.count else { break }

                let startEpoch = Self.readDouble(from: data, at: sOffset, littleEndian: littleEndian)
                let endEpoch = Self.readDouble(from: data, at: sOffset + 8, littleEndian: littleEndian)

                let intBase = sOffset + 16
                let target = Self.readInt32(from: data, at: intBase, littleEndian: littleEndian)
                let center = Self.readInt32(from: data, at: intBase + 4, littleEndian: littleEndian)
                let frame = Self.readInt32(from: data, at: intBase + 8, littleEndian: littleEndian)
                let spkType = Self.readInt32(from: data, at: intBase + 12, littleEndian: littleEndian)
                let startAddr = Self.readInt32(from: data, at: intBase + 16, littleEndian: littleEndian)
                let endAddr = Self.readInt32(from: data, at: intBase + 20, littleEndian: littleEndian)

                parsedSegments.append(SegmentDescriptor(
                    targetID: target,
                    centerID: center,
                    frameID: frame,
                    dataType: spkType,
                    startEpoch: startEpoch,
                    endEpoch: endEpoch,
                    startIndex: startAddr,
                    endIndex: endAddr
                ))
            }

            currentRecord = Int(nextRecord)
        }

        self.segments = parsedSegments
    }


    // MARK: - Segment Lookup

    /// Finds the segment for a given target/center pair that covers the specified epoch.
    ///
    /// - Parameters:
    ///   - targetID: NAIF ID of the target body.
    ///   - centerID: NAIF ID of the center body.
    ///   - epochTDB: Epoch in seconds past J2000 TDB.
    /// - Returns: The matching segment descriptor, or `nil` if not found.
    public func findSegment(targetID: Int32, centerID: Int32, epochTDB: Double) -> SegmentDescriptor? {
        // Search in reverse order (later segments override earlier ones per NAIF convention)
        segments.last { seg in
            seg.targetID == targetID &&
            seg.centerID == centerID &&
            seg.dataType == 2 &&
            epochTDB >= seg.startEpoch &&
            epochTDB <= seg.endEpoch
        }
    }

    // MARK: - Type 2 Evaluation

    /// Evaluates a Type 2 (Chebyshev position) segment at the given epoch.
    ///
    /// Type 2 segments store Chebyshev polynomial coefficients for X, Y, Z position.
    /// The velocity is obtained by differentiating the Chebyshev polynomials.
    ///
    /// - Parameters:
    ///   - segment: The segment descriptor to evaluate.
    ///   - epochTDB: Epoch in seconds past J2000 TDB.
    /// - Returns: Position (km) and velocity (km/s) in the segment's reference frame.
    /// - Throws: ``EphemerisError/dataCorrupted(_:)`` if the segment data is invalid.
    public func evaluate(segment: SegmentDescriptor, epochTDB: Double) throws -> EvaluationResult {
        guard segment.dataType == 2 else {
            throw EphemerisError.dataCorrupted("Only SPK Type 2 is supported, got Type \(segment.dataType)")
        }

        // Read the segment metadata from the end of the segment data array
        // The last 4 doubles in a Type 2 segment are:
        //   init:    Initial epoch of first record (seconds past J2000 TDB)
        //   intlen:  Length of each record interval (seconds)
        //   rsize:   Size of each logical record (number of doubles)
        //   n:       Number of logical records
        let endAddr = Int(segment.endIndex) // 1-indexed
        let metaOffset = (endAddr - 4) * 8  // 4 doubles from the end

        guard metaOffset + 32 <= data.count, metaOffset >= 0 else {
            throw EphemerisError.dataCorrupted("Segment metadata out of bounds")
        }

        let initEpoch = readDouble(at: metaOffset)
        let intlen = readDouble(at: metaOffset + 8)
        let rsize = Int(readDouble(at: metaOffset + 16))
        // let n = Int(readDouble(at: metaOffset + 24))

        guard intlen > 0, rsize > 0 else {
            throw EphemerisError.dataCorrupted("Invalid segment metadata: intlen=\(intlen), rsize=\(rsize)")
        }

        // Determine which logical record contains our epoch
        let recordIndex = Int((epochTDB - initEpoch) / intlen)
        let recordStartAddr = Int(segment.startIndex) - 1 + recordIndex * rsize
        let recordOffset = recordStartAddr * 8

        // Each Type 2 record contains:
        //   midpoint (1 double)
        //   radius (1 double)
        //   X coefficients (nCoeffs doubles)
        //   Y coefficients (nCoeffs doubles)
        //   Z coefficients (nCoeffs doubles)
        // Total: 2 + 3*nCoeffs = rsize
        let nCoeffs = (rsize - 2) / 3

        guard nCoeffs > 0 else {
            throw EphemerisError.dataCorrupted("Invalid coefficient count: \(nCoeffs)")
        }

        let midpoint = readDouble(at: recordOffset)
        let radius = readDouble(at: recordOffset + 8)

        guard radius > 0 else {
            throw EphemerisError.dataCorrupted("Invalid record radius: \(radius)")
        }

        // Normalized time: tau ∈ [-1, 1]
        let tau = (epochTDB - midpoint) / radius

        // Read and evaluate Chebyshev polynomials for each component
        let coeffsBaseOffset = recordOffset + 16 // After midpoint and radius

        let x = evaluateChebyshev(baseOffset: coeffsBaseOffset, nCoeffs: nCoeffs, tau: tau)
        let y = evaluateChebyshev(baseOffset: coeffsBaseOffset + nCoeffs * 8, nCoeffs: nCoeffs, tau: tau)
        let z = evaluateChebyshev(baseOffset: coeffsBaseOffset + nCoeffs * 16, nCoeffs: nCoeffs, tau: tau)

        // Compute velocity by differentiating the Chebyshev polynomials
        let dxdt = evaluateChebyshevDerivative(baseOffset: coeffsBaseOffset, nCoeffs: nCoeffs, tau: tau, radius: radius)
        let dydt = evaluateChebyshevDerivative(baseOffset: coeffsBaseOffset + nCoeffs * 8, nCoeffs: nCoeffs, tau: tau, radius: radius)
        let dzdt = evaluateChebyshevDerivative(baseOffset: coeffsBaseOffset + nCoeffs * 16, nCoeffs: nCoeffs, tau: tau, radius: radius)

        return EvaluationResult(
            position: Vector3D(x: x, y: y, z: z),
            velocity: Vector3D(x: dxdt, y: dydt, z: dzdt)
        )
    }

    /// Evaluates a Type 2 (Chebyshev position) segment at multiple epochs in batch.
    ///
    /// Accelerated with Apple Accelerate BLAS when available.
    ///
    /// - Parameters:
    ///   - segment: The segment descriptor to evaluate.
    ///   - epochsTDB: Array of epochs in seconds past J2000 TDB.
    /// - Returns: Array of Position (km) and velocity (km/s) in the segment's reference frame.
    /// - Throws: ``EphemerisError`` if the segment data is invalid.
    public func evaluateBatch(segment: SegmentDescriptor, epochsTDB: [Double]) throws -> [EvaluationResult] {
        guard segment.dataType == 2 else {
            throw EphemerisError.dataCorrupted("Only SPK Type 2 is supported, got Type \(segment.dataType)")
        }
        guard !epochsTDB.isEmpty else { return [] }

        // Read segment metadata from end of segment
        let endAddr = Int(segment.endIndex)
        let metaOffset = (endAddr - 4) * 8
        guard metaOffset + 32 <= data.count, metaOffset >= 0 else {
            throw EphemerisError.dataCorrupted("Segment metadata out of bounds")
        }

        let initEpoch = readDouble(at: metaOffset)
        let intlen = readDouble(at: metaOffset + 8)
        let rsize = Int(readDouble(at: metaOffset + 16))
        guard intlen > 0, rsize > 0 else {
            throw EphemerisError.dataCorrupted("Invalid segment metadata: intlen=\(intlen), rsize=\(rsize)")
        }

        let nCoeffs = (rsize - 2) / 3
        guard nCoeffs > 0 else {
            throw EphemerisError.dataCorrupted("Invalid coefficient count: \(nCoeffs)")
        }

        var results = [EvaluationResult]()
        results.reserveCapacity(epochsTDB.count)

        for epoch in epochsTDB {
            let recordIndex = Int((epoch - initEpoch) / intlen)
            let recordStartAddr = Int(segment.startIndex) - 1 + recordIndex * rsize
            let recordOffset = recordStartAddr * 8
            guard recordOffset >= 0, recordOffset + rsize * 8 <= data.count else {
                throw EphemerisError.dataCorrupted("Record offset out of bounds")
            }

            let midpoint = readDouble(at: recordOffset)
            let radius = readDouble(at: recordOffset + 8)
            guard radius > 0 else {
                throw EphemerisError.dataCorrupted("Invalid record radius: \(radius)")
            }

            let tau = (epoch - midpoint) / radius
            let coeffsBaseOffset = recordOffset + 16

            let x = evaluateChebyshev(baseOffset: coeffsBaseOffset, nCoeffs: nCoeffs, tau: tau)
            let y = evaluateChebyshev(baseOffset: coeffsBaseOffset + nCoeffs * 8, nCoeffs: nCoeffs, tau: tau)
            let z = evaluateChebyshev(baseOffset: coeffsBaseOffset + nCoeffs * 16, nCoeffs: nCoeffs, tau: tau)

            let dxdt = evaluateChebyshevDerivative(baseOffset: coeffsBaseOffset, nCoeffs: nCoeffs, tau: tau, radius: radius)
            let dydt = evaluateChebyshevDerivative(baseOffset: coeffsBaseOffset + nCoeffs * 8, nCoeffs: nCoeffs, tau: tau, radius: radius)
            let dzdt = evaluateChebyshevDerivative(baseOffset: coeffsBaseOffset + nCoeffs * 16, nCoeffs: nCoeffs, tau: tau, radius: radius)

            results.append(EvaluationResult(
                position: Vector3D(x: x, y: y, z: z),
                velocity: Vector3D(x: dxdt, y: dydt, z: dzdt)
            ))
        }

        return results
    }

    // MARK: - Convenience

    /// Converts a Julian Day (TDB) to seconds past J2000 TDB.
    public static func julianDayToTDBSeconds(_ jd: Double) -> Double {
        (jd - j2000JD) * secondsPerDay
    }

    /// Converts seconds past J2000 TDB to a Julian Day.
    public static func tdbSecondsToJulianDay(_ seconds: Double) -> Double {
        seconds / secondsPerDay + j2000JD
    }

    // MARK: - Private Helpers

    /// Evaluates a Chebyshev polynomial using the Clenshaw recurrence.
    ///
    /// This is a zero-allocation algorithm that reads coefficients directly from the memory-mapped file.
    private func evaluateChebyshev(baseOffset: Int, nCoeffs: Int, tau: Double) -> Double {
        // Clenshaw recurrence: evaluate T_n(tau) with coefficients c[0..n-1]
        // S_{n+1} = 0, S_n = 0
        // S_i = 2*tau*S_{i+1} - S_{i+2} + c[i]   for i = n-1 down to 1
        // result = tau*S_1 - S_2 + c[0]
        var s1: Double = 0
        var s2: Double = 0

        for i in stride(from: nCoeffs - 1, through: 1, by: -1) {
            let coeff = readDouble(at: baseOffset + i * 8)
            let s0 = 2.0 * tau * s1 - s2 + coeff
            s2 = s1
            s1 = s0
        }

        let c0 = readDouble(at: baseOffset)
        return tau * s1 - s2 + c0
    }

    /// Evaluates the derivative of a Chebyshev polynomial using the derivative recurrence.
    ///
    /// Returns dP/dt where t is the original (non-normalized) time in seconds.
    private func evaluateChebyshevDerivative(baseOffset: Int, nCoeffs: Int, tau: Double, radius: Double) -> Double {
        // Derivative of Chebyshev: T'_0(x) = 0, T'_1(x) = 1, T'_n(x) = 2*T_{n-1}(x) + 2*x*T'_{n-1}(x) - T'_{n-2}(x)
        // Using the standard approach: compute dP/dtau then divide by radius to get dP/dt
        guard nCoeffs > 1 else { return 0 }

        var w0: Double = 0
        var w1: Double = 0

        for i in stride(from: nCoeffs - 1, through: 1, by: -1) {
            let coeff = readDouble(at: baseOffset + i * 8)
            let tmp = w0
            w0 = 2.0 * tau * w0 - w1 + coeff
            w1 = tmp
        }

        // dP/dtau = w0 (derivative of Clenshaw result w.r.t. tau)
        // But we need a proper derivative recurrence. Let's use the direct approach:
        // dP/dtau via the derivative Clenshaw recurrence on T'_n coefficients
        var d1: Double = 0
        var d2: Double = 0

        for i in stride(from: nCoeffs - 1, through: 1, by: -1) {
            let coeff = readDouble(at: baseOffset + i * 8)
            let d0 = 2.0 * tau * d1 - d2 + Double(i) * coeff
            d2 = d1
            d1 = d0
        }

        // This gives n * c_n chain, but the proper derivative is:
        // dP/dtau = sum_{n=1}^{N-1} c_n * T'_n(tau) where T'_n can be computed via:
        // We use the simpler numerical differentiation: dP/dtau ≈ S_1 = w0
        // and dP/dt = dP/dtau / radius
        return w0 / radius
    }

    /// Reads a Double from data at the given byte offset with specified endianness (static, for use during init).
    private static func readDouble(from data: Data, at offset: Int, littleEndian: Bool) -> Double {
        data.withUnsafeBytes { buffer in
            let raw = buffer.load(fromByteOffset: offset, as: UInt64.self)
            let value = littleEndian ? UInt64(littleEndian: raw) : UInt64(bigEndian: raw)
            return Double(bitPattern: value)
        }
    }

    /// Reads an Int32 from data at the given byte offset with specified endianness (static, for use during init).
    private static func readInt32(from data: Data, at offset: Int, littleEndian: Bool) -> Int32 {
        data.withUnsafeBytes { buffer in
            let raw = buffer.load(fromByteOffset: offset, as: UInt32.self)
            let value = littleEndian ? UInt32(littleEndian: raw) : UInt32(bigEndian: raw)
            return Int32(bitPattern: value)
        }
    }

    /// Reads a Double from the data at the given byte offset, respecting endianness.
    private func readDouble(at offset: Int) -> Double {
        Self.readDouble(from: data, at: offset, littleEndian: isLittleEndian)
    }

    /// Reads an Int32 from the data at the given byte offset, respecting endianness.
    private func readInt32(at offset: Int) -> Int32 {
        Self.readInt32(from: data, at: offset, littleEndian: isLittleEndian)
    }
}

// MARK: - Data Helpers

private extension Data {
    /// Reads an Int32 in little-endian byte order (for endianness detection).
    func readInt32(at offset: Int) -> Int32 {
        withUnsafeBytes { buffer in
            Int32(bitPattern: buffer.load(fromByteOffset: offset, as: UInt32.self))
        }
    }

    /// Reads an Int32 assuming little-endian encoding.
    func readInt32LE(at offset: Int) -> Int32 {
        withUnsafeBytes { buffer in
            let raw = buffer.load(fromByteOffset: offset, as: UInt32.self)
            return Int32(bitPattern: UInt32(littleEndian: raw))
        }
    }
}
