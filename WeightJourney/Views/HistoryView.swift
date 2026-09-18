import SwiftUI
import SwiftData

struct HistoryView: View {
    var profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]

    @State private var isPresentingAddSheet = false
    @State private var entryToEdit: WeightEntry?

    private var groupedByMonth: [(month: Date, entries: [WeightEntry])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: entries) { entry in
            calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)) ?? entry.date
        }
        return groups
            .map { (month: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No entries yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Add your first weigh-in, or back-fill your history.")
                )
            } else {
                List {
                    ForEach(groupedByMonth, id: \.month) { group in
                        Section(group.month.formatted(.dateTime.month(.wide).year())) {
                            ForEach(group.entries) { entry in
                                Button {
                                    entryToEdit = entry
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(UnitConversion.formattedWeight(entry.weightKg, unit: profile.unitSystem))
                                                .font(.body.weight(.medium))
                                            if let note = entry.note, !note.isEmpty {
                                                Text(note)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Text(entry.date, format: .dateTime.month(.abbreviated).day().year())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .foregroundStyle(.primary)
                            }
                            .onDelete { offsets in
                                delete(entries: group.entries, at: offsets)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddSheet = true
                } label: {
                    Label("Add Entry", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddSheet) {
            LogWeightView(profile: profile)
        }
        .sheet(item: $entryToEdit) { entry in
            LogWeightView(profile: profile, entryToEdit: entry)
        }
    }

    private func delete(entries entriesInGroup: [WeightEntry], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entriesInGroup[index])
        }
        try? modelContext.save()
    }
}
