//
//  ViewController.swift
//  Texturing
//
//  Created by Caroline Begbie on 2/01/2016.
//  Copyright © 2016 Caroline Begbie. All rights reserved.
//

import MetalKit
import AudioToolbox


class ViewController: UIViewController {

  let kVelocityScale:CGFloat = 0.01
  let kRotationDamping:CGFloat = 0.05
  let kMooSpinThreshold:CGFloat = 30
  let kMooDuration:CFAbsoluteTime = 3
  
  var metalView:MTKView {
    return view as! MTKView
  }
  
  var renderer: MBERenderer?
  
  var mooSound: SystemSoundID = 0
  var lastMooTime:CFAbsoluteTime = 0
  var angularVelocity:CGPoint = .zero
  var angle:CGPoint = .zero
  
  override func viewDidLoad() {
    super.viewDidLoad()
    metalView.device = MTLCreateSystemDefaultDevice()
    renderer = MBERenderer(device: metalView.device)
    metalView.delegate = self
    
    let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(ViewController.gestureDidRecognize(_:)))
    metalView.addGestureRecognizer(panGesture)
    loadResources()
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  
  private func loadResources() {
    if let mooURL = Bundle.main.url(forResource: "moo", withExtension: "aiff") {
      let result = AudioServicesCreateSystemSoundID(mooURL, &mooSound)
      if result != noErr {
        print("Error when loading sound effect. Error code: \(result)")
      }
    } else {
      print("Could not find sound effect file in main bundle")
    }
  }
  
  func gestureDidRecognize(_ gesture: UIPanGestureRecognizer) {
    let velocity = gesture.velocity(in: view)
    angularVelocity = CGPoint(x:velocity.x * kVelocityScale,
                              y:velocity.y * kVelocityScale)
  }
}

extension ViewController: MTKViewDelegate {
  
  private func updateMotionWithTimestep(_ duration:CGFloat) {
    if duration > 0 {
      // Update the rotation angles according to the current velocity and time step
      
      angle = CGPoint(x: angle.x + angularVelocity.x * duration,
                      y: angle.y + angularVelocity.y * duration)

      // Apply damping by removing some proportion of the angular velocity each frame
      angularVelocity = CGPoint(x: angularVelocity.x * (1 - kRotationDamping),
                                y: angularVelocity.y * (1 - kRotationDamping))
      
      let spinSpeed = hypot(angularVelocity.x, angularVelocity.y)
      
      // If we're spinning fast and haven't mooed in a while, trigger the moo sound effect
      let frameTime = CFAbsoluteTimeGetCurrent()
      if spinSpeed > kMooSpinThreshold && frameTime > (lastMooTime + kMooDuration) {
        AudioServicesPlaySystemSound(mooSound)
        lastMooTime = frameTime
      }
    }
  }

  func draw(in view: MTKView) {
    updateMotionWithTimestep(1.0 / CGFloat(view.preferredFramesPerSecond))
    
    renderer?.rotationX = Float(-angle.y)
    renderer?.rotationY = Float(-angle.x)
    renderer?.draw(in: view)
    
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
  }
  
}
