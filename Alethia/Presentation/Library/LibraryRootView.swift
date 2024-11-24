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
    
    @State private var searchText = ""
    @State private var selectedTab: PublishStatus = .Ongoing
    
    private static var descriptor = FetchDescriptor<Manga>(
        predicate: #Predicate { $0.inLibrary }
    )
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                
                TabSelector(selectedTab: $selectedTab)
                    .padding(.top, 8)
                
                TabView(selection: $selectedTab) {
                    MangaListView(manga: filteredManga(for: .Ongoing))
                        .tag(PublishStatus.Ongoing)
                    
                    MangaListView(manga: filteredManga(for: .Completed))
                        .tag(PublishStatus.Completed)
                    
                    MangaListView(manga: filteredManga(for: .Hiatus))
                        .tag(PublishStatus.Hiatus)
                    
                    MangaListView(manga: filteredManga(for: .Cancelled))
                        .tag(PublishStatus.Cancelled)
                    
                    MangaListView(manga: filteredManga(for: .Unknown))
                        .tag(PublishStatus.Unknown)
                }
                
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
    }
    
    private func filteredManga(for status: PublishStatus) -> [Manga] {
        allManga.filter { manga in
            guard let firstOrigin = manga.origins.first else { return false }
            return firstOrigin.publishStatus == status &&
            (searchText.isEmpty || manga.title.localizedCaseInsensitiveContains(searchText))
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $text)
        }
        .padding(8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

struct TabSelector: View {
    @Binding var selectedTab: PublishStatus
    let tabs = PublishStatus.allCases
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(tabs, id: \.id) { tab in
                    VStack {
                        Text(tab.rawValue.capitalized)
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                        if selectedTab == tab {
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(tab.color)
                        }
                    }
                    .onTapGesture {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MangaListView: View {
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
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(manga) { item in
                        if let entry = try? item.toMangaEntry() {
                            NavigationLink {
                                DetailView(entry: entry)
                                    .navigationTransition(.zoom(sourceID: "image-\(item.id)", in: namespace))
                            } label: {
                                MangaEntryView(item: entry)
                                    .matchedTransitionSource(id: "image-\(item.id)", in: namespace)
                            }
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
