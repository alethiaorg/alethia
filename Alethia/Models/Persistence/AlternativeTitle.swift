//
//  AlternativeTitle.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/11/2024.
//

import Foundation
import SwiftData

@Model
final class AlternativeTitle {
    // MARK: Definitions - Indexed Definitions
    #Index<AlternativeTitle>([\.title])
    
    // MARK: Properties
    
    var title: String
    
    // MARK: Relational Properties
    
    @Relationship(deleteRule: .cascade, inverse: \Manga.alternativeTitles) var manga: Manga?
    
    // MARK: Initializer
    
    init(title: String, manga: Manga) {
        self.title = title
        self.manga = manga
    }
}
