//
/**
 *
 * Swift 4 code sample derived from the book Metal by Example by Warren Moore
 *  http://metalbyexample.com/
 *
 * Forked from https://github.com/metal-by-example/sample-code
 *
 *  Created by Caroline Begbie on 1/8/17
 *
 */

import MetalKit


class MBEMetalView: MTKView {

  required init(coder: NSCoder) {
    super.init(coder: coder)
    device = MTLCreateSystemDefaultDevice()
    colorPixelFormat = .bgra8Unorm
  }
  
  override func didMoveToWindow() {
    redraw()
  }
  
  private func redraw() {
    guard let drawable = currentDrawable else { return }
    
    let passDescriptor = MTLRenderPassDescriptor()
    passDescriptor.colorAttachments[0].texture = drawable.texture
    passDescriptor.colorAttachments[0].loadAction = .clear
    passDescriptor.colorAttachments[0].storeAction = .store
    passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 0, blue: 0, alpha: 1)
    
    let commandQueue = device?.makeCommandQueue()
    let commandBuffer = commandQueue?.makeCommandBuffer()
    
    let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor)
    commandEncoder?.endEncoding()
    
    commandBuffer?.present(drawable)
    commandBuffer?.commit()
  }
}
