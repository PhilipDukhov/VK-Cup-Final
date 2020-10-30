//
//  UIImageView+setImageUrl.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit

extension UIImageView {
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
    
    func setImage(photoSizes: PhotoSizes?) {
        setImage(
            url: photoSizes?
                .bestQualityPhoto(forContainer: bounds.size)?
                .url
        )
    }
    
    func setImage(url: URL?) {
        if self.url == url {
            return
        }
        image = nil
        backgroundColor = UIColor(rgb: 0xEBECF0)
        self.url = url
        guard let url = url else { return }
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard
                let data = data,
                let image = UIImage(data: data)
            else {
                self?.url = nil
                return
            }
            executeOnMainQueue {
                self?.backgroundColor = .clear
                self?.image = image
            }
        }
        dataTask.resume()
        currentTask = dataTask
    }
}
