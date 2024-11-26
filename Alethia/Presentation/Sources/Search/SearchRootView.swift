//
//  SearchRootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

struct SearchRootView: View {
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    @Namespace private var namespace
    @Environment(\.modelContext) private var modelContext
    @Query private var sources: [Source]
    
    @State private var searchText: String = ""
    @State private var contentLoading: Bool = false
    @State private var searchResults: [(source: Source, entries: [MangaEntry])] = []
    @State private var libraryStatus: [UUID: Bool] = [:]
    @State private var hasSearched: Bool = false
    
    var body: some View {
        VStack {
            SearchBar(searchText: $searchText)
                .onSubmit {
                    Task {
                        await fetchContent()
                        updateLibraryStatus()
                    }
                }
            
            if contentLoading {
                Spacer()
                ProgressView()
            }
            
            else if searchText.isEmpty || !hasSearched {
                Spacer()
                Text("Search Something")
                Text("(๑˃ᴗ˂)ﻭ")
            }
            
            else if searchResults.isEmpty {
                Spacer()
                Text("No Results")
                Text("(︶︹︺)")
            }
            
            else {
                SearchResults()
            }
            
            Spacer()
        }
        .padding(.horizontal, 15)
        .onAppear {
            updateLibraryStatus()
        }
        .onChange(of: searchText) {
            if !searchText.isEmpty {
                hasSearched = false
            }
            searchResults.removeAll()
        }
    }
    
    private func fetchContent() async {
        guard !searchText.isEmpty else { return }
        
        await MainActor.run {
            contentLoading = true
            searchResults.removeAll()
        }
        
        for source in sources {
            if let results = try? await getSearchContent(source: source, query: searchText), !results.isEmpty {
                await MainActor.run {
                    searchResults.append((source, results))
                }
            }
        }
        
        await MainActor.run {
            contentLoading = false
            hasSearched = true
        }
    }
    
    private func updateLibraryStatus() {
        for (_, entries) in searchResults {
            for entry in entries {
                if let isInLibrary = try? inLibrary(entry) {
                    libraryStatus[entry.id] = isInLibrary
                }
            }
        }
    }
    
    private func inLibrary(_ entry: MangaEntry) throws -> Bool {
        let entryId = entry.id
        let sameIdDescriptor = FetchDescriptor<Manga>(
            predicate: #Predicate { $0.id == entryId }
        )
        
        let entryTitle = entry.title
        let sameTitleDescriptor = FetchDescriptor<Manga>(
            predicate: #Predicate { manga in
                manga.title.localizedStandardContains(entryTitle) ||
                manga.alternativeTitles.contains { $0.title.localizedStandardContains(entryTitle) }
            }
        )
        
        if let result = try modelContext.fetch(sameIdDescriptor).first {
            return result.inLibrary
        }
        
        else if let result = try modelContext.fetch(sameTitleDescriptor).first {
            return result.inLibrary
        }
        
        return false
    }
    
    @ViewBuilder
    private func SearchResults() -> some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(searchResults, id: \.source.id) { result in
                    VStack(alignment: .leading) {
                        NavigationButton(
                            action: {
                                if hapticsEnabled {
                                    Haptics.impact()
                                }
                            },
                            destination: {
                                SourceSearchView(source: result.source, searchText: searchText)
                            },
                            label: {
                                HStack {
                                    Text(result.source.name)
                                        .font(.title)
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundStyle(.text)
                            }
                        )
                        
                        RowView(items: Array(result.entries.prefix(20)))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func RowView(items: [MangaEntry]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 4) {
                ForEach(items, id: \.id) { item in
                    NavigationLink {
                        DetailView(entry: item)
                            .navigationTransition(.zoom(sourceID: "image-\(item.id)", in: namespace))
                    } label: {
                        MangaEntryView(item: item, inLibrary: libraryStatus[item.id])
                        .matchedTransitionSource(id: "image-\(item.id)", in: namespace)
                    }
                    .frame(width: 150)
                    .simultaneousGesture(TapGesture().onEnded {
                        if hapticsEnabled {
                            Haptics.impact()
                        }
                    })
                }
            }
        }
    }
}

#Preview {
    SearchRootView()
}
