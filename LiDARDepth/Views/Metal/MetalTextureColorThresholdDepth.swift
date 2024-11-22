
import SwiftUI
import Combine
import MetalKit
import Metal
import SceneKit
struct MetalTextureColorThresholdDepthView: UIViewRepresentable, MetalRepresentable {
    var rotationAngle: Double

    @Binding var maxDepth: Float
    @Binding var minDepth: Float
    var capturedData: CameraCapturedData
    
    
    @Binding var tapLocation1: CGPoint?
    @Binding var tapLocation2: CGPoint?
    @Binding var distanceToPoint1: Float?
    @Binding var distanceToPoint2: Float?
    @Binding var depthPoints: [SIMD3<Float>]
    var fx: Float = 500.0
    var fy: Float = 500.0
    var cx: Float = 160.0
    var cy: Float = 120.0
    
    func makeCoordinator() -> MTKColorThresholdDepthTextureCoordinator {
        let coordinator = MTKColorThresholdDepthTextureCoordinator(parent: self)
        coordinator.depthPointsUpdated = { points in
            DispatchQueue.main.async {
                self.depthPoints = points
            }
        }
        return coordinator
    }
}

final class MTKColorThresholdDepthTextureCoordinator: MTKCoordinator<MetalTextureColorThresholdDepthView> {
    private var depthBuffer: [UInt16] = []
    var depthPointsUpdated: (([SIMD3<Float>]) -> Void)? 
    private func get3DDistanceAtPoint(_ point: CGPoint) -> Float? {
           guard let depthTexture = parent.capturedData.depth else { return nil }
           
           // Convert CGPoint (tap location in view coordinates) to texture coordinates
           let textureWidth = depthTexture.width
           let textureHeight = depthTexture.height
           let viewWidth = mtkView.drawableSize.width
           let viewHeight = mtkView.drawableSize.height

           let textureX = Int((point.x / viewWidth) * CGFloat(textureWidth))
           let textureY = Int((point.y / viewHeight) * CGFloat(textureHeight))

           guard textureX >= 0 && textureX < textureWidth && textureY >= 0 && textureY < textureHeight else {
               return nil
           }

           // Retrieve depth value as UInt16 at the calculated texture coordinates
           var depthValueRaw: UInt16 = 0
           let region = MTLRegionMake2D(textureX, textureY, 1, 1)
           depthTexture.getBytes(&depthValueRaw,
                                 bytesPerRow: MemoryLayout<UInt16>.size * textureWidth,
                                 from: region,
                                 mipmapLevel: 0)

           // Convert UInt16 to Float (assuming .r16Float format)
           let depthValue = float16to32(depthValueRaw)
           
           // Ignore invalid depth values
           if depthValue <= 0.0 {
               return nil
           }

           // Convert to 3D coordinates using intrinsic parameters
           let z = depthValue
           let x = (Float(textureX) - parent.cx) * z / parent.fx
           let y = (Float(textureY) - parent.cy) * z / parent.fy
            let convertedPoint = SCNVector3(x, y, z)
            print("", convertedPoint)

           // Calculate Euclidean distance from camera to point
           return sqrt(x * x + y * y + z * z)
       }
    override func preparePipelineAndDepthState() {
        guard let metalDevice = mtkView.device else { fatalError("Expected a Metal device.") }
        do {
            let library = MetalEnvironment.shared.metalLibrary
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "planeVertexShader")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "planeFragmentShaderColorThresholdDepth")
            pipelineDescriptor.vertexDescriptor = createPlaneMetalVertexDescriptor()
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
            
            let depthDescriptor = MTLDepthStencilDescriptor()
            depthDescriptor.isDepthWriteEnabled = true
            depthDescriptor.depthCompareFunction = .less
            depthState = metalDevice.makeDepthStencilState(descriptor: depthDescriptor)
        } catch {
            print("Unexpected error: \(error).")
        }
    }
    
    override func draw(in view: MTKView) {
        guard let depthTexture = parent.capturedData.depth else {
            print("No depth texture available.")
            return
        }
//        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else { return }
//        guard let passDescriptor = view.currentRenderPassDescriptor else { return }
//        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else { return }

        let depthPoints = extractPointCloud(from: depthTexture)
//        depthPointsUpdated?(depthPoints)
        DispatchQueue.main.async {
              self.depthPointsUpdated?(depthPoints)
          }
//        encoder.setVertexBytes(depthPoints, length: depthPoints.count * MemoryLayout<SIMD3<Float>>.stride, index: 0)
//            
//        encoder.setDepthStencilState(depthState)
//        encoder.setRenderPipelineState(pipelineState)

//        print("depthPoints::\(depthPoints)")
        
        
//        let vertexData: [Float] = [
//            -1, -1, 1, 1,
//             1, -1, 1, 0,
//            -1,  1, 0, 1,
//             1,  1, 0, 0
//        ]
//        encoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
//        encoder.setFragmentBytes(&parent.minDepth, length: MemoryLayout<Float>.stride, index: 0)
//        encoder.setFragmentBytes(&parent.maxDepth, length: MemoryLayout<Float>.stride, index: 1)
//        encoder.setFragmentTexture(depthTexture, index: 0) 
//        encoder.setDepthStencilState(depthState)
//        encoder.setRenderPipelineState(pipelineState)
//        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
//        encoder.endEncoding()
//        commandBuffer.present(view.currentDrawable!)
//        commandBuffer.commit()
    }

    func extractPointCloud(from depthTexture: MTLTexture) -> [SIMD3<Float>] {
            var points: [SIMD3<Float>] = []

            let width = depthTexture.width
            let height = depthTexture.height

            // Reuse the depth buffer to save memory allocations
            if depthBuffer.count != width * height {
                depthBuffer = [UInt16](repeating: 0, count: width * height)
            }

            let region = MTLRegionMake2D(0, 0, width, height)
            depthTexture.getBytes(&depthBuffer,
                                  bytesPerRow: MemoryLayout<UInt16>.size * width,
                                  from: region,
                                  mipmapLevel: 0)

            for y in 0..<height {
                for x in 0..<width {
                    let depthValue = float16to32(depthBuffer[y * width + x])
                    if depthValue > 0 {
                        let z = depthValue
                        let x3D = (Float(x) - parent.cx) * z / parent.fx
                        let y3D = (Float(y) - parent.cy) * z / parent.fy
                        points.append(SIMD3<Float>(x3D, y3D, z))
                    }
                }
            }
            return points
        }

        func float16to32(_ value: UInt16) -> Float {
            let exponent = Int((value >> 10) & 0x1F) - 15
            let fraction = Float(value & 0x3FF) / Float(1 << 10) + 1.0
            return (value & 0x8000 != 0 ? -1.0 : 1.0) * fraction * pow(2.0, Float(exponent))
        }
}
