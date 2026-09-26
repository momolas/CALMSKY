//
//  SPKRangeClient.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Thread-safe client providing HTTP partial byte-range requests (`Accept-Ranges: bytes`)
/// with a 2-tier CDN fallback and a local sparse cache.
public actor SPKRangeClient {

    // MARK: - Properties

    /// Primary remote URL (canonical GitHub Releases Assets CDN).
    public let primaryURL: URL

    /// Upstream fallback URL (e.g. NASA NAIF, IMCCE, IAA RAS).
    public let fallbackURL: URL?

    /// Directory used for sparse disk caching.
    public let cacheDirectory: URL

    /// Memory cache storing fetched byte slices: `[RangeKey: Data]`.
    private var memoryCache: [String: Data] = [:]
    private var memoryCacheKeys: [String] = []
    private let maxMemoryEntries: Int = 256
    private var isCacheDirectoryReady: Bool = false

    /// URLSession instance for range requests.
    private let session: URLSession

    // MARK: - Initialization

    /// Initializes a range request client.
    ///
    /// - Parameters:
    ///   - primaryURL: Canonical remote URL (e.g. GitHub Releases Asset).
    ///   - fallbackURL: Upstream official server fallback URL.
    ///   - cacheDirectory: Local directory where cached chunks are stored.
    ///   - session: URLSession used for network transport.
    public init(
        primaryURL: URL,
        fallbackURL: URL? = nil,
        cacheDirectory: URL,
        session: URLSession = .shared
    ) {
        self.primaryURL = primaryURL
        self.fallbackURL = fallbackURL
        self.cacheDirectory = cacheDirectory
        self.session = session
    }

    // MARK: - Range Fetching

    /// Fetches a specific byte range `[startOffset ..< startOffset + length]`.
    ///
    /// First checks memory and sparse disk cache. If not present, requests the range
    /// via HTTP header `Range: bytes=startOffset-(startOffset + length - 1)`.
    ///
    /// - Parameters:
    ///   - startOffset: Starting byte offset (0-indexed).
    ///   - length: Number of bytes to read.
    /// - Returns: The exact `Data` slice of length `length`.
    /// - Throws: ``EphemerisError`` if range request fails or data is invalid.
    public func fetchRange(startOffset: Int, length: Int) async throws -> Data {
        guard length > 0 else { return Data() }
        let endOffset = startOffset + length - 1
        let cacheKey = "\(startOffset)_\(endOffset)"

        // 1. Check in-memory cache
        if let cached = memoryCache[cacheKey] {
            return cached
        }

        // 2. Check sparse disk cache
        let diskURL = cacheDirectory.appendingPathComponent("chunk_\(cacheKey).bin")
        if let diskData = try? Data(contentsOf: diskURL), diskData.count == length {
            storeInMemoryCache(key: cacheKey, data: diskData)
            return diskData
        }

        // 3. Perform network range request with 2-tier fallback
        var fetchedData: Data
        do {
            fetchedData = try await performRangeRequest(url: primaryURL, start: startOffset, end: endOffset)
        } catch {
            if let fallback = fallbackURL {
                fetchedData = try await performRangeRequest(url: fallback, start: startOffset, end: endOffset)
            } else {
                throw error
            }
        }

        if fetchedData.count != length {
            // Handle cases where server returned 200 OK with whole or larger file
            if fetchedData.count > length && startOffset < fetchedData.count {
                let slice = fetchedData.subdata(in: startOffset..<min(startOffset + length, fetchedData.count))
                if slice.count == length {
                    fetchedData = slice
                } else {
                    throw EphemerisError.dataCorrupted(
                        "Range slice length mismatch: expected \(length) bytes, received \(fetchedData.count)"
                    )
                }
            } else {
                throw EphemerisError.dataCorrupted(
                    "Range response length mismatch: expected \(length) bytes, received \(fetchedData.count)"
                )
            }
        }

        // 4. Update memory cache and persist to sparse disk cache
        storeInMemoryCache(key: cacheKey, data: fetchedData)
        if !isCacheDirectoryReady {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            isCacheDirectoryReady = true
        }
        try? fetchedData.write(to: diskURL, options: .atomic)

        return fetchedData
    }

    /// Clears both memory and on-disk sparse caches for this client.
    public func clearCache() throws {
        memoryCache.removeAll()
        memoryCacheKeys.removeAll()
        isCacheDirectoryReady = false
        if FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try FileManager.default.removeItem(at: cacheDirectory)
        }
    }

    private func storeInMemoryCache(key: String, data: Data) {
        if memoryCache[key] == nil {
            memoryCacheKeys.append(key)
        }
        memoryCache[key] = data
        if memoryCacheKeys.count > maxMemoryEntries {
            let oldest = memoryCacheKeys.removeFirst()
            memoryCache.removeValue(forKey: oldest)
        }
    }

    // MARK: - Private Network Implementation

    private func performRangeRequest(url: URL, start: Int, end: Int) async throws -> Data {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" || scheme == "mock" else {
            throw EphemerisError.calculationFailed(
                "Dynamic byte-range streaming requires HTTP or HTTPS protocol (received \(url.scheme ?? "unknown"))"
            )
        }

        var request = URLRequest(url: url)
        request.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
        request.timeoutInterval = 8

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EphemerisError.calculationFailed("Invalid non-HTTP response from \(url.host ?? "")")
        }

        // 206 Partial Content indicates a successful partial byte range
        // 200 OK may be returned by servers that ignore Range headers and stream the full file
        guard httpResponse.statusCode == 206 || httpResponse.statusCode == 200 else {
            throw EphemerisError.dataFileNotFound(
                "HTTP \(httpResponse.statusCode) on range request [\(start)-\(end)] for \(url.absoluteString)"
            )
        }

        if httpResponse.statusCode == 206 {
            return data
        } else {
            // Server returned entire file: extract the requested window
            guard data.count >= end + 1 else {
                throw EphemerisError.dataCorrupted("Server returned full response with insufficient byte count")
            }
            return data.subdata(in: start..<(end + 1))
        }
    }
}
