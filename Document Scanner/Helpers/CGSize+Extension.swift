//
//  CGSize+Extension.swift
//  Document Scanner
//
//  Created by Anubhav Tomar on 25/01/25.
//

import SwiftUI

extension CGSize {
    // This function will return a new size that fits the given size in an aspect ratio
    func aspectFit(_ to: CGSize) -> CGSize {
        let scaleX = to.width / self.width
        let sacleY = to.height / self.height
        
        let aspectRatio = min(scaleX, sacleY)
        return .init(width: aspectRatio * width, height: aspectRatio * height)
    }
}
