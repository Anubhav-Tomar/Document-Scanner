//
//  DocumentDetailView.swift
//  Document Scanner
//
//  Created by Anubhav Tomar on 25/01/25.
//

import SwiftUI
import PDFKit
import LocalAuthentication

struct DocumentDetailView: View {
    // View Properties
    @State private var isLoading: Bool = false
    @State private var showFileMover: Bool = false
    @State private var fileURL: URL?
    
    // Lock properties
    @State private var isLockAvailable: Bool?
    @State private var isUnclocked: Bool = false
    
    // EnvironmentValues
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scene
    var document: Document
    
    var body: some View {
        if let pages = document.pages?.sorted(by: {$0.pageIndex < $1.pageIndex}) {
            VStack(spacing: 10) {
                
                //Header View
                HeaderView()
                    .padding([.horizontal, .top], 15)
                
                TabView {
                    ForEach(pages) { page in
                        if let image = UIImage(data: page.pageData) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                }
                .tabViewStyle(.page)
                
                // Footer View
                FooterView()
            }
            .background(.black)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .loadingScreen(status: $isLoading)
            .overlay {
                LockView()
            }
            .fileMover(isPresented: $showFileMover, file: fileURL) { result in
                if case .failure(_) = result {
                    guard let fileURL else { return }
                    try? FileManager.default.removeItem(at: fileURL)
                    self.fileURL = nil
                }
            }
            .onAppear {
                guard document.isLocked else {
                    isUnclocked = true
                    return
                }
                
                let context = LAContext()
                isLockAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            }
            .onChange(of: scene) { oldValue, newValue in
                if newValue != .active && document.isLocked {
                    isUnclocked = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func HeaderView() -> some View {
        Text(document.name)
            .font(.callout)
            .foregroundStyle(.white)
            .hSpacing(.center)
            .overlay(alignment: .trailing) {
                // Lock Button
                Button {
                    document.isLocked.toggle()
                    isUnclocked = !document.isLocked
                    try? context.save()
                } label: {
                    Image(systemName: document.isLocked ? "lock.fill" : "lock.open.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
            }
    }
    
    @ViewBuilder
    private func FooterView() -> some View {
        HStack {
            Button(action: createAndShareDocument) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
            }
            
            Spacer()
            
            Button {
                dismiss()
                Task { @MainActor in
                    // Giving some time to finish zoom transition effect
                    try? await Task.sleep(for: .seconds(0.3))
                    context.delete(document)
                    try? context.save()
                }
            } label: {
                Image(systemName: "trash.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
        }
        .padding([.horizontal, .bottom], 15)
    }
    
    @ViewBuilder
    private func LockView() -> some View {
        if document.isLocked {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(spacing: 6) {
                    if let isLockAvailable, !isLockAvailable {
                        Text("Please enable biometric authentication to unlock this document.")
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                        
                        Text("Tap to unlock!")
                            .font(.callout)
                    }
                }
                .padding(15)
                .background(.bar, in: .rect(cornerRadius: 10))
                .contentShape(.rect)
                .onTapGesture(perform: authenticateUser)
            }
            .opacity(isUnclocked ? 0 : 1)
            .animation(.snappy, value: isUnclocked)
        }
    }
    
    private func authenticateUser() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Locked Document") { status, _ in
                DispatchQueue.main.async {
                    self.isUnclocked = status
                }
            }
        } else {
            isLockAvailable = false
            isUnclocked = false
        }
    }
    
    private func createAndShareDocument() {
        // Converting into PDF
        guard let pages = document.pages?.sorted(by: {$0.pageIndex < $1.pageIndex}) else { return }
        isLoading = true
        
        Task.detached(priority: .high) { [document] in
            try? await Task.sleep(for: .seconds(0.2))
            
            let pdfDocument = PDFDocument()
            for index in pages.indices {
                if let pageImage = UIImage(data: pages[index].pageData),
                   let pdfPage = PDFPage(image: pageImage) {
                    pdfDocument.insert(pdfPage, at: index)
                }
                
                var pdfURL = FileManager.default.temporaryDirectory
                let fileName = "\(document.name).pdf"
                pdfURL.append(path: fileName)
                
                if pdfDocument.write(to: pdfURL) {
                    await MainActor.run { [pdfURL] in
                        fileURL = pdfURL
                        showFileMover = true
                        isLoading = false
                    }
                }
            }
        }
    }
}

