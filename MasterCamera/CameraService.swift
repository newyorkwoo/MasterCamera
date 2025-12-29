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
