//
//  MBEMetalView.swift
//  DrawingIn2D
//
//  Created by Caroline Begbie on 1/11/2015.
//  Copyright © 2015 Caroline Begbie. All rights reserved.
//

import UIKit
import QuartzCore
import MetalKit

struct MBEVertex {
  var position: float4
  var color: float4
}

class MBEMetalView: UIView {
  
  var metalLayer:CAMetalLayer {
    return self.layer as! CAMetalLayer
  }
  
  var device: MTLDevice?
  
  var displayLink: CADisplayLink?
  
  var vertexBuffer: MTLBuffer?
  var pipeline: MTLRenderPipelineState!
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    makeDevice()
    makeBuffers()
    makePipeline()
  }

  override class var layerClass: AnyClass {
    return CAMetalLayer.self
  }
  
  override func didMoveToSuperview() {
    super.didMoveToSuperview()

    if superview != nil {
      displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkDidFire))
      displayLink?.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
    } else {
      displayLink?.invalidate()
      displayLink = nil
    }
  }
  
  func displayLinkDidFire(displayLink: CADisplayLink) {
    redraw()
  }
  
  private func redraw() {

    // Setup drawable
    guard let drawable = metalLayer.nextDrawable() else {
      return
    }

    // Setup texture
    let framebufferTexture = drawable.texture
    
    // Setup render passes
    let passDescriptor = MTLRenderPassDescriptor()
    let colorAttachment = passDescriptor.colorAttachments[0]
    colorAttachment?.texture = framebufferTexture
    colorAttachment?.loadAction = .clear
    colorAttachment?.storeAction = .store
    colorAttachment?.clearColor = MTLClearColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    
    // Setup command queue
    let commandQueue = device?.newCommandQueue()
    
    // Setup command buffer
    let commandBuffer = commandQueue?.commandBuffer()
    
    // Start render pass
    let commandEncoder = commandBuffer?.renderCommandEncoder(with: passDescriptor)
    commandEncoder?.setRenderPipelineState(pipeline)
    commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
    commandEncoder?.drawPrimitives(.triangle, vertexStart: 0, vertexCount: 3)
    commandEncoder?.endEncoding()
    
    commandBuffer?.present(drawable)
    commandBuffer?.commit()
  }
  
  private func makeDevice() {
    device = MTLCreateSystemDefaultDevice()
    metalLayer.device = device
    metalLayer.pixelFormat = .bgra8Unorm
  }
  
  private func makeBuffers() {
    let vertices = [
      MBEVertex(position: float4(   0,  0.5, 0, 1), color: float4(1, 0, 0, 1)),
      MBEVertex(position: float4(-0.5, -0.5, 0, 1), color: float4(0, 1, 0, 1)),
      MBEVertex(position: float4( 0.5, -0.5, 0, 1), color: float4(0, 0, 1, 1)),
    ]
    vertexBuffer = device?.newBuffer(withBytes: vertices, length: sizeof(MBEVertex.self) * vertices.count, options: [])
  }
  
  private func makePipeline() {
    let library = device?.newDefaultLibrary()
    let vertexFunc = library?.newFunction(withName: "vertex_main")
    let fragmentFunc = library?.newFunction(withName: "fragment_main")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunc
    pipelineDescriptor.fragmentFunction = fragmentFunc
    pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
    
    do {
      pipeline = try device?.newRenderPipelineState(with: pipelineDescriptor)
    } catch let error as NSError {
      print("Error occurred when creating render pipeline state: \(error)")
    }
    
  }
}
