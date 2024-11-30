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
    @Query private var collections: [Collection]
    @State private var searchText = ""
    @State private var selectedCollection: Collection?
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(searchText: $searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                CollectionSelector(collections: collections, selectedCollection: $selectedCollection)
                    .padding(.vertical, 4)
                
                MangaListView(searchText: searchText, selectedCollection: selectedCollection)
                
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
}

private struct MangaListView: View {
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    @Namespace private var namespace
    
    @Query private var manga: [Manga]
    @State private var isContentVisible: Bool = false
    
    let searchText: String
    let selectedCollection: Collection?
        
    init(searchText: String, selectedCollection: Collection?) {
        self.searchText = searchText
        self.selectedCollection = selectedCollection
        
        _manga = Query(filter: MangaListView.buildPredicate(searchText: searchText, selectedCollection: selectedCollection))
    }
    
    let columns = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]
    
    private static func buildPredicate(searchText: String, selectedCollection: Collection?) -> Predicate<Manga> {
        let searchTextEmpty: Bool = searchText.isEmpty
        
        let selectedCollectionTitle = selectedCollection == nil ? "" : selectedCollection!.name
        let collectionTitleEmpty = selectedCollectionTitle.isEmpty
        
        return #Predicate<Manga> { manga in
            // Must be in library
            manga.inLibrary &&
            
            // Search-related filters
            (
                searchTextEmpty ||
                manga.title.localizedStandardContains(searchText) ||
                manga.alternativeTitles.contains { $0.title.localizedStandardContains(searchText) }
            ) &&
            
            // Collection-related filters
            (
                collectionTitleEmpty ||
                manga.collections.contains { $0.name.localizedStandardContains(selectedCollectionTitle) }
            )
        }
    }
    
    var body: some View {
            Group {
                if manga.isEmpty {
                    VStack {
                        Spacer()
                        Text("No Manga For This Section.")
                        Text("(︶︹︺)")
                        Spacer()
                    }
                    .opacity(isContentVisible ? 1 : 0) // Animate opacity
                    .onAppear {
                        withAnimation {
                            isContentVisible = true
                        }
                    }
                    .onDisappear {
                        withAnimation {
                            isContentVisible = false
                        }
                    }
                } else {
                    ListView()
                        .opacity(isContentVisible ? 1 : 0) // Animate opacity
                        .onAppear {
                            withAnimation {
                                isContentVisible = true
                            }
                        }
                        .onDisappear {
                            withAnimation {
                                isContentVisible = false
                            }
                        }
                }
            }
            .animation(.spring, value: manga)
        }
        
        @ViewBuilder
        private func ListView() -> some View {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(manga) { item in
                        if let entry = try? item.toMangaEntry() {
                            NavigationLink {
                                DetailView(entry: entry)
                                    .navigationTransition(.zoom(sourceID: "image-\(item.id)", in: namespace))
                            } label: {
                                MangaEntryView(item: entry, lineLimit: 2)
                                    .matchedTransitionSource(id: "image-\(item.id)", in: namespace)
                                    .scrollTargetLayout()
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
            }
            .padding(.horizontal, 10)
            .transition(.opacity)
            .scrollTargetBehavior(.viewAligned)
        }
}

private struct CollectionSelector: View {
    let collections: [Collection]
    @Binding var selectedCollection: Collection?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(collections) { collection in
                    VStack {
                        let isSelected = selectedCollection == collection
                        Text(collection.name)
                            .font(.headline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundColor(isSelected ? .text : .secondary)
                        if isSelected {
                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(.accentColor)
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

#Preview {
    LibraryRootView()
}
