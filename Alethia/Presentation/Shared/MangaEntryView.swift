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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geometry in
                let cellWidth = geometry.size.width
                let cellHeight = cellWidth * 16 / 11
                
                KFImage(URL(string: item.coverUrl))
                    .resizable()
                    .fade(duration: 0.25)
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .cornerRadius(6)
                    .clipped()
            }
            .aspectRatio(11/16, contentMode: .fit)
            
            Text(item.title)
                .font(.system(size: 14))
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .truncationMode(.tail)
                .foregroundStyle(.text)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
