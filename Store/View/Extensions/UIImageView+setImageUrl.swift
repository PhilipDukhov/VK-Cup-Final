//
//  UIImageView+setImageUrl.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit

extension UIImageView: Clearable {
    var childrenToClear: [Clearable] { [] }
    
    private static let dataTaskAssociation = ObjectAssociation<URLSessionDataTask>()
    private static let urlAssociation = ObjectAssociation<NSURL>()
    
    private var url: URL? {
        get { Self.urlAssociation[self] as URL? }
        set { Self.urlAssociation[self] = newValue as NSURL? }
    }
    private var currentTask: URLSessionDataTask? {
        get { Self.dataTaskAssociation[self] }
        set {
            Self.dataTaskAssociation[self]?.cancel()
            Self.dataTaskAssociation[self] = newValue
        }
    }
    
    func clear() {
        image = nil
        currentTask = nil
        url = nil
    }
    
    func cancelPhotoSizeDownload() {
        currentTask = nil
        url = nil
    }
    
    func setImage(photoSizes: PhotoSizes?) {
        guard
            let photoSizes = photoSizes,
            let bestSize = photoSizes
                .bestQualityPhoto(forContainer: bounds.size)
        else {
            setNil()
            return
        }
        guard let bestCache = photoSizes.sizes.mapLastWithSelf({
            URLSession.shared
                .configuration
                .urlCache?.cachedResponse(
                    for: .init(url: $0.url)
                )
        }) else {
            setImage(bestSize.url)
            return
        }
        if bestSize.width > bestCache.element.width {
            setImage(bestSize.url)
        }
        handleResponseData(bestCache.newValue.data)
    }
    
    private func setImage(_ newUrl: URL?) {
        if url == newUrl {
            return
        }
        setNil()
        url = newUrl
        guard let url = url else { return }
        let dataTask = URLSession.shared.dataTask(
            with: url
        ) { [weak self] data, _, _ in
            self?.handleResponseData(data)
            print(newUrl)
        }
        dataTask.resume()
        currentTask = dataTask
    }
    
    private func setNil() {
        image = nil
        backgroundColor = UIColor(rgb: 0xEBECF0)
    }
    
    private func handleResponseData(_ data: Data?) {
        guard
            let data = data,
            let newImage = UIImage(data: data)
        else {
            url = nil
            return
        }
        executeOnMainQueue { [self] in
            backgroundColor = .clear
            image = newImage
        }
    }
}

extension Sequence {
    func mapLastWithSelf<T>(
        _ transform: (Element) throws -> T?
    ) rethrows -> (element: Element, newValue: T)? {
        for element in reversed() {
            guard let last = try transform(element) else { continue }
            return (element, last)
        }
        return nil
    }
}
