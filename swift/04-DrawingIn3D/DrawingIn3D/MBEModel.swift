//
//  MBEModel.swift
//  DrawingIn3D
//
//  Created by Caroline Begbie on 3/11/2015.
//  Copyright © 2015 Caroline Begbie. All rights reserved.
//

import Foundation
import MetalKit

struct MBEVertex {
  var position: float4
  var color: float4
}

typealias MBEIndex = UInt16
let MBEIndexType:MTLIndexType = .UInt16

struct MBEUniforms {
  var modelViewProjectionMatrix: matrix_float4x4
}

let vertices = [
  MBEVertex(position: float4( -1,  1, 1, 1), color: float4(0, 1, 1, 1)),
  MBEVertex(position: float4( -1, -1, 1, 1), color: float4(0, 0, 1, 1)),
  MBEVertex(position: float4(  1, -1, 1, 1), color: float4(1, 0, 1, 1)),
  MBEVertex(position: float4(  1,  1, 1, 1), color: float4(1, 1, 1, 1)),
  MBEVertex(position: float4( -1,  1,-1, 1), color: float4(0, 1, 0, 1)),
  MBEVertex(position: float4( -1, -1,-1, 1), color: float4(0, 0, 0, 1)),
  MBEVertex(position: float4(  1, -1,-1, 1), color: float4(1, 0, 0, 1)),
  MBEVertex(position: float4(  1,  1,-1, 1), color: float4(1, 1, 0, 1)),
]


let indices: [MBEIndex] = [
  3, 2, 6, 6, 7, 3,
  4, 5, 1, 1, 0, 4,
  4, 0, 3, 3, 7, 4,
  1, 5, 6, 6, 2, 1,
  0, 1, 2, 2, 3, 0,
  7, 6, 5, 5, 4, 7,
]
