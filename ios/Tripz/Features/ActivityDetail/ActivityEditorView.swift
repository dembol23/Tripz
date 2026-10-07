import SwiftUI
import TripzKit

struct ActivityEditorView: View {
    let viewModel: ActivityDetailViewModel
    private let source: ActivitySource
    
    @State private var edit: ActivityEdit
    @State private var errorMessage: String?
    @State private var isConfirmingDelete = false
    @State private var isWorking = false
    @Environment(\.dismiss) private var dismiss
    
    init(activity: Activity, viewModel: ActivityDetailViewModel) {
        self.viewModel = viewModel
        self.source = activity.source
        _edit = State(initialValue: ActivityEdit(activity))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $edit.title)
                }
                Section("Notes") {
                    TextField("Notes", text: $edit.notes, axis: .vertical)
                        .lineLimit(3...8)
                }
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
                Section {
                    Button("Delete activity", role: .destructive) { isConfirmingDelete = true }
                }
            }
            .navigationTitle("Edit activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                }
            }
            .confirmationDialog("Delete this activity?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { Task { await delete() } }
            } message: {
                Text(deleteMessage)
            }
            .disabled(isWorking)
        }
        .presentationDetents([.medium, .large])
    }
    
    private var deleteMessage: String {
        switch source {
        case .manual:
            "This can't be undone"
        case .appleHealth:
            "It is removed from Tripz only. The workout stays in Apple Health."
        }
    }
    
    private func save() async {
        isWorking = true
        errorMessage = await viewModel.apply(edit)
        isWorking = false
        if errorMessage == nil { dismiss() }
    }
    
    private func delete() async {
        isWorking = true
        errorMessage = await viewModel.delete()
        isWorking = false
    }
}
