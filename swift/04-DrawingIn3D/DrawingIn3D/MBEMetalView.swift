//
//  MBEMetalView.swift
//  DrawingIn3D
//
//  Created by Caroline Begbie on 3/11/2015.
//  Copyright © 2015 Caroline Begbie. All rights reserved.
//

import UIKit
import QuartzCore
import Metal

protocol MBEMetalViewDelegate {
  /// This method is called once per frame. Within the method, you may access
  /// any of the properties of the view, and request the current render pass
  /// descriptor to get a descriptor configured with renderable color and depth
  /// textures.
  func drawInView(view: MBEMetalView)
}

class MBEMetalView: UIView {
  
  /// The Metal layer that backs this view
  var metalLayer:CAMetalLayer {
    return layer as! CAMetalLayer
  }
  
  
  var displayLink: CADisplayLink?
  
  /// The delegate of this view, responsible for drawing
  var delegate: MBEMetalViewDelegate?
  
  /// The view's layer's current drawable. This is valid only in the context
  /// of a callback to the delegate's drawInView() method.
  var currentDrawable: CAMetalDrawable?

  var depthTexture: MTLTexture?
  

  /// A render pass descriptor configured to use the current drawable's texture
  /// as its primary color attachment and an internal depth texture of the same
  /// size as its depth attachment's texture
  var currentRenderPassDescriptor: MTLRenderPassDescriptor {
    let passDescriptor = MTLRenderPassDescriptor()
    let colorAttachment = passDescriptor.colorAttachments[0]
    colorAttachment.texture = currentDrawable?.texture
    colorAttachment.clearColor = clearColor
    colorAttachment.storeAction = .Store
    colorAttachment.loadAction = .Clear
    
    passDescriptor.depthAttachment.texture = depthTexture
    passDescriptor.depthAttachment.clearDepth = 1.0
    passDescriptor.depthAttachment.storeAction = .DontCare
    passDescriptor.depthAttachment.loadAction = .Clear
    return passDescriptor
  }

  /// The duration (in seconds) of the previous frame. This is valid only in the context
  /// of a callback to the delegate's drawInView() method.
  var frameDuration: NSTimeInterval?

  /// The color to which the color attachment should be cleared at the start of
  /// a rendering pass
  var clearColor: MTLClearColor!

  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    metalLayer.device = MTLCreateSystemDefaultDevice()
    metalLayer.pixelFormat = .BGRA8Unorm
  }
  
  override class func layerClass() -> AnyClass {
    return CAMetalLayer.self
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.contentsScale = UIScreen.mainScreen().scale
    let scale = layer.contentsScale
    metalLayer.drawableSize = CGSize(width: layer.bounds.width * scale, height: layer.bounds.height * scale)
    makeDepthTexture()
  }
  override func didMoveToSuperview() {
  
    super.didMoveToSuperview()

    if superview != nil {
      displayLink = CADisplayLink(target: self, selector: "displayLinkDidFire:")
      displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    } else {
      displayLink?.invalidate()
      displayLink = nil
    }
  }
  
  func displayLinkDidFire(displayLink: CADisplayLink) {
    currentDrawable = metalLayer.nextDrawable()
    frameDuration = displayLink.duration;

    delegate?.drawInView(self)
  }
  
  private func makeDepthTexture() {
    let width = Int(metalLayer.drawableSize.width)
    let height = Int(metalLayer.drawableSize.height)
    guard let depthTexture = depthTexture else {
      let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.Depth32Float, width: width, height: height, mipmapped: false)
      self.depthTexture = metalLayer.device?.newTextureWithDescriptor(textureDescriptor)
      return
    }
    if depthTexture.width != width || depthTexture.height != height {
      let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.Depth32Float, width: width, height: height, mipmapped: false)
      self.depthTexture = metalLayer.device?.newTextureWithDescriptor(textureDescriptor)
    }
  }
}
