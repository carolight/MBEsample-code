//
//  MBERenderer.swift
//  Lighting
//
//  Created by Caroline Begbie on 1/01/2016.
//  Copyright © 2016 Caroline Begbie. All rights reserved.
//

import MetalKit

struct MBEUniforms {
  var modelViewProjectionMatrix: matrix_float4x4
  var modelViewMatrix: matrix_float4x4
  var normalMatrix: matrix_float3x3
}

class MBERenderer: NSObject {

  weak var device: MTLDevice?
  var uniformBuffer: MTLBuffer?

  var pipeline: MTLRenderPipelineState?
  var depthStencilState: MTLDepthStencilState?
  var commandQueue: MTLCommandQueue?
  
  var meshes = [MBEMesh]()

  var rotationX: Float = 0
  var rotationY: Float = 0

  init(device: MTLDevice?) {
    self.device = device
    super.init()
    makeUniformBuffer()
    makePipeline()
    loadModel(modelName: "teapot")
  }
  
  private func makeUniformBuffer() {
    uniformBuffer = device?.newBuffer(withLength: sizeof(MBEUniforms.self), options: [])
    uniformBuffer?.label = "Uniforms"
  }
  
  private func makePipeline() {
    let library = device?.newDefaultLibrary()
    let vertexFunc = library?.newFunction(withName: "vertex_project")
    let fragmentFunc = library?.newFunction(withName: "fragment_light")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunc
    pipelineDescriptor.fragmentFunction = fragmentFunc
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    pipelineDescriptor.depthAttachmentPixelFormat = .invalid
    
    let depthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStencilDescriptor.depthCompareFunction = .less
    depthStencilDescriptor.isDepthWriteEnabled = true
    depthStencilState = device?.newDepthStencilState(with: depthStencilDescriptor)
    
    do {
      pipeline = try device?.newRenderPipelineState(with: pipelineDescriptor)
    } catch let error as NSError {
      print("Error creating render pipeline state: \(error)")
    }
    commandQueue = device?.newCommandQueue()
  }
  
  private func loadModel(modelName:String) {
    assert(device != nil, "No device available")
    guard let device = device else {
      return
    }
    guard let assetURL = Bundle.main.urlForResource(modelName, withExtension: "obj") else {
      print("Asset \(modelName) does not exist.")
      return
    }

    
    // See Apple Sample Code MetalKitEssentials
    
    /*
    Create a vertex descriptor for pipeline. Specifies the layout
    of vertices the pipeline should expect.
    This must match the shader definitions.
    */
    
    let mtlVertexDescriptor = MTLVertexDescriptor()
    
    // Positions
    mtlVertexDescriptor.attributes[0].format = .float4
    mtlVertexDescriptor.attributes[0].offset = 0
    mtlVertexDescriptor.attributes[0].bufferIndex = 0
    
    // Normals
    mtlVertexDescriptor.attributes[1].format = .float4
    mtlVertexDescriptor.attributes[1].offset = 16
    mtlVertexDescriptor.attributes[1].bufferIndex = 0
    
    mtlVertexDescriptor.layouts[0].stride = 32
    mtlVertexDescriptor.layouts[0].stepRate = 1
    mtlVertexDescriptor.layouts[0].stepFunction = .perVertex
    
    /*
    Create a Model I/O vertex descriptor. This specifies the layout
    of vertices Model I/O should format loaded meshes with.
    */
    
    let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor)
    
    let attributePosition = mdlVertexDescriptor.attributes[0] as! MDLVertexAttribute
    attributePosition.name = MDLVertexAttributePosition
    mdlVertexDescriptor.attributes[0] = attributePosition
    
    let attributeNormal = mdlVertexDescriptor.attributes[1] as! MDLVertexAttribute
    attributeNormal.name = MDLVertexAttributeNormal
    mdlVertexDescriptor.attributes[1] = attributeNormal
    
    let bufferAllocator = MTKMeshBufferAllocator(device: device)
    
