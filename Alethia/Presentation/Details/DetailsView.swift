//
//  DetailView.swift
//  Alethia
//
//  Created by Angelo Carasig on 15/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

let BACKGROUND_GRADIENT_BREAKPOINT: CGFloat = 800

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var manga: Manga? = nil
    
    var entry: MangaEntry
    
    /// TODO: Check for manga entry
    /// 1. Check if any origin's slug is inside the manga entry's fetch URL
    /// 2. Display accordingly
    
    var body: some View {
        ContentView(manga: manga, entry: entry)
            .transition(.opacity)
            .task {
                await fetchManga()
            }
    }
    
    private func fetchManga() async {
        Task {
            do {
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
                    print("Manga Fetched from Context")
                    manga = result
                }
                else if let result = try modelContext.fetch(sameTitleDescriptor).first {
                    print("Similar Title Fetched from Context")
                    manga = result
                }
                else {
                    print("Manga Fetching from Remote Source")
                    manga = try await getMangaFromEntry(entry: entry, context: modelContext)
                }
            } catch {
                fatalError("Error fetching manga: \(error)")
            }
        }
    }
}

private struct ContentView: View {
    let manga: Manga?
    let entry: MangaEntry
    
    var body: some View {
        let inLibrary = manga?.inLibrary ?? false
        
        ZStack {
            BackdropView(coverUrl: URL(string: entry.coverUrl)!)
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Spacer().frame(height: geometry.size.height / 3)
                        
                        HeaderView(title: manga != nil ? manga!.title : entry.title, authors: manga?.authors ?? [])
                        
                        if let manga = manga {
                            ActionButtonsView(manga: manga, entry: entry)
                            
                            DescriptionView(description: manga.synopsis)
                            
                            TagsView(tags: manga.tags)
                            
                            Divider()
                            
                            TrackingView(title: manga.title, authors: manga.authors, chapterCount: manga.origins.first?.chapters.count ?? 0, inLibrary: inLibrary)
                            
                            Divider()
                            
                            SourcesView(origins: manga.origins, inLibrary: inLibrary)
                            
                            Divider()
                            
                            AdditionalView(origin: manga.origins.first!)
                            
                            Divider()
                            
                            AlternativeTitlesView(titles: manga.alternativeTitles)
                            
                            Divider()
                            
                            ChapterList(origins: manga.origins)
                        }
                        else {
                            PlaceholderView(geometry: geometry)
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(BackgroundGradientView())
                }
                .refreshable {
                    print("Refreshing content")
                }
            }
        }
    }
}

private struct PlaceholderView: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
            }
            .frame(height: 45)
            .shimmer()
            
            VStack(alignment: .leading) {
                Group {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height / 6)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .cornerRadius(4)
                        .opacity(0.6)
                }
                .redacted(reason: .placeholder)
                
                HStack {
                    Spacer()
                    HStack(spacing: 5) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 12)
                            .cornerRadius(2)
                    }
                }
                .padding(.top, 8)
            }
            .cornerRadius(8)
            .frame(maxWidth: .infinity)
            
            Spacer().frame(height: 1000)
        }
    }
}



private struct BackdropView: View {
    let coverUrl: URL
    
    var body: some View {
        GeometryReader { geometry in
            KFImage(coverUrl)
                .placeholder { ProgressView() }
                .retry(maxCount: 5, interval: .seconds(2))
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: BACKGROUND_GRADIENT_BREAKPOINT)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, Color.background]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
        }
    }
}

