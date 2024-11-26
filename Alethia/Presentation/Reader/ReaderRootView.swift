//
//  ReaderRootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

struct ReaderRootView: View {
    @StateObject private var controller: ReaderControls
    @Environment(\.modelContext) private var modelContext
    
    init(chapters: [Chapter], current: Int) {
        _controller = StateObject(wrappedValue: ReaderControls(chapters: chapters, currentIndex: current))
    }
    
    var body: some View {
        ReaderContent()
            .environmentObject(controller)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden(true)
            .onDisappear {
                controller.updateReadingHistory(modelContext: modelContext)
            }
    }
}

class ReaderControls: ObservableObject {
    let chapters: [Chapter]
    @Published var currentIndex: Int
    @Published var readerDirection: ReaderDirection
    @Published var currentPage: Int = 0
    @Published var currentReadingHistory: ReadingHistory?
    
    init(chapters: [Chapter], currentIndex: Int, initialDirection: ReaderDirection = .LTR) {
        self.chapters = chapters
        self.currentIndex = currentIndex
        self.readerDirection = initialDirection
    }
    
    var currentChapter: Chapter {
        chapters[currentIndex]
    }
    
    var canGoBack: Bool {
        currentIndex < chapters.count - 1
    }
    
    var canGoForward: Bool {
        currentIndex > 0
    }
    
    func goToPreviousChapter() {
        if canGoBack {
            currentIndex += 1
        }
    }
    
    func goToNextChapter() {
        if canGoForward {
            currentIndex -= 1
        }
    }
    
    func toggleReaderDirection() {
        readerDirection = readerDirection.cycleReadingDirection()
    }
    
    func createReadingHistory(modelContext: ModelContext, startPage: Int) {
        let newHistory = ReadingHistory(
            startChapter: currentChapter,
            startPage: startPage
        )
        
        modelContext.insert(newHistory)
        currentReadingHistory = newHistory
    }
    
    func updateReadingHistory(modelContext: ModelContext) {
        guard let history = currentReadingHistory else { return }
        
        history.finishSession(
            endPage: currentPage,
            dateEnded: Date()
        )
        
        if currentChapter != history.startChapter {
            history.endChapter = currentChapter
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save reading history: \(error)")
        }
    }
}

private struct ReaderOverlay<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var controller: ReaderControls
    @State var isOverlayVisible: Bool = true
    @Binding var currentPage: Int
    let totalPages: Int
    let content: Content
    
    private var inContentRange: Bool {
        currentPage >= 0 && currentPage < totalPages
    }
    
    init(currentPage: Binding<Int>, totalPages: Int, @ViewBuilder content: () -> Content) {
        self._currentPage = currentPage
        self.totalPages = totalPages
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        isOverlayVisible.toggle()
                    }
                }
            
            if isOverlayVisible && inContentRange {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(controller.currentChapter.origin?.manga?.title ?? "Unknown")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text(controller.currentChapter.toString())
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.top)
                    }
                    .foregroundColor(.white)
                    
                    HStack {
                        Button {
                            controller.toggleReaderDirection()
                        } label: {
                            Image(systemName: controller.readerDirection.systemImageName)
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.5))
                                .clipShape(.circle)
                        }
                        
                        Spacer()
                        
                        Button {
                            controller.toggleReaderDirection()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.5))
                                .clipShape(.circle)
                        }
                    }
                    .padding(.horizontal, 15)
                    
                    Spacer()
                    
                    VStack {
                        HStack {
                            Button(action: controller.goToPreviousChapter) {
                                Image(systemName: "chevron.left")
                            }
                            .disabled(!controller.canGoBack)
                            .foregroundStyle(Color.white.opacity(controller.canGoBack ? 1 : 0.4))
                            .padding(.horizontal, 15)
                            
                            let maxPage = max(0, totalPages - 1)
                            Slider(value: Binding(
                                get: { Double(min(currentPage, maxPage)) },
                                set: { newValue in
                                    currentPage = min(Int(newValue), maxPage)
                                }
                            ), in: 0...Double(maxPage), step: 1)
                            
                            Button(action: controller.goToNextChapter) {
                                Image(systemName: "chevron.right")
                            }
                            .disabled(!controller.canGoForward)
                            .foregroundStyle(Color.white.opacity(controller.canGoForward ? 1 : 0.4))
                            .padding(.horizontal, 15)
                        }
                        
                        Text("Page \(currentPage + 1) of \(totalPages)")
                            .font(.subheadline)
                            .padding(.bottom)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
            }
        }
        .statusBar(hidden: !isOverlayVisible)
        .edgesIgnoringSafeArea(.bottom)
    }
}

