import SwiftUI
import SwiftData

struct SettingsView: View {
    var profile: UserProfile

    @Environment(\.modelContext) private var modelContext

    @State private var unitSystem: UnitSystem
    @State private var heightCm: Double
    @State private var feet: Int
    @State private var inches: Double

    init(profile: UserProfile) {
        self.profile = profile
        _unitSystem = State(initialValue: profile.unitSystem)
        _heightCm = State(initialValue: profile.heightCm)
        let totalInches = UnitConversion.cmToInches(profile.heightCm)
        _feet = State(initialValue: Int(totalInches / 12))
        _inches = State(initialValue: (totalInches).truncatingRemainder(dividingBy: 12).rounded())
    }

    var body: some View {
        Form {
            Section("Units") {
                Picker("Units", selection: $unitSystem) {
                    Text("Pounds / ft-in").tag(UnitSystem.imperial)
                    Text("Kilograms / cm").tag(UnitSystem.metric)
                }
                .pickerStyle(.segmented)
                .onChange(of: unitSystem) { _, newValue in
                    profile.unitSystem = newValue
                    try? modelContext.save()
                }
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
                            .onChange(of: heightCm) { _, newValue in
                                profile.heightCm = newValue
                                try? modelContext.save()
                            }
                        Text("cm")
                    }
                } else {
                    HStack {
                        Stepper("\(feet) ft", value: $feet, in: 3...8)
                            .onChange(of: feet) { _, _ in updateImperialHeight() }
                        Divider()
                        Stepper("\(Int(inches)) in", value: $inches, in: 0...11)
                            .onChange(of: inches) { _, _ in updateImperialHeight() }
                    }
                }
            }

            Section("About") {
                LabeledContent("App", value: "Weight Journey")
                LabeledContent("Version", value: "1.0")
            }
        }
        .navigationTitle("Settings")
    }

    private func updateImperialHeight() {
        heightCm = UnitConversion.heightFromFeetInches(feet: feet, inches: inches)
        profile.heightCm = heightCm
        try? modelContext.save()
    }
}