private struct HeaderView: View {
    let title: String
    let authors: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            Text(authors.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

private struct ActionButtonsView: View {
    @AppStorage("haptics") private(set) var hapticsEnabled = false
    @Environment(\.modelContext) private var modelContext
    @State private var updatingOrigin: Bool = false
    
    let manga: Manga
    let entry: MangaEntry
    
    private var sourcePresent: Bool {
        return manga.inLibrary && manga.origins.contains { entry.fetchUrl.contains($0.slug) }
    }
    
    var body: some View {
        let inLibrary = manga.inLibrary
        
        HStack(spacing: 12) {
            Button {
                do {
                    manga.inLibrary.toggle()
                    try modelContext.save()
                    if hapticsEnabled {
                        Haptics.success()
                    }
                }
                catch {
                    print("Could not save model context when toggling \(manga.title)")
                }
            } label: {
                HStack {
                    Image(systemName: inLibrary ? "heart.fill" : "plus")
                    Text(inLibrary ? "In Library" : "Add to Library")
                }
            }
            .actionButton(inLibrary)
            
            Button(action: {
                Task {
                    await addOrigin()
                }
            }) {
                HStack {
                    if updatingOrigin {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.square.dashed")
                    }
                    Text(inLibrary ? "\(manga.origins.count == 1 ? "1 Source" : "\(manga.origins.count) Sources")" : "Add Source")
                }
            }
            .actionButton(sourcePresent)
            .disabled(!inLibrary)
            
            Button {
                // TODO: Implement tracking functionality
            } label: {
                Image(systemName: inLibrary ? "mappin.and.ellipse" : "mappin.slash")
                    .foregroundColor(inLibrary ? .background : .text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(12)
            }
            .background(inLibrary ? .text : Color.tint, in: .rect(cornerRadius: 12, style: .continuous))
            .disabled(!inLibrary)
            .opacity(inLibrary ? 1.0 : 0.5)
        }
        .frame(height: 45)
        .animation(.easeInOut(duration: 0.3), value: inLibrary)
    }
    
    private func addOrigin() async {
        guard !sourcePresent else { return }
        
        withAnimation {
            updatingOrigin = true
        }
        
        do {
            // get fresh manga from context bassed on the mangaEntry
            let mangaFromContext: Manga = try await getMangaFromEntry(entry: entry, context: modelContext, insert: false)
            
            // Need to update what origins point to
            for origin in mangaFromContext.origins {
                origin.manga = manga
            }
            
            manga.origins.append(contentsOf: mangaFromContext.origins)
            try modelContext.save()
            
            if hapticsEnabled {
                Haptics.success()
            }
        }
        catch {
            fatalError("Error adding new origin to manga: \(error)")
        }
        
        withAnimation {
            updatingOrigin = false
        }
    }
}

private struct DescriptionView: View {
    @AppStorage("haptics") private(set) var hapticsEnabled = false
    
    let description: String
    @State private var isExpanded: Bool = false
    @State private var truncated: Bool = false
    
    init(description: String = "No Description") {
        self.description = description
    }
    
    private func determineTruncation(_ geometry: GeometryProxy) {
        let total = self.description.boundingRect(
            with: CGSize(width: geometry.size.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 16)],
            context: nil
        )
        
        let lineHeight = UIFont.systemFont(ofSize: 16).lineHeight
        let maxHeight = lineHeight * 6
        
        if total.size.height > maxHeight {
            self.truncated = true
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(description)
                .lineLimit(isExpanded ? nil : 6)
                .multilineTextAlignment(.leading)
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            self.determineTruncation(geometry)
                        }
                    }
                )
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                        if hapticsEnabled {
                            Haptics.impact()
                        }
                    }
                }
            
            if truncated {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                            if hapticsEnabled {
                                Haptics.impact()
                            }
                        }
                    }) {
                        Text(Image(systemName: isExpanded ? "chevron.up" : "chevron.down"))
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

private struct TagsView: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.tint)
                        .foregroundColor(.text.opacity(0.75))
                        .cornerRadius(15)
                }
            }
        }
    }
}

private struct TrackingView: View {
    let title: String
    let authors: [String]
    let chapterCount: Int
    let inLibrary: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tracking")
                    .font(.headline)
                
                Image(systemName: "arrow.right")
            }
            
            HStack {
                Image("AniList")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(authors.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("1/\(chapterCount) Chapters")
                        .font(.caption)
                    Text("Reading")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .opacity(inLibrary ? 1 : 0.5)
    }
}

private struct SourcesView: View {
    let origins: [Origin]
    let inLibrary: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sources")
                    .font(.headline)
                
                Image(systemName: "arrow.right")
            }
            
            ForEach(origins, id: \.id) { origin in
                HStack {
                    KFImage(URL(fileURLWithPath: origin.source?.icon ?? ""))
                        .placeholder { Color.gray }
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text(origin.source?.name ?? "Unknown Source")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(origin.source?.host?.name ?? "Unknown Host")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(origin.chapters.count) Chapters")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .opacity(inLibrary ? 1 : 0.5)
    }
}

private struct AdditionalView: View {
    let origin: Origin
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Content Rating")
                        .font(.subheadline)
                    
                    Text(origin.contentRating.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(origin.contentRating.color.opacity(0.5))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created At")
                        .font(.subheadline)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(origin.createdAt.toString())
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.tint.opacity(0.5))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 10) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Publish Status")
                        .font(.subheadline)
                    
                    Text(origin.publishStatus.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(origin.publishStatus.color.opacity(0.5))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Updated At")
                        .font(.subheadline)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(origin.updatedAt.toRelativeString())
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.tint.opacity(0.5))
                    .cornerRadius(8)
                }
            }
        }
    }
}

private struct AlternativeTitlesView: View {
    let titles: [AlternativeTitle]
    @State private var isExpanded: Bool = false
    @State private var truncated: Bool = false
    
    private func determineTruncation(_ geometry: GeometryProxy) {
        let lineHeight = UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
        let maxHeight = lineHeight * 6
        
        let totalHeight = CGFloat(titles.count) * lineHeight
        
        if totalHeight > maxHeight {
            self.truncated = true
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alternative Titles")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(isExpanded ? titles : Array(titles.prefix(5)), id: \.self) { title in
                    Text(title.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        self.determineTruncation(geometry)
                    }
                }
            )
            .onTapGesture {
                if truncated {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            }
            
            if truncated {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(Image(systemName: isExpanded ? "chevron.up" : "chevron.down"))
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

private struct BackgroundGradientView: View {
    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .background.opacity(0.0), location: 0.0),
                    .init(color: .background.opacity(1.0), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: BACKGROUND_GRADIENT_BREAKPOINT)
            
            Color.background.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
