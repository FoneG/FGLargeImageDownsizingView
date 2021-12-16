//
//  ViewController.swift
//  FGLargeImageDownsizing
//
//  Created by 15757127193@163.com on 12/15/2021.
//  Copyright (c) 2021 15757127193@163.com. All rights reserved.
//

import UIKit
import FGLargeImageDownsizingView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let largeImageView = FGLargeImageDownsizingView.init(frame: self.view.bounds)
        largeImageView.kSourceImageTileSizeMB = 10
        largeImageView.kDestImageSizeMB = 100

        view.addSubview(largeImageView)
        let path = Bundle.main.path(forResource: "large_leaves_70mp.jpg", ofType: nil) ?? ""
        largeImageView.setContentsOfFile(path)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

