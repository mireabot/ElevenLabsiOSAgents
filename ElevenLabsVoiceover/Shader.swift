//
//  Shader.swift
//  ElevenLabsVoiceover
//
//  Created by Mikhail Kolkov on 8/11/25.
//

import Metal
import MetalKit
import SwiftUI

final class Coordinator: NSObject, MTKViewDelegate {

    // MARK: Metal setup
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState

    // MARK: Config
    private var blobCount: Int
    private var tightness: Float
    private var sharpness: Float
    private var warp1: Float
    private var warp2: Float
    private var warp3: Float
    private var colors: [SIMD3<Float>]

    struct Uniforms {
        var time: Float
        var resolution: SIMD2<Float>
        var blobCount: UInt32
        var tightness: Float
        var sharpness: Float
        var warp1: Float
        var warp2: Float
        var warp3: Float
    }

    private let start = CFAbsoluteTimeGetCurrent()
    let view: MTKView

    init(blobCount: Int, tightness: Float, sharpness: Float,
         warp1: Float, warp2: Float, warp3: Float, colors: [Color]) {

        self.blobCount = blobCount
        self.tightness = tightness
        self.sharpness = sharpness
        self.warp1 = warp1
        self.warp2 = warp2
        self.warp3 = warp3

        self.colors = colors.map {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
            UIColor($0).getRed(&r, green: &g, blue: &b, alpha: nil)
            return SIMD3(Float(r), Float(g), Float(b))
        }

        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("No Metal device") }
        self.device = device

        view = MTKView(frame: .zero, device: device)
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = false
        view.preferredFramesPerSecond = 60
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        let library = try! device.makeLibrary(source: Self.metalSource, options: nil)
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = library.makeFunction(name: "vertex_main")
        pipelineDesc.fragmentFunction = library.makeFunction(name: "fragment_main")
        pipelineDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDesc)

        commandQueue = device.makeCommandQueue()!
        super.init()
        view.delegate = self
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let desc = view.currentRenderPassDescriptor,
              let cmd = commandQueue.makeCommandBuffer(),
              let enc = cmd.makeRenderCommandEncoder(descriptor: desc) else { return }

        var u = Uniforms(
            time: Float(CFAbsoluteTimeGetCurrent() - start),
            resolution: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            blobCount: UInt32(blobCount),
            tightness: tightness,
            sharpness: sharpness,
            warp1: warp1,
            warp2: warp2,
            warp3: warp3
        )

        enc.setRenderPipelineState(pipeline)
        enc.setVertexBytes(&u, length: MemoryLayout<Uniforms>.size, index: 1)
        enc.setFragmentBytes(&u, length: MemoryLayout<Uniforms>.size, index: 1)

        let maxColors = 64
        var colorArray = colors
        if colorArray.count < blobCount {
            colorArray += Array(repeating: SIMD3<Float>(1, 1, 1), count: blobCount - colorArray.count)
        }
        enc.setFragmentBytes(colorArray, length: maxColors * MemoryLayout<SIMD3<Float>>.size, index: 2)

        enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        enc.endEncoding()
        cmd.present(drawable)
        cmd.commit()
    }

    func updateConfig(blobCount: Int, tightness: Float, sharpness: Float,
                      warp1: Float, warp2: Float, warp3: Float, colors: [SIMD3<Float>]) {
        self.blobCount = blobCount
        self.tightness = tightness
        self.sharpness = sharpness
        self.warp1 = warp1
        self.warp2 = warp2
        self.warp3 = warp3
        self.colors = colors
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    // MARK: Shader Code
    private static let metalSource = """
    #include <metal_stdlib>
    using namespace metal;
    struct Uniforms {
        float time;
        float2 resolution;
        uint blobCount;
        float tightness;
        float sharpness;
        float warp1;
        float warp2;
        float warp3;
    };
    struct VSOut {
        float4 pos [[position]];
        float2 uv;
    };
    vertex VSOut vertex_main(uint vid [[vertex_id]],
                             constant Uniforms& u [[buffer(1)]]) {
        float2 corners[4] = { {-1, 1}, {-1, -1}, {1, 1}, {1, -1} };
        VSOut out;
        out.pos = float4(corners[vid], 0, 1);
        out.uv = (corners[vid] + 1.0) * 0.5;
        return out;
    }
    float2 hash22(float2 p) {
        p = fract(p * float2(5.3983, 5.4427));
        p += dot(p, p.yx + 19.19);
        return fract(float2(p.x * p.y, p.x + p.y));
    }
    fragment float4 fragment_main(VSOut in [[stage_in]],
                                  constant Uniforms& u [[buffer(1)]],
                                  constant float3* blobColors [[buffer(2)]]) {
        float2 uv = in.uv * 2.0 - 1.0;
        float2 warped = uv
            + u.warp1 * float2(sin(uv.y * 2.0 + u.time * 0.65), cos(uv.x * 2.0 - u.time * 0.48))
            + u.warp2 * float2(cos(uv.y * 3.3 - u.time * 0.45), sin(uv.x * 3.3 + u.time * 0.38))
            + u.warp3 * float2(sin((uv.x + uv.y) * 2.4 + u.time * 0.55),
                               cos((uv.x - uv.y) * 2.4 - u.time * 0.43));
        float weightSum = 0.0;
        float3 colorSum = float3(0.0);
        for (uint i = 0; i < u.blobCount; ++i) {
            float2 center = i < 4
                ? float2((i & 1) == 0 ? -0.9 : 0.9, (i & 2) == 0 ? 0.9 : -0.9)
                : (hash22(float2(i, 42.0)) * 1.8 - 0.9);
            if (i >= 4) {
                float angle = 6.2831 * hash22(float2(i, 42.0)).x;
                center += 0.12 * float2(sin(u.time * 0.55 + angle),
                                        cos(u.time * 0.44 + angle * 1.3));
            }
            float w = exp(-dot(warped - center, warped - center) * u.tightness);
            w = pow(w, u.sharpness);
            float3 col = blobColors[i % u.blobCount];
            weightSum += w;
            colorSum += w * col;
        }
        float3 rgb = colorSum / max(weightSum, 1e-4);
        rgb = mix(rgb, float3(1.0), 0.01); // Subtle glow
        return float4(rgb, 1.0);
    }
    """;
}
