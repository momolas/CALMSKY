//
//  StreamingSPKReader.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation
import Accelerate
import simd

/// Reader for SPK (Spacecraft and Planet Kernel) binary files operating in Dynamic Temporal Streaming mode.
///
/// Instead of reading a complete local file, `StreamingSPKReader` fetches only the necessary
/// byte slices over HTTP range requests using an underlying ``SPKRangeClient``.
///
/// ### Network Transfer Profile
/// - File & Summary records: $\approx 2\,\text{KB}$ (downloaded and cached once per kernel).
/// - Segment metadata: $32\,\text{bytes}$ (downloaded and cached once per segment).
/// - Logical record at epoch $t$: $\approx 240–480\,\text{bytes}$ per body.
public actor StreamingSPKReader {

    // MARK: - Types

    /// Segment Type 2 metadata stored in the segment trailer.
    private struct SegmentMetadata: Sendable {
        let initEpoch: Double
        let intlen: Double
        let rsize: Int
        let nCoeffs: Int
        let nRecords: Int
    }

    // MARK: - Properties

    /// The underlying range client.
    public let client: SPKRangeClient

    /// Cached segment descriptors.
    private var cachedSegments: [SPKReader.SegmentDescriptor]?

    /// Failure record if segments could not be fetched from remote server.
    private var segmentsError: Error?

    /// Endianness of the remote SPK file (most SPK files are Little Endian).
    private var isLittleEndian: Bool = true

    /// Cached segment metadata keyed by `startIndex`.
    private var metadataCache: [Int32: SegmentMetadata] = [:]

    /// In-flight task for segment descriptors to prevent request stampede.
    private var segmentsTask: Task<[SPKReader.SegmentDescriptor], Error>?

    // MARK: - Initialization

    /// Initializes a streaming SPK reader.
    public init(client: SPKRangeClient) {
        self.client = client
    }

    /// Convenience initializer from URLs.
    public init(
        primaryURL: URL,
        fallbackURL: URL? = nil,
        cacheDirectory: URL
    ) {
        self.client = SPKRangeClient(
            primaryURL: primaryURL,
            fallbackURL: fallbackURL,
            cacheDirectory: cacheDirectory
        )
    }

    // MARK: - Segment Descriptors

    /// Retrieves all segment descriptors from the remote SPK file via streaming.
    public func getSegments() async throws -> [SPKReader.SegmentDescriptor] {
        if let error = segmentsError {
            throw error
        }
        if let cached = cachedSegments {
            return cached
        }
        if let inFlight = segmentsTask {
            return try await inFlight.value
        }

        let task = Task { [self] () -> [SPKReader.SegmentDescriptor] in
            // 1. Fetch File Record (first 1024 bytes)
            let fileRecordData = try await client.fetchRange(startOffset: 0, length: 1024)
            guard fileRecordData.count >= 1024 else {
                throw EphemerisError.dataCorrupted("Truncated DAF file record: expected 1024 bytes, received \(fileRecordData.count)")
            }

            let slice = fileRecordData[fileRecordData.startIndex..<fileRecordData.startIndex + 8]
            let locidff = String(data: slice, encoding: .ascii) ?? ""
            guard locidff.hasPrefix("DAF") || locidff.hasPrefix("NAIF") else {
                throw EphemerisError.dataCorrupted("Remote file is not a valid DAF/SPK kernel: \(locidff)")
            }

            let littleEndian = readInt32(from: fileRecordData, at: 8, littleEndian: true) == 2
            let nd = readInt32(from: fileRecordData, at: 8, littleEndian: littleEndian)
            let ni = readInt32(from: fileRecordData, at: 12, littleEndian: littleEndian)

            guard nd == 2, ni == 6 else {
                throw EphemerisError.dataCorrupted("Unexpected DAF format: ND=\(nd), NI=\(ni)")
            }

            let fward = readInt32(from: fileRecordData, at: 76, littleEndian: littleEndian)

            // 2. Fetch Summary Records starting from FWARD
            var parsedSegments: [SPKReader.SegmentDescriptor] = []
            var currentRecord = Int(fward)

            while currentRecord > 0 {
                let recordOffset = (currentRecord - 1) * 1024
                let summaryRecordData = try await client.fetchRange(startOffset: recordOffset, length: 1024)
                guard summaryRecordData.count >= 24 else { break }

                let nextRecord = readDouble(from: summaryRecordData, at: 0, littleEndian: littleEndian)
                let nSummaries = readDouble(from: summaryRecordData, at: 16, littleEndian: littleEndian)
                let summaryCount = Int(nSummaries)
                let summarySize = (Int(nd) + (Int(ni) + 1) / 2) * 8

                for i in 0..<summaryCount {
                    let sOffset = 24 + i * summarySize
                    guard sOffset + summarySize <= summaryRecordData.count else { break }

                    let startEpoch = readDouble(from: summaryRecordData, at: sOffset, littleEndian: littleEndian)
                    let endEpoch = readDouble(from: summaryRecordData, at: sOffset + 8, littleEndian: littleEndian)

                    let intBase = sOffset + 16
                    let target = readInt32(from: summaryRecordData, at: intBase, littleEndian: littleEndian)
                    let center = readInt32(from: summaryRecordData, at: intBase + 4, littleEndian: littleEndian)
                    let frame = readInt32(from: summaryRecordData, at: intBase + 8, littleEndian: littleEndian)
                    let spkType = readInt32(from: summaryRecordData, at: intBase + 12, littleEndian: littleEndian)
                    let startAddr = readInt32(from: summaryRecordData, at: intBase + 16, littleEndian: littleEndian)
                    let endAddr = readInt32(from: summaryRecordData, at: intBase + 20, littleEndian: littleEndian)

                    parsedSegments.append(SPKReader.SegmentDescriptor(
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

            return parsedSegments
        }

        self.segmentsTask = task
        do {
            let segments = try await task.value
            self.cachedSegments = segments
            self.segmentsTask = nil
            return segments
        } catch {
            self.segmentsError = error
            self.segmentsTask = nil
            throw error
        }
    }

    /// Finds the segment for a target/center pair covering the given epoch.
    public func findSegment(targetID: Int32, centerID: Int32, epochTDB: Double) async throws -> SPKReader.SegmentDescriptor? {
        let segs = try await getSegments()
        return segs.last { seg in
            seg.targetID == targetID &&
            seg.centerID == centerID &&
            seg.dataType == 2 &&
            epochTDB >= seg.startEpoch &&
            epochTDB <= seg.endEpoch
        }
    }

    // MARK: - Dynamic Streaming Evaluation

    /// Evaluates a Type 2 segment at an epoch by streaming only the required record slice.
    public func evaluate(
        segment: SPKReader.SegmentDescriptor,
        epochTDB: Double
    ) async throws -> SPKReader.EvaluationResult {
        guard segment.dataType == 2 else {
            throw EphemerisError.dataCorrupted("Only SPK Type 2 is supported in streaming mode, got Type \(segment.dataType)")
        }

        guard epochTDB.isFinite else {
            throw EphemerisError.dateOutOfRange(JulianDay(SPKReader.tdbSecondsToJulianDay(epochTDB)))
        }

        // 1. Fetch or reuse segment metadata (trailer: last 32 bytes)
        let meta = try await getSegmentMetadata(segment: segment)

        guard meta.intlen > 0, meta.rsize > 0, meta.nRecords > 0, meta.nCoeffs > 0 else {
            throw EphemerisError.dataCorrupted("Invalid segment metadata for target \(segment.targetID)")
        }

        // 2. Compute exact record index clamped to [0, nRecords - 1] and byte range
        let recordIndex = min(max(0, Int((epochTDB - meta.initEpoch) / meta.intlen)), max(1, meta.nRecords) - 1)
        let recordStartAddr = Int(segment.startIndex) - 1 + recordIndex * meta.rsize
        let recordByteOffset = recordStartAddr * 8
        let recordByteLength = meta.rsize * 8

        guard recordIndex >= 0,
              recordStartAddr >= Int(segment.startIndex) - 1,
              recordStartAddr + meta.rsize <= Int(segment.endIndex) - 4,
              recordByteOffset >= 0 else {
            throw EphemerisError.dateOutOfRange(JulianDay(SPKReader.tdbSecondsToJulianDay(epochTDB)))
        }

        // 3. Fetch exact logical record slice (around 240–480 bytes)
        let recordData = try await client.fetchRange(startOffset: recordByteOffset, length: recordByteLength)
        guard recordData.count >= recordByteLength else {
            throw EphemerisError.dataCorrupted("Truncated record slice received: \(recordData.count) < \(recordByteLength)")
        }

        let midpoint = readDouble(from: recordData, at: 0, littleEndian: isLittleEndian)
        let radius = readDouble(from: recordData, at: 8, littleEndian: isLittleEndian)

        guard radius > 0 else {
            throw EphemerisError.dataCorrupted("Invalid record radius: \(radius)")
        }

        let tau = (epochTDB - midpoint) / radius
        let coeffsBase = 16

        let (pos, vel) = evaluateChebyshevAndDerivative3D(data: recordData, baseOffset: coeffsBase, nCoeffs: meta.nCoeffs, tau: tau, radius: radius)

        return SPKReader.EvaluationResult(
            position: Vector3D(pos),
            velocity: Vector3D(vel)
        )
    }

    // MARK: - Private Helpers

    private func getSegmentMetadata(segment: SPKReader.SegmentDescriptor) async throws -> SegmentMetadata {
        if let meta = metadataCache[segment.startIndex] {
            return meta
        }

        let endAddr = Int(segment.endIndex)
        let metaOffset = (endAddr - 4) * 8

        let trailerData = try await client.fetchRange(startOffset: metaOffset, length: 32)
        guard trailerData.count >= 32 else {
            throw EphemerisError.dataCorrupted("Truncated segment trailer: expected 32 bytes, got \(trailerData.count)")
        }

        if let existing = metadataCache[segment.startIndex] {
            return existing
        }

        let initEpoch = readDouble(from: trailerData, at: 0, littleEndian: isLittleEndian)
        let intlen = readDouble(from: trailerData, at: 8, littleEndian: isLittleEndian)
        let rsize = Int(readDouble(from: trailerData, at: 16, littleEndian: isLittleEndian))
        let nRecords = Int(readDouble(from: trailerData, at: 24, littleEndian: isLittleEndian))
        let nCoeffs = (rsize - 2) / 3

        guard intlen > 0, rsize > 0, nRecords > 0, nCoeffs > 0 else {
            throw EphemerisError.dataCorrupted("Invalid segment metadata for target \(segment.targetID): intlen=\(intlen), rsize=\(rsize), n=\(nRecords)")
        }

        let meta = SegmentMetadata(initEpoch: initEpoch, intlen: intlen, rsize: rsize, nCoeffs: nCoeffs, nRecords: nRecords)
        metadataCache[segment.startIndex] = meta
        return meta
    }

    private func evaluateChebyshevAndDerivative3D(data: Data, baseOffset: Int, nCoeffs: Int, tau: Double, radius: Double) -> (position: simd_double3, velocity: simd_double3) {
        guard nCoeffs > 0 else {
            return (simd_double3(0, 0, 0), simd_double3(0, 0, 0))
        }

        let twoTau = 2.0 * tau
        let strideY = nCoeffs * 8
        let strideZ = nCoeffs * 16

        return data.withUnsafeBytes { buffer in
            guard let basePtr = buffer.baseAddress,
                  baseOffset >= 0,
                  baseOffset + 3 * nCoeffs * 8 <= buffer.count else {
                return (simd_double3(0, 0, 0), simd_double3(0, 0, 0))
            }

            @inline(__always)
            func loadCoeff3D(offset: Int) -> simd_double3 {
                let pX = basePtr.advanced(by: offset)
                let pY = basePtr.advanced(by: offset + strideY)
                let pZ = basePtr.advanced(by: offset + strideZ)

                let rawX = pX.loadUnaligned(as: UInt64.self)
                let rawY = pY.loadUnaligned(as: UInt64.self)
                let rawZ = pZ.loadUnaligned(as: UInt64.self)

                let valX = isLittleEndian ? UInt64(littleEndian: rawX) : UInt64(bigEndian: rawX)
                let valY = isLittleEndian ? UInt64(littleEndian: rawY) : UInt64(bigEndian: rawY)
                let valZ = isLittleEndian ? UInt64(littleEndian: rawZ) : UInt64(bigEndian: rawZ)

                return simd_double3(Double(bitPattern: valX), Double(bitPattern: valY), Double(bitPattern: valZ))
            }

            if nCoeffs == 1 {
                let c0 = loadCoeff3D(offset: baseOffset)
                return (c0, simd_double3(0, 0, 0))
            }

            var s1 = simd_double3(0, 0, 0)
            var s2 = simd_double3(0, 0, 0)
            var d1 = simd_double3(0, 0, 0)
            var d2 = simd_double3(0, 0, 0)

            for i in stride(from: nCoeffs - 1, through: 1, by: -1) {
                let offset = baseOffset + i * 8
                let coeff = loadCoeff3D(offset: offset)

                // Exact analytical derivative of Clenshaw recurrence:
                let d0 = 2.0 * (s1 + tau * d1) - d2
                d2 = d1
                d1 = d0

                // Position Clenshaw recurrence:
                let s0 = twoTau * s1 - s2 + coeff
                s2 = s1
                s1 = s0
            }

            let c0 = loadCoeff3D(offset: baseOffset)
            let pos = tau * s1 - s2 + c0
            let vel = (s1 + tau * d1 - d2) / radius
            return (pos, vel)
        }
    }

    private func readDouble(from data: Data, at offset: Int, littleEndian: Bool) -> Double {
        data.withUnsafeBytes { buffer in
            guard offset >= 0, offset + MemoryLayout<UInt64>.size <= buffer.count else { return 0.0 }
            let raw = buffer.loadUnaligned(fromByteOffset: offset, as: UInt64.self)
            let value = littleEndian ? UInt64(littleEndian: raw) : UInt64(bigEndian: raw)
            return Double(bitPattern: value)
        }
    }

    private func readInt32(from data: Data, at offset: Int, littleEndian: Bool) -> Int32 {
        data.withUnsafeBytes { buffer in
            guard offset >= 0, offset + MemoryLayout<UInt32>.size <= buffer.count else { return 0 }
            let raw = buffer.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
            let value = littleEndian ? UInt32(littleEndian: raw) : UInt32(bigEndian: raw)
            return Int32(bitPattern: value)
        }
    }
}
