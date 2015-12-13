//
//  Shaders.metal
//  DrawingIn3D
//
//  Created by Caroline Begbie on 3/11/2015.
//  Copyright © 2015 Caroline Begbie. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
  float4 position [[position]];
  float4 color;
};

struct Uniforms {
  float4x4 modelViewProjectionMatrix;
};

vertex Vertex vertex_main(device Vertex *vertices [[buffer(0)]],
                          uint vid [[vertex_id]]) {
  return vertices[vid];
}

fragment float4 fragment_main(Vertex inVertex [[stage_in]]) {
  return inVertex.color;
}

vertex Vertex vertex_project(device Vertex *vertices [[buffer(0)]],
                             constant Uniforms *uniforms [[buffer(1)]],
                             uint vid [[vertex_id]]) {
  Vertex vertexOut;
  vertexOut.position = uniforms->modelViewProjectionMatrix *vertices[vid].position;
  vertexOut.color = vertices[vid].color;
  
  return vertexOut;
}

fragment half4 fragment_flatColor(Vertex vertexIn [[stage_in]]) {
  return half4(vertexIn.color);
}
