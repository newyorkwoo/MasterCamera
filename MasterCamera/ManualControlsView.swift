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
    @State private var selectedISOIndex = 7 // 預設 ISO 100
    @State private var selectedShutterIndex = 15 // 預設 1/125
    @State private var selectedApertureIndex = 5 // 預設 f/2.8
    
    // 快門速度選項
    let shutterSpeeds: [(value: Double, display: String)] = [
        (1.0, "1\""),
        (0.5, "1/2"),
        (0.25, "1/4"),
        (0.125, "1/8"),
        (1.0/15, "1/15"),
        (1.0/30, "1/30"),
        (1.0/60, "1/60"),
        (1.0/125, "1/125"),
        (1.0/250, "1/250"),
        (1.0/500, "1/500"),
        (1.0/1000, "1/1000"),
        (1.0/2000, "1/2000"),
        (1.0/4000, "1/4000"),
        (1.0/8000, "1/8000")
    ]
    
    // 光圈選項
    let apertures: [Double] = [
        1.4, 1.8, 2.0, 2.8, 4.0, 5.6, 8.0, 11, 16, 22
    ]
    
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
        HStack(spacing: 20) {
            // ISO 滾輪
            VStack(spacing: 5) {
                Text("ISO")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Picker("ISO", selection: $selectedISOIndex) {
                    ForEach(0..<cameraService.standardISOValues.count, id: \.self) { index in
                        let iso = cameraService.standardISOValues[index]
                        if iso >= cameraService.minISO && iso <= cameraService.maxISO {
                            Text("\(Int(iso))")
                                .foregroundColor(.yellow)
                                .tag(index)
                        }
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .clipped()
                .onChange(of: selectedISOIndex) { _ in
                    updateISO()
                }
            }
            .frame(maxWidth: .infinity)
            
            // 快門速度滾輪
            VStack(spacing: 5) {
                HStack {
                    Text("快門")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    if cameraService.suggestedParameter == .shutter {
                        Text("(建議)")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                }
                
                Picker("快門", selection: $selectedShutterIndex) {
                    ForEach(0..<shutterSpeeds.count, id: \.self) { index in
                        Text(shutterSpeeds[index].display)
                            .foregroundColor(.yellow)
                            .tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .clipped()
                .onChange(of: selectedShutterIndex) { _ in
                    updateShutter()
                }
            }
            .frame(maxWidth: .infinity)
            
            // 光圈滾輪
            VStack(spacing: 5) {
                HStack {
                    Text("光圈")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    if cameraService.suggestedParameter == .aperture {
                        Text("(建議)")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                }
                
                Picker("光圈", selection: $selectedApertureIndex) {
                    ForEach(0..<apertures.count, id: \.self) { index in
                        Text("f/\(String(format: "%.1f", apertures[index]))")
                            .foregroundColor(.yellow)
                            .tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .clipped()
                .onChange(of: selectedApertureIndex) { _ in
                    updateAperture()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        
        VStack(spacing: 10) {
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
            .padding(.horizontal)
            
            // 重置按鈕
            Button(action: {
                resetToDefaults()
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
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.8))
        )
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    private func updateISO() {
        let iso = cameraService.standardISOValues[selectedISOIndex]
        cameraService.currentISO = iso
        cameraService.updateExposure(changedParameter: .iso)
    }
    
    private func updateShutter() {
        cameraService.currentShutterSpeed = shutterSpeeds[selectedShutterIndex].value
        cameraService.updateExposure(changedParameter: .shutter)
    }
    
    private func updateAperture() {
        cameraService.currentAperture = apertures[selectedApertureIndex]
        cameraService.updateExposure(changedParameter: .aperture)
    }
    
    private func resetToDefaults() {
        selectedISOIndex = 7 // ISO 100
        selectedShutterIndex = 7 // 1/125
        selectedApertureIndex = 3 // f/2.8
    }
}
