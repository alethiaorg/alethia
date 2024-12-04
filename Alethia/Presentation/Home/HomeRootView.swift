//
//  HomeRootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 16/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher
import ACarousel

struct HomeRootView: View {
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    @Environment(\.modelContext) private var context
    
    @Query(updatedAtDescriptor) private var updated: [Origin]
    @Query(addedAtDescriptor) private var added: [Manga]
    
    @State private var popular: [String: [Manga]] = [:]
    @State private var carouselContent: [Manga] = []
    
    private var noContent: Bool {
        return added.isEmpty && popular.isEmpty
    }
    
    private static var updatedAtDescriptor = FetchDescriptor<Origin>(
        predicate: nil,
        sortBy: [.init(\.updatedAt, order: .forward)]
    )
    
    private static var addedAtDescriptor = FetchDescriptor<Manga>(
        predicate: #Predicate { $0.inLibrary },
        sortBy: [.init(\.id, order: .reverse)]
    )
    
    private func loadPopular() {
        var fetchDescriptor = FetchDescriptor<Manga>(
            predicate: #Predicate { $0.inLibrary }
        )
        
        fetchDescriptor.fetchLimit = 100
        
        do {
            let results: [Manga] = try context.fetch(fetchDescriptor)
            
            var tagCounts: [String: Int] = [:]
            
            for manga in results {
                for tag in manga.tags {
                    tagCounts[tag, default: 0] += 1
                }
            }
            
            let popularTags = Array(tagCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key })
            
            for tag in popularTags {
                let mangaWithTag = results.filter { $0.tags.contains(tag) }
                popular[tag] = Array(mangaWithTag.shuffled().prefix(10))
            }
            
            // Select 10 random manga from all popular manga
            carouselContent = Array(Set(popular.values.flatMap { $0 })).shuffled().prefix(10).map { $0 }
        }
        catch {
            print("Error fetching manga: \(error)")
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if noContent {
                    NoContentView()
                }
                else {
                    ScrollView {
                        VStack(spacing: 15) {
                            if !carouselContent.isEmpty {
                                CarouselView(items: carouselContent, hapticsEnabled: hapticsEnabled)
                            }
                            
                            Group {
                                RowView(
                                    title: "Recently Updated",
                                    items: updated // Fetch via origin, filter those in library and compact map to unique
                                        .filter { $0.manga?.inLibrary ?? false }
                                        .compactMap { $0.manga },
                                    hapticsEnabled: hapticsEnabled
                                )
                                
                                RowView(title: "Recently Added", items: added, hapticsEnabled: hapticsEnabled)
                                
                                // Tags
                                ForEach(Array(popular.keys), id: \.self) { title in
                                    RowView(
                                        title: title,
                                        items: popular[title] ?? [],
                                        hapticsEnabled: hapticsEnabled
                                    )
                                }
                            }
                            .padding(.horizontal, 15)
                        }
                    }
                    .ignoresSafeArea(.container, edges: .top)
                }
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadPopular()
        }
    }
}

private struct NoContentView: View {
    var body: some View {
        Text("No Manga In Library")
        Text("(︶︹︺)")
    }
}

private struct RowView: View {
    @Namespace private var namespace
    let title: String
    let items: [Manga]
    
    var hapticsEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(Array(items).prefix(10), id: \.id) { item in
                        NavigationLink {
                            if let entry = try? item.toMangaEntry() {
                                DetailView(entry: entry)
                                    .navigationTransition(.zoom(sourceID: "\(title)-\(item.id)", in: namespace))
                            } else {
                                Text("Unable to load manga details")
                            }
                        } label: {
                            if let entry = try? item.toMangaEntry() {
                                MangaEntryView(item: entry)
                                    .matchedTransitionSource(id: "\(title)-\(item.id)", in: namespace)
                            } else {
                                Text("Unavailable to convert \(item.title) to entry.")
                                    .foregroundColor(.red)
                            }
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
}

private struct CarouselView: View {
    let items: [Manga]
    
    var hapticsEnabled: Bool
    
    var body: some View {
        ACarousel(items,
                  spacing: 0,
                  headspace: 0,
                  sidesScaling: 1,
                  isWrap: true,
                  autoScroll: .active(8)
        ) { item in
            ZStack {
                BackgroundImage(url: item.getFirstOrigin().cover)

                VStack {
                    Spacer()
                    
                    HStack {
                        CoverImage(url: item.getFirstOrigin().cover)
                        Details(item: item)
                    }
                    .frame(maxHeight: 250)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(height: 450)
    }
    
    @ViewBuilder
    private func BackgroundImage(url: String) -> some View {
        KFImage(URL(string: url))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: UIScreen.main.bounds.width, height: 450)
            .clipped()
            .blur(radius: 8)
            .opacity(0.25)
    }
    
    @ViewBuilder
    private func CoverImage(url: String) -> some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width
            let cellHeight = cellWidth * 16 / 11
            
            KFImage(URL(string: url))
                .placeholder { Color.gray }
                .resizable()
                .fade(duration: 0.25)
                .aspectRatio(contentMode: .fill)
                .frame(width: cellWidth, height: cellHeight)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
                .background(Color.tint.opacity(0.1).shimmer())
        }
        .aspectRatio(11/16, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func Details(item: Manga) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            Text(item.synopsis)
                .font(.subheadline)
                .lineLimit(8)
                .foregroundColor(.primary.opacity(0.75))
            
            Spacer()
            
            HStack(spacing: 8) {
                NavigationButton(
                    action: {
                        if hapticsEnabled {
                            Haptics.impact()
                        }
                    },
                    destination: {
                        if let entry = try? item.toMangaEntry() {
                            DetailView(entry: entry)
                        } else {
                            Text("Unable to load manga details")
                        }
                    },
                    label: {
                        Text("View Details")
                            .lineLimit(1)
                            .padding(.vertical, 14)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(Color.primary.opacity(0.85))
                            .foregroundColor(.background)
                            .cornerRadius(12)
                    }
                )
                
                Button {
                } label: {
                    Image(systemName: "book")
                }
                .padding(12)
                .frame(height: 44)
                .background(Color.primary.opacity(0.85))
                .foregroundColor(.background)
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    HomeRootView()
}
