import CoreFoundation
import ARKit
import SwiftUI
import SceneKit
import MetalKit

struct ARViewWithDepth: UIViewRepresentable {
    @Binding var verticalDistance: Float
    @Binding var distanceBetweenPoints: Float?
    @Binding var maxDepth: Float
    @Binding var minDepth: Float
    @Binding var tapLocation1: CGPoint?
    @Binding var tapLocation2: CGPoint?
    @Binding var distanceToPoint1: Float?
    @Binding var distanceToPoint2: Float?
    
    var manager: CameraManager
    var fx: Float
    var fy: Float
    var cx: Float
    var cy: Float
    
    private let sceneView = ARSCNView()
    private let metalView = MTKView()
    
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        
        // Configure ARSCNView
        sceneView.delegate = context.coordinator
        sceneView.scene = SCNScene()
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
        container.addSubview(sceneView)
        
        // Configure MTKView
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.framebufferOnly = false
        metalView.delegate = context.coordinator
        metalView.contentMode = .scaleAspectFit
        container.addSubview(metalView)
        
        // Layout ARSCNView and MTKView
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        metalView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: container.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            metalView.topAnchor.constraint(equalTo: container.topAnchor),
            metalView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            metalView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, metalDevice: metalView.device)
    }

    class Coordinator: NSObject, ARSCNViewDelegate, MTKViewDelegate {
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
                    }
        
        var parent: ARViewWithDepth
        var depthPipelineState: MTLRenderPipelineState?
        var depthState: MTLDepthStencilState?
        var spheres: [SCNNode] = []
        var tappedPoints: [SCNVector3] = []
        var lineNode: SCNNode?
        
        init(_ parent: ARViewWithDepth, metalDevice: MTLDevice?) {
            self.parent = parent
            super.init()
            
            guard let device = metalDevice else {
                print("Metal device is nil.")
                return
            }
            
            setupMetalPipeline(device: device)
            if depthPipelineState == nil {
                print("Failed to initialize depthPipelineState.")
            }
        }
        
        
        private func setupMetalPipeline(device: MTLDevice) {
            do {
                let library = try device.makeDefaultLibrary()
                
                // Create pipeline descriptor
                let pipelineDescriptor = MTLRenderPipelineDescriptor()
                pipelineDescriptor.vertexFunction = library?.makeFunction(name: "planeVertexShader")
                pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "planeFragmentShaderColorThresholdDepth")
                pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
                pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
                
                // Initialize pipeline state
                depthPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                
                // Depth state descriptor
                let depthDescriptor = MTLDepthStencilDescriptor()
                depthDescriptor.isDepthWriteEnabled = true
                depthDescriptor.depthCompareFunction = .less
                depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
                
                print("Metal pipeline successfully initialized.")
            } catch {
                print("Failed to setup Metal pipeline: \(error)")
            }
        }
        
        
        // MARK: - ARSCNViewDelegate Methods
        func session(_ session: ARSession, didUpdate frame: ARFrame) {}
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            let location = sender.location(in: parent.sceneView)
            let hitTestResults = parent.sceneView.hitTest(location, types: [.featurePoint])
            guard let result = hitTestResults.last else { return }
            let transform = result.worldTransform
            parent.verticalDistance = transform.columns.3.z
            
            let position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            if tappedPoints.count == 2 {
                clearPoints()
            }
            addPoint(position)
            
            if tappedPoints.count == 2 {
                let distance = tappedPoints[0].distance(to: tappedPoints[1])
                parent.distanceBetweenPoints = distance
                drawLineBetweenPoints()
            }
        }
        
        func addPoint(_ position: SCNVector3) {
            tappedPoints.append(position)
            let sphere = createSphere(at: position)
            parent.sceneView.scene.rootNode.addChildNode(sphere)
            spheres.append(sphere)
        }
        
        func clearPoints() {
            for sphere in spheres {
                sphere.removeFromParentNode()
            }
            spheres.removeAll()
            tappedPoints.removeAll()
            parent.distanceBetweenPoints = nil
            lineNode?.removeFromParentNode()
            lineNode = nil
        }
        
        func drawLineBetweenPoints() {
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
            lineNode.look(at: end, up: parent.sceneView.scene.rootNode.worldUp, localFront: lineNode.worldUp)
            
            parent.sceneView.scene.rootNode.addChildNode(lineNode)
            self.lineNode = lineNode
        }
        
        func createSphere(at position: SCNVector3) -> SCNNode {
            let sphere = SCNSphere(radius: 0.02)
            sphere.firstMaterial?.diffuse.contents = UIColor.red
            
            let node = SCNNode(geometry: sphere)
            node.position = position
            
            return node
        }
        
        // MARK: - MTKViewDelegate Methods
        func draw(in view: MTKView) {
            guard let depthPipelineState = depthPipelineState else {
                print("Depth pipeline state is nil. Skipping rendering.")
                return
            }
            
            guard let commandQueue = view.device?.makeCommandQueue(),
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            guard let depthTexture = parent.manager.capturedData.depth else {
                print("Depth texture not available")
                renderEncoder.endEncoding()
                return
            }
            
            renderEncoder.setRenderPipelineState(depthPipelineState)
            renderEncoder.setDepthStencilState(depthState)
            
            let vertexData: [Float] = [
                -1, -1, 1, 1,
                 1, -1, 1, 0,
                 -1,  1, 0, 1,
                 1,  1, 0, 0
            ]
            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setFragmentBytes(&parent.minDepth, length: MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setFragmentBytes(&parent.maxDepth, length: MemoryLayout<Float>.stride, index: 1)
            renderEncoder.setFragmentTexture(depthTexture, index: 0)
            
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            
            commandBuffer.present(view.currentDrawable!)
            commandBuffer.commit()
        }
    }
}
