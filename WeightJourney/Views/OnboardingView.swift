import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var unitSystem: UnitSystem = .imperial
    @State private var heightCm: Double = 170
    @State private var feet: Int = 5
    @State private var inches: Double = 7

    @State private var startDate: Date = .now
    @State private var startWeightValue: Double = 180
    @State private var hasGoal: Bool = true
    @State private var targetWeightValue: Double = 160
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now
    @State private var milestoneCount: Double = 5

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Let's set up your profile so we can calculate BMI, trends, and a forecast.")
                        .foregroundStyle(.secondary)
                }

                Section("Units") {
                    Picker("Units", selection: $unitSystem) {
                        Text("Pounds / ft-in").tag(UnitSystem.imperial)
                        Text("Kilograms / cm").tag(UnitSystem.metric)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Height") {
                    if unitSystem == .metric {
                        HStack {
                            Text("Height")
                            Spacer()
                            TextField("cm", value: $heightCm, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("cm")
                        }
                    } else {
                        HStack {
                            Stepper("\(feet) ft", value: $feet, in: 3...8)
                            Divider()
                            Stepper("\(Int(inches)) in", value: $inches, in: 0...11)
                        }
                    }
                }

                Section("Starting weight") {
                    DatePicker("Date", selection: $startDate, in: ...Date.now, displayedComponents: .date)
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField(unitSystem.weightUnitLabel, value: $startWeightValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unitSystem.weightUnitLabel)
                    }
                } footer: {
                    Text("You can back-date this if you already know your weight from a past date.")
                }

                Section("Goal") {
                    Toggle("Set a goal weight", isOn: $hasGoal.animation())
                    if hasGoal {
                        HStack {
                            Text("Goal weight")
                            Spacer()
                            TextField(unitSystem.weightUnitLabel, value: $targetWeightValue, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text(unitSystem.weightUnitLabel)
                        }
                        Toggle("Target a specific date", isOn: $hasTargetDate.animation())
                        if hasTargetDate {
                            DatePicker("Target date", selection: $targetDate, in: Date.now..., displayedComponents: .date)
                        }
                        VStack(alignment: .leading) {
                            Stepper("Milestones: \(Int(milestoneCount))", value: $milestoneCount, in: 1...10)
                            Text("Your goal will be split into \(Int(milestoneCount)) even milestones to help you track progress.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button("Get Started") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
            .navigationTitle("Weight Journey")
        }
    }

    private func save() {
        let resolvedHeightCm = unitSystem == .metric ? heightCm : UnitConversion.heightFromFeetInches(feet: feet, inches: inches)
        let profile = UserProfile(heightCm: resolvedHeightCm, unitSystem: unitSystem)
        modelContext.insert(profile)

        let startWeightKg = UnitConversion.weightToKg(startWeightValue, unit: unitSystem)
        let entry = WeightEntry(date: startDate, weightKg: startWeightKg)
        modelContext.insert(entry)

        if hasGoal {
            let targetWeightKg = UnitConversion.weightToKg(targetWeightValue, unit: unitSystem)
            let goal = WeightGoal(
                startDate: startDate,
                startWeightKg: startWeightKg,
                targetWeightKg: targetWeightKg,
                targetDate: hasTargetDate ? targetDate : nil,
                isActive: true,
                milestoneCount: Int(milestoneCount)
            )
            modelContext.insert(goal)

            let milestones = MilestoneGenerator.generate(
                startWeightKg: startWeightKg,
                targetWeightKg: targetWeightKg,
                count: Int(milestoneCount)
            )
            for milestone in milestones {
                milestone.goal = goal
                modelContext.insert(milestone)
            }
        }

        try? modelContext.save()
    }
}
