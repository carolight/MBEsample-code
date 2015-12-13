//
//  MBEMetalView.swift
//  ClearScreen
//
//  Created by Caroline Begbie on 1/11/2015.
//  Copyright © 2015 Caroline Begbie. All rights reserved.
//

import UIKit
import QuartzCore
import Metal

class MBEMetalView: UIView {
  
  var metalLayer:CAMetalLayer {
    return self.layer as! CAMetalLayer
  }
  
  let device: MTLDevice?
  
  required init?(coder aDecoder: NSCoder) {
    device = MTLCreateSystemDefaultDevice()
    super.init(coder: aDecoder)
    metalLayer.device = device
    metalLayer.pixelFormat = .BGRA8Unorm
  }

  override class func layerClass() -> AnyClass {
    return CAMetalLayer.self
  }
  
  override func didMoveToWindow() {
    super.didMoveToWindow()
    redraw()
  }
  
  private func redraw() {

    // Setup drawable
    guard let drawable = metalLayer.nextDrawable() else {
      return
    }
    // Setup texture
    let texture = drawable.texture
    
    // Setup render passes
    let passDescriptor = MTLRenderPassDescriptor()
    let colorAttachment = passDescriptor.colorAttachments[0]
    colorAttachment.texture = texture
    colorAttachment.loadAction = .Clear
    colorAttachment.storeAction = .Store
    colorAttachment.clearColor = MTLClearColor(red: 1, green: 0, blue: 0, alpha: 1)
    
    // Setup command queue
    let commandQueue = device?.newCommandQueue()
    
    // Setup command buffer
    let commandBuffer = commandQueue?.commandBuffer()
    
    // Setup command encoder
    let commandEncoder = commandBuffer?.renderCommandEncoderWithDescriptor(passDescriptor)
    commandEncoder?.endEncoding()
    
    commandBuffer?.presentDrawable(drawable)
    commandBuffer?.commit()
  }
  
  
}
