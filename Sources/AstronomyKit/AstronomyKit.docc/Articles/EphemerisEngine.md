# Ephemeris Engine

Learn how AstronomyKit's multi-agency ephemeris engine works: network-first adaptive selection, HTTP byte-range streaming, and offline DE442s caching.

## Overview

AstronomyKit's ephemeris engine implements a **network-first adaptive policy**: when a network path is available it orchestrates real-time parallel HTTP byte-range streaming from four international space agency numerical kernels; when offline, it falls back to a locally cached compact NASA JPL baseline.

No kernel is ever bundled inside the Swift package. All files are distributed on demand.

---

## Source Routing per Agency

| Mode | Agency | Dataset | HTTP Source | Size | Temporal Coverage |
|---|---|---|---|---|---|
| 🌐 **Streaming** | 🇺🇸 NASA JPL | DE442 | **NASA NAIF direct** | 120 MB | 1549–2650 CE |
| 🌐 **Streaming** | 🇫🇷 IMCCE | INPOP21a millennial | **GitHub CDN** | 213 MB | 973–3026 CE |
| 🌐 **Streaming** | 🇷🇺 IAA RAS | EPM2021 | **GitHub CDN** | 40 MB | 1787–2214 CE |
| 🌐 **Streaming** | 🇨🇳 PMO/CAS | PMOE | **GitHub CDN** | 25 MB | 1900–2100 CE |
| 📵 **Offline cache** | 🇺🇸 NASA JPL | DE442s compact | **GitHub CDN** → local | 31 MB | 1849–2150 CE |

> **Note**: HTTP Range streaming fetches only ~328 bytes per requested date regardless of kernel size. The full kernel file is never downloaded during live evaluation.

---

## Adaptive Provider — Network-First Policy

``AdaptiveEphemerisProvider`` is the recommended entry point. It automatically selects the best available engine based on current network reachability using `NWPathMonitor`:

- **Network available** → ``StreamingTetradProvider`` (4-agency parallel HTTP streaming)
- **No network** → ``SPKEphemerisProvider`` initialized from the locally cached `de442s.bsp`

```swift
let manager = EphemerisDataManager()

// Create the adaptive provider — automatically selects online or offline engine
let provider = try await manager.makeAdaptiveProvider()

// Uniform API regardless of online/offline mode
let marsPos = try await provider.position(for: .mars, at: jd)
let moonState = try await provider.stateVector(for: .moon, at: jd)
```

---

## Launch Preparation — Ensuring the Offline Baseline

To guarantee offline availability, call ``EphemerisDataManager/prepareOfflineBaseline(progress:)`` at application startup. This downloads `de442s.bsp` (~31 MB) from the GitHub CDN once and caches it locally. On subsequent launches the file is already present and the method returns immediately without any network activity.

```swift
// In your SwiftUI App struct:
@main
struct MyAstronomyApp: App {
    let manager = EphemerisDataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(manager)
                .task {
                    // Fire-and-forget: downloads once, no-op thereafter
                    manager.prepareOfflineBaseline()
                }
        }
    }
}
```

You can also await the returned `Task` to track progress:

```swift
let task = manager.prepareOfflineBaseline { received, total in
    let progress = Double(received) / Double(total)
    print("DE442s: \(Int(progress * 100))%")
}
try await task.value
```

---

## Streaming Tetrad — 4-Agency Consensus

``StreamingTetradProvider`` orchestrates four simultaneous HTTP Range requests, one per agency, and computes a **metrological consensus position** with a **physical 1σ uncertainty**:

```swift
let manager = EphemerisDataManager()

// No download required — fetches ~328 bytes per body per query
let tetrad = try manager.makeStreamingTetradProvider()

let consensus = try await tetrad.consensusDetails(for: .mars, at: jd)
print("Consensus (AU):    ", consensus.consensusPosition)
print("1-σ uncertainty:   ", consensus.physicalUncertaintyKm, "km")
print("Angular dispersion:", consensus.physicalUncertaintyArcsec, "arcsec")
print("Max discrepancy:   ", consensus.maxDiscrepancyKm, "km")
```

