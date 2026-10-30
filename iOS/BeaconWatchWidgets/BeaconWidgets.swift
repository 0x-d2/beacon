// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppIntents
import SwiftUI
import WidgetKit

/// Beacon's complications: a Mac's reading on the watch face, as the watch
/// app last had it (LastReading.swift). The watch reads a Mac through the
/// iPhone only while the app shows it, so a complication says when its
/// reading is from and dims once it's ten minutes old; tapping it opens the
/// app on that Mac, which brings the readings back.
@main
struct BeaconWidgets: WidgetBundle {
    var body: some Widget {
        ReadingWidget()
    }
}

struct ReadingWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: LastReading.widgetKind, intent: ReadingIntent.self, provider: ReadingProvider()) { entry in
            ReadingView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
                .widgetURL(entry.reading?.link)
        }
        .configurationDisplayName("Mac reading")
        .description("One of your Mac's readings, as the watch last saw it.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}

/// The readings a complication can show.
enum ComplicationMetric: String, AppEnum, CaseIterable {
    case cpu, memory, gpu, temperature

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Reading" }
    static var caseDisplayRepresentations: [ComplicationMetric: DisplayRepresentation] {
        [.cpu: "CPU", .memory: "Memory", .gpu: "GPU", .temperature: "Temperature"]
    }

    var kind: MetricKind {
        switch self {
        case .cpu: return .cpu
        case .memory: return .memory
        case .gpu: return .gpu
        case .temperature: return .temperature
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "Memory"
        case .gpu: return "GPU"
        case .temperature: return "Temperature"
        }
    }
}

struct ReadingIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Mac reading" }
    static var description: IntentDescription { "Which of the Mac's readings the complication shows." }

    @Parameter(title: "Reading", default: .cpu)
    var metric: ComplicationMetric

    init() {}

    init(metric: ComplicationMetric) {
        self.metric = metric
    }
}

struct ReadingEntry: TimelineEntry {
    let date: Date
    let reading: LastReading?
    let metric: ComplicationMetric

    /// Ten minutes past its reading: the complication dims it.
    var isStale: Bool { reading.map { date.timeIntervalSince($0.time) >= LastReading.freshFor } ?? true }
}

struct ReadingProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ReadingEntry {
        ReadingEntry(date: .now, reading: .sample, metric: .cpu)
    }

    func snapshot(for configuration: ReadingIntent, in context: Context) async -> ReadingEntry {
        ReadingEntry(date: .now, reading: LastReadingStore.read() ?? (context.isPreview ? .sample : nil), metric: configuration.metric)
    }

    /// The reading as it is now, and the moment it goes stale; the app asks for a new timeline as readings come.
    func timeline(for configuration: ReadingIntent, in context: Context) async -> Timeline<ReadingEntry> {
        let reading = LastReadingStore.read()
        var entries = [ReadingEntry(date: .now, reading: reading, metric: configuration.metric)]
        if let reading, reading.time.addingTimeInterval(LastReading.freshFor) > .now {
            entries.append(ReadingEntry(date: reading.time.addingTimeInterval(LastReading.freshFor), reading: reading, metric: configuration.metric))
        }
        return Timeline(entries: entries, policy: .never)
    }

    /// The face editor lists these: a complication per reading.
    func recommendations() -> [AppIntentRecommendation<ReadingIntent>] {
        ComplicationMetric.allCases.map { AppIntentRecommendation(intent: ReadingIntent(metric: $0), description: $0.title) }
    }
}

/// A complication: a ring (circular), a number with a curved gauge (corner), a
/// line (inline), or the Mac with three readings (rectangular).
struct ReadingView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ReadingEntry

    private var metric: ComplicationMetric { entry.metric }
    private var reading: LastReading? { entry.reading }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: reading?.fraction(metric) ?? 0) {
                Image(systemName: metric.kind.symbol)
            } currentValueLabel: {
                Text(reading?.shortValue(metric) ?? "–")
            }
            .gaugeStyle(.accessoryCircular)
            .tint(metric.kind.tint)
            .opacity(entry.isStale ? 0.45 : 1)
        case .accessoryCorner:
            Text(reading?.shortValue(metric) ?? "–")
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .widgetCurvesContent()
                .widgetLabel {
                    Gauge(value: reading?.fraction(metric) ?? 0) { Text(metric.title) }
                        .tint(metric.kind.tint)
                }
                .opacity(entry.isStale ? 0.45 : 1)
        case .accessoryInline:
            Label {
                Text(verbatim: reading.map { "\(String(localized: metric.title)) \($0.value(metric)) · \($0.macName)" } ?? "Beacon")
            } icon: {
                Image(systemName: metric.kind.symbol)
            }
        default:
            rectangular
        }
    }

    @ViewBuilder
    private var rectangular: some View {
        if let reading {
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline) {
                    Text(reading.macName).font(.headline).widgetAccentable().lineLimit(1)
                    Spacer(minLength: 4)
                    Text(reading.time, style: .time).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(rows, id: \.self) { row in
                    HStack {
                        Text(row.title).foregroundStyle(.secondary)
                        Spacer()
                        Text(reading.value(row)).monospacedDigit()
                    }
                    .font(.caption)
                }
            }
            .opacity(entry.isStale ? 0.6 : 1)
        } else {
            VStack(alignment: .leading) {
                Text(verbatim: "Beacon").font(.headline).widgetAccentable()
                Text("Open Beacon on the watch to see your Mac here.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    /// The chosen reading first, then the others, three in all.
    private var rows: [ComplicationMetric] {
        Array(([metric] + [.cpu, .memory, .temperature, .gpu].filter { $0 != metric }).prefix(3))
    }
}

extension LastReading {
    /// The demo Mac's reading, for the face editor's preview.
    static let sample = LastReading(macID: DemoData.pairing.id, macName: DemoData.pairing.name, time: .now, cpu: 0.23, memory: 0.65,
                                    gpu: 0.12, cpuTemperature: 54, temperatureUnit: .celsius)

    /// The reading as a share of its gauge: a usage as it is, a temperature between 20 and 100 °C.
    func fraction(_ metric: ComplicationMetric) -> Double? {
        switch metric {
        case .cpu: return cpu
        case .memory: return memory
        case .gpu: return gpu
        case .temperature: return cpuTemperature.map { min(1, max(0, ($0 - 20) / 80)) }
        }
    }

    func value(_ metric: ComplicationMetric) -> String {
        switch metric {
        case .cpu: return Format.percent(cpu)
        case .memory: return Format.percent(memory)
        case .gpu: return Format.percent(gpu)
        case .temperature: return Format.temperature(cpuTemperature, unit: temperatureUnit)
        }
    }

    /// As `value`, but a temperature without its unit's letter, to fit a ring.
    func shortValue(_ metric: ComplicationMetric) -> String {
        guard metric == .temperature else { return value(metric) }
        guard let celsius = cpuTemperature else { return "–" }
        let degrees = temperatureUnit == .fahrenheit ? celsius * 9 / 5 + 32 : celsius
        return "\(degrees.formatted(.number.precision(.fractionLength(0))))°"
    }
}
