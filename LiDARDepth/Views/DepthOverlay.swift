/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that shows the depth image on top of the color image with a slider
 to adjust the depth layer's opacity.
*/

import SwiftUI

struct DepthOverlay: View {
    
    @ObservedObject var manager: CameraManager
    @State private var opacity = Float(0.1)
    @Binding var maxDepth: Float
    @Binding var minDepth: Float
    var targetArea = CGRect(x: 150, y: 150, width: 150, height: 150)
    var body: some View {
        if manager.dataAvailable {
            ZStack {
                MetalTextureViewColor(
                    rotationAngle: rotationAngle,
                    capturedData: manager.capturedData
                )
//              MetalTextureDepthView(
//                rotationAngle: 0,
//                maxDepth: $maxDepth,
//                minDepth:$minDepth,
//                capturedData: manager.capturedData,
//                targetArea:targetArea
//                )
//              .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
          
            }
        }
    }
}