### Streaming Baseline (US Only)

For a lighter single-agency streaming provider using NASA JPL DE442 directly from NAIF:

```swift
let baselineStream = manager.makeStreamingBaselineProvider()
let marsPos = try await baselineStream.position(for: .mars, at: jd)
```

---

## Downloaded Kernels — Full Local Access

For applications requiring full local kernel access (no runtime network dependency after setup), download the kernels once and use them from cache:

```swift
// Download all four Tetrad kernels (runs once; cached thereafter)
let tetrad = try await manager.makeTetradProvider { dataset, received, total in
    print("[\(dataset.name)] \(received)/\(total)")
}

// Or load from cache without network
let tetradFromCache = try manager.makeTetradProviderFromCache()
```

### Kernel Distribution

All kernels are distributed from the canonical GitHub Releases CDN at
`https://github.com/momolas/CALMSKY/releases/tag/ephemerides-v1.0`,
with upstream official institutional servers as fallback:

| Dataset | Primary (CDN) | Fallback (Institutional) |
|---|---|---|
| `de442s.bsp` | GitHub CDN | NASA NAIF |
| `inpop21a.bsp` | GitHub CDN | IMCCE FTP |
| `epm2021.bsp` | GitHub CDN | IAA RAS FTP |
| `pmoe.bsp` | GitHub CDN | PMO CAS |
| `de442.bsp` (streaming only) | NASA NAIF | GitHub CDN |

---

## Dataset Reference

``EphemerisDataset`` enumerates all supported kernels:

| Case | Description | Usage |
|---|---|---|
| `.de442` | NASA JPL DE442 complete (1549–2650 CE, 120 MB) | Online streaming (NAIF) |
| `.de442s` | NASA JPL DE442s compact (1849–2150 CE, 31 MB) | Offline cache baseline |
| `.inpop21a` | IMCCE INPOP21a millennial (973–3026 CE, 213 MB) | Online streaming (CDN) |
| `.epm2021` | IAA RAS EPM2021 (1787–2214 CE, 40 MB) | Online streaming (CDN) |
| `.pmoe` | PMO/CAS PMOE (1900–2100 CE, 25 MB) | Online streaming (CDN) |
| `.lunarDE440` | NASA JPL DE440 lunar (1550–2650 CE, 115 MB) | Specialized lunar |
| `.lunarDE440s` | NASA JPL DE440s lunar compact (1900–2050 CE, 32 MB) | Specialized lunar compact |

---

## Architecture Diagram

```
EphemerisDataManager
├── prepareOfflineBaseline()  ← call at launch
│   └── download(.de442s) → Caches/AstronomyKit/de442s.bsp
│
├── makeAdaptiveProvider()    ← main entry point
│   ├── NWPathMonitor: network available?
│   │   ├── YES → makeStreamingTetradProvider()
│   │   │         ├── StreamingSPKEphemerisProvider(.de442)    → NAIF
│   │   │         ├── StreamingSPKEphemerisProvider(.inpop21a) → GitHub CDN
│   │   │         ├── StreamingSPKEphemerisProvider(.epm2021)  → GitHub CDN
│   │   │         └── StreamingSPKEphemerisProvider(.pmoe)     → GitHub CDN
│   │   └── NO  → makeBaselineProviderFromCache()
│   │             └── SPKEphemerisProvider(de442s.bsp)
│   └── AdaptiveEphemerisProvider(.onlineTetrad | .offlineBaseline)
│
├── makeStreamingTriadProvider() / makeStreamingTetradProvider()
│   └── StreamingTriadProvider (3 or 4 agency streaming)
│
└── makeTetradProvider()  ← downloads full kernels once
    └── TriadEphemerisProvider (local SPK files)
```
