//
//  ARView.swift
//  LiDARDepth
//
//  Created by Farkhod on 11/18/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import SceneKit
import ARKit

struct ARView: UIViewRepresentable {
    var points: [SIMD3<Float>] = []
    @Binding var verticalDistance: Float
    @Binding var distanceBetweenPoints: Float?
    var manager:CameraManager
    @Binding var isTapped: Bool
    @Binding var showBallToast: Bool
    @Binding var showHoleCupToast: Bool
    var sceneView = ARSCNView()
    var spheres: [SCNNode] = []
    var tappedPoints: [SCNVector3] = []
    var lineNode: SCNNode?
    var curveNode: SCNNode?
    var planeNode: SCNNode?
    var baseLayer: CAGradientLayer?
    var circleView: UIImageView?
    var fx: Float
    var fy: Float
    var cx: Float
    var cy: Float

   
    
    func makeUIView(context: Context) -> ARSCNView {
        sceneView.delegate = context.coordinator
        sceneView.scene = SCNScene()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
            context.coordinator.updateDepthPoints(points)
        }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARView
        private var depthPointNodes: [SCNNode] = []
        
        private var isSessionInitialized = false
        private var feedbackCircles: [UIView] = []
        
        
        init(_ parent: ARView) {
            self.parent = parent
        }
        func updateDepthPoints(_ points: [SIMD3<Float>]) {
            guard let cameraTransform = parent.sceneView.session.currentFrame?.camera.transform else { return }
            
            let cameraPosition = SCNVector3(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            
            // Calculate distance of each point from the camera
            let sortedPoints = points
                .map { point -> (SIMD3<Float>, Float) in
                    let scnPoint = SCNVector3(point.x, point.y, point.z)
                    let distance = cameraPosition.distance(to: scnPoint)
                    return (point, distance)
                }
                .sorted(by: { $0.1 < $1.1 }) // Sort by distance
            
            // Take the closest 1000 points
            let closestPoints = sortedPoints.prefix(1000).map { $0.0 }
            
            // Remove existing depth point nodes
            for node in depthPointNodes {
                node.removeFromParentNode()
            }
            depthPointNodes.removeAll()
            
            // Add new depth point nodes
            for point in closestPoints {
                let position = SCNVector3(point.x, point.y, point.z)
                let node = createPointNode(at: position, color: .green)
                parent.sceneView.scene.rootNode.addChildNode(node)
                depthPointNodes.append(node)
            }
        }
        private func createPointNode(at position: SCNVector3, color: UIColor) -> SCNNode {
              let sphere = SCNSphere(radius: 0.0001) // Adjust size
              sphere.firstMaterial?.diffuse.contents = color

              let node = SCNNode(geometry: sphere)
              node.position = position

              return node
          }

        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let cameraTransform = frame.camera.transform
            let cameraPosition = cameraTransform.columns.3
            _ = cameraPosition.z
            
            
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            let location = sender.location(in: parent.sceneView)
            let hitTestResults = parent.sceneView.hitTest(location, types: [.featurePoint])
            
            guard let result = hitTestResults.last else { return }
            let transform = result.worldTransform
            parent.verticalDistance = transform.columns.3.z
            let position = SCNVector3(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )
            
            
            
            
            if !parent.isTapped {
                parent.isTapped = true
                parent.showBallToast = false
                parent.showHoleCupToast = true
            }
            
            if parent.tappedPoints.count == 2 {
                parent.clearPoints()  // Clear previous points and line
                clearFeedbackCircles()
                parent.baseLayer?.removeFromSuperlayer()
                parent.circleView?.removeFromSuperview()
                
            }
            
            parent.addPoint(position)
            showTap(at: CGPoint(x: CGFloat(parent.sceneView.projectPoint(position).x),
                                y: CGFloat(parent.sceneView.projectPoint(position).y)))
            
            if parent.tappedPoints.count == 2 {
                let distance = parent.tappedPoints[0].distance(to: parent.tappedPoints[1])
                parent.distanceBetweenPoints = distance
                parent.drawCurveBetweenPoints()
                parent.drawDensePointCloudWithDepth()

            }
        }
       
