import SwiftUI
import SwiftData
import Charts

private enum TrendRange: String, CaseIterable, Identifiable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 182
        case .year: return 365
        case .all: return nil
        }
    }
}

struct TrendsView: View {
    var profile: UserProfile

    @Query(sort: \WeightEntry.date, order: .forward) private var allEntries: [WeightEntry]
    @Query(filter: #Predicate<WeightGoal> { $0.isActive }) private var activeGoals: [WeightGoal]

    @State private var range: TrendRange = .threeMonths

    private var goal: WeightGoal? { activeGoals.first }

    private var filteredEntries: [WeightEntry] {
        guard let days = range.days else { return allEntries }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
        return allEntries.filter { $0.date >= cutoff }
    }

    /// A trailing 7-entry moving average, giving a smoother line than raw weigh-ins.
    private var movingAverage: [(date: Date, weightKg: Double)] {
        let source = filteredEntries
        guard source.count > 1 else { return [] }
        var result: [(date: Date, weightKg: Double)] = []
        for index in source.indices {
            let windowStart = max(0, index - 6)
            let window = source[windowStart...index]
            let average = window.reduce(0) { $0 + $1.weightKg } / Double(window.count)
            result.append((source[index].date, average))
        }
        return result
    }

    private var forecastPoints: [(date: Date, weightKg: Double)] {
        guard let goal, let lastDate = filteredEntries.last?.date else { return [] }
        let forecast = ForecastEngine.forecast(entries: allEntries, goalWeightKg: goal.targetWeightKg)
        guard let projectedDate = forecast.projectedDate, projectedDate > lastDate else { return [] }

        var points: [(date: Date, weightKg: Double)] = []
        let totalDays = max(1, Int(projectedDate.timeIntervalSince(lastDate) / 86400))
        let step = max(1, totalDays / 12)
        var offset = 0
        while offset <= totalDays {
            let date = lastDate.addingTimeInterval(Double(offset) * 86400)
            if let weight = ForecastEngine.projectedWeight(entries: allEntries, on: date) {
                points.append((date, weight))
            }
            offset += step
        }
        return points
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Range", selection: $range) {
                    ForEach(TrendRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if filteredEntries.isEmpty {
                    ContentUnavailableView(
                        "No data in this range",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Try a wider range or log a new weigh-in.")
                    )
                    .padding(.top, 40)
                } else {
                    Chart {
                        ForEach(filteredEntries) { entry in
                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("Weight", UnitConversion.displayWeight(entry.weightKg, unit: profile.unitSystem))
                            )
                            .foregroundStyle(.blue.opacity(0.5))
                            .symbolSize(20)
                        }

                        ForEach(movingAverage, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("7-entry average", UnitConversion.displayWeight(point.weightKg, unit: profile.unitSystem))
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }

                        ForEach(forecastPoints, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Forecast", UnitConversion.displayWeight(point.weightKg, unit: profile.unitSystem)),
                                series: .value("Series", "Forecast")
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                        }

                        if let goal {
                            RuleMark(y: .value("Goal", UnitConversion.displayWeight(goal.targetWeightKg, unit: profile.unitSystem)))
                                .foregroundStyle(.orange)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("Goal")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                        }
                    }
                    .frame(height: 280)
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        LegendDot(color: .blue, label: "Weigh-ins & trend")
                        LegendDot(color: .green, label: "Forecast")
                        if goal != nil {
                            LegendDot(color: .orange, label: "Goal")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Trends")
    }
}

private struct LegendDot: View {
    var color: Color
    var label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}
