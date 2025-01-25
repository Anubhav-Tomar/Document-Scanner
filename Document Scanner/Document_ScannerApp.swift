//
//  Document_ScannerApp.swift
//  Document Scanner
//
//  Created by Anubhav Tomar on 24/01/25.
//

import SwiftUI

@main
struct Document_ScannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Document.self)
        }
    }
}