        func extractDepthMap(around point: CGPoint, in depthData: AVDepthData) {
            print("this is working1")
            
            // Ensure the depth map exists
            let depthMap = depthData.depthDataMap
            guard CFGetTypeID(depthMap) == CVPixelBufferGetTypeID() else {
                print("Invalid depth map type.")
                return
            }
            
            let pixelBuffer = depthMap as CVPixelBuffer
            
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
            
            let rowStride = CVPixelBufferGetBytesPerRow(pixelBuffer) / MemoryLayout<Float32>.size
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!.assumingMemoryBound(to: Float32.self)
            
            // Convert the 2D screen point to a 3D point in camera space
            let projectedPoint = parent.sceneView.unprojectPoint(SCNVector3(point.x, point.y, 0))
            
            // Map the unprojected point to the depth buffer's coordinates
            let depthX = Int(projectedPoint.x * Float(width))
            let depthY = Int(projectedPoint.y * Float(height))
            
            if depthX >= 0 && depthX < width && depthY >= 0 && depthY < height {
                let depthValue = baseAddress[depthY * rowStride + depthX]
                print("Depth value at tapped point: \(depthValue) meters")
                
                // Optional: Extract a region around the point
                let kernelSize = 5
                for row in (depthY - kernelSize)...(depthY + kernelSize) {
                    for col in (depthX - kernelSize)...(depthX + kernelSize) {
                        guard row >= 0, row < height, col >= 0, col < width else { continue }
                        let localDepthValue = baseAddress[row * rowStride + col]
                        print("Depth at (\(col), \(row)): \(localDepthValue)")
                    }
                }
            } else {
                print("Projected point out of depth map bounds.")
            }
        }

        
        private func showTap(at point: CGPoint) {
                   let feedbackCircle = UIView(frame: CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20))
                   feedbackCircle.backgroundColor = UIColor.red.withAlphaComponent(0.6)
                   feedbackCircle.layer.cornerRadius = 10
                   feedbackCircle.alpha = 1.0
                   parent.sceneView.addSubview(feedbackCircle)
                   
