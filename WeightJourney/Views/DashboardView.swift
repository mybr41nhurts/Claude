import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    var profile: UserProfile
    @Binding var isPresentingLogSheet: Bool

    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @Query(filter: #Predicate<WeightGoal> { $0.isActive }) private var activeGoals: [WeightGoal]

    private var goal: WeightGoal? { activeGoals.first }
    private var latestEntry: WeightEntry? { entries.first }
    private var recentEntries: [WeightEntry] {
        Array(entries.prefix(30)).sorted { $0.date < $1.date }
    }

    private var forecast: ForecastResult {
        ForecastEngine.forecast(entries: entries, goalWeightKg: goal?.targetWeightKg)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let latestEntry {
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Current Weight",
                            value: UnitConversion.formattedWeight(latestEntry.weightKg, unit: profile.unitSystem),
                            icon: "scalemass",
                            tint: .blue
                        )
                        let bmi = BMICalculator.bmi(weightKg: latestEntry.weightKg, heightCm: profile.heightCm)
                        let category = BMICalculator.category(for: bmi)
                        StatCard(
                            title: "BMI · \(category.rawValue)",
                            value: String(format: "%.1f", bmi),
                            icon: "figure.arms.open",
                            tint: category.color
                        )
                    }

                    if !recentEntries.isEmpty {
                        MiniTrendChart(entries: recentEntries, unit: profile.unitSystem)
                            .frame(height: 160)
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }

                    if let goal {
                        GoalProgressCard(goal: goal, currentWeightKg: latestEntry.weightKg, unit: profile.unitSystem)
                    }

                    ForecastCard(forecast: forecast, unit: profile.unitSystem)
                } else {
                    ContentUnavailableView(
                        "No weigh-ins yet",
                        systemImage: "scalemass",
                        description: Text("Log your first weight to get started.")
                    )
                    .padding(.top, 60)
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingLogSheet = true
                } label: {
                    Label("Log Weight", systemImage: "plus.circle.fill")
                }
            }
        }
    }
}

private struct StatCard: View {
    var title: String
    var value: String
    var icon: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct MiniTrendChart: View {
    var entries: [WeightEntry]
    var unit: UnitSystem

    var body: some View {
        VStack(alignment: .leading) {
            Text("Last 30 entries")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Chart(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", UnitConversion.displayWeight(entry.weightKg, unit: unit))
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", UnitConversion.displayWeight(entry.weightKg, unit: unit))
                )
                .foregroundStyle(.blue)
            }
            .chartXAxis(.hidden)
        }
    }
}

private struct GoalProgressCard: View {
    var goal: WeightGoal
    var currentWeightKg: Double
    var unit: UnitSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Goal Progress", systemImage: "target")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(UnitConversion.formattedWeight(goal.targetWeightKg, unit: unit))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: goal.progress(currentWeightKg: currentWeightKg))
                .tint(.green)
            HStack {
                Text("Start: \(UnitConversion.formattedWeight(goal.startWeightKg, unit: unit))")
                Spacer()
                Text("\(Int(goal.progress(currentWeightKg: currentWeightKg) * 100))% there")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ForecastCard: View {
    var forecast: ForecastResult
    var unit: UnitSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Forecast", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.semibold))

            if let projectedDate = forecast.projectedDate {
                Text(projectedDate, format: .dateTime.month(.wide).day().year())
                    .font(.title3.weight(.semibold))
                Text("Estimated goal date at your current pace")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(forecast.reason ?? "Not enough data yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if forecast.slopeKgPerDay != 0 {
                let perWeek = forecast.slopeKgPerDay * 7
                Text("Trend: \(UnitConversion.formattedWeight(abs(perWeek), unit: unit, fractionDigits: 2)) per week \(perWeek < 0 ? "loss" : "gain")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
