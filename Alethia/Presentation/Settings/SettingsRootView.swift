//
//  SettingsRootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/11/2024.
//

import SwiftUI
import SwiftData
import Setting

struct SettingsRootView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            Button("Delete History") {
                deleteAllReadingHistory()
            }
            
            SettingStack {
                SettingPage(title: "Settings") {
                    SettingGroup {
                        SettingPage(title: "General") {
                            general
                        }
                        .previewIcon("gearshape.fill")
                    }
                    
                    SettingGroup {
                        SettingPage(title: "Privacy") {
                            notImplemented
                        }
                        .previewIcon("hand.raised.fill", color: .green)
                        
                        SettingPage(title: "Notifications") {
                            notImplemented
                        }
                        .previewIcon("bell.badge.fill", color: .red)
                        
                        SettingPage(title: "Tracking") {
                            notImplemented
                        }
                        .previewIcon("clock.arrow.2.circlepath")
                    }
                    
                    SettingGroup {
                        SettingPage(title: "Library") {
                            notImplemented
                        }
                        .previewIcon("books.vertical.fill", color: .orange)
                        
                        SettingPage(title: "Collections") {
                            collection
                        }
                        .previewIcon("rectangle.3.group.fill", color: .red)
                        
                        SettingPage(title: "Tags") {
                            notImplemented
                        }
                        .previewIcon("tag.fill", color: .blue)
                        
                        SettingPage(title: "History") {
                            history
                        }
                        .previewIcon("clock.fill", color: .green)
                    }
                    
                    SettingGroup {
                        SettingPage(title: "Sources") {
                            notImplemented
                        }
                        .previewIcon("cube.box.fill", color: .purple)
                        
                        SettingPage(title: "Reader") {
                            reader
                        }
                        .previewIcon("book.fill", color: .orange)
                        
                        SettingPage(title: "Storage") {
                            notImplemented
                        }
                        .previewIcon("externaldrive.fill", color: .teal)
                    }
                    
                    SettingGroup {
                        SettingPage(title: "Backups") {
                            notImplemented
                        }
                        .previewIcon("hand.raised.fill", color: .green)
                        
                        SettingPage(title: "About") {
                            about
                        }
                        .previewIcon("hand.raised.fill", color: .appPurple)
                    }
                }
            }
        }
        .alert("Delete All Reading History", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllReadingHistory()
            }
        } message: {
            Text("This action cannot be undone. Are you sure you want to delete all reading history?")
        }
    }
    
    @SettingBuilder var notImplemented: some Setting {
        SettingText(title: "Not Yet Implemented!")
    }
    
    @AppStorage("haptics") private var haptics = false
    @SettingBuilder var general: some Setting {
        SettingGroup(header: "Controls") {
            SettingToggle(title: "Allow Custom Haptic Feedback", isOn: $haptics)
        }
    }
    
    @Query private var collections: [Collection]
    @SettingBuilder var collection: some Setting {
        SettingGroup(header: "General") {
            
        }
        
        SettingGroup(header: "All Collections") {
            SettingCustomView {
                Section {
                    ForEach(collections, id: \.id) { item in
                        NavigationButton(
                            action: {
                                if haptics {
                                    Haptics.impact()
                                }
                            },
                            destination: {
                                CollectionEditView(collection: item)
                            },
                            label: {
                                HStack {
                                    Text(item.name)
                                    
                                    Spacer()
                                    
                                    Text("\(item.size) Total")
                                    
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .foregroundStyle(.text)
                            }
                        )
                    }
                }
            }
        }
    }
    
    @AppStorage("prefetch") private var prefetch = 0
    @SettingBuilder var reader: some Setting {
        SettingGroup {
            SettingCustomView {
                HStack {
                    Text("Pages To Prefetch")
                    Spacer()
                    HStack(spacing: 15) {
                        Button {
                            prefetch = max(0, prefetch - 1)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(prefetch == 0 ? Color.tint : Color.gray)
                                .imageScale(.large)
                                .animation(.easeInOut(duration: 0.2), value: prefetch)
                        }
                        .disabled(prefetch == 0)
                        
                        Text("\(prefetch)")
                            .frame(minWidth: 30)
                            .font(.headline)
                        
                        Button{
                            prefetch += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(prefetch == 0 ? Color.tint : Color.gray)
                                .imageScale(.large)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
            }
        }
    }
    
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "Version \(version) (\(build))"
        }
        return "Version Unknown"
    }
    
    @SettingBuilder
    private var about: some Setting {
        SettingGroup {
            SettingCustomView {
                HStack {
                    Text("App Version")
                    
                    Spacer()
                    
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
            }
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false
    
    @SettingBuilder
    private var history: some Setting {
        SettingGroup {
            SettingPage(title: "Delete All History") {
                SettingCustomView {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete All Reading History")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func deleteAllReadingHistory() {
            do {
                // Fetch all reading histories first
                let descriptor = FetchDescriptor<ReadingHistory>()
                let histories = try modelContext.fetch(descriptor)
                
                // Delete each history individually to properly handle relationships
                for history in histories {
                    modelContext.delete(history)
                }
                
                try modelContext.save()
                print("Successfully deleted all reading history.")
            } catch {
                print("Failed to delete reading history: \(error)")
            }
        }
}


private struct CollectionEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var collection: Collection
    @State private var showingDeleteAlert = false
    @State private var newName: String = ""
    
    private var isDefaultCollection: Bool {
        collection.name == "Default"
    }
    
    var body: some View {
        List {
            Section {
                if isDefaultCollection {
                    Text(collection.name)
                        .foregroundColor(.secondary)
                } else {
                    TextField("New Name", text: $newName)
                        .accessibilityLabel("Edit collection name")
                    
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(newName.isEmpty || newName == collection.name)
                    .accessibilityHint("Save the new collection name")
                }
            } header: {
                Text(isDefaultCollection ? "Default Collection" : "Edit Name - \(collection.name)")
            } footer: {
                if isDefaultCollection {
                    Text("The default collection cannot be edited or removed.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            if !isDefaultCollection {
                Section {
                    Button("Delete Collection", role: .destructive) {
                        showingDeleteAlert = true
                    }
                    .accessibilityHint("Delete this collection permanently")
                } footer: {
                    Text("Deleting this collection will remove it from all associated manga.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Edit Collection")
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete Collection", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCollection()
            }
        } message: {
            Text("Are you sure you want to delete this collection? All manga will lose a relationship to this collection. This action cannot be undone.")
        }
    }
    
    private func saveChanges() {
        guard !isDefaultCollection else { return }
        collection.name = newName
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteCollection() {
        guard !isDefaultCollection else { return }
        modelContext.delete(collection)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    SettingsRootView()
}
