//
//  SourceSearchView.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher
import ScrollViewLoader

struct SourceSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Namespace var namespace
    
    let source: Source
    
    @State private var page: Int = 0
    @State private var noMoreContent: Bool = false
    
    @State private var searchText: String
    @State private var contentLoading = false
    @State private var searchResults = [MangaEntry]()
    @State private var libraryStatus: [UUID: Bool] = [:]
    @State private var hasSearched: Bool = false
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    init(source: Source, searchText: String = "") {
        self.source = source
        _searchText = State(initialValue: searchText)
    }
    
    private func fetchContent() async {
        guard !searchText.isEmpty,
              !noMoreContent else { return }
        
        await MainActor.run {
            contentLoading = true
        }
        
        if let results = try? await getSearchContent(source: source, query: searchText, page: page) {
            searchResults.append(contentsOf: results)
            noMoreContent = results.isEmpty
        }
        
        await MainActor.run {
            contentLoading = false
            hasSearched = true
        }
    }
    
    private func updateLibraryStatus() {
        do {
            for manga in searchResults {
                libraryStatus[manga.id] = try inLibrary(manga)
            }
        } catch {
            print("Error fetching library status: \(error)")
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
    
    var body: some View {
        VStack {
            SearchBar(searchText: $searchText)
                .padding(.bottom, 20)
                .onSubmit {
                    Task {
                        hasSearched = true
                        await fetchContent()
                        updateLibraryStatus()
                    }
                }
            
            if contentLoading {
                ProgressView()
            }
            
            if searchText.isEmpty || !hasSearched {
                Spacer()
                Text("Search Something")
                Text("(๑˃ᴗ˂)ﻭ")
                Spacer()
            }
            
            else if searchResults.isEmpty {
                Spacer()
                Text("No Results")
                Text("(︶︹︺)")
                Spacer()
            }
            
            else {
                SearchResults()
            }
        }
        .padding(.horizontal, 15)
        .navigationTitle("\(source.name) - Search")
        .onAppear {
            if !searchText.isEmpty {
                Task {
                    hasSearched = true
                    await fetchContent()
                    updateLibraryStatus()
                }
            }
            else {
                updateLibraryStatus()
            }
        }
        .onChange(of: searchText) {
            page = 0
            noMoreContent = false
            
            contentLoading = false
            searchResults.removeAll()
            libraryStatus.removeAll()
            hasSearched = false
        }
    }
    
    @ViewBuilder
    private func SearchResults() -> some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(searchResults, id: \.id) { item in
                    NavigationLink {
                        DetailView(entry: item)
                            .navigationTransition(.zoom(sourceID: "image-\(item.id)", in: namespace))
                    } label: {
                        MangaEntryView(item: item, lineLimit: 2, inLibrary: libraryStatus[item.id])
                            .matchedTransitionSource(id: "image-\(item.id)", in: namespace)
                    }
                    .id(item.id)
                }
            }
            if noMoreContent {
                Text("No More Content.")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding()
            }
        }
        .refreshable {
            page = 0
            searchResults.removeAll()
            hasSearched = false
            noMoreContent = false
            await fetchContent()
            updateLibraryStatus()
        }
        .shouldLoadMore(bottomDistance: .absolute(50), waitForHeightChange: .always) {
            guard !contentLoading,
                  !noMoreContent else { return }
            
            page += 1
            await fetchContent()
            updateLibraryStatus()
        }
    }
}
