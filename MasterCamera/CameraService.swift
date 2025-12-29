//
//  CameraService.swift
//  MasterCamera
//
//  Created by SHU-FANG WU on 2025/12/28.
//

import AVFoundation
import UIKit
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var error: CameraError?
    @Published var capturedImage: UIImage?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var isFrontCamera = false
    @Published var zoomFactor: CGFloat = 1.0
    
    // 手動曝光控制
    @Published var currentISO: Float = 100
    @Published var currentShutterSpeed: Double = 0.01 // 秒
    @Published var currentAperture: Double = 1.8
    @Published var currentEV: Double = 0
    @Published var suggestedParameter: ExposureParameter?
    
    var minISO: Float = 50
    var maxISO: Float = 3200
    var minShutterSpeed: Double = 0.0001 // 1/10000
    var maxShutterSpeed: Double = 1.0 // 1秒
    
    enum ExposureParameter {
        case iso, shutter, aperture
    }
    
    var shutterSpeedText: String {
        if currentShutterSpeed >= 1.0 {
            return String(format: "%.1f\"", currentShutterSpeed)
        } else {
            return "1/\(Int(1.0 / currentShutterSpeed))"
        }
    }
    
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var deviceInput: AVCaptureDeviceInput?
    private var _previewLayer: AVCaptureVideoPreviewLayer?
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        if let layer = _previewLayer {
            return layer
        }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        _previewLayer = layer
        return layer
    }
    
    enum CameraError: Error, LocalizedError {
        case cameraUnavailable
        case cannotAddInput
        case cannotAddOutput
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .cameraUnavailable:
                return "相機無法使用"
            case .cannotAddInput:
                return "無法新增相機輸入"
            case .cannotAddOutput:
                return "無法新增相機輸出"
            case .permissionDenied:
                return "相機權限被拒絕"
            }
        }
    }
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            isAuthorized = false
            error = .permissionDenied
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, 
                                                   for: .video, 
                                                   position: isFrontCamera ? .front : .back) else {
            error = .cameraUnavailable
            session.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(input) {
                session.addInput(input)
                deviceInput = input
            } else {
                error = .cannotAddInput
                session.commitConfiguration()
                return
            }
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.maxPhotoQualityPrioritization = .quality
            } else {
                error = .cannotAddOutput
                session.commitConfiguration()
                return
            }
            
            session.commitConfiguration()
            
            // 設置手動控制的範圍
            setupManualControls()
            
        } catch {
            self.error = .cameraUnavailable
            session.commitConfiguration()
        }
    }
    
    func start() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        
        if let device = deviceInput?.device, device.hasFlash {
            settings.flashMode = flashMode
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func switchCamera() {
        session.beginConfiguration()
        
        if let currentInput = deviceInput {
            session.removeInput(currentInput)
        }
        
        isFrontCamera.toggle()
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: isFrontCamera ? .front : .back) else {
            session.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                deviceInput = input
            }
        } catch {
            print("Error switching camera: \(error)")
        }
        
        session.commitConfiguration()
    }
    
    func toggleFlash() {
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .auto
        case .auto:
            flashMode = .off
        @unknown default:
            flashMode = .off
        }
    }
    
    func hasFlash() -> Bool {
        guard let device = deviceInput?.device else { return false }
        return device.hasFlash
    }
    
    func focus(at point: CGPoint) {
        guard let device = deviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error focusing: \(error)")
        }
    }
    
    func zoom(factor: CGFloat) {
        guard let device = deviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 10.0)
            let newZoom = max(1.0, min(factor, maxZoom))
            
            device.videoZoomFactor = newZoom
            
            device.unlockForConfiguration()
            
            DispatchQueue.main.async {
                self.zoomFactor = newZoom
            }
        } catch {
            print("Error zooming: \(error)")
        }
    }
    
    func getMaxZoom() -> CGFloat {
        guard let device = deviceInput?.device else { return 1.0 }
        return min(device.activeFormat.videoMaxZoomFactor, 10.0)
    }
    
    // MARK: - 手動曝光控制
    
    func updateExposure(changedParameter: ExposureParameter) {
        guard let device = deviceInput?.device else { return }
        
        // 計算當前曝光值 (EV)
        calculateEV()
        
        do {
            try device.lockForConfiguration()
            
            // 設置手動曝光模式
            if device.isExposureModeSupported(.custom) {
                // 轉換快門速度為 CMTime
                let shutterDuration = CMTime(seconds: currentShutterSpeed, preferredTimescale: 1000000000)
                
                // 根據哪個參數被改變，建議另一個參數
                switch changedParameter {
                case .iso:
                    // ISO 改變，建議快門速度
                    suggestedParameter = .shutter
                    // 可以在這裡計算建議的快門速度
                    
                case .shutter:
                    // 快門改變，建議光圈
                    suggestedParameter = .aperture
                    // 計算建議的光圈值
                    
                case .aperture:
                    // 光圈改變，建議 ISO
                    suggestedParameter = .iso
                    // 計算建議的 ISO 值
                }
                
                // 應用 ISO 和快門設置
                device.setExposureModeCustom(duration: shutterDuration,
                                            iso: currentISO,
                                            completionHandler: nil)
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting exposure: \\(error)")
        }
    }
    
    func calculateEV() {
        // 曝光值計算公式: EV = log2(N² / t) - log2(S / 100)
        // N = 光圈數, t = 快門時間(秒), S = ISO
        let apertureSquared = currentAperture * currentAperture
        let ev = log2(apertureSquared / currentShutterSpeed) - log2(currentISO / 100.0)
        currentEV = ev
    }
    
    func resetToAuto() {
        guard let device = deviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            device.unlockForConfiguration()
            
            // 重置為默認值
            DispatchQueue.main.async {
                self.currentISO = 100
                self.currentShutterSpeed = 0.01
                self.currentAperture = 1.8
                self.suggestedParameter = nil
                self.calculateEV()
            }
        } catch {
            print("Error resetting to auto: \\(error)")
        }
    }
    
    func setupManualControls() {
        guard let device = deviceInput?.device else { return }
        
        // 獲取設備支持的 ISO 範圍
        minISO = device.activeFormat.minISO
        maxISO = device.activeFormat.maxISO
        
        // 獲取設備支持的快門速度範圍
        let minDuration = device.activeFormat.minExposureDuration
        let maxDuration = device.activeFormat.maxExposureDuration
        
        minShutterSpeed = CMTimeGetSeconds(minDuration)
        maxShutterSpeed = min(CMTimeGetSeconds(maxDuration), 1.0)
        
        // 初始化當前值
        currentISO = 100
        currentShutterSpeed = 0.01
        currentAperture = 1.8
        calculateEV()
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, 
                    didFinishProcessingPhoto photo: AVCapturePhoto, 
                    error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // 自動儲存照片到相簿
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}
