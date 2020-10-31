//
//  PrepareImageStoryViewController.swift
//  Store
//
//  Created by Philip Dukhov on 10/31/20.
//

import UIKit

class PrepareImageStoryViewController: BasePrepareStoryViewController {
    @IBOutlet private weak var imageView: UIImageView!
    
    var photo: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = photo
    }
    
    override func shareButtonTap() {
        state = .exporting(0)
        
        let imageViewSize = imageView.bounds.size
        let photoSize = photo.size
        
        var scale: CGFloat = imageViewSize.width / photoSize.width
        if photoSize.height * scale < imageViewSize.height {
            scale = imageViewSize.height / photoSize.height
        }
        
        let croppedPhotoSize = CGSize(
            width: imageViewSize.width / scale,
            height: imageViewSize.height / scale
        )
        let cropRect = CGRect(
            origin: CGPoint(
                x: (croppedPhotoSize.width - photoSize.width) / 2,
                y: (croppedPhotoSize.height - photoSize.height) / 2
            ), size: croppedPhotoSize
        )
        let productFrame = productView.frame
            .applying(
                .init(
                    scaleX: 1 / scale,
                    y: 1 / scale
                )
            )
        let productImage = renderProductView()
        DispatchQueue(label: "processImage")
            .async { [self] in
                cropImageAndUpload(
                    photo,
                    cropRect: cropRect,
                    productFrame: productFrame,
                    productImage: productImage
                )
            }
    }
    
    private func cropImageAndUpload(
        _ image: UIImage,
        cropRect: CGRect,
        productFrame: CGRect,
        productImage: UIImage
    ) {
        let image = UIGraphicsImageRenderer(
            size: cropRect.size
        ).image { _ in
            photo.draw(at: cropRect.origin)
            productImage.draw(in: productFrame)
        }
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("file.jpg")
        try? FileManager.default.removeItem(at: url)
        
        var data: Data
        var compressionQuality: CGFloat = 0
        repeat {
            data = image.jpegData(
                compressionQuality: compressionQuality
            )!
            compressionQuality += 0.1
        } while data.count < 1024 * 1024 && compressionQuality <= 1
        try? data.write(to: url)
        executeOnMainQueue { [self] in
            state = .exporting(0.1)
        }
        
        apiManager
            .uploadPhoto(
                photoURL: url,
                linkURL: attachedProduct.link
            ) { progress in
                executeOnMainQueue { [weak self] in
                    self?.state = .exporting(0.1 + 0.9 * progress)
                }
            } completion: { [weak self] in
                self?.handleUploadResult($0.mapError { $0 })
            }
    }
}
