//
//  ViewController.swift
//  DrawingIn3D
//
//  Created by Caroline Begbie on 3/11/2015.
//  Copyright © 2015 Caroline Begbie. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  var metalView:MBEMetalView {
    return view as! MBEMetalView
  }
  
  var renderer = MBERenderer()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    metalView.delegate = renderer
  }
}

