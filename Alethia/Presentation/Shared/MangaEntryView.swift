//
//  MangaEntryView.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/11/2024.
//

import SwiftUI
import Kingfisher

struct MangaEntryView: View {
    let item: MangaEntry
    let lineLimit: Int
    let inLibrary: Bool
    
    init(item: MangaEntry, lineLimit: Int? = 1, inLibrary: Bool? = nil) {
        self.item = item
        self.lineLimit = lineLimit ?? 1
        self.inLibrary = inLibrary ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geometry in
                let cellWidth = geometry.size.width
                let cellHeight = cellWidth * 16 / 11
                
                KFImage(URL(string: item.coverUrl))
                    .placeholder { Color.secondary.shimmer() }
                    .resizable()
                    .fade(duration: 0.25)
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .cornerRadius(6)
                    .clipped()
                    .overlay {
                        if inLibrary {
                            ZStack(alignment: .topTrailing) {
                                Color.black.opacity(0.5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .cornerRadius(6)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.green)
                                    .padding(10)
                            }
                        }
                    }
            }
            .aspectRatio(11/16, contentMode: .fit)
            
            Text(item.title)
                .font(.system(size: 14))
                .fontWeight(.medium)
                .lineLimit(lineLimit)
                .multilineTextAlignment(.leading)
                .truncationMode(.tail)
                .foregroundStyle(.text)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
