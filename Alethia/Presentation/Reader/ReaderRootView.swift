//
//  ReaderRootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import SwiftUI
import Kingfisher

let PREFETCH_RANGE = 5

struct ReaderRootView: View {
    @StateObject private var controller: ReaderControls
    
    init(chapters: [Chapter], current: Int) {
        _controller = StateObject(wrappedValue: ReaderControls(chapters: chapters, currentIndex: current))
    }
    
    var body: some View {
        ReaderContent()
        .environmentObject(controller)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
    }
}

class ReaderControls: ObservableObject {
    let chapters: [Chapter]
    @Published var currentIndex: Int {
        didSet {
            print("Current Index: \(currentIndex)")
        }
    }
    @Published var readerDirection: ReaderDirection
    
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
}

struct ReaderOverlay<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var controller: ReaderControls
    @State var isOverlayVisible: Bool = true
    @Binding var currentPage: Int
    let totalPages: Int
    let content: Content
    
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
            
            if isOverlayVisible && (currentPage >= 0 && currentPage < totalPages) {
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

struct ReaderContent: View {
    @EnvironmentObject var controller: ReaderControls
    
    @State private var contents = [String]()
    @State private var page = 0
    @State private var isLoading = true
    @State private var error: Error?
    
    @State private var isGoingToPreviousChapter = false
    
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
                ReaderOverlay(currentPage: $page, totalPages: contents.count) {
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
        .onChange(of: page) { _, _ in
            prefetchImages()
        }
        .onChange(of: controller.currentIndex) { oldValue, newValue in
            isGoingToPreviousChapter = newValue > oldValue
            loadChapterContent()
        }
    }
    
    private func loadChapterContent() {
        isLoading = true
        Task {
            do {
                let results = try await getChapterContent(chapter: controller.currentChapter)
                await MainActor.run {
                    contents = results
                    isLoading = false
                    page = isGoingToPreviousChapter ? contents.count - 1 : 0
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
        let startIndex = max(0, page - PREFETCH_RANGE)
        let endIndex = min(contents.count - 1, page + PREFETCH_RANGE)
        
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
        TabView(selection: $page) {
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
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .onChange(of: page) { newPage, oldPage in
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

struct PreviousChapterView: View {
    @EnvironmentObject var controller: ReaderControls
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Currently: \(controller.currentChapter.toString())")
                .font(.title)
                .foregroundColor(.primary)
            
            Spacer()
            
            if controller.canGoBack {
                let prevChapter = controller.chapters[controller.currentIndex + 1]
                Text("Previous: \(prevChapter.toString())")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Published by: \(prevChapter.scanlator)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
            } else {
                Text("There is no previous chapter.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct NextChapterView: View {
    @EnvironmentObject var controller: ReaderControls
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Currently: \(controller.currentChapter.toString())")
                .font(.title)
                .foregroundColor(.primary)
            
            Spacer()
            
            if controller.canGoForward {
                let nextChapter = controller.chapters[controller.currentIndex - 1]
                Text("Next: \(nextChapter.toString())")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Published by: \(nextChapter.scanlator)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
            } else {
                Text("There is no next chapter.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview("Reader Overlay") {
    @Previewable @State var currentPage = 0
    
    @Previewable @StateObject var controller: ReaderControls = ReaderControls(
        chapters: [Chapter(title: "Some", slug: "Thing", number: 1, scanlator: "IDK", date: Date())],
        currentIndex: 0,
        initialDirection: .LTR
    )
    
    ZStack {
        ReaderOverlay(currentPage: $currentPage, totalPages: 10) {
            VStack {
                Text("Hi")
            }
        }
    }
    .environmentObject(controller)
}
