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
    
    var body: some View {
        NavigationStack {
            VStack {
                if noContent {
                    Text("No Manga In Library")
                    Text("(︶︹︺)")
                }
                else {
                    ContentView()
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        print("Notifications!")
                    } label: {
                        Image(systemName: "bell")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        print("Settings tapped")
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .onAppear {
                loadPopular()
            }
        }
    }
    
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
}

private extension HomeRootView {
    @ViewBuilder
    private func ContentView() -> some View {
        ScrollView {
            VStack(spacing: 15) {
                if !carouselContent.isEmpty {
                    CarouselView(items: carouselContent)
                }
                
                Group {
                    recentlyUpdatedSection
                    
                    recentlyAddedSection
                    
                    tagsSection
                }
                .padding(.horizontal, 15)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
    
    @ViewBuilder
    private func RowView(items: [Manga]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(Array(items).prefix(10), id: \.id) { item in
                    NavigationLink {
                        if let entry = try? item.toMangaEntry() {
                            DetailView(entry: entry)
                        } else {
                            Text("Unable to load manga details")
                        }
                    } label: {
                        if let entry = try? item.toMangaEntry() {
                            NavigationLink {
                                DetailView(entry: entry)
                            } label: {
                                MangaEntryView(item: entry)
                            }
                        } else {
                            Text("Unavailable to convert \(item.title) to entry.")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 4)
                    .frame(width: 150)
                }
            }
        }
    }
    
    private var recentlyUpdatedSection: some View {
        VStack(alignment: .leading) {
            Text("Recently Updated")
                .font(.title)
                .fontWeight(.bold)
            
            RowView(
                items: updated
                    .filter { $0.manga?.inLibrary ?? false }
                    .map { $0.manga! }
            )
        }
    }
    
    private var recentlyAddedSection: some View {
        VStack(alignment: .leading) {
            Text("Recently Added")
                .font(.title)
                .fontWeight(.bold)
            
            RowView(items: added)
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading) {
            ForEach(Array(popular.keys), id: \.self) { title in
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    RowView(items: popular[title] ?? [])
                }
            }
        }
    }
}

private struct CarouselView: View {
    var items: [Manga]
    
    var body: some View {
        ACarousel(items,
                  spacing: 0,
                  headspace: 0,
                  sidesScaling: 1,
                  isWrap: true,
                  autoScroll: .active(8)
        ) { item in
            CarouselItem(item: item)
        }
        .frame(height: 450)
    }
}

private struct CarouselItem: View {
    let item: Manga
    
    var body: some View {
        ZStack {
            BackgroundImage(url: item.origins.first?.cover ?? "")
            
            VStack {
                Spacer()
                
                HStack {
                    CoverImage(url: item.origins.first?.cover ?? "")
                    
                    MangaDetails(item: item)
                }
                .frame(maxHeight: 250)
                .padding(16)
                .padding(.bottom, 20)
            }
        }
    }
}

private struct BackgroundImage: View {
    let url: String
    
    var body: some View {
        KFImage(URL(string: url))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: UIScreen.main.bounds.width, height: 450)
            .clipped()
            .blur(radius: 8)
            .opacity(0.25)
    }
}

private struct CoverImage: View {
    let url: String
    
    var body: some View {
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
                .background(Color.gray.opacity(0.1))
        }
        .aspectRatio(11/16, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

private struct MangaDetails: View {
    let item: Manga
    
    var body: some View {
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
                NavigationLink {
                    if let entry = try? item.toMangaEntry() {
                        DetailView(entry: entry)
                    } else {
                        Text("Unable to load manga details")
                    }
                } label: {
                    Text("View Details")
                        .lineLimit(1)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            Color.primary.opacity(0.85),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .foregroundColor(.background)
                }
                
                Button {
                    print("Continue Reading \(item.title)!")
                } label: {
                    Image(systemName: "book")
                        .accessibilityLabel("Continue Reading")
                }
                .padding(12)
                .background(Color.primary.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.background)
            }
        }
    }
}

#Preview {
    HomeRootView()
}
