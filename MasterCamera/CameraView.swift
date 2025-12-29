//
//  CameraView.swift
//  MasterCamera
//
//  Created by SHU-FANG WU on 2025/12/28.
//

import SwiftUI
import PhotosUI

struct CameraView: View {
    @StateObject private var cameraService = CameraService()
    @State private var showImagePicker = false
    @State private var showCapturedImage = false
    @State private var showSettings = false
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var focusLocation: CGPoint?
    @State private var showFocusIndicator = false
    @State private var currentMagnification: CGFloat = 1.0
    @State private var totalMagnification: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if cameraService.isAuthorized {
                GeometryReader { geometry in
                    ZStack {
                        CameraPreview(previewLayer: cameraService.previewLayer)
                            .ignoresSafeArea()
                            .onAppear {
                                cameraService.start()
                            }
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        currentMagnification = value
                                        let delta = value / totalMagnification
                                        let newZoom = cameraService.zoomFactor * delta
                                        let maxZoom = cameraService.getMaxZoom()
                                        let clampedZoom = min(max(newZoom, 1.0), maxZoom)
                                        cameraService.zoom(factor: clampedZoom)
                                    }
                                    .onEnded { value in
                                        totalMagnification = currentMagnification
                                    }
                            )
                            .onTapGesture { location in
                                let x = location.x / geometry.size.width
                                let y = location.y / geometry.size.height
                                let focusPoint = CGPoint(x: x, y: y)
                                
                                cameraService.focus(at: focusPoint)
                                
                                focusLocation = location
                                showFocusIndicator = true
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    showFocusIndicator = false
                                }
                            }
                        
                        // 對焦指示器
                        if showFocusIndicator, let location = focusLocation {
                            FocusIndicator()
                                .position(location)
                        }
                    }
                }
                
                VStack {
                    // 頂部控制列
                    topControlsBar
                    
                    Spacer()
                    
                    // 手動控制面板
                    ManualControlsView(cameraService: cameraService)
                    
                    // 底部控制列
                    bottomControlsBar
                }
                .padding()
            } else {
                permissionDeniedView
            }
        }
        .sheet(isPresented: $showCapturedImage) {
            if let image = cameraService.capturedImage {
                ImagePreviewView(image: image) {
                    showCapturedImage = false
                    cameraService.capturedImage = nil
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            PhotoPickerView()
        }
    }
    
    private var topControlsBar: some View {
        HStack {
            // 閃光燈控制
            if cameraService.hasFlash() && !cameraService.isFrontCamera {
                Button(action: {
                    cameraService.toggleFlash()
                }) {
                    Image(systemName: flashIconName)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            
            Spacer()
            
            // 縮放倍數顯示
            if cameraService.zoomFactor > 1.01 {
                Text(String(format: "%.1fx", cameraService.zoomFactor))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
            }
            
            Spacer()
            
            // 設定按鈕（可選）
            Button(action: {
                showSettings.toggle()
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }
    
    private var bottomControlsBar: some View {
        HStack(spacing: 40) {
            // 照片縮圖預覽按鈕
            Button(action: {
                if cameraService.capturedImage != nil {
                    showCapturedImage = true
                } else {
                    showImagePicker = true
                }
            }) {
                ZStack {
                    if let image = cameraService.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    } else {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
            }
            
            // 拍照按鈕
            Button(action: {
                cameraService.capturePhoto()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 68, height: 68)
                }
            }
            
            // 切換鏡頭按鈕
            Button(action: {
                withAnimation {
                    cameraService.switchCamera()
                }
            }) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 30)
    }
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("需要相機權限")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("請在設定中允許存取相機")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("前往設定")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var flashIconName: String {
        switch cameraService.flashMode {
        case .off:
            return "bolt.slash.fill"
        case .on:
            return "bolt.fill"
        case .auto:
            return "bolt.badge.automatic.fill"
        @unknown default:
            return "bolt.slash.fill"
        }
    }
}

struct ImagePreviewView: View {
    let image: UIImage
    let onDismiss: () -> Void
    @State private var isSaving = false
    @State private var showSaveAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                HStack(spacing: 40) {
                    Button(action: {
                        savePhoto()
                    }) {
                        VStack {
                            Image(systemName: isSaving ? "arrow.down.circle.fill" : "square.and.arrow.down")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            Text("儲存")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isSaving)
                    
                    Button(action: {
                        sharePhoto()
                    }) {
                        VStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            Text("分享")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .alert("已儲存", isPresented: $showSaveAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text("照片已儲存至相簿")
        }
    }
    
    private func savePhoto() {
        isSaving = true
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            showSaveAlert = true
        }
    }
    
    private func sharePhoto() {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct PhotoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("相簿功能")
                .navigationTitle("相簿")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct FocusIndicator: View {
    @State private var animate = false
    
    var body: some View {
        Circle()
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: 80, height: 80)
            .scaleEffect(animate ? 1.0 : 1.5)
            .opacity(animate ? 1.0 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    animate = true
                }
            }
    }
}

#Preview {
    CameraView()
}
