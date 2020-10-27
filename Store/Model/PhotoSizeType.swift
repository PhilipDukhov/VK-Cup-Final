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

protocol PhotoSize: Codable, Hashable {
    var type: PhotoSizeType { get }
    var src: String { get }
    var width: Int { get }
    var height: Int { get }
}

extension PhotoSize {
    var size: CGSize {
        .init(width: width, height: height)
    }
    
    var url: URL { URL(string: src)! }
}

struct PhotoSizes<Size: PhotoSize>: Codable, Hashable {
    let sizes: [Size]
    
    init(sizes: [Size]) {
        self.sizes = sizes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        sizes = try container.decode([Size].self)
            .filter { $0.type.isAspectRatioOriginal }
            .sorted { $0.width < $1.width }
    }
    
    func bestQualityPhoto(forContainer size: CGSize) -> Size {
        let res = sizes.first {
            $0.size.width > size.width * UIScreen.main.scale &&
                $0.size.height > size.height * UIScreen.main.scale
        } ?? sizes.last!
        return res
    }
}