    /*
    Load Model I/O Asset with mdlVertexDescriptor, specifying vertex layout and
    bufferAllocator enabling ModelIO to load vertex and index buffers directory
    into Metal GPU memory.
    */
    
    let asset = MDLAsset(url: assetURL, vertexDescriptor: mdlVertexDescriptor, bufferAllocator: bufferAllocator)
    
    let mtkMeshes:[MTKMesh]?
    var mdlMeshes:NSArray?
    
    do {
      mtkMeshes = try MTKMesh.newMeshes(from: asset, device: device, sourceMeshes: &mdlMeshes)
    } catch {
      print("error creating mesh")
      return
    }
    
    if let mdlMeshes = mdlMeshes as? [MDLMesh],
      let mtkMeshes = mtkMeshes
    {
      meshes = []
      
      for (index, mtkMesh) in mtkMeshes.enumerated() {
        let mesh = MBEMesh(mesh: mtkMesh, mdlMesh: mdlMeshes[index], device: device)
        meshes.append(mesh)
      }
    }
  }
}

extension MBERenderer: MTKViewDelegate {

  private func updateUniformsForView(view: MTKView, duration: TimeInterval) {
    guard let uniformBuffer = uniformBuffer else {
      print("uniformBuffer not created")
      return
    }
    
    rotationX += Float(duration) * (π / 2)
    rotationY += Float(duration) * (π / 3)
    let scaleFactor:Float = 1
    let xAxis = float3(1, 0, 0)
    let yAxis = float3(0, 1, 0)
    let xRotation = matrix_float4x4_rotation(axis: xAxis, angle: rotationX)
    let yRotation = matrix_float4x4_rotation(axis: yAxis, angle: rotationY)
    let scale = matrix_float4x4_uniform_scale(scale: scaleFactor)
    let modelMatrix = matrix_multiply(matrix_multiply(xRotation, yRotation), scale)
    
    let cameraTranslation = vector_float3(0, 0, -1.5)
    let viewMatrix = matrix_float4x4_translation(t: cameraTranslation)
    
    let drawableSize = view.drawableSize
    let aspect: Float = Float(drawableSize.width / drawableSize.height)
    let fov: Float = Float((2 * π) / 5)
    let near: Float = 0.1
    let far: Float = 100
    let projectionMatrix = matrix_float4x4_perspective(aspect: aspect, fovy: fov, near: near, far: far)
    
    // update uniform data with current viewing and model matrices
    let uniformPointer = UnsafeMutablePointer<MBEUniforms>(uniformBuffer.contents())
    var uniformData = uniformPointer.pointee
    
    uniformData.modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);
    uniformData.modelViewProjectionMatrix = matrix_multiply(projectionMatrix, uniformData.modelViewMatrix);
    uniformData.normalMatrix = matrix_float4x4_extract_linear(m: uniformData.modelViewMatrix);
    uniformPointer.pointee = uniformData
  }

  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable else {
      print("drawable not set")
      return
    }
    guard let pipeline = pipeline else {
      print("pipeline not set")
      return
    }
    guard let commandBuffer = commandQueue?.commandBuffer() else  {
      print("command buffer not set")
      return
    }
    
    view.clearColor = MTLClearColor(red: 0.85, green: 0.85, blue: 085, alpha: 1)
    
    let frameDuration:TimeInterval = 0.02
    updateUniformsForView(view: view, duration: frameDuration)
    
    // Setup render passes - do calculations before allocating this
    guard let descriptor = view.currentRenderPassDescriptor else {
      print("no render pass descriptor")
      return
    }
    
    // Start render pass
    let commandEncoder = commandBuffer.renderCommandEncoder(with: descriptor)
    commandEncoder.setRenderPipelineState(pipeline)
    commandEncoder.setDepthStencilState(depthStencilState)
    
    
    // Set up uniform buffer
    commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
    
    for mesh in meshes {
      mesh.renderWithEncoder(encoder: commandEncoder)
    }
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
  }

}
