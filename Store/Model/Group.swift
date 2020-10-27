//
//  Group.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

// swiftlint:disable identifier_name

struct Group: Codable {
    struct Size: PhotoSize {
        let type: PhotoSizeType
        let src: String
        let width: Int
        let height: Int
    }
    enum Visibility: Int, Codable {
        case opened
        case closed
        case `private`
    }
    
    let id: String
    let name: String
    let visibility: Visibility
    
    private let photo_50: String
    private let photo_100: String
    private let photo_200: String
    
    var photoSizes: PhotoSizes<Size> {
        let sizes = [
            50: photo_50,
            100: photo_100,
            200: photo_200,
        ].map {
            Size(type: .custom,
                 src: $0.value,
                 width: $0.key,
                 height: $0.key)
        }
        return PhotoSizes(sizes: sizes)
    }
}
