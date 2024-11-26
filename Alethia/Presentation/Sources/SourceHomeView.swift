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
    
    // Array<path: [mangaEntry]>
    @State private var items: [String: [MangaEntry]] = [:]
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
                        
                        if let entries = items[route.path], itemsSet {
                            RowView(items: Array(entries.prefix(20)))
                        } else {
                            SkeletonRowView()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .onAppear {
            Task {
                itemsSet = false
                if firstLoad {
                    try await getRootContent()
                    try updateLibraryStatus()
                    firstLoad = false
                }
                else {
                    try updateLibraryStatus()
                }
                
                itemsSet = true
            }
        }
        .navigationTitle(source.name)
        .toolbar {
            ToolbarItem {
                NavigationLink(destination: Text("Hi")) {
                    Image(systemName: "gearshape.fill")
                }
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
            LazyHStack {
                ForEach(items, id: \.id) { item in
                    NavigationLink {
                        DetailView(entry: item)
                            .navigationTransition(.zoom(sourceID: "image-\(item.id)", in: namespace))
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            GeometryReader { geometry in
                                let cellWidth = geometry.size.width
                                let cellHeight = cellWidth * 16 / 11
                                
                                KFImage(URL(string: item.coverUrl))
                                    .placeholder { Color.tint.shimmer() }
                                    .resizable()
                                    .fade(duration: 0.25)
                                    .scaledToFill()
                                    .frame(width: cellWidth, height: cellHeight)
                                    .cornerRadius(6)
                                    .clipped()
                            }
                            .aspectRatio(11/16, contentMode: .fit)
                            
                            Text(item.title)
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .multilineTextAlignment(.leading)
                                .truncationMode(.tail)
                                .foregroundStyle(.text)
                            
                            Spacer()
                        }
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
                    .padding(.horizontal, 4)
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
    
    private func getRootContent() async throws -> Void {
        for route in source.routes {
            let newContent = try await getSourceContent(source: source, route: route.path, page: 1)
            items[route.path] = newContent
        }
    }
    
    private func updateLibraryStatus() throws -> Void {
        for (_, entries) in items {
            for entry in entries {
                libraryStatus[entry.id] = try inLibrary(entry)
            }
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

