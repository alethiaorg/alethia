//
//  HostAddView.swift
//  Alethia
//
//  Created by Angelo Carasig on 20/11/2024.
//

import SwiftUI
import SwiftData
import Kingfisher

struct HostAddView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var newHost: TransientHost?
    @State private var url: String = "https://lighthouse.alethia.workers.dev/"
    
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        List {
            Section("Repository URL") {
                TextField("URL", text: Binding(
                    get: { url },
                    set: { newValue in
                        url = newValue
                        withAnimation {
                            newHost = nil
                        }
                    }
                ))
                .keyboardType(.URL)
                .disableAutocorrection(true)
            }
            
            Section {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                else {
                    Button(action: testUrl) {
                        Text("Test")
                            .foregroundStyle(isLoading || url.isEmpty ? Color.secondary : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading || url.isEmpty)
                    
                    Button {
                        Task {
                            try await saveNewHost()
                        }
                    } label: {
                        Text("Save")
                            .foregroundStyle(isLoading || newHost == nil ? Color.secondary : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading || newHost == nil)
                }
            }
            
            if let newHost = newHost {
                Section("Sources - \(newHost.host.repository)") {
                    ForEach(newHost.sources, id: \.id) { x in
                        HStack {
                            KFImage(URL(string: x.icon))
                                .placeholder { Color.gray }
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading) {
                                Text(x.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Add New Host")
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func testUrl() {
        guard !url.isEmpty else { return }
        
        withAnimation {
            isLoading = true
            newHost = nil
        }
        
        Task {
            do {
                let result = try await getNewHost(for: url)
                withAnimation {
                    newHost = result
                    isLoading = false
                }
            } catch {
                withAnimation {
                    alertMessage = error.localizedDescription.description
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    @MainActor
    private func saveNewHost() async throws -> Void {
        guard let transientHost = newHost, !url.isEmpty else { return }
                
        let host: Host = Host(
            id: UUID(),
            name: transientHost.host.repository,
            baseUrl: url,
            version: transientHost.host.version
        )
        
        // Prevent adding new host when existing host exists
        let hostId = host.id
        let hostName = host.name
        let hostUrl = host.baseUrl
        let predicate = #Predicate<Host> {
            $0.id == hostId ||
            $0.name == hostName ||
            $0.baseUrl == hostUrl
        }
        
        let existingHosts = try modelContext.fetch(FetchDescriptor<Host>(predicate: predicate))
        
        guard existingHosts.isEmpty else {
            withAnimation {
                alertMessage = AppError.duplicateHost.errorDescription!
                showingAlert = true
                isLoading = false
            }
            return
        }
        
        var sources = [Source]()
        
        for source in transientHost.sources {
            guard let icon = await downloadImage(name: source.name, url: URL.appendingPaths(source.icon)!) else { return }
            
            let newSource = Source(
                id: UUID(),
                name: source.name,
                icon: icon,
                path: source.path
            )
            
            var routes = [SourceRoute]()
            for route in source.routes {
                routes.append(SourceRoute(name: route.name, path: route.path))
            }
            
            newSource.routes = routes
            sources.append(newSource)
        }
        
        print("""
            New Host Added:
            ---------------
            ID: \(host.id)
            Name: \(host.name)
            Base URL: \(host.baseUrl)
            Version: \(host.version)
            
            Sources:
            --------
            \(sources.enumerated().map { index, source in
                """
                [\(index + 1)]
                ID: \(source.id)
                Name: \(source.name)
                Icon: \(source.icon)
                Path: \(source.path)
                """
            }.joined(separator: "\n\n"))
            
            Total Sources Added: \(sources.count)
            """)
        
        host.sources.append(contentsOf: sources)
        
        modelContext.insert(host)
        try modelContext.save()
        
        dismiss()
    }
}

#Preview {
    HostAddView()
}
