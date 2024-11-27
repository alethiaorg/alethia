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
            Group {
                if readingHistories.isEmpty {
                    Spacer()
                    Text("No Available History.")
                    Text("(︶︹︺)")
                    Spacer()
                } else {
                    List {
                        ForEach(readingHistories, id: \.id) { history in
                            Button(action: {
                                selectedHistory = history
                            }) {
                                HistoryItemView(history: history)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(
                                Group {
                                    if let url = history.startChapter.origin?.cover {
                                        KFImage(URL(string: url))
                                            .resizable()
                                            .scaledToFill()
                                            .opacity(0.45)
                                            .blur(radius: 8, opaque: true)
                                            .clipped()
                                    } else {
                                        Color.tint
                                    }
                                }
                            )
                        }
                    }
                    .listRowSpacing(15)
                }
            }
            .navigationTitle("Reading History")
            .sheet(item: $selectedHistory) { history in
                HistoryDetailView(history: history)
            }
        }
    }
}


struct HistoryItemView: View {
    let history: ReadingHistory
    @State private var isShowingDetail = false
    
    var body: some View {
        HStack {
            KFImage(URL(fileURLWithPath: history.startChapter.origin?.source?.icon ?? ""))
                .placeholder { Color.gray }
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(history.startChapter.origin?.manga?.title ?? "Unknown Manga")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(history.startChapter.toString())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(formatDate(history.dateStarted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
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
