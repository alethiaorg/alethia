//
//  Origin.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/11/2024.
//

import Foundation
import SwiftData

@Model
final class Origin {
    // MARK: Properties
    
    var id = UUID()
    var slug: String
    var url: String
    var cover: String
    var rating: Double
    var referer: String
    var publishStatus: PublishStatus
    var contentRating: ContentRating
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: Relational Properties
    
    @Relationship(inverse: \Manga.origins) var manga: Manga?
    @Relationship(inverse: \Source.origins) var source: Source?
    var chapters: [Chapter] = []
    
    // MARK: Display Priority
    
    /// Based on order of display priority to manga (0 is highest)
    var priority: Int = 0
    
    // MARK: Initializer
    
    init(
        slug: String,
        url: String,
        cover: String,
        rating: Double,
        referer: String,
        publishStatus: PublishStatus,
        contentRating: ContentRating,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.slug = slug
        self.url = url
        self.cover = cover
        self.rating = rating
        self.referer = referer
        self.publishStatus = publishStatus
        self.contentRating = contentRating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Notes and TODOs

/// NOTE: These props may not be unique if they belong to different sources that return the same
/// TODO: https://stackoverflow.com/a/78640334
