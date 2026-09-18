import SwiftUI
import SwiftData

struct LogWeightView: View {
    var profile: UserProfile
    var entryToEdit: WeightEntry?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var weightValue: Double
    @State private var note: String

    init(profile: UserProfile, entryToEdit: WeightEntry? = nil) {
        self.profile = profile
        self.entryToEdit = entryToEdit
        _date = State(initialValue: entryToEdit?.date ?? .now)
        if let entryToEdit {
            _weightValue = State(initialValue: UnitConversion.displayWeight(entryToEdit.weightKg, unit: profile.unitSystem))
        } else {
            _weightValue = State(initialValue: 0)
        }
        _note = State(initialValue: entryToEdit?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weigh-in") {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField(profile.unitSystem.weightUnitLabel, value: $weightValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text(profile.unitSystem.weightUnitLabel)
                    }
                }
                Section("Note (optional)") {
                    TextField("e.g. after workout", text: $note)
                }
            }
            .navigationTitle(entryToEdit == nil ? "Log Weight" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(weightValue <= 0)
                }
            }
        }
    }

    private func save() {
        let weightKg = UnitConversion.weightToKg(weightValue, unit: profile.unitSystem)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let entryToEdit {
            entryToEdit.date = date
            entryToEdit.weightKg = weightKg
            entryToEdit.note = trimmedNote.isEmpty ? nil : trimmedNote
        } else {
            let entry = WeightEntry(date: date, weightKg: weightKg, note: trimmedNote.isEmpty ? nil : trimmedNote)
            modelContext.insert(entry)
        }

        try? modelContext.save()
        dismiss()
    }
}
