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
    loadModel("teapot")
  }
  
  private func makeUniformBuffer() {
    uniformBuffer = device?.newBufferWithLength(sizeof(MBEUniforms), options: .CPUCacheModeDefaultCache)
    uniformBuffer?.label = "Uniforms"
  }
  
  private func makePipeline() {
    let library = device?.newDefaultLibrary()
    let vertexFunc = library?.newFunctionWithName("vertex_project")
    let fragmentFunc = library?.newFunctionWithName("fragment_light")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunc
    pipelineDescriptor.fragmentFunction = fragmentFunc
    pipelineDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
    pipelineDescriptor.depthAttachmentPixelFormat = .Depth32Float
    pipelineDescriptor.depthAttachmentPixelFormat = .Invalid
    
    let depthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStencilDescriptor.depthCompareFunction = .Less
    depthStencilDescriptor.depthWriteEnabled = true
    depthStencilState = device?.newDepthStencilStateWithDescriptor(depthStencilDescriptor)
    
    do {
      pipeline = try device?.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
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
    guard let assetURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "obj") else {
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
    mtlVertexDescriptor.attributes[0].format = .Float4
    mtlVertexDescriptor.attributes[0].offset = 0
    mtlVertexDescriptor.attributes[0].bufferIndex = 0
    
    // Normals
    mtlVertexDescriptor.attributes[1].format = .Float4
    mtlVertexDescriptor.attributes[1].offset = 16
    mtlVertexDescriptor.attributes[1].bufferIndex = 0
    
    mtlVertexDescriptor.layouts[0].stride = 32
    mtlVertexDescriptor.layouts[0].stepRate = 1
    mtlVertexDescriptor.layouts[0].stepFunction = .PerVertex
    
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
    
    let asset = MDLAsset(URL: assetURL, vertexDescriptor: mdlVertexDescriptor, bufferAllocator: bufferAllocator)
    
    let mtkMeshes:[MTKMesh]?
    var mdlMeshes:NSArray?
    
    do {
      mtkMeshes = try MTKMesh.newMeshesFromAsset(asset, device: device, sourceMeshes: &mdlMeshes)
    } catch {
      print("error creating mesh")
      return
    }
    
    if let mdlMeshes = mdlMeshes as? [MDLMesh],
      let mtkMeshes = mtkMeshes
    {
      meshes = []
      
      for (index, mtkMesh) in mtkMeshes.enumerate() {
        let mesh = MBEMesh(mesh: mtkMesh, mdlMesh: mdlMeshes[index], device: device)
        meshes.append(mesh)
      }
    }
  }
}

extension MBERenderer: MTKViewDelegate {

  private func updateUniformsForView(view: MTKView, duration: NSTimeInterval) {
    guard let uniformBuffer = uniformBuffer else {
      print("uniformBuffer not created")
      return
    }
    
    rotationX += Float(duration) * (π / 2)
    rotationY += Float(duration) * (π / 3)
    let scaleFactor:Float = 1
    let xAxis = float3(1, 0, 0)
    let yAxis = float3(0, 1, 0)
    let xRotation = matrix_float4x4_rotation(xAxis, angle: rotationX)
    let yRotation = matrix_float4x4_rotation(yAxis, angle: rotationY)
    let scale = matrix_float4x4_uniform_scale(scaleFactor)
    let modelMatrix = matrix_multiply(matrix_multiply(xRotation, yRotation), scale)
    
    let cameraTranslation = vector_float3(0, 0, -1.5)
    let viewMatrix = matrix_float4x4_translation(cameraTranslation)
    
    let drawableSize = view.drawableSize
    let aspect: Float = Float(drawableSize.width / drawableSize.height)
    let fov: Float = Float((2 * π) / 5)
    let near: Float = 0.1
    let far: Float = 100
    let projectionMatrix = matrix_float4x4_perspective(aspect, fovy: fov, near: near, far: far)
    
    // update uniform data with current viewing and model matrices
    let uniformPointer = UnsafeMutablePointer<MBEUniforms>(uniformBuffer.contents())
    var uniformData = uniformPointer.memory
    uniformData.modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);
    uniformData.modelViewProjectionMatrix = matrix_multiply(projectionMatrix, uniformData.modelViewMatrix);
    uniformData.normalMatrix = matrix_float4x4_extract_linear(uniformData.modelViewMatrix);
    uniformPointer.memory = uniformData
  }

  func drawInMTKView(view: MTKView) {
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
    
    let frameDuration:NSTimeInterval = 0.02
    updateUniformsForView(view, duration: frameDuration)
    
    // Setup render passes - do calculations before allocating this
    guard let descriptor = view.currentRenderPassDescriptor else {
      print("no render pass descriptor")
      return
    }
    
    // Start render pass
    let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(descriptor)
    commandEncoder.setRenderPipelineState(pipeline)
    commandEncoder.setDepthStencilState(depthStencilState)
    
    
    // Set up uniform buffer
    commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, atIndex: 1)
    
    for mesh in meshes {
      mesh.renderWithEncoder(commandEncoder)
    }
    commandEncoder.endEncoding()
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()
  }

  func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
  }

}