private struct ReaderContent: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var controller: ReaderControls
    @AppStorage("prefetch") private(set) var PREFETCH_RANGE = 0
    
    @State private var contents = [String]()
    @State private var isLoading = true
    @State private var error: Error?
    
    @State private var isGoingToPreviousChapter = false
    @State private var isGoingToNextChapter = false
    
    @State private var prefetcher: ImagePrefetcher?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading chapter content...")
            } else if let error = error {
                Text("Error: \(error.localizedDescription)")
            } else if contents.isEmpty {
                Text("No content available for this chapter.")
                Button {
                    loadChapterContent()
                } label: {
                    Text("Try Again?")
                }
            } else {
                ReaderOverlay(currentPage: $controller.currentPage, totalPages: contents.count) {
                    if controller.readerDirection.isVertical {
                        VerticalReader()
                    }
                    else {
                        HorizontalReader()
                    }
                }
            }
        }
        .onAppear {
            loadChapterContent()
        }
        .onChange(of: controller.currentPage) {
            guard !contents.isEmpty else { return }
            
            prefetchImages()
            
            updateProgress()
        }
        .onChange(of: controller.currentIndex) { oldValue, newValue in
            isGoingToPreviousChapter = newValue > oldValue
            isGoingToNextChapter = newValue < oldValue
            loadChapterContent()
        }
    }
    
    private func updateProgress() {
        let newProgress = max(0.0, min(Double(controller.currentPage) / Double(contents.count - 1), 1.0))
        controller.currentChapter.progress = newProgress
        
        try? modelContext.save()
    }
    
    private func loadChapterContent() {
        isLoading = true
        Task {
            do {
                let results = try await getChapterContent(chapter: controller.currentChapter)
                await MainActor.run {
                    contents = results
                    isLoading = false
                    
                    // When chapter content gets initially loaded, jump to last page if going to previous chapter or load from the current chapter's progress
                    if isGoingToPreviousChapter {
                        controller.currentPage = contents.count - 1
                    }
                    else if isGoingToNextChapter {
                        controller.currentPage = 0
                    }
                    else {
                        let totalPages = contents.count
                        let currentProgress = max(0.0, min(controller.currentChapter.progress, 1.0))
                        let calculatedPage = Int(Double(totalPages - 1) * currentProgress)
                        let clampedPage = max(0, min(calculatedPage, totalPages - 1))
                        
                        print("Total Pages: \(totalPages)")
                        print("Current Progress: \(currentProgress)")
                        
                        // + 1 since its 0-based counting
                        
                        print("Calculated Page (before clamping): \(calculatedPage + 1)")
                        print("Clamped Page: \(clampedPage + 1)")
                        
                        controller.currentPage = clampedPage
                        controller.createReadingHistory(modelContext: modelContext, startPage: controller.currentPage)
                    }
                    
                    isGoingToPreviousChapter = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    // Eager loading
    private func prefetchImages() {
        prefetcher?.stop()
        
        guard !contents.isEmpty else { return }
        
        // Calculate the range of indices to prefetch
        let startIndex = max(0, controller.currentPage - PREFETCH_RANGE)
        let endIndex = min(contents.count - 1, controller.currentPage + PREFETCH_RANGE)
        
        print("Prefetching Indexes \(startIndex) to \(endIndex)")
        
        guard startIndex <= endIndex else { return }
        
        let urlsToPrefetch = Array(contents[startIndex...endIndex]).map { URL(string: $0)! }
        
        prefetcher = ImagePrefetcher(
            urls: urlsToPrefetch,
            options: [.cacheOriginalImage],
            progressBlock: nil
        )
        
        prefetcher?.start()
    }
    
    @ViewBuilder
    private func HorizontalReader() -> some View {
        TabView(selection: $controller.currentPage) {
            if controller.canGoBack {
                Text("")
                    .tag(-2)
            }
            
            PreviousChapterView()
                .tag(-1)
            
            ForEach(Array(contents.enumerated()), id: \.element) { index, imageUrlString in
                Group {
                    if let url = URL(string: imageUrlString) {
                        RetryableImage(
                            url: url,
                            index: index,
                            referer: controller.currentChapter.origin?.referer ?? "",
                            readerDirection: controller.readerDirection
                        )
                        .tag(index)
                    } else {
                        Text("Invalid image URL")
                            .tag(index)
                    }
                }
            }
            
            NextChapterView()
                .tag(contents.count)
            
            if controller.canGoForward {
                Text("")
                    .tag(contents.count + 1)
            }
        }
        .environment(\.layoutDirection, controller.readerDirection == .RTL ? .rightToLeft : .leftToRight) // Already handled if horizontal so just check if RTL here
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .onChange(of: controller.currentPage) { newPage, oldPage in
            if oldPage == -2 {
                controller.goToPreviousChapter()
            }
            else if oldPage == contents.count + 1 {
                controller.goToNextChapter()
            }
        }
    }
    
    @ViewBuilder
    private func VerticalReader() -> some View {
        ScrollView {
            LazyVStack {
                ForEach(Array(contents.enumerated()), id: \.element) { index, imageUrlString in
                    Group {
                        if let url = URL(string: imageUrlString) {
                            RetryableImage(
                                url: url,
                                index: index,
                                referer: controller.currentChapter.origin?.referer ?? "",
                                readerDirection: controller.readerDirection
                            )
                            .tag(index)
                        } else {
                            Text("Invalid image URL")
                                .tag(index)
                        }
                    }
                }
            }
        }
    }
}

private struct PreviousChapterView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    @EnvironmentObject var controller: ReaderControls
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 8) {
                Text(controller.currentChapter.toString())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Currently Reading")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if controller.canGoBack {
                let prevChapter = controller.chapters[controller.currentIndex + 1]
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Previous Chapter")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prevChapter.toString())
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text("Published by: \(prevChapter.scanlator)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                )
                .padding(.horizontal)
            } else {
                Text("There is no previous chapter.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Exit")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding(.horizontal)
            .highPriorityGesture(
                TapGesture().onEnded {
                    if hapticsEnabled {
                        Haptics.impact()
                    }
                    dismiss()
                }
            )
            
            Spacer()
        }
        .padding()
    }
}


private struct NextChapterView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    @EnvironmentObject var controller: ReaderControls
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 8) {
                Text(controller.currentChapter.toString())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Currently Reading")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if controller.canGoForward {
                let nextChapter = controller.chapters[controller.currentIndex - 1]
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Next Chapter")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextChapter.toString())
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text("Published by: \(nextChapter.scanlator)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                )
                .padding(.horizontal)
            } else {
                Text("There is no next chapter.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Exit")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding(.horizontal)
            .highPriorityGesture(
                TapGesture().onEnded {
                    if hapticsEnabled {
                        Haptics.impact()
                    }
                    dismiss()
                }
            )
            
            Spacer()
        }
        .padding()
    }
}
