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

    let points: [SIMD3<Float>] = [
        SIMD3<Float>(-0.20680664, -0.1018125, 0.79541016),
        SIMD3<Float>(-0.20521583, -0.1018125, 0.79541016),
        SIMD3<Float>(-0.14147656, -0.0995, 0.77734375), SIMD3<Float>(-0.13983399, -0.0994375, 0.77685547), SIMD3<Float>(-0.13828027, -0.0994375, 0.77685547), SIMD3<Float>(-0.13672656, -0.0994375, 0.77685547), SIMD3<Float>(-0.13508789, -0.099375, 0.7763672), SIMD3<Float>(-0.13353516, -0.099375, 0.7763672), SIMD3<Float>(-0.13189942, -0.0993125, 0.7758789), SIMD3<Float>(-0.13026562, -0.09925, 0.7753906), SIMD3<Float>(-0.12871484, -0.09925, 0.7753906), SIMD3<Float>(-0.12708399, -0.0991875, 0.77490234), SIMD3<Float>(-0.12561329, -0.09925, 0.7753906), SIMD3<Float>(-0.25078124, -0.098745115, 0.7836914), SIMD3<Float>(-0.24797168, -0.09825293, 0.77978516), SIMD3<Float>(-0.24795508, -0.09886816, 0.78466797), SIMD3<Float>(-0.24669239, -0.09899121, 0.78564453), SIMD3<Float>(-0.24496876, -0.09892969, 0.78515625), SIMD3<Float>(-0.24339844, -0.09892969, 0.78515625), SIMD3<Float>(-0.24197851, -0.09899121, 0.78564453), SIMD3<Float>(-0.24040723, -0.09899121, 0.78564453), SIMD3<Float>(-0.23883593, -0.09899121, 0.78564453), SIMD3<Float>(-0.23741211, -0.099052735, 0.7861328), SIMD3<Float>(-0.23598632, -0.099114254, 0.7866211), SIMD3<Float>(-0.2348496, -0.09929883, 0.78808594), SIMD3<Float>(-0.23341797, -0.099360354, 0.7885742), SIMD3<Float>(-0.23184082, -0.099360354, 0.7885742), SIMD3<Float>(-0.23040625, -0.09942187, 0.7890625), SIMD3<Float>(-0.22896972, -0.0994834, 0.7895508), SIMD3<Float>(-0.22753125, -0.09954492, 0.79003906), SIMD3<Float>(-0.22595116, -0.09954492, 0.79003906), SIMD3<Float>(-0.22450976, -0.09960645, 0.79052734), SIMD3<Float>(-0.2230664, -0.09966797, 0.7910156), SIMD3<Float>(-0.2216211, -0.09972949, 0.7915039), SIMD3<Float>(-0.22017382, -0.09979101, 0.7919922), SIMD3<Float>(-0.21885937, -0.09991406, 0.79296875), SIMD3<Float>(-0.21754101, -0.10003711, 0.7939453), SIMD3<Float>(-0.21595313, -0.10003711, 0.7939453), SIMD3<Float>(-0.21449707, -0.10009863, 0.7944336), SIMD3<Float>(-0.21303906, -0.10016016, 0.7949219), SIMD3<Float>(-0.2115791, -0.10022168, 0.79541016), SIMD3<Float>(-0.20998828, -0.10022168, 0.79541016), SIMD3<Float>(-0.20839746, -0.10022168, 0.79541016), SIMD3<Float>(-0.20680664, -0.10022168, 0.79541016), SIMD3<Float>(-0.20508984, -0.10016016, 0.7949219), SIMD3<Float>(-0.203375, -0.10009863, 0.7944336), SIMD3<Float>(-0.20178613, -0.10009863, 0.7944336), SIMD3<Float>(-0.20007423, -0.10003711, 0.7939453), SIMD3<Float>(-0.19848633, -0.10003711, 0.7939453), SIMD3<Float>(-0.19689843, -0.10003711, 0.7939453), SIMD3<Float>(-0.19543067, -0.10009863, 0.7944336), SIMD3<Float>(-0.1938418, -0.10009863, 0.7944336), SIMD3<Float>(-0.1923711, -0.10016016, 0.7949219), SIMD3<Float>(-0.19078125, -0.10016016, 0.7949219), SIMD3<Float>(-0.1890752, -0.10009863, 0.7944336), SIMD3<Float>(-0.18748632, -0.10009863, 0.7944336), SIMD3<Float>(-0.1857832, -0.10003711, 0.7939453), SIMD3<Float>(-0.18408203, -0.099975586, 0.79345703), SIMD3<Float>(-0.1823828, -0.09991406, 0.79296875), SIMD3<Float>(-0.18057422, -0.09979101, 0.7919922), SIMD3<Float>(-0.17865919, -0.09960645, 0.79052734), SIMD3<Float>(-0.17696875, -0.09954492, 0.79003906), SIMD3<Float>(-0.17517188, -0.09942187, 0.7890625), SIMD3<Float>(-0.1733789, -0.09929883, 0.78808594), SIMD3<Float>(-0.17169629, -0.09923731, 0.78759766), SIMD3<Float>(-0.17001562, -0.09917578, 0.7871094), SIMD3<Float>(-0.16823243, -0.099052735, 0.7861328), SIMD3<Float>(-0.16655664, -0.09899121, 0.78564453), SIMD3<Float>(-0.16498536, -0.09899121, 0.78564453), SIMD3<Float>(-0.16341406, -0.09899121, 0.78564453), SIMD3<Float>(-0.1616416, -0.09886816, 0.78466797), SIMD3<Float>(-0.15987305, -0.098745115, 0.7836914), SIMD3<Float>(-0.15820703, -0.098683596, 0.7832031), SIMD3<Float>(-0.15644531, -0.09856055, 0.78222656), SIMD3<Float>(-0.15478417, -0.09849902, 0.7817383), SIMD3<Float>(-0.153125, -0.0984375, 0.78125), SIMD3<Float>(-0.15137304, -0.09831446, 0.78027344), SIMD3<Float>(-0.14971875, -0.09825293, 0.77978516), SIMD3<Float>(-0.1480664, -0.0981914, 0.7792969), SIMD3<Float>(-0.14632422, -0.09806836, 0.7783203), SIMD3<Float>(-0.14467676, -0.09800684, 0.77783203), SIMD3<Float>(-0.14303125, -0.09794531, 0.77734375), SIMD3<Float>(-0.1413877, -0.09788379, 0.77685547), SIMD3<Float>(-0.1397461, -0.097822264, 0.7763672), SIMD3<Float>(-0.13819335, -0.097822264, 0.7763672), SIMD3<Float>(-0.13664062, -0.097822264, 0.7763672), SIMD3<Float>(-0.13500293, -0.097760744, 0.7758789), SIMD3<Float>(-0.13345118, -0.097760744, 0.7758789), SIMD3<Float>(-0.1318164, -0.09769922, 0.7753906), SIMD3<Float>(-0.13026562, -0.09769922, 0.7753906), SIMD3<Float>(-0.12863378, -0.0976377, 0.77490234), SIMD3<Float>(-0.12708399, -0.0976377, 0.77490234), SIMD3<Float>(-0.12553418, -0.0976377, 0.77490234), SIMD3<Float>(-0.25078124, -0.09717774, 0.7836914), SIMD3<Float>(-0.24812695, -0.0967539, 0.78027344), SIMD3<Float>(-0.24795508, -0.09729883, 0.78466797), SIMD3<Float>(-0.24669239, -0.097419925, 0.78564453), SIMD3<Float>(-0.24496876, -0.097359374, 0.78515625), SIMD3<Float>(-0.24354981, -0.097419925, 0.78564453), SIMD3<Float>(-0.24212891, -0.09748047, 0.7861328), SIMD3<Float>(-0.24040723, -0.097419925, 0.78564453), SIMD3<Float>(-0.23898438, -0.09748047, 0.7861328), SIMD3<Float>(-0.23741211, -0.09748047, 0.7861328), SIMD3<Float>(-0.23613282, -0.09760156, 0.7871094), SIMD3<Float>(-0.2348496, -0.09772266, 0.78808594), SIMD3<Float>(-0.23341797, -0.0977832, 0.7885742), SIMD3<Float>(-0.23198438, -0.09784375, 0.7890625), SIMD3<Float>(-0.23054883, -0.097904295, 0.7895508), SIMD3<Float>(-0.22896972, -0.097904295, 0.7895508), SIMD3<Float>(-0.22739063, -0.097904295, 0.7895508), SIMD3<Float>(-0.22595116, -0.097964846, 0.79003906), SIMD3<Float>(-0.22450976, -0.09802539, 0.79052734), SIMD3<Float>(-0.2230664, -0.09808594, 0.7910156), SIMD3<Float>(-0.2216211, -0.09814648, 0.7915039), SIMD3<Float>(-0.22030957, -0.09826758, 0.79248047), SIMD3<Float>(-0.21885937, -0.09832813, 0.79296875), SIMD3<Float>(-0.21754101, -0.098449215, 0.7939453), SIMD3<Float>(-0.21595313, -0.098449215, 0.7939453), SIMD3<Float>(-0.21449707, -0.098509766, 0.7944336), SIMD3<Float>(-0.21303906, -0.09857031, 0.7949219), SIMD3<Float>(-0.2115791, -0.09863086, 0.79541016), SIMD3<Float>(-0.20998828, -0.09863086, 0.79541016), SIMD3<Float>(-0.20839746, -0.09863086, 0.79541016), SIMD3<Float>(-0.20680664, -0.09863086, 0.79541016), SIMD3<Float>(-0.20508984, -0.09857031, 0.7949219), SIMD3<Float>(-0.2035, -0.09857031, 0.7949219), SIMD3<Float>(-0.20178613, -0.098509766, 0.7944336), SIMD3<Float>(-0.20019726, -0.098509766, 0.7944336), SIMD3<Float>(-0.19848633, -0.098449215, 0.7939453), SIMD3<Float>(-0.19689843, -0.098449215, 0.7939453), SIMD3<Float>(-0.19531055, -0.098449215, 0.7939453), SIMD3<Float>(-0.1938418, -0.098509766, 0.7944336), SIMD3<Float>(-0.19225293, -0.098509766, 0.7944336), SIMD3<Float>(-0.19078125, -0.09857031, 0.7949219), SIMD3<Float>(-0.1890752, -0.098509766, 0.7944336), SIMD3<Float>(-0.18737109, -0.098449215, 0.7939453), SIMD3<Float>(-0.1857832, -0.098449215, 0.7939453), SIMD3<Float>(-0.18408203, -0.09838867, 0.79345703), SIMD3<Float>(-0.18227051, -0.09826758, 0.79248047), SIMD3<Float>(-0.1804629, -0.09814648, 0.7915039), SIMD3<Float>(-0.17865919, -0.09802539, 0.79052734), SIMD3<Float>(-0.17685938, -0.097904295, 0.7895508), SIMD3<Float>(-0.17506348, -0.0977832, 0.7885742), SIMD3<Float>(-0.1733789, -0.09772266, 0.78808594), SIMD3<Float>(-0.17158984, -0.09760156, 0.7871094), SIMD3<Float>(-0.16991016, -0.09754102, 0.7866211), SIMD3<Float>(-0.16823243, -0.09748047, 0.7861328), SIMD3<Float>(-0.16655664, -0.097419925, 0.78564453), SIMD3<Float>(-0.16498536, -0.097419925, 0.78564453), SIMD3<Float>(-0.1633125, -0.097359374, 0.78515625), SIMD3<Float>(-0.1616416, -0.09729883, 0.78466797), SIMD3<Float>(-0.15987305, -0.09717774, 0.7836914), SIMD3<Float>(-0.1581084, -0.09705664, 0.78271484), SIMD3<Float>(-0.15644531, -0.09699609, 0.78222656), SIMD3<Float>(-0.15478417, -0.09693555, 0.7817383), SIMD3<Float>(-0.1530293, -0.09681445, 0.7807617), SIMD3<Float>(-0.15137304, -0.0967539, 0.78027344), SIMD3<Float>(-0.14971875, -0.09669336, 0.77978516), SIMD3<Float>(-0.14797363, -0.096572265, 0.7788086), SIMD3<Float>(-0.14632422, -0.09651172, 0.7783203), SIMD3<Float>(-0.14458594, -0.09639063, 0.77734375), SIMD3<Float>(-0.1429414, -0.09633008, 0.77685547), SIMD3<Float>(-0.14129883, -0.09626953, 0.7763672), SIMD3<Float>(-0.1397461, -0.09626953, 0.7763672), SIMD3<Float>(-0.13819335, -0.09626953, 0.7763672), SIMD3<Float>(-0.13655469, -0.09620898, 0.7758789), SIMD3<Float>(-0.13500293, -0.09620898, 0.7758789), SIMD3<Float>(-0.13336718, -0.09614844, 0.7753906), SIMD3<Float>(-0.1318164, -0.09614844, 0.7753906), SIMD3<Float>(-0.13018359, -0.09608789, 0.77490234), SIMD3<Float>(-0.12863378, -0.09608789, 0.77490234), SIMD3<Float>(-0.12708399, -0.09608789, 0.77490234), SIMD3<Float>(-0.12545508, -0.096027344, 0.77441406), SIMD3<Float>(-0.2509375, -0.095669925, 0.7841797), SIMD3<Float>(-0.24797168, -0.09513379, 0.77978516), SIMD3<Float>(-0.24810937, -0.09578906, 0.78515625), SIMD3<Float>(-0.2468457, -0.0959082, 0.7861328), SIMD3<Float>(-0.24512109, -0.095848635, 0.78564453), SIMD3<Float>(-0.24354981, -0.095848635, 0.78564453), SIMD3<Float>(-0.24212891, -0.0959082, 0.7861328), SIMD3<Float>(-0.24055664, -0.0959082, 0.7861328), SIMD3<Float>(-0.2391328, -0.09596778, 0.7866211), SIMD3<Float>(-0.23755957, -0.09596778, 0.7866211), SIMD3<Float>(-0.2362793, -0.09608691, 0.78759766), SIMD3<Float>(-0.23499511, -0.096206054, 0.7885742), SIMD3<Float>(-0.2335625, -0.09626562, 0.7890625), SIMD3<Float>(-0.23212793, -0.0963252, 0.7895508), SIMD3<Float>(-0.2306914, -0.09638476, 0.79003906), SIMD3<Float>(-0.22911133, -0.09638476, 0.79003906), SIMD3<Float>(-0.22753125, -0.09638476, 0.79003906), SIMD3<Float>(-0.22609082, -0.09644434, 0.79052734), SIMD3<Float>(-0.22464843, -0.096503906, 0.7910156), SIMD3<Float>(-0.2232041, -0.09656347, 0.7915039), SIMD3<Float>(-0.22189453, -0.096682616, 0.79248047), SIMD3<Float>(-0.2204453, -0.09674219, 0.79296875), SIMD3<Float>(-0.21899414, -0.09680176, 0.79345703), SIMD3<Float>(-0.21754101, -0.096861325, 0.7939453), SIMD3<Float>(-0.21608594, -0.0969209, 0.7944336), SIMD3<Float>(-0.2146289, -0.09698047, 0.7949219), SIMD3<Float>(-0.21303906, -0.09698047, 0.7949219), SIMD3<Float>(-0.2115791, -0.09704004, 0.79541016), SIMD3<Float>(-0.21011719, -0.09709961, 0.79589844), SIMD3<Float>(-0.20852539, -0.09709961, 0.79589844), SIMD3<Float>(-0.20693359, -0.09709961, 0.79589844), SIMD3<Float>(-0.20521583, -0.09704004, 0.79541016), SIMD3<Float>(-0.2035, -0.09698047, 0.7949219), SIMD3<Float>(-0.20191015, -0.09698047, 0.7949219), SIMD3<Float>(-0.20032032, -0.09698047, 0.7949219), SIMD3<Float>(-0.1986084, -0.0969209, 0.7944336), SIMD3<Float>(-0.19701953, -0.0969209, 0.7944336), SIMD3<Float>(-0.19543067, -0.0969209, 0.7944336), SIMD3<Float>(-0.1938418, -0.0969209, 0.7944336), SIMD3<Float>(-0.1923711, -0.09698047, 0.7949219), SIMD3<Float>(-0.19078125, -0.09698047, 0.7949219), SIMD3<Float>(-0.1890752, -0.0969209, 0.7944336), SIMD3<Float>(-0.18737109, -0.096861325, 0.7939453), SIMD3<Float>(-0.1857832, -0.096861325, 0.7939453), SIMD3<Float>(-0.18396875, -0.09674219, 0.79296875), SIMD3<Float>(-0.18227051, -0.096682616, 0.79248047), SIMD3<Float>(-0.1804629, -0.09656347, 0.7915039), SIMD3<Float>(-0.17865919, -0.09644434, 0.79052734), SIMD3<Float>(-0.17685938, -0.0963252, 0.7895508), SIMD3<Float>(-0.17517188, -0.09626562, 0.7890625), SIMD3<Float>(-0.1733789, -0.09614649, 0.78808594), SIMD3<Float>(-0.17169629, -0.09608691, 0.78759766), SIMD3<Float>(-0.16991016, -0.09596778, 0.7866211), SIMD3<Float>(-0.16823243, -0.0959082, 0.7861328), SIMD3<Float>(-0.16666016, -0.0959082, 0.7861328), SIMD3<Float>(-0.16498536, -0.095848635, 0.78564453), SIMD3<Float>(-0.1633125, -0.09578906, 0.78515625), SIMD3<Float>(-0.1616416, -0.09572949, 0.78466797), SIMD3<Float>(-0.15997265, -0.095669925, 0.7841797), SIMD3<Float>(-0.15820703, -0.09555078, 0.7832031), SIMD3<Float>(-0.15654297, -0.09549121, 0.78271484), SIMD3<Float>(-0.15488087, -0.09543164, 0.78222656), SIMD3<Float>(-0.153125, -0.0953125, 0.78125), SIMD3<Float>(-0.15137304, -0.09519336, 0.78027344), SIMD3<Float>(-0.14971875, -0.09513379, 0.77978516), SIMD3<Float>(-0.1480664, -0.09507422, 0.7792969), SIMD3<Float>(-0.14632422, -0.09495508, 0.7783203), SIMD3<Float>(-0.14467676, -0.094895504, 0.77783203), SIMD3<Float>(-0.14303125, -0.09483594, 0.77734375), SIMD3<Float>(-0.1413877, -0.09477637, 0.77685547), SIMD3<Float>(-0.1397461, -0.094716795, 0.7763672), SIMD3<Float>(-0.13819335, -0.094716795, 0.7763672), SIMD3<Float>(-0.13664062, -0.094716795, 0.7763672), SIMD3<Float>(-0.13500293, -0.09465723, 0.7758789), SIMD3<Float>(-0.13345118, -0.09465723, 0.7758789), SIMD3<Float>(-0.1318164, -0.09459765, 0.7753906), SIMD3<Float>(-0.13026562, -0.09459765, 0.7753906), SIMD3<Float>(-0.12863378, -0.094538085, 0.77490234), SIMD3<Float>(-0.12708399, -0.094538085, 0.77490234), SIMD3<Float>(-0.12545508, -0.09447852, 0.77441406)
    ]
    
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

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARView
        
        
        private var isSessionInitialized = false
        private var feedbackCircles: [UIView] = []
        init(_ parent: ARView) {
            self.parent = parent
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

                let adjustedPosition = SCNVector3(position.x, -0.055214845,position.z)
                    
                let pointNode = createPoint(at: adjustedPosition, color: color)
                sceneView.scene.rootNode.addChildNode(pointNode)
                spheres.append(pointNode)
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
