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

  var time: TimeInterval = 0
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
    vertexBuffer = device?.newBuffer(withBytes: vertices, length: sizeof(MBEVertex.self) * vertices.count, options: [])
    vertexBuffer?.label = "Vertices"
    indexBuffer = device?.newBuffer(withBytes: indices, length: sizeof(MBEIndex.self) * indices.count, options: [])
    indexBuffer?.label = "Indices"
    uniformBuffer = device?.newBuffer(withLength: sizeof(MBEUniforms.self), options: [])
    uniformBuffer?.label = "Uniforms"
  }
  
  private func makePipeline() {
    
    let library = device?.newDefaultLibrary()
    let vertexFunc = library?.newFunction(withName: "vertex_project")
    let fragmentFunc = library?.newFunction(withName: "fragment_flatColor")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunc
    pipelineDescriptor.fragmentFunction = fragmentFunc
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    
    let depthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStencilDescriptor.depthCompareFunction = .less
    depthStencilDescriptor.isDepthWriteEnabled = true
    depthStencilState = device?.newDepthStencilState(with: depthStencilDescriptor)
    
    do {
      pipeline = try device?.newRenderPipelineState(with: pipelineDescriptor)
    } catch let error as NSError {
      print("Error occurred when creating render pipeline state: \(error)")
    }
    commandQueue = device?.newCommandQueue()
  }
  
  private func updateUniformsForView(view: MBEMetalView, duration: TimeInterval) {
    
    time += duration
    rotationX += Float(duration) * (π / 2)
    rotationY += Float(duration) * (π / 3)
    let scaleFactor = sinf(5.0 * Float(time)) * 0.25 + 1
    let xAxis = float3(1, 0, 0)
    let yAxis = float3(0, 1, 0)
    let xRotation = matrix_float4x4_rotation(axis: xAxis, angle: rotationX)
    let yRotation = matrix_float4x4_rotation(axis: yAxis, angle: rotationY)
    let scale = matrix_float4x4_uniform_scale(scale: scaleFactor)
    let modelMatrix = matrix_multiply(matrix_multiply(xRotation, yRotation), scale)
    
    let cameraTranslation = vector_float3(0, 0, -5)
    let viewMatrix = matrix_float4x4_translation(t: cameraTranslation)
    
    let drawableSize = view.metalLayer.drawableSize
    let aspect: Float = Float(drawableSize.width / drawableSize.height)
    let fov: Float = Float((2 * π) / 5)
    let near: Float = 1
    let far: Float = 100
    let projectionMatrix = matrix_float4x4_perspective(aspect: aspect, fovy: fov, near: near, far: far)

    let modelViewProjectionMatrix = matrix_multiply(projectionMatrix, matrix_multiply(viewMatrix, modelMatrix))
    var uniforms: MBEUniforms = MBEUniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
    
    let uniformBufferOffset = sizeof(MBEUniforms.self) * bufferIndex
    memcpy(uniformBuffer!.contents() + uniformBufferOffset, &uniforms, sizeof(MBEUniforms.self))
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

    updateUniformsForView(view: view, duration: frameDuration)
    
    // Setup texture
    let framebufferTexture = drawable.texture
    
    // Setup render passes
    let passDescriptor = view.currentRenderPassDescriptor
    let colorAttachment = passDescriptor.colorAttachments[0]
    colorAttachment?.texture = framebufferTexture
    colorAttachment?.loadAction = .clear
    colorAttachment?.storeAction = .store
    colorAttachment?.clearColor = MTLClearColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    
    
    // Start render pass
    let commandEncoder = commandBuffer.renderCommandEncoder(with: passDescriptor)
    commandEncoder.setRenderPipelineState(pipeline)
    commandEncoder.setDepthStencilState(depthStencilState)
    commandEncoder.setFrontFacing(.counterClockwise)
    commandEncoder.setCullMode(.back)
    

    // Set up buffers
    let uniformBufferOffset = sizeof(MBEUniforms.self) * bufferIndex

    commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
    commandEncoder.setVertexBuffer(uniformBuffer, offset: uniformBufferOffset, at: 1)

    commandEncoder.drawIndexedPrimitives(.triangle, indexCount: indexBuffer!.length / sizeof(MBEIndex.self), indexType: MBEIndexType, indexBuffer: indexBuffer!, indexBufferOffset: 0)
    
    commandEncoder.endEncoding()

    commandBuffer.present(drawable)
    commandBuffer.commit()

  }
}
