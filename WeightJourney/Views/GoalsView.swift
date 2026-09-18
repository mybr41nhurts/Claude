import SwiftUI
import SwiftData

struct GoalsView: View {
    var profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @Query(filter: #Predicate<WeightGoal> { $0.isActive }) private var activeGoals: [WeightGoal]

    @State private var isPresentingNewGoal = false

    private var goal: WeightGoal? { activeGoals.first }
    private var latestWeightKg: Double? { entries.first?.weightKg }

    var body: some View {
        Group {
            if let goal {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(UnitConversion.formattedWeight(goal.startWeightKg, unit: profile.unitSystem))
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)
                                Text(UnitConversion.formattedWeight(goal.targetWeightKg, unit: profile.unitSystem))
                                    .fontWeight(.semibold)
                            }
                            .font(.title3)

                            if let latestWeightKg {
                                ProgressView(value: goal.progress(currentWeightKg: latestWeightKg))
                                    .tint(.green)
                                Text("\(Int(goal.progress(currentWeightKg: latestWeightKg) * 100))% of the way there")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let targetDate = goal.targetDate {
                                Label(targetDate.formatted(date: .abbreviated, time: .omitted), systemImage: "flag.checkered")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Milestones") {
                        ForEach(goal.milestones.sorted { $0.order < $1.order }) { milestone in
                            MilestoneRow(
                                milestone: milestone,
                                unit: profile.unitSystem,
                                isAchieved: milestone.isAchieved(latestWeightKg: latestWeightKg, isLossGoal: goal.isLossGoal),
                                achievedDate: milestone.achievedDate(entries: entries, isLossGoal: goal.isLossGoal)
                            )
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            endGoal(goal)
                        } label: {
                            Text("End This Goal")
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No active goal",
                    systemImage: "target",
                    description: Text("Set a goal weight and we'll break it into milestones for you.")
                )
            }
        }
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNewGoal = true
                } label: {
                    Label("New Goal", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewGoal) {
            NewGoalView(profile: profile, currentWeightKg: latestWeightKg ?? UnitConversion.weightToKg(150, unit: profile.unitSystem))
        }
    }

    private func endGoal(_ goal: WeightGoal) {
        goal.isActive = false
        try? modelContext.save()
    }
}

private struct MilestoneRow: View {
    var milestone: Milestone
    var unit: UnitSystem
    var isAchieved: Bool
    var achievedDate: Date?

    var body: some View {
        HStack {
            Image(systemName: isAchieved ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isAchieved ? .green : .secondary)
            VStack(alignment: .leading) {
                Text(UnitConversion.formattedWeight(milestone.targetWeightKg, unit: unit))
                    .fontWeight(isAchieved ? .semibold : .regular)
                if let achievedDate {
                    Text("Reached \(achievedDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

private struct NewGoalView: View {
    var profile: UserProfile
    var currentWeightKg: Double

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allGoals: [WeightGoal]

    @State private var targetWeightValue: Double
    @State private var hasTargetDate = false
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now
    @State private var milestoneCount: Double = 5

    init(profile: UserProfile, currentWeightKg: Double) {
        self.profile = profile
        self.currentWeightKg = currentWeightKg
        _targetWeightValue = State(initialValue: UnitConversion.displayWeight(currentWeightKg, unit: profile.unitSystem) - 10)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Current")
                        Spacer()
                        Text(UnitConversion.formattedWeight(currentWeightKg, unit: profile.unitSystem))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Goal weight")
                        Spacer()
                        TextField(profile.unitSystem.weightUnitLabel, value: $targetWeightValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(profile.unitSystem.weightUnitLabel)
                    }
                }

                Section {
                    Toggle("Target a specific date", isOn: $hasTargetDate.animation())
                    if hasTargetDate {
                        DatePicker("Target date", selection: $targetDate, in: Date.now..., displayedComponents: .date)
                    }
                    Stepper("Milestones: \(Int(milestoneCount))", value: $milestoneCount, in: 1...10)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { save() }
                }
            }
        }
    }

    private func save() {
        for existing in allGoals where existing.isActive {
            existing.isActive = false
        }

        let targetWeightKg = UnitConversion.weightToKg(targetWeightValue, unit: profile.unitSystem)
        let goal = WeightGoal(
            startDate: .now,
            startWeightKg: currentWeightKg,
            targetWeightKg: targetWeightKg,
            targetDate: hasTargetDate ? targetDate : nil,
            isActive: true,
            milestoneCount: Int(milestoneCount)
        )
        modelContext.insert(goal)

        let milestones = MilestoneGenerator.generate(
            startWeightKg: currentWeightKg,
            targetWeightKg: targetWeightKg,
            count: Int(milestoneCount)
        )
        for milestone in milestones {
            milestone.goal = goal
            modelContext.insert(milestone)
        }

        try? modelContext.save()
        dismiss()
    }
}
