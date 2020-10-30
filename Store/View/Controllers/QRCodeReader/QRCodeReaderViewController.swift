//
//  QRCodeReaderViewController.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import UIKit

class QRCodeReaderViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
