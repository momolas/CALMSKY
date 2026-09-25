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

    /// JPL DE442s compact modern planetary ephemerides covering 1849–2150 CE (≈31.1 MB).
    /// Primary source: Canonical GitHub Releases Assets (fallback to NASA NAIF).
    case de442s

    /// IMCCE INPOP21a modern planetary ephemerides covering 1900–2100 CE (≈24.2 MB).
    /// Primary source: Canonical GitHub Releases Assets (fallback to IMCCE).
    case inpop21a

    /// IAA RAS EPM2021 modern planetary ephemerides covering 1787–2214 CE (≈39.7 MB).
    /// Primary source: Canonical GitHub Releases Assets (fallback to IAA RAS).
    case epm2021

    /// PMO / CAS PMOE modern planetary ephemerides covering 1900–2100 CE (≈25.0 MB).
    /// Primary source: Canonical GitHub Releases Assets (fallback to PMO CAS).
    case pmoe

    public var id: String { rawValue }

    /// Official baseline ephemeris dataset (NASA JPL DE442s).
    public static var baseline: EphemerisDataset { .de442s }

    /// Human-readable name of the dataset.
    public var name: String {
        switch self {
        case .vsop2013Modern: return "VSOP2013 Modern (0–2000 CE)"
        case .vsop2013Full: return "VSOP2013 Full (−4000 to +8000 CE)"
        case .lunarDE440: return "DE440 Lunar (1550–2650 CE)"
        case .lunarDE440s: return "DE440s Lunar (1900–2050 CE)"
        case .de442s: return "DE442s Planetary (1849–2150 CE) [US - NASA JPL]"
        case .inpop21a: return "INPOP21a Planetary (1900–2100 CE) [FR - IMCCE]"
        case .epm2021: return "EPM2021 Planetary (1787–2214 CE) [RU - IAA RAS]"
        case .pmoe: return "PMOE Planetary (1900–2100 CE) [CN - PMO / CAS]"
        }
    }

    /// The remote URL of the official source (canonical GitHub Releases Assets for Triad models).
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
        case .de442s:
            return URL(string: "https://github.com/momolas/CALMSKY/releases/download/ephemerides-v1.0/de442s.bsp")!
        case .inpop21a:
            return URL(string: "https://github.com/momolas/CALMSKY/releases/download/ephemerides-v1.0/inpop21a.bsp")!
        case .epm2021:
            return URL(string: "https://github.com/momolas/CALMSKY/releases/download/ephemerides-v1.0/epm2021.bsp")!
        case .pmoe:
            return URL(string: "https://github.com/momolas/CALMSKY/releases/download/ephemerides-v1.0/pmoe.bsp")!
        }
    }

    /// Upstream official repository URL (fallback if GitHub Releases is unreachable).
    public var fallbackRemoteURL: URL? {
        switch self {
        case .de442s:
            return URL(string: "https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de442s.bsp")
        case .inpop21a:
            return URL(string: "ftp://ftp.imcce.fr/pub/ephem/planets/inpop21a/inpop21a_TDB_m100_p100_spice.tar.gz")
        case .epm2021:
            return URL(string: "ftp://ftp.iaaras.ru/pub/epm/EPM2021/SPICE/epm2021.bsp")
        case .pmoe:
            return URL(string: "http://www.pmo.cas.cn/ephem/pmoe.bsp")
        case .vsop2013Modern, .vsop2013Full, .lunarDE440, .lunarDE440s:
            return nil
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
        case .de442s:
            return "NASA NAIF / Jet Propulsion Laboratory (US)"
        case .inpop21a:
            return "IMCCE – Observatoire de Paris (FR)"
        case .epm2021:
            return "IAA RAS – Institute of Applied Astronomy (RU)"
        case .pmoe:
            return "Purple Mountain Observatory / CAS (CN)"
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
            self.cacheDirectory = URL.cachesDirectory.appending(path: "AstronomyKit")
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

        // Attempt download from primary URL (canonical GitHub Releases Assets)
        do {
            return try await performDownload(from: dataset.remoteURL, targetFilename: dataset.filename, progress: progress)
        } catch {
            // Fallback to official upstream repository URL if available
            if let fallbackURL = dataset.fallbackRemoteURL {
                return try await performDownload(from: fallbackURL, targetFilename: dataset.filename, progress: progress)
            }
            throw error
        }
    }

    /// Performs the network download and moves the file to the local cache.
    private func performDownload(
        from url: URL,
        targetFilename: String,
        progress: (@Sendable (Int64, Int64) -> Void)?
    ) async throws -> URL {
        let (tempURL, response) = try await URLSession.shared.download(from: url) { totalBytesWritten, totalBytesExpectedToWrite in
            progress?(totalBytesWritten, totalBytesExpectedToWrite)
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw EphemerisError.dataFileNotFound(
                "HTTP \(httpResponse.statusCode) downloading \(url.absoluteString)"
            )
        }

        let finalURL = cacheDirectory.appendingPathComponent(targetFilename)
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

    // MARK: - Provider Factories

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

    /// Creates a ``HybridEphemerisProvider`` using VSOP2013 for planets and the official NASA JPL DE442s baseline for the Moon.
    ///
    /// - Parameter progress: Optional closure called with `(dataset, bytesReceived, totalBytes)`.
    /// - Returns: A configured ``HybridEphemerisProvider`` combining VSOP2013 with DE442s.
    public func makeHybridDE442sProvider(
        progress: (@Sendable (EphemerisDataset, Int64, Int64) -> Void)? = nil
    ) async throws -> HybridEphemerisProvider {
        let vsopURL = try await download(.vsop2013Modern) { received, total in
            progress?(.vsop2013Modern, received, total)
        }

        let lunarURL = try await download(.de442s) { received, total in
            progress?(.de442s, received, total)
        }

        return try HybridEphemerisProvider(
            vsop2013DataURL: vsopURL.deletingLastPathComponent(),
            lunarSPKURL: lunarURL
        )
    }

    /// Creates a ``TriadEphemerisProvider`` combining US (DE442s), FR (INPOP21a), and RU (EPM2021) numerical ephemerides.
    ///
    /// Downloads missing kernels from the canonical GitHub Releases CDN (with upstream fallback)
    /// and instantiates the multi-agency consensus provider.
    ///
    /// Strictly enforces numerical exclusivity: no silent fallback to analytical models.
    ///
    /// - Parameters:
    ///   - datasets: Datasets to include (defaults to all three: `.de442s`, `.inpop21a`, `.epm2021`).
    ///   - progress: Optional closure called with `(dataset, bytesReceived, totalBytes)`.
    /// - Returns: A configured ``TriadEphemerisProvider``.
    /// - Throws: An error if download fails or kernels cannot be parsed.
    public func makeTriadProvider(
        datasets: [EphemerisDataset] = [.de442s, .inpop21a, .epm2021],
        progress: (@Sendable (EphemerisDataset, Int64, Int64) -> Void)? = nil
    ) async throws -> TriadEphemerisProvider {
        var providers: [TriadAgency: any EphemerisProvider] = [:]

        for ds in datasets {
            let fileURL = try await download(ds) { received, total in
                progress?(ds, received, total)
            }
            let spkProvider = try SPKEphemerisProvider(spkFileURL: fileURL)
            switch ds {
            case .de442s:
                providers[.us] = spkProvider
            case .inpop21a:
                providers[.fr] = spkProvider
            case .epm2021:
                providers[.ru] = spkProvider
            case .pmoe:
                providers[.cn] = spkProvider
            default:
                break
            }
        }

        return try TriadEphemerisProvider(providers: providers)
    }

    /// Instantiates a ``TriadEphemerisProvider`` from locally cached numerical kernels without network access.
    ///
    /// Strictly enforces numerical exclusivity: if none of the requested kernels are present in cache,
    /// throws ``EphemerisError/dataFileNotFound(_:)``. Never falls back to analytical models.
    ///
    /// - Parameter datasets: Candidate datasets to look for in local cache (defaults to `.de442s`, `.inpop21a`, `.epm2021`).
    /// - Returns: A configured ``TriadEphemerisProvider``.
    /// - Throws: ``EphemerisError`` if no cached kernel is available or if data is corrupted.
    public nonisolated func makeTriadProviderFromCache(
        datasets: [EphemerisDataset] = [.de442s, .inpop21a, .epm2021]
    ) throws -> TriadEphemerisProvider {
        var providers: [TriadAgency: any EphemerisProvider] = [:]

        for ds in datasets {
            let fileURL = cacheDirectory.appendingPathComponent(ds.filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let spk = try SPKEphemerisProvider(spkFileURL: fileURL)
                switch ds {
                case .de442s: providers[.us] = spk
                case .inpop21a: providers[.fr] = spk
                case .epm2021: providers[.ru] = spk
                case .pmoe: providers[.cn] = spk
                default: break
                }
            }
        }

        guard !providers.isEmpty else {
            throw EphemerisError.dataFileNotFound(
                "No Triad/Tetrad numerical kernels (.de442s, .inpop21a, .epm2021, .pmoe) found in cache directory \(cacheDirectory.path). " +
                "Numerical exclusivity strictly enforced (analytical fallback disabled)."
            )
        }

        return try TriadEphemerisProvider(providers: providers)
    }

    // MARK: - Tetrad Ensemble Factories (US + FR + RU + CN)

    /// Instantiates a 4-agency ``TetradEphemerisProvider`` (NASA JPL DE442s, IMCCE INPOP21a, IAA RAS EPM2021, PMO/CAS PMOE).
    ///
    /// Downloads missing numerical kernels in parallel with progress reporting.
    public func makeTetradProvider(
        datasets: [EphemerisDataset] = [.de442s, .inpop21a, .epm2021, .pmoe],
        progress: (@Sendable (EphemerisDataset, Int64, Int64) -> Void)? = nil
    ) async throws -> TetradEphemerisProvider {
        try await makeTriadProvider(datasets: datasets, progress: progress)
    }

    /// Instantiates a 4-agency ``TetradEphemerisProvider`` from locally cached numerical kernels without network access.
    public nonisolated func makeTetradProviderFromCache(
        datasets: [EphemerisDataset] = [.de442s, .inpop21a, .epm2021, .pmoe]
    ) throws -> TetradEphemerisProvider {
        try makeTriadProviderFromCache(datasets: datasets)
    }

    // MARK: - Dynamic Temporal Streaming Factories

    /// Creates a ``StreamingSPKEphemerisProvider`` for on-demand HTTP range streaming of a dataset.
    ///
    /// Fetches only the required byte chunks for requested dates without downloading the full kernel.
    public func makeStreamingProvider(for dataset: EphemerisDataset) -> StreamingSPKEphemerisProvider {
        let datasetCacheDir = cacheDirectory.appendingPathComponent("streaming_\(dataset.rawValue)")
        return StreamingSPKEphemerisProvider(
            reader: StreamingSPKReader(
                primaryURL: dataset.remoteURL,
                fallbackURL: dataset.fallbackRemoteURL,
                cacheDirectory: datasetCacheDir
            )
        )
    }

    /// Creates a ``StreamingTriadProvider`` combining US, FR, and RU ephemerides in parallel HTTP streaming mode.
    ///
    /// Fetches and evaluates Chebyshev polynomial slices across all three models in parallel,
    /// transferring less than 10 KB per requested date while providing full consensus and 1-sigma physical uncertainty.
    public func makeStreamingTriadProvider(
        datasets: [EphemerisDataset] = [.de442s, .inpop21a, .epm2021]
    ) throws -> StreamingTriadProvider {
        var providers: [TriadAgency: StreamingSPKEphemerisProvider] = [:]
        for ds in datasets {
            let sp = makeStreamingProvider(for: ds)
            switch ds {
            case .de442s: providers[.us] = sp
            case .inpop21a: providers[.fr] = sp
            case .epm2021: providers[.ru] = sp
            case .pmoe: providers[.cn] = sp
            default: break
            }
        }
        return try StreamingTriadProvider(providers: providers)
    }

    /// Creates a ``StreamingTetradProvider`` combining US, FR, RU, and CN ephemerides in parallel HTTP streaming mode.
    public func makeStreamingTetradProvider(
        datasets: [EphemerisDataset] = [.de442s, .inpop21a, .epm2021, .pmoe]
    ) throws -> StreamingTetradProvider {
        try makeStreamingTriadProvider(datasets: datasets)
    }

    // MARK: - Baseline Numerical Ephemeris (NASA JPL DE442s)

    /// Instantiates the official baseline numerical ephemeris provider (NASA JPL DE442s).
    ///
    /// Downloads the kernel from the canonical GitHub Releases CDN (or NASA NAIF fallback) if not present.
    /// - Parameter progress: Optional closure called with `(bytesReceived, totalBytes)`.
    /// - Returns: An ``SPKEphemerisProvider`` initialized with NASA JPL DE442s.
    public func makeBaselineProvider(
        progress: (@Sendable (Int64, Int64) -> Void)? = nil
    ) async throws -> SPKEphemerisProvider {
        let fileURL = try await download(.de442s) { received, total in
            progress?(received, total)
        }
        return try SPKEphemerisProvider(spkFileURL: fileURL)
    }

    /// Instantiates the official baseline numerical ephemeris provider (NASA JPL DE442s) from local cache for offline use.
    ///
    /// - Returns: An ``SPKEphemerisProvider`` initialized with cached NASA JPL DE442s.
    /// - Throws: ``EphemerisError/dataFileNotFound(_:)`` if the DE442s kernel is not in local cache.
    public nonisolated func makeBaselineProviderFromCache() throws -> SPKEphemerisProvider {
        let fileURL = cacheDirectory.appendingPathComponent(EphemerisDataset.de442s.filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw EphemerisError.dataFileNotFound(
                "Offline baseline numerical kernel (DE442s) not found in cache at: \(fileURL.path). " +
                "Call makeBaselineProvider() to download it from the canonical repository."
            )
        }
        return try SPKEphemerisProvider(spkFileURL: fileURL)
    }

    /// Instantiates a dedicated high-precision lunar provider using the official NASA JPL DE442s baseline.
    ///
    /// - Parameter progress: Optional closure called with `(bytesReceived, totalBytes)`.
    /// - Returns: A ``LunarDE442sProvider`` initialized with NASA JPL DE442s.
    public func makeLunarDE442sProvider(
        progress: (@Sendable (Int64, Int64) -> Void)? = nil
    ) async throws -> LunarDE442sProvider {
        let fileURL = try await download(.de442s) { received, total in
            progress?(received, total)
        }
        return try LunarDE442sProvider(spkFileURL: fileURL)
    }

    /// Instantiates a dedicated high-precision lunar provider using cached NASA JPL DE442s for offline use.
    ///
    /// - Returns: A ``LunarDE442sProvider`` initialized with cached NASA JPL DE442s.
    /// - Throws: ``EphemerisError/dataFileNotFound(_:)`` if DE442s is not in local cache.
    public nonisolated func makeLunarDE442sProviderFromCache() throws -> LunarDE442sProvider {
        let fileURL = cacheDirectory.appendingPathComponent(EphemerisDataset.de442s.filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw EphemerisError.dataFileNotFound(
                "Offline baseline numerical kernel (DE442s) not found in cache at: \(fileURL.path)."
            )
        }
        return try LunarDE442sProvider(spkFileURL: fileURL)
    }

    /// Creates a ``StreamingSPKEphemerisProvider`` for on-demand HTTP range streaming of the NASA JPL DE442s baseline.
    public func makeStreamingBaselineProvider() -> StreamingSPKEphemerisProvider {
        makeStreamingProvider(for: .de442s)
    }

    /// Creates an optimal adaptive numerical provider adhering to the policy:
    /// - **Hors-ligne (Offline)** : Utilise la Baseline numérique NASA JPL DE442s si disponible en cache local (`.offlineBaseline`).
    /// - **Sinon (En ligne / Streaming)** : Utilise la Triade numérique (DE442s US + INPOP21a FR + EPM2021 RU) via streaming dynamique HTTP Range (`.onlineTriad`).
    public func makeAdaptiveProvider() throws -> AdaptiveEphemerisProvider {
        let baselineURL = cacheDirectory.appendingPathComponent(EphemerisDataset.de442s.filename)
        if FileManager.default.fileExists(atPath: baselineURL.path) {
            let baseline = try makeBaselineProviderFromCache()
            return AdaptiveEphemerisProvider(engine: .offlineBaseline(baseline))
        } else {
            let triad = try makeStreamingTriadProvider()
            return AdaptiveEphemerisProvider(engine: .onlineTriad(triad))
        }
    }
}

// MARK: - Adaptive Ephemeris Provider

/// Adaptive ephemeris orchestrator dynamically selecting between:
/// - Offline Baseline: NASA JPL DE442s local numerical SPK kernel.
/// - Online Consensus: Streaming Triad (NASA JPL DE442s + IMCCE INPOP21a + IAA RAS EPM2021) via parallel HTTP Range requests.
public final class AdaptiveEphemerisProvider: Sendable {
    public enum Engine: Sendable {
        case offlineBaseline(SPKEphemerisProvider)
        case onlineTriad(StreamingTriadProvider)
    }

    public let engine: Engine

    public init(engine: Engine) {
        self.engine = engine
    }

    public var isOfflineBaseline: Bool {
        if case .offlineBaseline = engine { return true }
        return false
    }

    public var isStreamingTriad: Bool {
        if case .onlineTriad = engine { return true }
        return false
    }

    public func position(for body: SolarSystemBody, at jd: JulianDay) async throws -> Vector3D {
        switch engine {
        case .offlineBaseline(let baseline):
            return try baseline.position(for: body, at: jd)
        case .onlineTriad(let triad):
            let details = try await triad.consensusDetails(for: body, at: jd)
            return details.consensusPosition
        }
    }

    public func stateVector(for body: SolarSystemBody, at jd: JulianDay) async throws -> StateVector {
        switch engine {
        case .offlineBaseline(let baseline):
            return try baseline.stateVector(for: body, at: jd)
        case .onlineTriad(let triad):
            let details = try await triad.consensusDetails(for: body, at: jd)
            return StateVector(position: details.consensusPosition, velocity: details.consensusVelocity)
        }
    }

    /// Geocentric position of the Moon in AU (ICRS/J2000, TDB) via the adaptive engine.
    public func lunarGeocentricPosition(at jd: JulianDay) async throws -> Vector3D {
        let moonHelio = try await position(for: .moon, at: jd)
        let earthHelio = try await position(for: .earth, at: jd)
        return moonHelio - earthHelio
    }

    /// Geocentric 6D state vector of the Moon (position in AU, velocity in AU/day) via the adaptive engine.
    public func lunarGeocentricStateVector(at jd: JulianDay) async throws -> StateVector {
        let moonState = try await stateVector(for: .moon, at: jd)
        let earthState = try await stateVector(for: .earth, at: jd)
        return StateVector(
            position: moonState.position - earthState.position,
            velocity: moonState.velocity - earthState.velocity
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
