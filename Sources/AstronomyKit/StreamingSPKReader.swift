//
//  StreamingSPKReader.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

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
    }

    // MARK: - Properties

    /// The underlying range client.
    public let client: SPKRangeClient

    /// Cached segment descriptors.
    private var cachedSegments: [SPKReader.SegmentDescriptor]?

    /// Endianness of the remote SPK file (most SPK files are Little Endian).
    private var isLittleEndian: Bool = true

    /// Cached segment metadata keyed by `startIndex`.
    private var metadataCache: [Int32: SegmentMetadata] = [:]

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
        if let cached = cachedSegments {
            return cached
        }

        // 1. Fetch File Record (first 1024 bytes)
        let fileRecordData = try await client.fetchRange(startOffset: 0, length: 1024)

        let locidff = String(data: fileRecordData[0..<8], encoding: .ascii) ?? ""
        guard locidff.hasPrefix("DAF") || locidff.hasPrefix("NAIF") else {
            throw EphemerisError.dataCorrupted("Remote file is not a valid DAF/SPK kernel: \(locidff)")
        }

        let littleEndian = readInt32(from: fileRecordData, at: 8, littleEndian: true) == 2
        self.isLittleEndian = littleEndian

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

        self.cachedSegments = parsedSegments
        return parsedSegments
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

        // 1. Fetch or reuse segment metadata (trailer: last 32 bytes)
        let meta = try await getSegmentMetadata(segment: segment)

        guard meta.intlen > 0, meta.rsize > 0, meta.nCoeffs > 0 else {
            throw EphemerisError.dataCorrupted("Invalid segment metadata for target \(segment.targetID)")
        }

        // 2. Compute exact record index and byte range
        let recordIndex = Int((epochTDB - meta.initEpoch) / meta.intlen)
        let recordStartAddr = Int(segment.startIndex) - 1 + recordIndex * meta.rsize
        let recordByteOffset = recordStartAddr * 8
        let recordByteLength = meta.rsize * 8

        // 3. Fetch exact logical record slice (around 240–480 bytes)
        let recordData = try await client.fetchRange(startOffset: recordByteOffset, length: recordByteLength)

        let midpoint = readDouble(from: recordData, at: 0, littleEndian: isLittleEndian)
        let radius = readDouble(from: recordData, at: 8, littleEndian: isLittleEndian)

        guard radius > 0 else {
            throw EphemerisError.dataCorrupted("Invalid record radius: \(radius)")
        }

        let tau = (epochTDB - midpoint) / radius
        let coeffsBase = 16

        let x = evaluateChebyshev(data: recordData, baseOffset: coeffsBase, nCoeffs: meta.nCoeffs, tau: tau)
        let y = evaluateChebyshev(data: recordData, baseOffset: coeffsBase + meta.nCoeffs * 8, nCoeffs: meta.nCoeffs, tau: tau)
        let z = evaluateChebyshev(data: recordData, baseOffset: coeffsBase + meta.nCoeffs * 16, nCoeffs: meta.nCoeffs, tau: tau)

        let vx = evaluateChebyshevDerivative(data: recordData, baseOffset: coeffsBase, nCoeffs: meta.nCoeffs, tau: tau, radius: radius)
        let vy = evaluateChebyshevDerivative(data: recordData, baseOffset: coeffsBase + meta.nCoeffs * 8, nCoeffs: meta.nCoeffs, tau: tau, radius: radius)
        let vz = evaluateChebyshevDerivative(data: recordData, baseOffset: coeffsBase + meta.nCoeffs * 16, nCoeffs: meta.nCoeffs, tau: tau, radius: radius)

        return SPKReader.EvaluationResult(
            position: Vector3D(x: x, y: y, z: z),
            velocity: Vector3D(x: vx, y: vy, z: vz)
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

        let initEpoch = readDouble(from: trailerData, at: 0, littleEndian: isLittleEndian)
        let intlen = readDouble(from: trailerData, at: 8, littleEndian: isLittleEndian)
        let rsize = Int(readDouble(from: trailerData, at: 16, littleEndian: isLittleEndian))
        let nCoeffs = (rsize - 2) / 3

        let meta = SegmentMetadata(initEpoch: initEpoch, intlen: intlen, rsize: rsize, nCoeffs: nCoeffs)
        metadataCache[segment.startIndex] = meta
        return meta
    }

    private func evaluateChebyshev(data: Data, baseOffset: Int, nCoeffs: Int, tau: Double) -> Double {
        var s1: Double = 0
        var s2: Double = 0

        for i in stride(from: nCoeffs - 1, through: 1, by: -1) {
            let coeff = readDouble(from: data, at: baseOffset + i * 8, littleEndian: isLittleEndian)
            let s0 = 2.0 * tau * s1 - s2 + coeff
            s2 = s1
            s1 = s0
        }

        let c0 = readDouble(from: data, at: baseOffset, littleEndian: isLittleEndian)
        return tau * s1 - s2 + c0
    }

    private func evaluateChebyshevDerivative(data: Data, baseOffset: Int, nCoeffs: Int, tau: Double, radius: Double) -> Double {
        guard nCoeffs > 1 else { return 0 }
        var w0: Double = 0
        var w1: Double = 0

        for i in stride(from: nCoeffs - 1, through: 1, by: -1) {
            let coeff = readDouble(from: data, at: baseOffset + i * 8, littleEndian: isLittleEndian)
            let tmp = w0
            w0 = 2.0 * tau * w0 - w1 + coeff
            w1 = tmp
        }

        return w0 / radius
    }

    private func readDouble(from data: Data, at offset: Int, littleEndian: Bool) -> Double {
        data.withUnsafeBytes { buffer in
            let raw = buffer.load(fromByteOffset: offset, as: UInt64.self)
            let value = littleEndian ? UInt64(littleEndian: raw) : UInt64(bigEndian: raw)
            return Double(bitPattern: value)
        }
    }

    private func readInt32(from data: Data, at offset: Int, littleEndian: Bool) -> Int32 {
        data.withUnsafeBytes { buffer in
            let raw = buffer.load(fromByteOffset: offset, as: UInt32.self)
            let value = littleEndian ? UInt32(littleEndian: raw) : UInt32(bigEndian: raw)
            return Int32(bitPattern: value)
        }
    }
}
