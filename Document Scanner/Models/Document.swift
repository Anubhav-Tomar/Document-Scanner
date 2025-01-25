//
//  Document.swift
//  Document Scanner
//
//  Created by Anubhav Tomar on 24/01/25.
//

import SwiftUI
import SwiftData

@Model
class Document {
    var name: String
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \DocumentPage.document)
    var pages: [DocumentPage]?
    var isLocked: Bool = false
    var uniqueID: String = UUID().uuidString
    
    init(name: String,pages: [DocumentPage]? = nil) {
        self.name = name
        self.pages = pages
    }
}
