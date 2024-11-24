//
// SourceGridView.swift
// Alethia
//
// Created by Angelo Carasig on 20/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

struct SourceGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Namespace var namespace
    var source: Source
    var route: SourceRoute
    
    @State private var items = [MangaEntry]()
    @State private var libraryStatus: [UUID: Bool] = [:]
    @State private var firstLoad = true
    @State private var isLoading = false
    @State private var error: Error?
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else if let error = error {
                Text("Error: \(error.localizedDescription)")
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(items, id: \.id) { item in
                            NavigationLink {
                                DetailView(entry: item)
                                    .navigationTransition(.zoom(sourceID: "image-\(item.id)", in: namespace))
                            } label: {
                                MangaEntryView(item: item)
                                    .matchedTransitionSource(id: "image-\(item.id)", in: namespace)
                                    .overlay {
                                        if libraryStatus[item.id] == true {
                                            ZStack(alignment: .topTrailing) {
                                                Color.black.opacity(0.5)
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.green)
                                                    .padding(10)
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if firstLoad {
                Task {
                    await fetchContent()
                    updateLibraryStatus()
                    firstLoad = false
                }
            } else {
                updateLibraryStatus()
            }
        }
        .navigationTitle("\(source.name) - \(route.name)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func fetchContent() async {
        isLoading = true
        error = nil
        do {
            let newItems = try await getSourceContent(source: source, route: route.path)
            items.append(contentsOf: newItems)
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    private func updateLibraryStatus() {
        do {
            for manga in items {
                libraryStatus[manga.id] = try inLibrary(manga)
            }
        } catch {
            print("Error fetching library status: \(error)")
        }
    }
    
    private func inLibrary(_ entry: MangaEntry) throws-> Bool {
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
}

#Preview { let models: [any PersistentModel.Type] = [ Host.self, Source.self, SourceRoute.self, Manga.self, Origin.self, Chapter.self ]
    
    let preview = PreviewContainer(models)
    
    return SourceGridView(source: preview.host.sources.first!, route: preview.host.sources.first!.routes.first!)
        .modelContainer(preview.container)
}
