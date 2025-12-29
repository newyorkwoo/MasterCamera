//
//  ManualControlsView.swift
//  MasterCamera
//
//  Created by SHU-FANG WU on 2025/12/29.
//

import SwiftUI

struct ManualControlsView: View {
    @ObservedObject var cameraService: CameraService
    @State private var showControls = false
    
    var body: some View {
        VStack {
            Spacer()
            
            if showControls {
                controlsPanel
                    .transition(.move(edge: .bottom))
            }
            
            // 切換按鈕
            Button(action: {
                withAnimation {
                    showControls.toggle()
                }
            }) {
                HStack {
                    Image(systemName: showControls ? "chevron.down" : "chevron.up")
                    Text("手動控制")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
            }
            .padding(.bottom, 10)
        }
    }
    
    private var controlsPanel: some View {
        VStack(spacing: 15) {
            // ISO 控制
            VStack(spacing: 5) {
                HStack {
                    Text("ISO")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(cameraService.currentISO))")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                }
                
                Slider(value: $cameraService.currentISO,
                       in: cameraService.minISO...cameraService.maxISO,
                       onEditingChanged: { editing in
                    if !editing {
                        cameraService.updateExposure(changedParameter: .iso)
                    }
                })
                .accentColor(.yellow)
            }
            
            // 快門速度控制
            VStack(spacing: 5) {
                HStack {
                    Text("快門")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(cameraService.shutterSpeedText)
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    if cameraService.suggestedParameter == .shutter {
                        Text("(建議)")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                }
                
                Slider(value: $cameraService.currentShutterSpeed,
                       in: cameraService.minShutterSpeed...cameraService.maxShutterSpeed,
                       onEditingChanged: { editing in
                    if !editing {
                        cameraService.updateExposure(changedParameter: .shutter)
                    }
                })
                .accentColor(.yellow)
            }
            
            // 光圈控制（模擬）
            VStack(spacing: 5) {
                HStack {
                    Text("光圈")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("f/\(String(format: "%.1f", cameraService.currentAperture))")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    if cameraService.suggestedParameter == .aperture {
                        Text("(建議)")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                }
                
                Slider(value: $cameraService.currentAperture,
                       in: 1.4...22.0,
                       step: 0.1,
                       onEditingChanged: { editing in
                    if !editing {
                        cameraService.updateExposure(changedParameter: .aperture)
                    }
                })
                .accentColor(.yellow)
            }
            
            // 曝光值顯示
            HStack {
                Text("曝光值 (EV)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(String(format: "%.1f", cameraService.currentEV))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // 重置按鈕
            Button(action: {
                cameraService.resetToAuto()
            }) {
                Text("自動模式")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.8))
        )
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}
