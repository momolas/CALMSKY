//
//  EphemerisDataManager.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Identifies a downloadable ephemeris dataset from an official astronomical data center.
public enum EphemerisDataset: String, Sendable, CaseIterable, Identifiable {
    /// VSOP2013 planetary ephemerides covering the modern era (0–2000 CE).
    /// Source: IMCCE, Observatoire de Paris.
    case vsop2013Modern

    /// VSOP2013 planetary ephemerides with full coverage (−4000 to +8000 CE).
    /// Source: IMCCE, Observatoire de Paris.
    case vsop2013Full

    /// JPL DE440 lunar segments covering 1550–2650 CE (≈115 MB).
    /// Source: NASA NAIF/JPL.
    case lunarDE440

    /// JPL DE440s lunar segments covering 1900–2050 CE, more compact (≈32 MB).
    /// Source: NASA NAIF/JPL. Recommended for most applications.
    case lunarDE440s

    public var id: String { rawValue }

    /// Human-readable name of the dataset.
    public var name: String {
        switch self {
        case .vsop2013Modern: return "VSOP2013 Modern (0–2000 CE)"
        case .vsop2013Full: return "VSOP2013 Full (−4000 to +8000 CE)"
        case .lunarDE440: return "DE440 Lunar (1550–2650 CE)"
        case .lunarDE440s: return "DE440s Lunar (1900–2050 CE)"
        }
    }

    /// The remote URL of the official source.
    public var remoteURL: URL {
        switch self {
        case .vsop2013Modern:
            return URL(string: "https://ftp.imcce.fr/pub/ephem/planets/vsop2013/solution/VSOP2013.P2000.bin")!
        case .vsop2013Full:
            return URL(string: "https://ftp.imcce.fr/pub/ephem/planets/vsop2013/solution/VSOP2013.P4000.bin")!
        case .lunarDE440:
            return URL(string: "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de440.bsp")!
        case .lunarDE440s:
            return URL(string: "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de440s.bsp")!
        }
    }

    /// Expected filename for the local cache.
    public var filename: String {
        remoteURL.lastPathComponent
    }

    /// Official data source institution.
    public var source: String {
        switch self {
        case .vsop2013Modern, .vsop2013Full:
            return "IMCCE – Observatoire de Paris"
        case .lunarDE440, .lunarDE440s:
            return "NASA NAIF / Jet Propulsion Laboratory"
        }
    }
}

