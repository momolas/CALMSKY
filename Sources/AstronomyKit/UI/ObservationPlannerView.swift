//
//  ObservationPlannerView.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

#if canImport(SwiftUI)
import SwiftUI

/// An interactive, HIG-compliant SwiftUI view for planning astronomical observations.
public struct ObservationPlannerView: View {
    @State private var selectedDate: Date = .now
    @State private var selectedFilter: BodyFilter = .all
    @State private var selectedBody: SolarSystemBody?
    @State private var snapshots: [EphemerisSnapshot] = []

    public enum BodyFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case planets = "Planets"
        case sunAndMoon = "Sun & Moon"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .all: return "sparkles"
            case .planets: return "globe"
            case .sunAndMoon: return "sun.max"
            }
        }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HeaderSection()
                DatePickerCard(selectedDate: $selectedDate)
                FilterSection(selectedFilter: $selectedFilter)
                BodiesListSection(snapshots: snapshots) { body in
                    selectedBody = body
                }
            }
            .padding(16)
        }
        .navigationTitle("Observation Planner")
        .sheet(item: $selectedBody) { body in
            NavigationStack {
                VStack(spacing: 20) {
                    if let snapshot = snapshots.first(where: { $0.body == body }) {
                        CelestialBodyCard(snapshot: snapshot)
                            .padding()
                    }
                    Spacer()
                }
                .navigationTitle(body.name)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            selectedBody = nil
                        }
                    }
                }
            }
        }
        .task(id: selectedDate) {
            await reloadSnapshots()
        }
        .onChange(of: selectedFilter) {
            Task { await reloadSnapshots() }
        }
    }

    private func reloadSnapshots() async {
        let jd = JulianDay(selectedDate)
        let bodies = filteredBodies
        let results = await Task.detached(priority: .userInitiated) {
            bodies.map { $0.ephemeris(at: jd) }
        }.value
        self.snapshots = results
    }

    private var filteredBodies: [SolarSystemBody] {
        let allExcludingEarth = SolarSystemBody.allCases.filter { $0 != .earth }
        switch selectedFilter {
        case .all:
            return allExcludingEarth
        case .planets:
            return allExcludingEarth.filter { $0 != .sun && $0 != .moon && $0 != .pluto }
        case .sunAndMoon:
            return [.sun, .moon]
        }
    }
}

// MARK: - Subviews

private struct HeaderSection: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "telescope.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.tint.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text("Sky Observation Planner")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text("Ephemeris computed at high precision")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct DatePickerCard: View {
    @Binding var selectedDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Observation Epoch", systemImage: "clock")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("JD \(JulianDay(selectedDate).value, format: .number.precision(.fractionLength(3)))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            DatePicker(
                "Date and Time",
                selection: $selectedDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
    }
}

private struct FilterSection: View {
    @Binding var selectedFilter: ObservationPlannerView.BodyFilter

    var body: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(ObservationPlannerView.BodyFilter.allCases) { filter in
                Label(filter.rawValue, systemImage: filter.icon)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel("Body filter")
    }
}

private struct BodiesListSection: View {
    let snapshots: [EphemerisSnapshot]
    let onSelect: (SolarSystemBody) -> Void

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(snapshots) { snapshot in
                CelestialBodyCard(snapshot: snapshot) {
                    onSelect(snapshot.body)
                }
            }
        }
    }
}
#endif
