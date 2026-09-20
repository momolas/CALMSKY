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
                headerSection
                datePickerCard
                filterSection
                bodiesListSection
            }
            .padding(16)
        }
        .navigationTitle("Observation Planner")
    }

    private var headerSection: some View {
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

                Text("Ephemeris computed at high precision (VSOP87)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var datePickerCard: some View {
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    private var filterSection: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(BodyFilter.allCases) { filter in
                Label(filter.rawValue, systemImage: filter.icon)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel("Body filter")
    }

    private var bodiesListSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredBodies) { body in
                let snapshot = body.ephemeris(at: JulianDay(selectedDate))
                CelestialBodyCard(snapshot: snapshot) {
                    selectedBody = body
                }
            }
        }
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
#endif