                   feedbackCircles.append(feedbackCircle)
               }
               
               private func clearFeedbackCircles() {
                   for circle in feedbackCircles {
                       circle.removeFromSuperview()
                   }
                   feedbackCircles.removeAll() // 배열 초기화
               }
        
    }
    
    mutating func drawCurveBetweenPoints() {
           guard tappedPoints.count == 2 else { return }
           
           let start3D = tappedPoints[0]
           let end3D = tappedPoints[1]
           
           // Convert 3D coordinates to 2D screen points
           let startScreenPoint = sceneView.projectPoint(start3D)
           let endScreenPoint = sceneView.projectPoint(end3D)
           
           print("startScreenPoint: \(startScreenPoint)")
           print("endScreenPoint: \(endScreenPoint)")
           
           guard !startScreenPoint.x.isNaN, !startScreenPoint.y.isNaN,
                 !endScreenPoint.x.isNaN, !endScreenPoint.y.isNaN else {
               print("Invalid screen points")
               return
           }
           
           let start = CGPoint(x: CGFloat(startScreenPoint.x), y: CGFloat(startScreenPoint.y))
           let end = CGPoint(x: CGFloat(endScreenPoint.x), y: CGFloat(endScreenPoint.y))
           
           print("start: \(start)")
           print("end: \(end)")
           // Draw the curve with animation
           drawCurve(from: start, to: end, color: UIColor.red)
       }
       
       private mutating func drawCurve(from start: CGPoint, to end: CGPoint, color: UIColor) {
           
           let midY = (start.y + end.y) / 2
           let controlPoint = CGPoint(x: (start.x + end.x) / 2, y: midY - 100)
           //let controlPoint = CGPoint(x: 20, y: midY)
           
           let path = UIBezierPath()
           path.move(to: start)
           path.addQuadCurve(to: end, controlPoint: controlPoint)
           
           // CAShapeLayer for the curve path
           let shapeLayer = CAShapeLayer()
           shapeLayer.path = path.cgPath
           shapeLayer.lineWidth = 15
           shapeLayer.strokeColor = UIColor.white.cgColor
           shapeLayer.fillColor = UIColor.clear.cgColor
           shapeLayer.strokeEnd = 0
           
           // CAGradientLayer for gradient
           let gradientLayer = CAGradientLayer()
           gradientLayer.frame = sceneView.bounds
           gradientLayer.colors = [
               color.withAlphaComponent(1.0).cgColor,
               color.withAlphaComponent(0.2).cgColor
           ]
           gradientLayer.startPoint = CGPoint(x: 0, y: 0.4)
           gradientLayer.endPoint = CGPoint(x: 0, y: 1.0)
           gradientLayer.mask = shapeLayer
           sceneView.layer.addSublayer(gradientLayer)
           
           animateRollingCircleAlongPath(path: path)
           animateCurve(layer: shapeLayer)
           baseLayer = gradientLayer
       }
       
       private func animateCurve(layer: CAShapeLayer) {
           let animation = CABasicAnimation(keyPath: "strokeEnd")
           animation.fromValue = 0
           animation.toValue = 1
           animation.duration = 1.5
           animation.fillMode = .forwards
           animation.isRemovedOnCompletion = false
           layer.add(animation, forKey: "lineAnimation")
       }
       
       private mutating func animateRollingCircleAlongPath(path: UIBezierPath) {
           let circle = UIImageView(image: UIImage(named: "ball2"))
           circle.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
           circle.layer.cornerRadius = 10
           circle.clipsToBounds = true
           circle.layer.shadowColor = UIColor.black.cgColor
           circle.layer.shadowOpacity = 0.5
           circle.layer.shadowOffset = CGSize(width: -3, height: -3)
           circle.layer.shadowRadius = 4
           circle.layer.zPosition = 1
           sceneView.addSubview(circle)
           
           let positionAnimation = CAKeyframeAnimation(keyPath: "position")
           positionAnimation.path = path.cgPath
           positionAnimation.duration = 1.5
           positionAnimation.rotationMode = .rotateAuto
           positionAnimation.fillMode = .forwards
           positionAnimation.isRemovedOnCompletion = false
           
           let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
           rotationAnimation.fromValue = 0
           rotationAnimation.toValue = Double.pi * 2
           rotationAnimation.duration = 1.5
           rotationAnimation.repeatCount = .infinity
           
           let animationGroup = CAAnimationGroup()
           animationGroup.animations = [positionAnimation, rotationAnimation]
           animationGroup.duration = 1.5
           animationGroup.fillMode = .forwards
           animationGroup.isRemovedOnCompletion = false
           
           circle.layer.add(animationGroup, forKey: "rollingCircleAnimation")
           
           circleView = circle
       }
    private mutating func clearPoints() {
        for sphere in spheres {
            sphere.removeFromParentNode()
        }
        spheres.removeAll()
        tappedPoints.removeAll()
        distanceBetweenPoints = nil
        lineNode?.removeFromParentNode()
        lineNode = nil
    }
    
    private mutating func addPoint(_ position: SCNVector3) {
        tappedPoints.append(position)
        
        let sphere = createSphere(at: position)
        sceneView.scene.rootNode.addChildNode(sphere)
        spheres.append(sphere)
    }
    
    private func createSphere(at position: SCNVector3) -> SCNNode {
        let sphere = SCNSphere(radius: 0.02)
        let node = SCNNode(geometry: sphere)
        node.position = position
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        sphere.firstMaterial = material
        
        return node
    }
    
    private mutating func drawLineBetweenPoints() {
        guard tappedPoints.count == 2 else { return }
        let start = tappedPoints[0]
        let end = tappedPoints[1]
        
        let cylinder = SCNCylinder(radius: 0.002, height: CGFloat(start.distance(to: end)))
        cylinder.firstMaterial?.diffuse.contents = UIColor.yellow
        
        let lineNode = SCNNode(geometry: cylinder)
        
        lineNode.position = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        lineNode.look(at: end, up: sceneView.scene.rootNode.worldUp, localFront: lineNode.worldUp)
        sceneView.scene.rootNode.addChildNode(lineNode)
        self.lineNode = lineNode
    }
    
    private mutating func drawDensePointCloudWithDepth() {
        
        guard tappedPoints.count == 2 else { return }
        guard let depthData = manager.capturedData.depth else {
            print("Depth data is unavailable")
            return
        }
        
        let start = tappedPoints[0]
        let end = tappedPoints[1]
        print("start: \(start), end: \(end)")
        // Calculate midpoint and directions
        let midPoint = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        let horizontalDirection = SCNVector3(
            end.x - start.x,
            end.y - start.y,
            end.z - start.z
        )
        let perpendicularDirection = SCNVector3(
            -horizontalDirection.z,
            horizontalDirection.y,
            horizontalDirection.x
        )
        let normalizedHorizontalDirection = normalize(vector: horizontalDirection)
        let normalizedPerpendicularDirection = normalize(vector: perpendicularDirection)

        let gridSize = 40
        let columnSize = 20
        let rowSpacing = Float(start.distance(to: end)) / Float(gridSize)
        let columnSpacing = rowSpacing

        for point in points {
                // Convert the SIMD3<Float> to SCNVector3
                let position = SCNVector3(point.x, point.y, point.z)
                
                // Create a small sphere node for each point
                let pointNode = createPoint(at: position, color: UIColor.green)
                sceneView.scene.rootNode.addChildNode(pointNode)
            }
        
        for row in 0..<gridSize {
            
            let colorRatio = Float(row) / Float(gridSize - 1)
            let color = UIColor(
                red: CGFloat(colorRatio),
                green: CGFloat(1 - colorRatio),
                blue: 0,
                alpha: 1
            )

            for column in 0..<columnSize {
                
                let x = midPoint.x + Float(row - gridSize / 2) * rowSpacing * normalizedHorizontalDirection.x
                let z = midPoint.z + Float(row - gridSize / 2) * rowSpacing * normalizedHorizontalDirection.z

                
                let position = SCNVector3(
                    x + Float(column - columnSize / 2) * columnSpacing * normalizedPerpendicularDirection.x,
                    0,
                    z + Float(column - columnSize / 2) * columnSpacing * normalizedPerpendicularDirection.z
                )
//
//                let adjustedPosition = SCNVector3(position.x, -0.055214845,position.z)
//                    
//                let pointNode = createPoint(at: adjustedPosition, color: color)
//                sceneView.scene.rootNode.addChildNode(pointNode)
//                spheres.append(pointNode)
            }
        }
    }

    private func createPoint(at position: SCNVector3, color: UIColor) -> SCNNode {
        let sphere = SCNSphere(radius: 0.003) // Adjust radius if needed
        sphere.firstMaterial?.diffuse.contents = color

        let pointNode = SCNNode(geometry: sphere)
        pointNode.position = position

        return pointNode
    }

    private func normalize(vector: SCNVector3) -> SCNVector3 {
        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        guard length > 0 else { return SCNVector3(0, 0, 0) }
        return SCNVector3(vector.x / length, vector.y / length, vector.z / length)
    }
    
}
