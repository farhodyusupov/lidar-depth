import SceneKit
import SwiftUI

struct SceneKit3DOverlay: UIViewRepresentable {
    @Binding var point3D1: SCNVector3?
    @Binding var point3D2: SCNVector3?
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        
        let scene = createScene()
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = UIColor.clear
        
        // Add tap gesture recognizer to detect taps
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = uiView.scene else { return }
        
        // Update positions of points based on bindings
        if let point1 = point3D1 {
            setSpherePosition(scene: scene, id: "sphere1", position: point1)
        }
        if let point2 = point3D2 {
            setSpherePosition(scene: scene, id: "sphere2", position: point2)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func createScene() -> SCNScene {
        let scene = SCNScene()

        // Set up a basic camera for the SceneKit scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.01
        cameraNode.camera?.zFar = 10.0
        cameraNode.position = SCNVector3(0, 0, 1)  // Position the camera slightly away from origin
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)

        // Create red sphere for the first point
        let sphere1 = SCNSphere(radius: 0.05)
        sphere1.firstMaterial?.diffuse.contents = UIColor.red
        sphere1.firstMaterial?.lightingModel = .constant
        let node1 = SCNNode(geometry: sphere1)
        node1.name = "sphere1"
        scene.rootNode.addChildNode(node1)

        // Create blue sphere for the second point
        let sphere2 = SCNSphere(radius: 0.05)
        sphere2.firstMaterial?.diffuse.contents = UIColor.blue
        sphere2.firstMaterial?.lightingModel = .constant
        let node2 = SCNNode(geometry: sphere2)
        node2.name = "sphere2"
        scene.rootNode.addChildNode(node2)

        return scene
    }

    private func setSpherePosition(scene: SCNScene, id: String, position: SCNVector3) {
        guard let sphereNode = scene.rootNode.childNode(withName: id, recursively: false) else { return }
        sphereNode.position = position
    }
    
    // Coordinator to handle gesture and update binding points
    class Coordinator: NSObject {
        var parent: SceneKit3DOverlay
        private var tapCount = 0
        
        init(_ parent: SceneKit3DOverlay) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = gesture.view as? SCNView,
                  let cameraNode = sceneView.scene?.rootNode.childNode(withName: "camera", recursively: true) else { return }
            let location = gesture.location(in: sceneView)
            
            // Convert 2D screen point to a point on a ray in 3D space
            let nearPoint = SCNVector3(location.x, location.y, 0) // Near clipping plane
            let farPoint = SCNVector3(location.x, location.y, 1) // Far clipping plane
            let near3D = sceneView.unprojectPoint(nearPoint)
            let far3D = sceneView.unprojectPoint(farPoint)
            
            // Calculate a point at a fixed distance along the ray from the camera
            let direction = SCNVector3(
                far3D.x - near3D.x,
                far3D.y - near3D.y,
                far3D.z - near3D.z
            )
            let distance: Float = 1.0 // Desired distance from the camera
            let normalizedDirection = normalize(vector: direction)
            let positionIn3D = SCNVector3(
                near3D.x + normalizedDirection.x * distance,
                near3D.y + normalizedDirection.y * distance,
                near3D.z + normalizedDirection.z * distance
            )
            
            // Alternate between point1 and point2 for each tap
            if tapCount % 2 == 0 {
                parent.point3D1 = positionIn3D
            } else {
                parent.point3D2 = positionIn3D
            }
            tapCount += 1
        }
        
        // Helper function to normalize a vector
        private func normalize(vector: SCNVector3) -> SCNVector3 {
            let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
            return SCNVector3(vector.x / length, vector.y / length, vector.z / length)
        }
    }
}
