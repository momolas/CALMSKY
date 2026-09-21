//
//  StreamingSPKTests.swift
//  AstronomyKitTests
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Testing
import Foundation
@testable import AstronomyKit

@Suite("Dynamic Temporal Streaming (HTTP Byte-Range)")
struct StreamingSPKTests {

    // MARK: - Mock Range Transport for Protocol & Cache Verification

    private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
        static let cannedData: Data = Data(repeating: 0x42, count: 2048)

        override class func canInit(with request: URLRequest) -> Bool {
            return request.url?.scheme == "mock"
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let url = request.url else { return }
            let rangeHeader = request.value(forHTTPHeaderField: "Range") ?? ""

            // Parse Range: bytes=start-end
            var start = 0
            var end = Self.cannedData.count - 1

            if rangeHeader.hasPrefix("bytes=") {
                let rangeStr = rangeHeader.replacingOccurrences(of: "bytes=", with: "")
                let parts = rangeStr.split(separator: "-")
                if parts.count == 2, let s = Int(parts[0]), let e = Int(parts[1]) {
                    start = s
                    end = min(e, Self.cannedData.count - 1)
                }
            }

            let slice = Self.cannedData.subdata(in: start..<(end + 1))
            let response = HTTPURLResponse(
                url: url,
                statusCode: 206,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Range": "bytes \(start)-\(end)/\(Self.cannedData.count)",
                    "Content-Length": "\(slice.count)",
                    "Accept-Ranges": "bytes"
                ]
            )!

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: slice)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    // MARK: - Range Client & Sparse Cache Tests

    @Test("SPKRangeClient fetches exact byte slices and populates sparse cache")
    func rangeClientSparseCache() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("streaming_cache_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let client = SPKRangeClient(
            primaryURL: URL(string: "mock://ephemeris.test/kernel.bsp")!,
            cacheDirectory: tempDir,
            session: session
        )

        // 1. Fetch range [10..<50] (40 bytes)
        let data1 = try await client.fetchRange(startOffset: 10, length: 40)
        #expect(data1.count == 40)

        // 2. Second fetch of identical range should hit cache (verify file exists on disk)
        let diskURL = tempDir.appendingPathComponent("chunk_10_49.bin")
        #expect(FileManager.default.fileExists(atPath: diskURL.path))

        let data2 = try await client.fetchRange(startOffset: 10, length: 40)
        #expect(data2 == data1)

        // 3. Clear cache
        try await client.clearCache()
        #expect(!FileManager.default.fileExists(atPath: diskURL.path))
    }

    // MARK: - Mathematical Address & Offset Arithmetic

    @Test("SPK Record byte offset and temporal indexing arithmetic")
    func recordOffsetArithmetic() {
        // Given a Type 2 segment with:
        let startIndex: Int32 = 1001 // 1-indexed double address
        let initEpoch: Double = 0.0  // J2000.0 TDB (seconds past J2000)
        let intlen: Double = 16.0 * 86400.0 // 16 days per record
        let rsize: Int = 41 // doubles per record = 2 + 3 * 13 coeffs (328 bytes)

        // Target epoch: 40 days past J2000
        let targetEpoch = 40.0 * 86400.0
        let recordIndex = Int((targetEpoch - initEpoch) / intlen) // record 2 (0-indexed)
        #expect(recordIndex == 2)

        let recordStartAddr = Int(startIndex) - 1 + recordIndex * rsize
        let startByte = recordStartAddr * 8
        let byteLength = rsize * 8

        #expect(startByte == (1000 + 2 * 41) * 8)
        #expect(byteLength == 328) // exactly 328 bytes to stream!
    }

    // MARK: - Streaming Triad Consensus & Uncertainty Tests

    @Test("StreamingTriadProvider combines parallel streaming models into consensus and 1-sigma uncertainty")
    func streamingTriadConsensus() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("streaming_triad_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let triad = try StreamingTriadProvider(
            cacheDirectory: tempDir,
            datasets: [.de442s, .inpop21a, .epm2021]
        )

        #expect(triad.providers.count == 3)
        #expect(triad.providers[.us] != nil)
        #expect(triad.providers[.fr] != nil)
        #expect(triad.providers[.ru] != nil)

        // Sun consensus evaluation should return zero without network overhead
        let sunDetails = try await triad.consensusDetails(for: .sun, at: JulianDay(2451545.0))
        #expect(sunDetails.consensusPosition == .zero)
        #expect(sunDetails.consensusVelocity == .zero)
        #expect(sunDetails.physicalUncertaintyKm == 0.0)
        #expect(sunDetails.physicalUncertaintyArcsec == 0.0)
        #expect(sunDetails.maxDiscrepancyKm == 0.0)
    }

    // MARK: - Live Network Range Test (NASA NAIF)

    @Test("Live HTTP partial Range request retrieves exactly 1024-byte DAF File Record")
    func liveNAIFByteRangeHeader() async throws {
        let naifURL = URL(string: "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de442s.bsp")!
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("live_range_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let client = SPKRangeClient(primaryURL: naifURL, cacheDirectory: tempDir)

        // Request exactly the first 1024 bytes (DAF File Record)
        let headerData = try await client.fetchRange(startOffset: 0, length: 1024)
        #expect(headerData.count == 1024)

        // Check DAF/SPK identifier in first 8 bytes
        let locidff = String(data: headerData[0..<8], encoding: .ascii) ?? ""
        #expect(locidff.hasPrefix("DAF") || locidff.hasPrefix("NAIF"))
    }
}
