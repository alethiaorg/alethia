//
//  ChapterList.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher
import Reorderable

private struct OriginPriority: Identifiable {
    let id = UUID()
    let origin: Origin
    var priority: Int
}

private struct ScanlatorPriority: Identifiable {
    let id = UUID()
    let source: Source?
    let scanlator: String
    var priority: Int
}

struct ChapterList: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("haptics") private(set) var hapticsEnabled = false
    
    let origins: [Origin]
    @State private var showManageSheet = false
    @State private var originPriorities: [OriginPriority] = []
    @State private var scanlatorPriorities: [ScanlatorPriority] = []
    
    @State private var showAllChapters = false
    @State private var showHalfChapters = true
    
    private var unifiedChapters: [Chapter] {
        let allChapters = origins.flatMap { $0.chapters }
        var chapterMap: [Double: Chapter] = [:]
        
        if showAllChapters {
            return allChapters.sorted { $0.number > $1.number }
        }
        
        for chapter in allChapters {
            let chapterNumber = chapter.number
            
            guard showHalfChapters || chapterNumber.truncatingRemainder(dividingBy: 1) == 0 else {
                continue
            }
            
            if let existingChapter = chapterMap[chapterNumber] {
                chapterMap[chapterNumber] = resolveChapterPriority(existing: existingChapter, new: chapter)
            } else {
                chapterMap[chapterNumber] = chapter
            }
        }
        
        return chapterMap.values.sorted { $0.number > $1.number }
    }
    
    // Chapters go from LATEST -> OLDEST order by default
    private var continueChapterIndex: Int? {
        unifiedChapters.lastIndex { $0.progress != 1 }
    }
    
    var body: some View {
        NavigationStack {
            ChapterListHeader(
                unifiedChapters: unifiedChapters,
                continueIndex: continueChapterIndex,
                isFilterActive: .constant(false),
                isSortDescending: .constant(true),
                settings: { ManageSettingsView(
                    origins: origins,
                    originPriorities: $originPriorities,
                    scanlatorPriorities: $scanlatorPriorities,
                    showAllChapters: $showAllChapters,
                    showHalfChapters: $showHalfChapters)
                },
                filter: { Text("Hi") },
                sort: { Text("Hi") }
            )
            
            Divider()
            
            LazyVStack {
                ForEach(Array(unifiedChapters.enumerated()), id: \.element.id) { index, chapter in
                    NavigationLink {
                        ReaderRootView(chapters: unifiedChapters, current: index)
                    } label: {
                        ChapterRow(
                            modelContext: modelContext,
                            chapter: chapter,
                            markAllPrevious: { chapter, isRead in
                                markAll(unifiedChapters, startingFrom: chapter, isRead: isRead, direction: .previous)
                            },
                            markAllNext: { chapter, isRead in
                                markAll(unifiedChapters, startingFrom: chapter, isRead: isRead, direction: .next)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        if hapticsEnabled {
                            Haptics.impact()
                        }
                    })
                }
            }
        }
        .onAppear {
            setupPriorities()
        }
    }
    
    private func setupPriorities() {
        originPriorities = origins.enumerated().map { index, origin in
            OriginPriority(origin: origin, priority: index)
        }
        
        var scanlatorSet = Set<String>()
        
        scanlatorPriorities = origins.flatMap { origin in
            origin.chapters.compactMap { chapter in
                guard let source = origin.source,
                      !scanlatorSet.contains(chapter.scanlator) else {
                    return nil
                }
                scanlatorSet.insert(chapter.scanlator)
                return ScanlatorPriority(
                    source: source,
                    scanlator: chapter.scanlator,
                    priority: scanlatorPriorities.count
                )
            }
        }
    }
    
    private func resolveChapterPriority(existing: Chapter, new: Chapter) -> Chapter {
        guard let existingOrigin = existing.origin,
              let newOrigin = new.origin,
              let existingPriority = originPriorities.first(where: { $0.origin == existingOrigin })?.priority,
              let newPriority = originPriorities.first(where: { $0.origin == newOrigin })?.priority
        else { return existing }
        
        if newPriority < existingPriority {
            return new
        }
        
        if newPriority == existingPriority {
            return resolveScanlatorPriority(existing: existing, new: new)
        }
        
        return existing
    }
    
    private func resolveScanlatorPriority(existing: Chapter, new: Chapter) -> Chapter {
        guard let existingPriority = scanlatorPriorities.first(where: { $0.scanlator == existing.scanlator })?.priority,
              let newPriority = scanlatorPriorities.first(where: { $0.scanlator == new.scanlator })?.priority
        else { return existing }
        
        return newPriority < existingPriority ? new : existing
    }
    
    private func markAll(_ chapters: [Chapter], startingFrom chapter: Chapter, isRead: Bool, direction: Direction) {
        guard let index = chapters.firstIndex(where: { $0.id == chapter.id }) else { return }
        
        let range: Range<Int>
        switch direction {
        case .previous:
            range = 0..<index + 1
        case .next:
            range = index..<chapters.count
        }
        
        for i in range {
            chapters[i].progress = isRead ? 1.0 : 0.0
        }
        
        try? modelContext.save()
    }
    
    private enum Direction {
        case previous
        case next
    }
}

