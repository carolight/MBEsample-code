//
//  MBEMathUtilities.swift
//  DrawingIn3D
//
//  Created by Caroline Begbie on 3/11/2015.
//  Copyright © 2015 Caroline Begbie. All rights reserved.
//

import Foundation
import simd

let π = Float(M_PI)

func matrix_float4x4_translation(t: float3) -> matrix_float4x4 {
  let X = vector_float4(1, 0, 0, 0)
  let Y = vector_float4(0, 1, 0, 0)
  let Z = vector_float4(0, 0, 1, 0)
  let W = vector_float4(t.x, t.y, t.z, 1)

  return matrix_float4x4(columns:(X, Y, Z, W))
}

func matrix_float4x4_uniform_scale(scale: Float) -> matrix_float4x4 {
  let X = vector_float4(scale, 0, 0, 0)
  let Y = vector_float4(0, scale, 0, 0)
  let Z = vector_float4(0, 0, scale, 0)
  let W = vector_float4(0, 0, 0, 1)
  return matrix_float4x4(columns:(X, Y, Z, W))
}

func matrix_float4x4_rotation(axis: vector_float3, angle: Float) -> matrix_float4x4 {
  let c = cos(angle)
  let s = sin(angle)
  
  var X = vector_float4(0, 0, 0, 0)
  X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c
  X.y = axis.x * axis.y * (1 - c) - axis.z * s
  X.z = axis.x * axis.z * (1 - c) + axis.y * s
  X.w = 0.0
  
  var Y = vector_float4(0, 0, 0, 0)
  Y.x = axis.x * axis.y * (1 - c) + axis.z * s
  Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c
  Y.z = axis.y * axis.z * (1 - c) - axis.x * s
  Y.w = 0.0
  
  var Z = vector_float4(0, 0, 0, 0)
  Z.x = axis.x * axis.z * (1 - c) - axis.y * s
  Z.y = axis.y * axis.z * (1 - c) + axis.x * s
  Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c
  Z.w = 0.0

  let W = vector_float4(0, 0, 0, 1)
  
  return matrix_float4x4(columns:(X, Y, Z, W))
}

func matrix_float4x4_perspective(aspect: Float, fovy: Float, near: Float, far: Float) -> matrix_float4x4 {
  
  let yScale = 1 / tan(fovy * 0.5)
  let xScale = yScale / aspect
  let zRange = far - near
  let zScale = -(far + near) / zRange
  let wzScale = -2 * far * near / zRange

  let P = vector_float4(xScale, 0, 0, 0)
  let Q = vector_float4(0, yScale, 0, 0)
  let R = vector_float4(0, 0, zScale, -1)
  let S = vector_float4(0, 0, wzScale, 0)

  return matrix_float4x4(columns:(P, Q, R, S))

}

