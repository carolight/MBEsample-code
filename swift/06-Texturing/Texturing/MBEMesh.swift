//
//  MBEMesh.swift
//  Lighting
//
//  Created by Caroline Begbie on 30/12/2015.
//  Copyright © 2015 Caroline Begbie. All rights reserved.
//

import Foundation
import MetalKit

class MBEMesh {
  let mesh: MTKMesh?
  var submeshes: [MBESubmesh] = []
  
  init(mesh: MTKMesh, mdlMesh: MDLMesh, device: MTLDevice) {
    self.mesh = mesh
    for i in 0 ..< mesh.submeshes.count {
      let submesh = MBESubmesh(submesh: mesh.submeshes[i], mdlSubmesh: mdlMesh.submeshes?[i] as! MDLSubmesh, device: device)
      submeshes.append(submesh)
    }
  }
  
  func renderWithEncoder(_ encoder:MTLRenderCommandEncoder) {
    
    guard let mesh = mesh else { return }
    for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
      encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, at: index)
    }
    for submesh in submeshes {
      submesh.renderWithEncoder(encoder)
    }
  }
}

class MBESubmesh {
  
  
  let submesh:MTKSubmesh?
  
  init(submesh:MTKSubmesh, mdlSubmesh:MDLSubmesh, device: MTLDevice) {
    self.submesh = submesh
  }
  
  func renderWithEncoder(_ encoder:MTLRenderCommandEncoder) {
    guard let submesh = submesh else { return }
    encoder.drawIndexedPrimitives(submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
  }
}
