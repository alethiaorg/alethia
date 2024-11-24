//
//  Accordion.swift
//  Alethia
//
//  Created by Angelo Carasig on 16/11/2024.
//

import SwiftUI

struct Accordion<Content: View>: View {
    let title: String
    let content: Content
    @State private var isExpanded: Bool = false
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .padding(.trailing, 10)
                        .rotation3DEffect(
                            .degrees(isExpanded ? 180 : 0),
                            axis: (x: 1, y: 0, z: 0)
                        )
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 0)
                .foregroundColor(.text)
                .background(Color.background)
                .frame(maxWidth: .infinity)
                // Border bottom
                .overlay(Rectangle().frame(height: 1, alignment: .top).foregroundColor(.tint), alignment: .bottom)
            }
            
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(title)
            .accessibilityHint(isExpanded ? "Collapse" : "Expand")
            
            if isExpanded {
                content
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 16) {
        Accordion(title: "Is it accessible?") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Yes. It adheres to the WAI-ARIA design pattern.")
                Text("Key features:")
                    .font(.headline)
                Text("• Proper labeling for screen readers")
                Text("• Keyboard navigation support")
                Text("• Clear visual indicators")
            }
        }
        
        Accordion(title: "Is it styled?") {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.blue)
                Text("Yes. It comes with default styles that match the other components' aesthetic.")
            }
        }
        
        Accordion(title: "Is it animated?") {
            VStack {
                Text("Yes. It's animated by default, but you can disable it if you prefer.")
                Button("Toggle Animation") {
                    // Animation toggle logic would go here
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
    .padding()
}

#Preview("AniList") {
    let title: String = "Some Title"
    let authors: [String] = ["Some", "Author", "I D K"]
    let chapterCount: Int = 2
    let inLibrary: Bool = true
    
    Accordion(title: "Tracking") {
        HStack {
            Image("AniList")
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(4)
                .clipped()
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.text)
                    .lineLimit(1)
                
                Text(authors.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.text.opacity(0.75))
                    .lineLimit(1)
                
                HStack {
                    Text("1/\(chapterCount) Chapters")
                        .font(.subheadline)
                        .foregroundColor(.text)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Text("Reading")
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .foregroundColor(.text)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            .padding(.leading, 10)
            
            Spacer()
        }
        .padding()
        .frame(height: 100)
        .background(
            Image("AniList")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 16)
                .overlay(.black.opacity(0.3))
                .clipped()
                .allowsHitTesting(false)
        )
        .cornerRadius(8)
        .grayscale(inLibrary ? 0 : 1)
    }
}
