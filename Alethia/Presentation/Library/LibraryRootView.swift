//
//  LibraryRootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

struct LibraryRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(descriptor) private var allManga: [Manga]
    @Query private var collections: [Collection]
    
    @State private var searchText = ""
    @State private var selectedCollection: Collection?
    
    private static var descriptor = FetchDescriptor<Manga>(
        predicate: #Predicate { $0.inLibrary }
    )
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(searchText: $searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                CollectionSelector(collections: collections, selectedCollection: $selectedCollection)
                    .padding(.top, 8)
                
                MangaListView(manga: filteredManga())
                
                Spacer()
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal.decrease")
                        }
                        Button(action: {}) {
                            Image(systemName: "slider.horizontal.3")
                        }
                        Button(action: {}) {
                            Image(systemName: "gearshape")
                        }
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            if selectedCollection == nil {
                selectedCollection = collections.first { $0.name == "Default" }
            }
        }
    }
    
    private func filteredManga() -> [Manga] {
        allManga.filter { manga in
            let collectionMatch = selectedCollection == nil || manga.collections.contains(selectedCollection!)
            return collectionMatch && (searchText.isEmpty || manga.title.localizedCaseInsensitiveContains(searchText))
        }
    }
}

struct CollectionSelector: View {
    let collections: [Collection]
    @Binding var selectedCollection: Collection?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(collections) { collection in
                    VStack {
                        Text(collection.name)
                            .foregroundColor(selectedCollection == collection ? .white : .gray)
                        if selectedCollection == collection {
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(.blue)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut){
                            selectedCollection = collection
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MangaListView: View {
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    @Namespace private var namespace
    let manga: [Manga]
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        if manga.isEmpty {
            VStack {
                Spacer()
                Text("No Manga For This Section.")
                Text("(︶︹︺)")
                Spacer()
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(manga) { item in
                        if let entry = try? item.toMangaEntry() {
                            NavigationLink {
                                DetailView(entry: entry)
                                    .navigationTransition(.zoom(sourceID: "image-\(item.id)", in: namespace))
                            } label: {
                                MangaEntryView(item: entry)
                                    .matchedTransitionSource(id: "image-\(item.id)", in: namespace)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                if hapticsEnabled {
                                    Haptics.impact()
                                }
                            })
                        } else {
                            Text("Unavailable to convert \(item.title) to entry.")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    LibraryRootView()
}