/// Manages downloading, caching, and verification of ephemeris data files from official sources.
///
/// `EphemerisDataManager` is an `actor` providing thread-safe asynchronous access to
/// large binary data files required by ``VSOP2013Provider`` and ``LunarDE440Provider``.
///
/// ## Usage
///
/// ```swift
/// let manager = EphemerisDataManager()
///
/// // Download specific datasets
/// let vsopURL = try await manager.download(.vsop2013Modern)
/// let lunarURL = try await manager.download(.lunarDE440s)
///
/// // Or create a ready-to-use hybrid provider in one call
/// let provider = try await manager.makeHybridProvider { dataset, received, total in
///     print("[\(dataset.name)] \(received)/\(total) bytes")
/// }
///
/// let moonPos = try provider.position(for: .moon, at: jd) // Centimeter precision!
/// ```
public actor EphemerisDataManager {

    // MARK: - Properties

    /// The local cache directory for downloaded data files.
    public let cacheDirectory: URL

    // MARK: - Initialization

    /// Creates an ephemeris data manager.
    ///
    /// - Parameter cacheDirectory: Directory to store downloaded files.
    ///   Defaults to `Caches/AstronomyKit/` on the current platform.
    public init(cacheDirectory: URL? = nil) {
        if let dir = cacheDirectory {
            self.cacheDirectory = dir
        } else {
            self.cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("AstronomyKit")
        }
    }

    // MARK: - Download

    /// Downloads a dataset from its official source.
    ///
    /// If the file already exists in the cache, it is returned immediately without re-downloading.
    ///
    /// - Parameters:
    ///   - dataset: The dataset to download.
    ///   - progress: Optional closure called with `(bytesReceived, totalBytes)`.
    /// - Returns: Local URL of the downloaded file.
    /// - Throws: An error if the download fails.
    public func download(
        _ dataset: EphemerisDataset,
        progress: (@Sendable (Int64, Int64) -> Void)? = nil
    ) async throws -> URL {
        let localURL = cacheDirectory.appendingPathComponent(dataset.filename)

        // Return cached file if it exists
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }

        // Ensure cache directory exists
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Download with progress tracking
        let (tempURL, response) = try await URLSession.shared.download(from: dataset.remoteURL) { totalBytesWritten, totalBytesExpectedToWrite in
            progress?(totalBytesWritten, totalBytesExpectedToWrite)
        }

        // Validate HTTP response
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw EphemerisError.dataFileNotFound(
                "HTTP \(httpResponse.statusCode) downloading \(dataset.remoteURL.absoluteString)"
            )
        }

        // Move to final location
        let finalURL = cacheDirectory.appendingPathComponent(dataset.filename)
        if FileManager.default.fileExists(atPath: finalURL.path) {
            try FileManager.default.removeItem(at: finalURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: finalURL)

        return finalURL
    }

    // MARK: - Cache Management

    /// Whether a dataset is already available in the local cache.
    public func isAvailable(_ dataset: EphemerisDataset) -> Bool {
        let localURL = cacheDirectory.appendingPathComponent(dataset.filename)
        return FileManager.default.fileExists(atPath: localURL.path)
    }

    /// Returns the local URL of a cached dataset, or `nil` if not downloaded.
    public func localURL(for dataset: EphemerisDataset) -> URL? {
        let localURL = cacheDirectory.appendingPathComponent(dataset.filename)
        guard FileManager.default.fileExists(atPath: localURL.path) else {
            return nil
        }
        return localURL
    }

    /// Removes a dataset from the local cache.
    ///
    /// - Parameter dataset: The dataset to remove.
    /// - Throws: A file system error if removal fails.
    public func remove(_ dataset: EphemerisDataset) throws {
        let localURL = cacheDirectory.appendingPathComponent(dataset.filename)
        if FileManager.default.fileExists(atPath: localURL.path) {
            try FileManager.default.removeItem(at: localURL)
        }
    }

    /// Total size of all cached data files in bytes.
    public func cacheSize() throws -> Int64 {
        guard FileManager.default.fileExists(atPath: cacheDirectory.path) else {
            return 0
        }
        let contents = try FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        )
        return try contents.reduce(0) { total, url in
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            return total + Int64(values.fileSize ?? 0)
        }
    }

    // MARK: - Provider Factory

    /// Creates a ``HybridEphemerisProvider`` by downloading any missing data files.
    ///
    /// This convenience method downloads the VSOP2013 modern-era planetary data
    /// and the DE440s compact lunar kernel, then constructs a ready-to-use provider.
    ///
    /// - Parameter progress: Optional closure called with `(dataset, bytesReceived, totalBytes)`.
    /// - Returns: A configured ``HybridEphemerisProvider``.
    /// - Throws: An error if downloads fail or data files are invalid.
    public func makeHybridProvider(
        progress: (@Sendable (EphemerisDataset, Int64, Int64) -> Void)? = nil
    ) async throws -> HybridEphemerisProvider {
        let vsopURL = try await download(.vsop2013Modern) { received, total in
            progress?(.vsop2013Modern, received, total)
        }

        let lunarURL = try await download(.lunarDE440s) { received, total in
            progress?(.lunarDE440s, received, total)
        }

        // VSOP2013 expects a directory; the downloaded file is within the cache directory
        return try HybridEphemerisProvider(
            vsop2013DataURL: vsopURL.deletingLastPathComponent(),
            lunarSPKURL: lunarURL
        )
    }
}

// MARK: - URLSession Download with Progress

private extension URLSession {
    /// Downloads from a URL with byte-level progress reporting.
    func download(
        from url: URL,
        progress: @escaping @Sendable (Int64, Int64) -> Void
    ) async throws -> (URL, URLResponse) {
        let request = URLRequest(url: url)
        let (asyncBytes, response) = try await self.bytes(for: request)

        let expectedLength = response.expectedContentLength
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: tempURL.path, contents: nil)

        let fileHandle = try FileHandle(forWritingTo: tempURL)
        var succeeded = false
        defer {
            if !succeeded {
                try? fileHandle.close()
                try? FileManager.default.removeItem(at: tempURL)
            }
        }

        var totalWritten: Int64 = 0
        let bufferSize = 65536
        var buffer = Data()
        buffer.reserveCapacity(bufferSize)

        for try await byte in asyncBytes {
            buffer.append(byte)
            if buffer.count >= bufferSize {
                try Task.checkCancellation()
                try fileHandle.write(contentsOf: buffer)
                totalWritten += Int64(buffer.count)
                progress(totalWritten, expectedLength)
                buffer.removeAll(keepingCapacity: true)
            }
        }

        // Write remaining bytes
        if !buffer.isEmpty {
            try Task.checkCancellation()
            try fileHandle.write(contentsOf: buffer)
            totalWritten += Int64(buffer.count)
            progress(totalWritten, expectedLength)
        }

        try fileHandle.close()
        succeeded = true
        return (tempURL, response)
    }
}