private struct ChapterListHeader<Settings: View, Filter: View, Sort: View>: View {
    @AppStorage("haptics") private(set) var hapticsEnabled = false
    
    @Binding var isFilterActive: Bool
    @Binding var isSortDescending: Bool
    
    let settingsView: Settings
    let filterView: Filter
    let sortView: Sort
    let continueIndex: Int?
    let unifiedChapters: [Chapter]
    
    init(
        unifiedChapters: [Chapter],
        continueIndex: Int?,
        isFilterActive: Binding<Bool>,
        isSortDescending: Binding<Bool>,
        @ViewBuilder settings: () -> Settings,
        @ViewBuilder filter: () -> Filter,
        @ViewBuilder sort: () -> Sort
    ) {
        self.continueIndex = continueIndex
        self.unifiedChapters = unifiedChapters
        self._isFilterActive = isFilterActive
        self._isSortDescending = isSortDescending
        self.settingsView = settings()
        self.filterView = filter()
        self.sortView = sort()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chapters")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(unifiedChapters.count) chapters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    CircleButton(
                        icon: "line.3.horizontal.decrease",
                        isActive: isFilterActive
                    ) {
                        withAnimation { isFilterActive.toggle() }
                    }
                    
                    CircleButton(
                        icon: "arrow.up.arrow.down",
                        isActive: isSortDescending
                    ) {
                        withAnimation { isSortDescending.toggle() }
                    }
                }
            }
            
            HStack {
                NavigationLink {
                    if let continueIndex = continueIndex {
                        ReaderRootView(chapters: unifiedChapters, current: continueIndex)
                    } else {
                        EmptyView()
                    }
                } label: {
                    Text("Continue Reading")
                        .font(.headline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .disabled(continueIndex == nil)
                .buttonStyle(.borderedProminent)
                
                NavigationLink {
                    settingsView
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    if hapticsEnabled {
                        Haptics.impact()
                    }
                })
            }
            .frame(height: 44)
        }
    }
}

private struct CircleButton: View {
    let icon: String
    var isActive: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    buttonContent
                }
            } else {
                buttonContent
            }
        }
    }
    
    private var buttonContent: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 40, height: 40)
            .background(isActive ? Color.accentColor : Color.tint.opacity(0.7))
            .foregroundStyle(.white)
            .clipShape(Circle())
            .contentShape(Circle())
    }
}

private struct ChapterRow: View {
    let modelContext: ModelContext
    let chapter: Chapter
    
    let markAllPrevious: (Chapter, Bool) -> Void
    let markAllNext: (Chapter, Bool) -> Void
    
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var downloadFailed: Bool = false
    
    var body: some View {
        HStack {
            KFImage(URL(fileURLWithPath: chapter.origin?.source?.icon ?? ""))
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                .padding(.trailing, 8)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Chapter \(chapter.number.toString())")
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(chapter.date.toRelativeString())
                        .foregroundColor(.secondary)
                    
                    if chapter.date >= Calendar.current.date(byAdding: .day, value: -3, to: Date())! {
                        Text("NEW")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(Color.appRed)
                            .cornerRadius(8)
                    }
                    
                    if chapter.read {
                        Text("Read")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(Color.appOrange)
                            .cornerRadius(8)
                    }
                }
                .font(.subheadline)
                
                Text(chapter.title ?? "Chapter \(chapter.number.toString())")
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(chapter.scanlator)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if chapter.progress > 0 && chapter.progress != 1 {
                    Spacer()
                    
                    ProgressView(value: chapter.progress)
                        .tint(Color.accentColor)
                        .frame(height: 3)
                        .clipShape(Capsule())
                        .opacity(chapter.progress > 0.0 ? 1.0 : 0.0)
                }
            }
            
