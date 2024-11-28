//
//  SourcesView.swift
//  Alethia
//
//  Created by Angelo Carasig on 27/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

private enum AlertType: Identifiable {
    case promote
    case delete
    
    var id: String {
        switch self {
        case .promote: return "promote"
        case .delete: return "delete"
        }
    }
}

struct SourcesView: View {
    @AppStorage("haptics") private var hapticsEnabled: Bool = false
    let manga: Manga
    
    var body: some View {
        let origins = manga.origins.sorted { $0.order < $1.order }
        
        VStack(alignment: .leading, spacing: 16) {
            NavigationButton(
                action: { if hapticsEnabled { Haptics.impact() } },
                destination: { SourceDetailView(manga: manga) },
                label: {
                    HStack {
                        Text("Sources")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Image(systemName: "chevron.right")
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            )
            
            VStack(spacing: 20) {
                ForEach(origins, id: \.id) { origin in
                    HStack(spacing: 12) {
                        KFImage(URL(fileURLWithPath: origin.source?.icon ?? ""))
                            .placeholder {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(origin.source?.name ?? "Unknown Source")
                                .font(.headline)
                            
                            Text(origin.source?.host?.name ?? "unknown")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("\(origin.chapters.count) Chapters")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if let originURL = URL(string: origin.url) {
                            HStack(spacing: 16) {
                                Button {
                                    UIPasteboard.general.string = originURL.absoluteString
                                } label: {
                                    Image(systemName: "link")
                                        .font(.system(size: 20, weight: .medium))
                                }
                                .buttonStyle(.plain)
                                
                                Link(destination: originURL) {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 20, weight: .medium))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .contextMenu {
                        if let originURL = URL(string: origin.url) {
                            Button {
                                UIPasteboard.general.string = originURL.absoluteString
                            } label: {
                                Label("Copy Link", systemImage: "link")
                            }
                            
                            Link(destination: originURL) {
                                Label("Open in Browser", systemImage: "safari")
                            }
                        }
                    }
                }
            }
        }
        .opacity(manga.inLibrary ? 1 : 0.5)
    }
}

struct SourceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""
    
    let manga: Manga
    
    var filtered: [Origin] {
        manga.origins
            .filter { searchText.isEmpty || $0.source!.name.localizedStandardContains(searchText) }
            .sorted { $0.order < $1.order }
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 16) {
                SearchBar(searchText: $searchText)
                    .padding(.horizontal)
                
                List {
                    if let firstOrigin = filtered.first {
                        Section(header: Text("Display Origin")) {
                            OriginRow(
                                modelContext: modelContext,
                                origin: firstOrigin,
                                isFirst: true,
                                setDefault: { }
                            )
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if filtered.count > 1 {
                        Section(header: Text("Other Origins")) {
                            ForEach(filtered.dropFirst(), id: \.id) { origin in
                                OriginRow(
                                    modelContext: modelContext,
                                    origin: origin,
                                    isFirst: false,
                                    setDefault: { setDefaultOrigin(origin) }
                                )
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Manage Origins")
    }
    
    private func setDefaultOrigin(_ origin: Origin) -> Void {
        Task {
            do {
                withAnimation {
                    manga.updateOriginOrder(newDefaultOrigin: origin)
                }
                
                let newOrigin = manga.getFirstOrigin()
                
                guard let host = newOrigin.source?.host,
                      let sourcePath = newOrigin.source?.path else {
                    return
                }
                
                let baseUrl = host.baseUrl
                let version = host.version
                
                let mangaFromContext: Manga = try await getMangaFromEntry(
                    entry: MangaEntry(
                        sourceId: newOrigin.source!.id,
                        fetchUrl: URL.appendingPaths(
                            baseUrl,
                            "api",
                            "v\(version)",
                            sourcePath,
                            "manga",
                            newOrigin.slug
                        )!.absoluteString,
                        
                        // Not important values
                        title: "",
                        coverUrl: ""
                    ),
                    context: modelContext,
                    transient: true,
                    insert: false
                )
                
                manga.updateMetadataFromTransient(mangaFromContext)
                
                modelContext.insert(manga)
                
                try modelContext.save()
                print("Successfully saved changes to the model context.")
            } catch {
                print("Error occurred during setDefaultOrigin:")
                print("Error: \(error)")
            }
        }
    }
    
}

private struct OriginRow: View {
    let modelContext: ModelContext
    let origin: Origin
    let isFirst: Bool
    
    let setDefault: () -> Void
    
    @State private var activeAlert: AlertType? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            KFImage(URL(fileURLWithPath: origin.source?.icon ?? ""))
                .placeholder {
                    Color.gray.opacity(0.3)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .cornerRadius(12)
                .shadow(radius: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(origin.source?.name ?? "Unknown Source")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(origin.source?.host?.name ?? "Unknown Host")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                
                Text("\(origin.chapters.count) chapters")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: {
                    activeAlert = .promote
                }) {
                    Text("Set Default")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.15))
                        )
                        .foregroundColor(isFirst ? Color.blue.opacity(0.5) : Color.blue)
                }
                .disabled(isFirst)
                
                Button(action: {
                    activeAlert = .delete
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.15))
                    )
                    .foregroundColor(isFirst ? Color.red.opacity(0.5) : Color.red)
                }
                .disabled(isFirst)
            }
        }
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .promote:
                return Alert(
                    title: Text("Confirm Promote to Default"),
                    message: Text("Are you sure you want to set this origin to be the default origin for \(origin.manga?.title ?? "'Unknown Manga'")?"),
                    primaryButton: .default(Text("Confirm")) {
                        setDefault()
                    },
                    secondaryButton: .cancel()
                )
            case .delete:
                return Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to remove this origin from \(origin.manga?.title ?? "'Unknown Manga'")?"),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteOrigin()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func deleteOrigin() {
        modelContext.delete(origin)
        print("Deleted origin with ID: \(origin.id)")
    }
}

