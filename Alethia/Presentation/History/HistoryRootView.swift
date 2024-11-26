//
//  HistoryRootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

struct HistoryRootView: View {
    @Query(sort: \ReadingHistory.dateStarted, order: .reverse) private var readingHistories: [ReadingHistory]
    @State private var selectedHistory: ReadingHistory?
    
    var body: some View {
        NavigationStack {
            if readingHistories.isEmpty {
                Spacer()
                Text("No Available History.")
                Text("(︶︹︺)")
                Spacer()
            }
            else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(readingHistories) { history in
                            Button {
                                selectedHistory = history
                            } label: {
                                HistoryItemView(history: history)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationTitle("Reading History")
                .sheet(item: $selectedHistory) { history in
                    HistoryDetailView(history: history)
                }
            }
        }
    }
}

private struct HistoryItemView: View {
    let history: ReadingHistory
    
    var body: some View {
        ZStack(alignment: .leading) {
            if let url = history.startChapter.origin?.cover {
                KFImage(URL(string: url))
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .blur(radius: 8)
                    .opacity(0.25)
            }
            
            HStack {
                KFImage(URL(fileURLWithPath: history.startChapter.origin?.source?.icon ?? ""))
                    .placeholder { Color.gray }
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(history.startChapter.origin?.manga?.title ?? "Unknown Manga")
                        .font(.headline)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Text("Chapter \(history.startChapter.number.toString())")
                        .font(.subheadline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(formatDate(history.dateStarted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .frame(height: 100)
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct HistoryDetailView: View {
    let history: ReadingHistory
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack {
                headerView
                Form {
                    Section(header: Text("Manga")) {
                        NavigationLink {
                            if let manga = history.startChapter.origin?.manga {
                                DetailView(entry: try! manga.toMangaEntry())
                            }
                            else {
                                Text("Manga Not Found.")
                            }
                        } label: {
                            Text(history.startChapter.origin?.manga?.title ?? "Unknown Manga")
                        }
                    }
                    
                    Section(header: Text("Reading Session")) {
                        LabeledContent("Start Chapter", value: "Chapter \(history.startChapter.number.toString())")
                        LabeledContent("Start Page", value: "\(history.startPage)")
                        if let endChapter = history.endChapter {
                            LabeledContent("End Chapter", value: "Chapter \(endChapter.number.toString())")
                        }
                        if let endPage = history.endPage {
                            LabeledContent("End Page", value: "\(endPage)")
                        }
                    }
                    
                    Section(header: Text("Time")) {
                        LabeledContent("Started", value: formatDate(history.dateStarted))
                        if let dateEnded = history.dateEnded {
                            LabeledContent("Ended", value: formatDate(dateEnded))
                            LabeledContent("Duration", value: formatDuration(from: history.dateStarted, to: dateEnded))
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete History")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .confirmationDialog(
                "Are you sure you want to delete this history?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(history)
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private var headerView: some View {
        ZStack {
            if let url = history.startChapter.origin?.cover {
                KFImage(URL(string: url))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .overlay(Color.black.opacity(0.5))
            }
            
            VStack(spacing: 10) {
                KFImage(URL(fileURLWithPath: history.startChapter.origin?.source?.icon ?? ""))
                    .placeholder { Color.gray }
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                
                Text(history.startChapter.origin?.manga?.title ?? "Unknown Manga")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .shadow(radius: 2)
                
                Text("Chapter \(history.startChapter.number.toString())")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .padding()
        }
        .frame(height: 200)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(from startDate: Date, to endDate: Date) -> String {
        let duration = endDate.timeIntervalSince(startDate)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "Unknown"
    }
}



#Preview {
    HistoryRootView()
}