            Spacer()
            
            DownloadButton()
        }
        .padding(.vertical, 6)
        .overlay {
            if chapter.read {
                ZStack(alignment: .topTrailing) {
                    Color.background.opacity(0.3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .allowsHitTesting(false)
            }
        }
        .contextMenu {
            ContextMenu()
        }
    }
    
    private func startDownload() {
        let ds = DownloadService(modelContext: modelContext)
        isDownloading = true
        downloadFailed = false
        
        Task {
            do {
                for try await progress in ds.downloadChapter(chapter) {
                    await MainActor.run {
                        downloadProgress = progress.progress
                        
                        if case .completed = progress {
                            withAnimation {
                                isDownloading = false
                            }
                        }
                    }
                }
            } catch {
                print("Download failed: \(error)")
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) {
                        isDownloading = false
                        downloadProgress = 0
                        downloadFailed = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func DownloadButton() -> some View {
        let size: CGFloat = 20
        
        Group {
            ZStack {
                if !chapter.isDownloaded {
                    Circle()
                        .stroke(lineWidth: 2)
                        .opacity(!isDownloading ? 0 : 0.3)
                        .foregroundColor(.gray)
                    
                    Circle()
                        .trim(from: 0.0, to: downloadProgress)
                        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.accentColor)
                        .rotationEffect(Angle(degrees: 270.0))
                        .opacity(isDownloading ? 1 : 0)
                    
                    Button {
                        if downloadFailed {
                            // Reset states and retry download
                            downloadFailed = false
                            startDownload()
                        } else {
                            startDownload()
                        }
                    } label: {
                        Image(systemName: downloadFailed ? "xmark.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: size))
                            .foregroundStyle(downloadFailed ? Color.red : Color.accentColor)
                            .opacity(!isDownloading ? 1 : 0)
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: size))
                        .foregroundStyle(.green)
                }
            }
            .frame(width: size, height: size)
        }
        .animation(.easeInOut, value: chapter.isDownloaded)
        .animation(.spring(response: 0.3), value: downloadProgress)
        .animation(.spring(response: 0.3), value: downloadFailed)
    }
    
    @ViewBuilder
    private func ContextMenu() -> some View {
        Group {
            ControlGroup {
                Button {
                    chapter.progress = 1
                    try? modelContext.save()
                } label: {
                    Label("Mark Read", systemImage: "book.closed")
                }
                .disabled(chapter.read)
                
                Button {
                    markAllPrevious(chapter, true)
                } label: {
                    Label("Read Above", systemImage: "arrow.up.square.fill")
                }
                
                Button {
                    markAllNext(chapter, true)
                } label: {
                    Label("Read Below", systemImage: "arrow.down.square.fill")
                }
            }
            
            ControlGroup {
                Button {
                    chapter.progress = 0
                    try? modelContext.save()
                } label: {
                    Label("Mark Unread", systemImage: "book")
                }
                .disabled(!chapter.read)
                
                Button {
                    markAllPrevious(chapter, false)
                } label: {
                    Label("Unread Above", systemImage: "arrow.up.square")
                }
                
                Button {
                    markAllNext(chapter, false)
                } label: {
                    Label("Unread Below", systemImage: "arrow.down.square")
                }
            }
            
            ControlGroup {
                Button {
                    startDownload()
                } label: {
                    Label("Start Chapter Download", systemImage: "arrow.down")
                }
                .disabled(chapter.isDownloaded || isDownloading)
                
                Button(role: .destructive) {
                    do {
                        let ds = DownloadService(modelContext: modelContext)
                        try ds.deleteChapter(chapter)
                    } catch {
                        print("Failed to delete chapter: \(error)")
                    }
                } label: {
                    Label("Remove Chapter Download", systemImage: "trash.fill")
                }
                .disabled(!chapter.isDownloaded)
            }
        }
    }
}

private struct ManageSettingsView: View {
    let origins: [Origin]
    @Binding fileprivate var originPriorities: [OriginPriority]
    @Binding fileprivate var scanlatorPriorities: [ScanlatorPriority]
    
    @Binding var showAllChapters: Bool
    @Binding var showHalfChapters: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Some early space
                Spacer().frame(height: 10)
                
                VStack(alignment:. leading) {
                    Text("DISPLAY SETTINGS")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                        .textCase(.uppercase)
                    Toggle("Show All Chapters", isOn: $showAllChapters)
                        .tint(.green)
                        .padding(10)
                        .background(Color.tint.opacity(0.5))
                        .cornerRadius(8)
                    
                    Toggle("Show Half Chapters", isOn: $showHalfChapters)
                        .tint(.green)
                        .padding(10)
                        .background(Color.tint.opacity(0.5))
                        .cornerRadius(8)
                        .opacity(showAllChapters ? 0.5 : 1)
                        .animation(.easeInOut(duration: 0.25), value: showAllChapters)
                }
                
                Group {
                    VStack(alignment: .leading) {
                        Text("SOURCE PRIORITY")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                            .textCase(.uppercase)
                            .padding(0)
                        
                        ReorderableVStack(originPriorities, onMove: { from, to in
                            withAnimation {
                                originPriorities.move(fromOffsets: IndexSet(integer: from),
                                                      toOffset: (to > from) ? to + 1 : to)
                                
                                updateOriginPriorities()
                                print("Origin priorities reordered: \(originPriorities)")
                            }
                        }) { originPriority in
                            let title = originPriority.origin.source?.name ?? "Unknown Source"
                            HStack {
                                KFImage(URL(fileURLWithPath: originPriority.origin.source?.icon ?? ""))
                                    .placeholder { Color.gray }
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading) {
                                    Text(title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        let host = originPriority.origin.source?.host?.name.lowercased() ?? "Unknown Host"
                                        
                                        Text(host)
                                        
                                        Text("(\(originPriority.origin.chapters.count) Chapters)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.secondary)
                                    .padding()
                                    .offset(x: 16)
                                    .dragHandle()
                            }
                            .padding(15)
                            .background(Color.tint.opacity(0.5))
                            .cornerRadius(8)
                            .padding(.bottom, 10)
                        }
                        .dragDisabled(showAllChapters)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("SCANLATOR PRIORITY")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                            .textCase(.uppercase)
                        
                        ReorderableVStack(scanlatorPriorities, onMove: { from, to in
                            withAnimation {
                                scanlatorPriorities.move(fromOffsets: IndexSet(integer: from),
                                                         toOffset: (to > from) ? to + 1 : to)
                                updateScanlatorPriorities()
                                print("Scanlator priorities reordered: \(scanlatorPriorities)")
                            }
                        }) { scanlatorPriority in
                            HStack {
                                KFImage(URL(fileURLWithPath: scanlatorPriority.source?.icon ?? ""))
                                    .placeholder { Color.gray }
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading) {
                                    Text(scanlatorPriority.scanlator)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        let host = scanlatorPriority.source?.host?.name.lowercased() ?? "Unknown Host"
                                        let source = scanlatorPriority.source?.name.lowercased() ?? "Unknown Source"
                                        Text("\(host)/\(source)")
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.secondary)
                                    .padding()
                                    .offset(x: 16)
                                    .dragHandle()
                            }
                            .padding(15)
                            .background(Color.tint.opacity(0.5))
                            .cornerRadius(8)
                            .padding(.bottom, 10)
                        }
                        .dragDisabled(showAllChapters)
                    }
                }
                .opacity(showAllChapters ? 0.5 : 1)
                .animation(.easeInOut(duration: 0.25), value: showAllChapters)
                
                Spacer()
            }
        }
        .autoScrollOnEdges()
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .navigationTitle("Chapter Settings")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func updateOriginPriorities() {
        for (index, _) in originPriorities.enumerated() {
            originPriorities[index].priority = index
        }
    }
    
    private func updateScanlatorPriorities() {
        for (index, _) in scanlatorPriorities.enumerated() {
            scanlatorPriorities[index].priority = index
        }
    }
}

#Preview {
    let models: [any PersistentModel.Type] = [
        Host.self, Source.self, SourceRoute.self,
        Manga.self, Origin.self, Chapter.self
    ]
    
    let preview = PreviewContainer(models)
    
    return ChapterList(origins: preview.manga.origins)
        .modelContainer(preview.container)
}
