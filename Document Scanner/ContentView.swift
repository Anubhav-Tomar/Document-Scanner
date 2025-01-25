//
//  ContentView.swift
//  Document Scanner
//
//  Created by Anubhav Tomar on 24/01/25.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("showIntroView") private var showIntroView: Bool = true 
    
    var body: some View {
        Home()
            .sheet(isPresented: $showIntroView) {
                IntroScreen()
                    .interactiveDismissDisabled()
            }
    }
}

#Preview {
    ContentView()
}
