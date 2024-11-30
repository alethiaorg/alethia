//
//  ChapterListContentView.swift
//  Alethia
//
//  Created by Angelo Carasig on 29/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

struct ChapterListContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("haptics") private var hapticsEnabled = false
    
    var vm: ChapterListViewModel
    
    var body: some View {
        NavigationStack {
            LazyVStack {
                ForEach(Array(vm.unified.enumerated()), id: \.element.id) { index, chapter in
                    NavigationLink {
                        ReaderRootView(settings: vm.manga.chapterSettings, chapters: vm.unified, current: index)
                    } label: {
                        ChapterRow(
                            modelContext: modelContext,
                            chapter: chapter,
                            markAllPrevious: { chapter, isRead in
                                vm.markAll(modelContext: modelContext, startingFrom: chapter, isRead: isRead, direction: .previous)
                            },
                            markAllNext: { chapter, isRead in
                                vm.markAll(modelContext: modelContext, startingFrom: chapter, isRead: isRead, direction: .next)
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
