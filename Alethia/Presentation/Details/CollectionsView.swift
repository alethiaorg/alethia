//
//  CollectionsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 25/11/2024.
//

import SwiftUI
import SwiftData
import Flow

struct CollectionsView: View {
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    let manga: Manga
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationButton(
                action: {
                    if hapticsEnabled {
                        Haptics.impact()
                    }
                },
                destination: {
                    ManageCollectionsView(manga: manga)
                },
                label: {
                    HStack {
                        Text("Collections")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Image(systemName: "arrow.right")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(.text)
                }
            )
            
            HFlow(spacing: 12) {
                ForEach(manga.collections, id: \.id) { collection in
                    HStack(spacing: 8) {
                        
                        Image(systemName: "square.grid.2x2.fill")
                        
                        Text(collection.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(12)
                    .background(Color.tint)
                    .cornerRadius(8)
                }
            }
        }
        .opacity(manga.inLibrary ? 1 : 0.5)
    }
}

struct ManageCollectionsView: View {
    @Namespace private var namespace
    @Environment(\.modelContext) private var modelContext
    @Query private var allCollections: [Collection]
    
    let manga: Manga
    
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var selectedCollection: Collection?
    @State private var newCollectionName = ""
    @State private var showingCreateAlert = false
    
    var filteredCollections: [Collection] {
        let collectionsSet = Set(manga.collections)
        return allCollections.filter { !collectionsSet.contains($0) }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 8) {
                SearchBar(searchText: $searchText)
                    .frame(maxHeight: .infinity)
                
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.text)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel("Add to collection")
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            
            Divider()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(manga.collections) { collection in
                        NavigationLink {
                            CollectionDetailView(collection: collection)
                                .navigationTransition(.zoom(sourceID: "collection-\(collection.id)", in: namespace))
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.text)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(collection.name)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.text)
                                    
                                    Text("\(collection.size) Total")
                                        .font(.system(size: 15))
                                        .foregroundColor(.text.opacity(0.7))
                                }
                            }
                            .foregroundStyle(.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.tint.opacity(0.7))
                            .cornerRadius(16)
                            .matchedTransitionSource(id: "collection-\(collection.id)", in: namespace)
                        }
                        .accessibilityLabel("Collection: \(collection.name), \(collection.size) items")
                        .contextMenu {
                            Button {
                            } label: {
                                Label("View In Library", systemImage: "square.arrowtriangle.4.outward")
                            }
                            Button(role: .destructive) {
                                removeCollectionFromManga(collection)
                            } label: {
                                Label("Remove Group From Manga", systemImage: "minus.circle")
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 15)
        }
        .navigationTitle("Manage Collections")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddSheet) {
            AddCollectionSheet(
                showingAddSheet: $showingAddSheet,
                collections: manga.collections,
                modelContext: modelContext,
                manga: manga
            )
        }
    }
    
    private func removeCollectionFromManga(_ collection: Collection) {
        manga.collections.removeAll { $0.id == collection.id }
        try? modelContext.save()
    }
}

private struct AddCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query var allCollections: [Collection]
    @Binding var showingAddSheet: Bool
    
    let collections: [Collection]
    let modelContext: ModelContext
    let manga: Manga
    
    var availableCollections: [Collection] {
        allCollections.filter { collection in
            !collections.contains(where: { $0.id == collection.id })
        }
    }
    
    var validCollectionName: Bool {
        !newCollectionName.isEmpty && allCollections.allSatisfy { $0.name != newCollectionName }
    }
    
    @State private var selectedCollection: Collection?
    @State private var newCollectionName = ""
    @State private var showingCreateAlert = false
    @State private var isCreatingNewCollection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    existingCollectionsSection
                    Divider()
                    newCollectionSection
                }
                .padding()
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .alert(isPresented: $showingCreateAlert) {
            Alert(
                title: Text("Invalid Name"),
                message: Text("Please enter a unique name for the new collection."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var existingCollectionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add to Existing Collection")
                .font(.headline)
            
            if availableCollections.isEmpty {
                Text("No available collections")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Picker("Select Collection", selection: $selectedCollection) {
                    Text("Select a collection").tag(nil as Collection?)
                    ForEach(availableCollections, id: \.self) { collection in
                        Text(collection.name).tag(collection as Collection?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: {
                if let collection = selectedCollection {
                    addMangaToCollection(collection)
                }
            }) {
                Text("Add to Selected Collection")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedCollection != nil ? Color.accentColor : Color.secondary.opacity(0.3))
                    .foregroundColor(selectedCollection != nil ? .white : .secondary)
                    .cornerRadius(8)
            }
            .disabled(selectedCollection == nil)
        }
    }
    
    private var newCollectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Collection")
                .font(.headline)
            
            HStack {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
                    .accessibilityHidden(true)
                
                TextField("Search", text: $newCollectionName)
                    .accessibilityLabel("Search collections")
                
                if !newCollectionName.isEmpty {
                    Button(action: {
                        newCollectionName = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 17))
                    }
                    .accessibilityLabel("Clear")
                    .animation(.easeInOut, value: newCollectionName)
                }
            }
            .padding(8)
            .frame(maxHeight: .infinity)
            .background(Color.tint)
            .cornerRadius(10)
            
            Text("\(newCollectionName.count)/20 characters")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                if validCollectionName {
                    let createdCollection = createCollection()
                    addMangaToCollection(createdCollection)
                } else {
                    showingCreateAlert = true
                }
            }) {
                Text("Create and Add")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(validCollectionName ? Color.accentColor : Color.secondary.opacity(0.3))
                    .foregroundColor(validCollectionName ? .white : .secondary)
                    .cornerRadius(8)
            }
            .disabled(!validCollectionName)
        }
    }
    
    private func createCollection() -> Collection {
        let newCollection = Collection(name: newCollectionName)
        modelContext.insert(newCollection)
        return newCollection
    }
    
    private func addMangaToCollection(_ collection: Collection) {
        manga.collections.append(collection)
        try? modelContext.save()
        dismiss()
    }
}


private struct CollectionDetailView: View {
    let collection: Collection
    
    var body: some View {
        Text("TODO: More on collection details")
            .font(.largeTitle)
            .navigationTitle("Collection Details")
    }
}
