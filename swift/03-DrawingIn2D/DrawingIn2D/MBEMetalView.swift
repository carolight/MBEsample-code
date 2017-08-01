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

  var commandQueue: MTLCommandQueue!
  
  required init(coder: NSCoder) {
    super.init(coder: coder)
    device = MTLCreateSystemDefaultDevice()
    colorPixelFormat = .bgra8Unorm
    commandQueue = device?.makeCommandQueue()
    clearColor = MTLClearColor(red: 1, green: 0, blue: 0, alpha: 1)
  }
  
  override func draw(_ rect: CGRect) {
    guard let drawable = currentDrawable,
    let renderPassDescriptor = currentRenderPassDescriptor
    else { return }
    
    let commandBuffer = commandQueue.makeCommandBuffer()
    let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    commandEncoder?.endEncoding()
    
    commandBuffer?.present(drawable)
    commandBuffer?.commit()
  }
}

