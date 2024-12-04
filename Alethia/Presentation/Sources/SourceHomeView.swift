//
//  SourceHomeView.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

struct SourceHomeView: View {
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    @Namespace private var namespace
    @Environment(\.modelContext) private var modelContext
    let source: Source
    
    @State private var items: [String: Result<[MangaEntry], Error>] = [:]
    @State private var libraryStatus: [UUID: Bool] = [:]
    @State private var firstLoad: Bool = true
    @State private var itemsSet: Bool = false
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(source.routes, id: \.name) { route in
                    VStack(alignment: .leading) {
                        NavigationButton(
                            action: {
                                if hapticsEnabled {
                                    Haptics.impact()
                                }
                            },
                            destination: {
                                SourceGridView(source: source, route: route)
                            },
                            label: {
                                HStack {
                                    Text(route.name)
                                        .font(.title)
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundStyle(.text)
                            }
                        )
                        
                        if let result = items[route.path], itemsSet {
                            switch result {
                            case .success(let entries):
                                RowView(items: Array(entries.prefix(20)))
                            case .failure(let error):
                                Text("Error: \(error.localizedDescription)")
                                    .foregroundColor(.red)
                            }
                        } else {
                            SkeletonRowView()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .onAppear {
            Task {
                itemsSet = false
                if firstLoad {
                    await getRootContent()
                    try updateLibraryStatus()
                    firstLoad = false
                }
                else {
                    try updateLibraryStatus()
                }
                withAnimation(.easeInOut) {
                    itemsSet = true
                }
            }
        }
        .navigationTitle(source.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationButton(
                    action: {
                        
                    },
                    destination: {
                        SourceSearchView(source: source)
                    },
                    label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.accentColor)
                    }
                )
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                NavigationButton(
                    action: {
                        
                    },
                    destination: {
                        Text("Hi")
                    },
                    label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private func SkeletonRowView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(0..<10, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 150 * 16 / 11)
                            .shimmer()
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 130, height: 14)
                            .shimmer()
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .frame(width: 150)
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
    
    private func getRootContent() async {
        await withTaskGroup(of: (String, Result<[MangaEntry], Error>).self) { group in
            for route in source.routes {
                group.addTask {
                    do {
                        let newContent = try await getSourceContent(source: self.source, route: route.path, page: 0)
                        return (route.path, .success(newContent))
                    } catch {
                        return (route.path, .failure(error))
                    }
                }
            }
            
            for await (path, result) in group {
                items[path] = result
            }
        }
    }
    
    private func updateLibraryStatus() throws -> Void {
        for (_, result) in items {
            if case .success(let entries) = result {
                for entry in entries {
                    libraryStatus[entry.id] = try inLibrary(entry)
                }
            }
            // Skip updating library status for entries that failed to load
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

