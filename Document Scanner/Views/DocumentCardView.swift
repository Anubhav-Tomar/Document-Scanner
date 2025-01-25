//
//  DocumentCardView.swift
//  Document Scanner
//
//  Created by Anubhav Tomar on 25/01/25.
//

import SwiftUI

struct DocumentCardView: View {
    
    var document: Document
    var animationID: Namespace.ID
    @State private var downsizedImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let firstPage = document.pages?.sorted(by: {$0.pageIndex < $1.pageIndex}).first {
                GeometryReader {
                    let size = $0.size
                    
                    // Actual image without Downsizing
//                    if let image = UIImage(data: firstPage.pageData!){
//                        Image(uiImage: downsizedImage)
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .frame(width: size.width, height: size.height)
//                    }
                    
                    if let downsizedImage {
                        Image(uiImage: downsizedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                    } else {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .task(priority: .high) {
                                // Down sizing image
                                guard let image = UIImage(data: firstPage.pageData) else { return }
                                let aspectSize = image.size.aspectFit(.init(width: 150, height: 150))
                                let render = UIGraphicsImageRenderer(size: aspectSize)
                                let resizedImage = render.image { context in
                                    image.draw(in: .init(origin: .zero, size: aspectSize))
                                }
                                await MainActor.run {
                                    downsizedImage = resizedImage
                                }
                            }
                    }
                    
                    if document.isLocked {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                            
                            Image(systemName: "lock.fill")
                                .font(.title3)
                        }
                    }
                }
                .frame(height: 150)
                .clipShape(.rect(cornerRadius: 15))
                .matchedTransitionSource(id: document.uniqueID, in: animationID)
            }
            
            Text(document.name)
                .font(.callout)
                .lineLimit(1)
                .padding(.top, 10)
            
            Text(document.createdAt.formatted(date: .numeric, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
}

//#Preview {
//    DocumentCardView()
//}
