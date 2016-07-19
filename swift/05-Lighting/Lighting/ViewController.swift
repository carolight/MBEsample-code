//
//  ViewController.swift
//  Lighting
//
//  Created by Caroline Begbie on 1/01/2016.
//  Copyright © 2016 Caroline Begbie. All rights reserved.
//

import MetalKit

class ViewController: UIViewController {

  var metalView:MTKView {
    return view as! MTKView
  }
  
  var renderer: MBERenderer?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    metalView.device = MTLCreateSystemDefaultDevice()
    renderer = MBERenderer(device: metalView.device)
    metalView.delegate = renderer
  }

}

