//
// SourceGridView.swift
// Alethia
//
// Created by Angelo Carasig on 20/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher
import ScrollViewLoader

struct SourceGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Namespace var namespace
    
    var source: Source
    var route: SourceRoute
    
    @State private var page: Int = 0
    @State private var items = [MangaEntry]()
    @State private var libraryStatus: [UUID: Bool] = [:]
    @State private var firstLoad = true
    @State private var isLoading = false
    @State private var error: Error?
    @State private var noMoreContent: Bool = false
    
    let columns = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]
    
    var body: some View {
        ZStack {
            if isLoading && items.isEmpty {
                ProgressView()
            } else if let error = error {
                Text("Error: \(error.localizedDescription)")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(items, id: \.id) { item in
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
                }
                .padding(.horizontal, 10)
                .refreshable {
                    await refresh()
                }
                .shouldLoadMore(bottomDistance: .absolute(50), waitForHeightChange: .always) {
                    guard !isLoading else { return }
                    page += 1
                    await fetchContent()
                }
                
                if noMoreContent {
                    Text("No More Content.")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                if isLoading {
                    ProgressView()
                        .padding()
                }
            }
        }
        .task {
            if firstLoad {
                await fetchContent()
                updateLibraryStatus()
            } else {
                updateLibraryStatus()
            }
        }
        .navigationTitle("\(source.name) - \(route.name)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func fetchContent(reset: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let newItems = try await getSourceContent(source: source, route: route.path, page: page)
            if Task.isCancelled { return }
            if reset {
                items = newItems
            } else {
                items.append(contentsOf: newItems)
            }
            if newItems.isEmpty {
                noMoreContent = true
            }
            updateLibraryStatus()
        } catch {
            if !Task.isCancelled {
                self.error = error
            }
        }
        firstLoad = false
        isLoading = false
    }
    
    private func refresh() async {
        page = 0
        items.removeAll()
        firstLoad = true
        isLoading = false
        await fetchContent(reset: true)
    }
    
    private func updateLibraryStatus() {
        for manga in items {
            do {
                libraryStatus[manga.id] = try inLibrary(manga)
            } catch {
                print("Error fetching library status: \(error)")
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
        } else if let result = try modelContext.fetch(sameTitleDescriptor).first {
            return result.inLibrary
        }
        
        return false
    }
}
