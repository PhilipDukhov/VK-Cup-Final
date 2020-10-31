//
//  BasePrepareStoryViewController.swift
//  VK-Cup-C-Camera
//
//  Created by Philip Dukhov on 2/28/20.
//  Copyright © 2020 Philip Dukhov. All rights reserved.
//

import UIKit

class BasePrepareStoryViewController: UIViewController {
    enum State {
        case idle
        case exporting(Float)
    }
    
    let apiManager = ShareStoryApiManager()
    
    private let exportingProgressView =  UIProgressView().apply {
        $0.tintColor = .vkBlue
    }
    private lazy var exportingOverlay = UIView().apply {
        $0.backgroundColor = .white
    }
    
    var attachedProduct: Product!
    
    var state: State = .idle {
        didSet {
            if case .exporting(let progress) = state {
                exportingProgressView.progress = progress
                if case .exporting = oldValue {
                    //no need to animate alpha during exporting
                    return
                }
            }
            let overlayAlpha: CGFloat
            switch state {
            case .exporting:
                overlayAlpha = 1
            case .idle:
                overlayAlpha = 0
            }
            UIView.animate(withDuration: 0.3) { [self] in
                exportingOverlay.alpha = overlayAlpha
            }
        }
    }
    
    private lazy var scrollView = UIScrollView()
    lazy var productView = StoryProductView(product: attachedProduct)
    private lazy var productViewCenterXConstraint =
        productView.centerXAnchor.constraint(
            equalTo: view.leftAnchor,
            constant: 200
            )
    private lazy var productViewCenterYConstraint =
        productView.centerYAnchor.constraint(
            equalTo: view.topAnchor,
            constant: 200
        )
    
    override func viewDidLoad() {
        super.viewDidLoad()
         [productView,
          exportingOverlay,
        ].forEach(view.addSubview)
        
        state = .idle
        let exportingLabel = UILabel()
        exportingLabel.text = ""
        [exportingProgressView,
         exportingLabel,
        ].forEach(exportingOverlay.addSubview)
        [exportingProgressView,
         exportingLabel,
         exportingOverlay,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            exportingOverlay.topAnchor
                .constraint(equalTo: view.topAnchor),
            exportingOverlay.bottomAnchor
                .constraint(equalTo: view.bottomAnchor),
            exportingOverlay.leftAnchor
                .constraint(equalTo: view.leftAnchor),
            exportingOverlay.rightAnchor
                .constraint(equalTo: view.rightAnchor),
            
            exportingProgressView.centerXAnchor
                .constraint(equalTo: exportingOverlay.centerXAnchor),
            exportingProgressView.centerYAnchor
                .constraint(equalTo: exportingOverlay.centerYAnchor),
            exportingProgressView.leftAnchor
                .constraint(
                    equalTo: exportingOverlay.leftAnchor,
                    constant: 16
                ),
            exportingLabel.centerXAnchor
                .constraint(equalTo: exportingOverlay.centerXAnchor),
            exportingLabel.bottomAnchor
                .constraint(
                    equalTo: exportingProgressView.topAnchor,
                    constant: -20
                ),
            productViewCenterXConstraint,
            productViewCenterYConstraint,
        ])
        
        [UITapGestureRecognizer(
            target: self,
            action: #selector(tapHandler(_:))
        ),
        UIPinchGestureRecognizer(
            target: self,
            action: #selector(pinchPanHandler(_:))
        ),
        UIPanGestureRecognizer(
            target: self,
            action: #selector(pinchPanHandler(_:))
        )].forEach {
            view.addGestureRecognizer($0)
            $0.delegate = self
        }
    }
    
    @IBAction func closeButtonTap() {
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func shareButtonTap() {
    }
    
    @objc private func tapHandler(_ gestureRecognizer: UIGestureRecognizer) {
        productView.priceLabelShowed.toggle()
    }
    
    private var moveStartLocation: CGPoint!
    private var pinchStartWidth: CGFloat!
    private var productViewStartCenter: CGPoint!
    private var productViewCenter: CGPoint {
        get {
            .init(
                x: productViewCenterXConstraint.constant,
                y: productViewCenterYConstraint.constant
            )
        }
        set {
            productViewCenterXConstraint.constant = newValue.x
            productViewCenterYConstraint.constant = newValue.y
        }
    }
    
    @objc private func pinchPanHandler(_ gestureRecognizer: UIGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)
        switch gestureRecognizer.state {
        case .began:
            moveStartLocation = location
            productViewStartCenter = productViewCenter
            pinchStartWidth = productView.width
            
        case .changed:
            (gestureRecognizer as? UIPinchGestureRecognizer).map {
                productView.width = pinchStartWidth * $0.scale
            }
            let x = productViewStartCenter.x - moveStartLocation.x + location.x
            let y = productViewStartCenter.y - moveStartLocation.y + location.y
            productViewCenter = .init(
                x: x,
                y: y
            )
        default: break
        }
    }
    
    func dismissAfterFinished() {
        navigationController.map {
            var viewControllers = $0.viewControllers
            viewControllers.removeLast(2)
            $0.setViewControllers(
                viewControllers,
                animated: true
            )
        }
    }
    
    func handleUploadResult(
        _ result: Result<Void, Error>
    ) {
        switch result {
        case .success:
            executeOnMainQueue { [self] in
                state = .exporting(1)
                dismissAfterFinished()
            }
            
        case .failure(let error):
            state = .idle
            present(error: error)
        }
    }
    
    func renderProductView() -> UIImage {
        UIGraphicsImageRenderer(
            size: productView.bounds.size
        ).image { context in
            productView.layer.render(in: context.cgContext)
        }
    }
}

extension BasePrepareStoryViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        productView.frame.controlOptimized.contains(
            touch.location(in: view)
        )
    }
}
