//
//  MBERenderer.swift
//  DrawingIn3D
//
//  Created by Caroline Begbie on 3/11/2015.
//  Copyright © 2015 Caroline Begbie. All rights reserved.
//

import Foundation
import MetalKit
import simd

class MBERenderer {

  var device: MTLDevice?

  var vertexBuffer: MTLBuffer?
  var indexBuffer: MTLBuffer?
  var uniformBuffer: MTLBuffer?


  var pipeline: MTLRenderPipelineState?
  var depthStencilState: MTLDepthStencilState?
  var bufferIndex:Int = 0
  var commandQueue: MTLCommandQueue?

  var time: NSTimeInterval = 0
  var rotationX: Float = 0
  var rotationY: Float = 0
  
  
  
  init() {
    makeDevice()
    makeBuffers()
    makePipeline()
  }
  
  private func makeDevice() {
    device = MTLCreateSystemDefaultDevice()
  }
  
  private func makeBuffers() {
    vertexBuffer = device?.newBufferWithBytes(vertices, length: sizeof(MBEVertex) * vertices.count, options: .CPUCacheModeDefaultCache)
    vertexBuffer?.label = "Vertices"
    indexBuffer = device?.newBufferWithBytes(indices, length: sizeof(MBEIndex) * indices.count, options: .CPUCacheModeDefaultCache)
    indexBuffer?.label = "Indices"
    uniformBuffer = device?.newBufferWithLength(sizeof(MBEUniforms), options: .CPUCacheModeDefaultCache)
    uniformBuffer?.label = "Uniforms"
  }
  
  private func makePipeline() {
    
    let library = device?.newDefaultLibrary()
    let vertexFunc = library?.newFunctionWithName("vertex_project")
    let fragmentFunc = library?.newFunctionWithName("fragment_flatColor")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunc
    pipelineDescriptor.fragmentFunction = fragmentFunc
    pipelineDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
    pipelineDescriptor.depthAttachmentPixelFormat = .Depth32Float
    
    let depthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStencilDescriptor.depthCompareFunction = .Less
    depthStencilDescriptor.depthWriteEnabled = true
    depthStencilState = device?.newDepthStencilStateWithDescriptor(depthStencilDescriptor)
    
    do {
      pipeline = try device?.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
    } catch let error as NSError {
      print("Error occurred when creating render pipeline state: \(error)")
    }
    commandQueue = device?.newCommandQueue()
  }
  
  private func updateUniformsForView(view: MBEMetalView, duration: NSTimeInterval) {
    
    time += duration
    rotationX += Float(duration) * (π / 2)
    rotationY += Float(duration) * (π / 3)
    let scaleFactor = sinf(5.0 * Float(time)) * 0.25 + 1
    let xAxis = float3(1, 0, 0)
    let yAxis = float3(0, 1, 0)
    let xRotation = matrix_float4x4_rotation(xAxis, angle: rotationX)
    let yRotation = matrix_float4x4_rotation(yAxis, angle: rotationY)
    let scale = matrix_float4x4_uniform_scale(scaleFactor)
    let modelMatrix = matrix_multiply(matrix_multiply(xRotation, yRotation), scale)
    
    let cameraTranslation = vector_float3(0, 0, -5)
    let viewMatrix = matrix_float4x4_translation(cameraTranslation)
    
    let drawableSize = view.metalLayer.drawableSize
    let aspect: Float = Float(drawableSize.width / drawableSize.height)
    let fov: Float = Float((2 * π) / 5)
    let near: Float = 1
    let far: Float = 100
    let projectionMatrix = matrix_float4x4_perspective(aspect, fovy: fov, near: near, far: far)

    let modelViewProjectionMatrix = matrix_multiply(projectionMatrix, matrix_multiply(viewMatrix, modelMatrix))
    var uniforms: MBEUniforms = MBEUniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
    
    let uniformBufferOffset = sizeof(MBEUniforms) * bufferIndex
    memcpy(uniformBuffer!.contents() + uniformBufferOffset, &uniforms, sizeof(MBEUniforms))
  }
}

extension MBERenderer: MBEMetalViewDelegate {
  
  func drawInView(view: MBEMetalView) {
    // Setup drawable
    guard let drawable = view.currentDrawable else {
      print("drawable not set")
      return
    }

    guard let frameDuration = view.frameDuration else {
      print("frameDuration not set")
      return
    }
    
    guard let pipeline = pipeline else {
      print("pipeline not set")
      return
    }
    
    // Setup command buffer
    guard let commandBuffer = commandQueue?.commandBuffer() else  {
      print("command buffer not set")
      return
    }

    view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)

    updateUniformsForView(view, duration: frameDuration)
    
    // Setup texture
    let framebufferTexture = drawable.texture
    
    // Setup render passes
    let passDescriptor = view.currentRenderPassDescriptor
    let colorAttachment = passDescriptor.colorAttachments[0]
    colorAttachment.texture = framebufferTexture
    colorAttachment.loadAction = .Clear
    colorAttachment.storeAction = .Store
    colorAttachment.clearColor = MTLClearColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    
    
    // Start render pass
    let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(passDescriptor)
    commandEncoder.setRenderPipelineState(pipeline)
    commandEncoder.setDepthStencilState(depthStencilState)
    commandEncoder.setFrontFacingWinding(.CounterClockwise)
    commandEncoder.setCullMode(.Back)
    

    // Set up buffers
    let uniformBufferOffset = sizeof(MBEUniforms) * bufferIndex

    commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
    commandEncoder.setVertexBuffer(uniformBuffer, offset: uniformBufferOffset, atIndex: 1)

    commandEncoder.drawIndexedPrimitives(.Triangle, indexCount: indexBuffer!.length / sizeof(MBEIndex), indexType: MBEIndexType, indexBuffer: indexBuffer!, indexBufferOffset: 0)
    
    commandEncoder.endEncoding()

    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()

  }
}