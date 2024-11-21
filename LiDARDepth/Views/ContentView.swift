import SwiftUI
import SceneKit
import ARKit

struct ContentView: View {
    @StateObject private var manager = CameraManager()
    @State private var maxDepth = Float(15.0)
    @State private var minDepth = Float(0.0)
    @State private var tapLocation1: CGPoint? = nil
    @State private var tapLocation2: CGPoint? = nil
    @State private var distanceToPoint1: Float? = nil
    @State private var distanceToPoint2: Float? = nil
    @State private var distanceBetweenPoints: Float? = nil
    @State private var sceneView = ARSCNView()
    @State private var horizontalDistance: Double = 0.0
    @State private var verticalDistance: Float = 0.0
    @State private var capturedData = CameraCapturedData(depth: nil, colorY: nil)
    private let targetArea = CGRect(x: 0, y: 0, width: 200, height: 200)
    @State private var showDepthView = false
    @State private var showBallToast = false
    @State private var showHoleCupToast = false
    @State private var isTapped = false
    
    @State private var isInit: Bool = false
    var spheres: [SCNNode] = []
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("H Distance")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(String(format: "%.2f m", distanceBetweenPoints ?? 0.0))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("V Distance")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(String(format: "%.2f m", verticalDistance))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 20)
                
                Divider()
                    .background(Color.white.opacity(0.5))
                    .padding(.horizontal, 10)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Comp. Dist.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("0.00 m")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Ball Spd.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("0.0 m/s")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 20)
                HStack{
                    Text("Point 1: \(distanceToPoint1 ?? 0.0, specifier: "%.2f") m")
                    Text("Point 2: \(distanceToPoint2 ?? 0.0, specifier: "%.2f") m")
                    Text("Distance: \(distanceBetweenPoints ?? 0.0, specifier: "%.2f") m")

                }
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
            
            ZStack {
//                ARViewWithDepth(
//                    verticalDistance: $verticalDistance,
//                    distanceBetweenPoints: $distanceBetweenPoints,
//                    maxDepth: $maxDepth,
//                    minDepth: $minDepth,
//                    tapLocation1: $tapLocation1,
//                    tapLocation2: $tapLocation2,
//                    distanceToPoint1: $distanceToPoint1,
//                    distanceToPoint2: $distanceToPoint2,
//                    manager: manager,
//                    fx: 500.0,
//                    fy: 500.0,
//                    cx: 160.0,
//                    cy: 120.0
//                )
//                .edgesIgnoringSafeArea(.all)
              
                MetalTextureColorThresholdDepthView(
                    rotationAngle: 0,
                    maxDepth: $maxDepth,
                    minDepth: $minDepth,
                    capturedData: manager.capturedData,
                    tapLocation1: $tapLocation1,
                    tapLocation2: $tapLocation2,
                    distanceToPoint1: $distanceToPoint1,
                    distanceToPoint2: $distanceToPoint2,
//                    distanceBetweenPoints: $distanceBetweenPoints,
                    fx: 500.0,
                    fy: 500.0,
                    cx: 160.0,
                    cy: 120.0
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            if tapLocation1 == nil {
                                // Set the first tap location
                                tapLocation1 = value.location
                            } else if tapLocation2 == nil {
                                // Set the second tap location
                                tapLocation2 = value.location
                                
                                // Print the tapped locations
                                if let location1 = tapLocation1, let location2 = tapLocation2 {
                                    print("tapLocation1:: \(location1)")
                                    print("tapLocation2:: \(location2)")
                                    
                                }
                                
                                // Reset the locations after processing
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    tapLocation1 = nil
                                    tapLocation2 = nil
                                }
                            }
                        }
                )

                
//                  ARView(
//                    verticalDistance: $verticalDistance,
//                    distanceBetweenPoints: $distanceBetweenPoints,
//                    manager: manager,
//                    isTapped: $isTapped,
//                    showBallToast: $showBallToast,
//                    showHoleCupToast: $showHoleCupToast,
//                    fx: 500.0,
//                    fy: 500.0,
//                    cx: 160.0,
//                    cy: 120.0
//                )

                if showBallToast {
                    ToastView(message: "ballMsg".localized())
                                        .onAppear {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                withAnimation {
                                                    showBallToast = false
                                                }
                                            }
                                        }
                                }
                                
                                if showHoleCupToast {
                                    ToastView(message: "holeCupMsg".localized())
                                        .onAppear {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                withAnimation {
                                                    showHoleCupToast = false
                                                }
                                            }
                                        }
                                }
            }
        }
//        .onAppear {
//                  DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                      showBallToast = true
//                  }
//              }
    }
}

extension SCNVector3 {
    func distance(to vector: SCNVector3) -> Float {
        let dx = self.x - vector.x
        let dy = self.y - vector.y
        let dz = self.z - vector.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
}
extension String {
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
    
}
