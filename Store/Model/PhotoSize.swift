//
//  VKPhotoSizeType.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit

enum PhotoSizeType: String, Codable {
    case custom
    
    case s // пропорциональная копия изображения с максимальной стороной 75px;
    case m // пропорциональная копия изображения с максимальной стороной 130px;
    case x // пропорциональная копия изображения с максимальной стороной 604px;
    case y // пропорциональная копия изображения с максимальной стороной 807px;
    case z // пропорциональная копия изображения с максимальным размером 1080x1024;
    case w // пропорциональная копия изображения с максимальным размером 2560x2048px.
    
    case o // если соотношение "ширина/высота" исходного изображения меньше или равно 3:2, то пропорциональная копия с максимальной шириной 130px. Если соотношение "ширина/высота" больше 3:2, то копия обрезанного слева изображения с максимальной шириной 130px и соотношением сторон 3:2.
    case p // если соотношение "ширина/высота" исходного изображения меньше или равно 3:2, то пропорциональная копия с максимальной шириной 200px. Если соотношение "ширина/высота" больше 3:2, то копия обрезанного слева и справа изображения с максимальной шириной 200px и соотношением сторон 3:2.
    case q // если соотношение "ширина/высота" исходного изображения меньше или равно 3:2, то пропорциональная копия с максимальной шириной 320px. Если соотношение "ширина/высота" больше 3:2, то копия обрезанного слева и справа изображения с максимальной шириной 320px и соотношением сторон 3:2.
    case r // если соотношение "ширина/высота" исходного изображения меньше или равно 3:2, то пропорциональная копия с максимальной шириной 510px. Если соотношение "ширина/высота" больше 3:2, то копия обрезанного слева и справа изображения с максимальной шириной 510px и соотношением сторон 3:2
    
    var isAspectRatioOriginal: Bool {
        switch self {
        case .s, .m, .x, .y, .z, .w:
            return true
            
        default:
            return false
        }
    }
}

struct PhotoSize: Codable, Hashable {
    let type: PhotoSizeType
    let src: String
    let width: Int
    let height: Int
    
    var size: CGSize {
        .init(width: width, height: height)
    }
    
    var url: URL { URL(string: src)! }
    
    enum CodingKeys: String, CodingKey {
        case type
        case src
        case url
        case width
        case height
    }
    
    init(
        type: PhotoSizeType,
        src: String,
        width: Int,
        height: Int
    ) {
        self.type = type
        self.src = src
        self.width = width
        self.height = height
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(PhotoSizeType.self, forKey: .type)
        src = try (container.decodeIfPresent(String.self, forKey: .url) ??
            container.decode(String.self, forKey: .src))
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(src, forKey: .src)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}

struct PhotoSizes: Codable, Hashable {
    let sizes: [PhotoSize]
    
    init(sizes: [PhotoSize]) {
        self.sizes = sizes
            .sorted()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        sizes = try container.decode([PhotoSize].self)
            .filter { $0.type.isAspectRatioOriginal }
            .sorted()
    }
    
    func bestQualityPhoto(forContainer size: CGSize) -> PhotoSize? {
        sizes.first {
            $0.size.width > size.width * UIScreen.main.scale &&
                $0.size.height > size.height * UIScreen.main.scale
        } ?? sizes.last
    }
    
    static let zero = Self(sizes: [])
}

extension Array where Element == PhotoSize {
    fileprivate func sorted() -> Self {
        sorted { $0.width < $1.width }
    }
}
