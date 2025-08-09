import Foundation
import AVFoundation
import Vision
import UIKit

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isScanning = false
    @Published var scannedCode: String?
    @Published var error: String?
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var barcodeRequest: VNDetectBarcodesRequest?
    
    override init() {
        super.init()
        checkCameraAuthorization()
    }
    
    // MARK: - Camera Authorization
    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                }
            }
        case .denied, .restricted:
            isAuthorized = false
            error = "Camera access is required for barcode scanning"
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - Setup Camera
    func setupCamera() throws {
        guard isAuthorized else {
            throw CameraError.notAuthorized
        }
        
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else {
            throw CameraError.setupFailed
        }
        
        // Configure camera input
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            throw CameraError.noCameraAvailable
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            throw CameraError.inputError
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            throw CameraError.inputError
        }
        
        // Configure video output
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        } else {
            throw CameraError.outputError
        }
        
        // Setup Vision barcode detection
        setupBarcodeDetection()
    }
    
    private func setupBarcodeDetection() {
        barcodeRequest = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNBarcodeObservation],
                  let firstResult = results.first,
                  let payload = firstResult.payloadStringValue else {
                return
            }
            
            DispatchQueue.main.async {
                self.scannedCode = payload
                self.isScanning = false
                self.stopCamera()
            }
        }
        
        barcodeRequest?.symbologies = [
            .qr,
            .code128,
            .code39,
            .ean13,
            .ean8,
            .upce
        ]
    }
    
    // MARK: - Camera Control
    func startCamera() {
        guard let captureSession = captureSession else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        isScanning = true
        scannedCode = nil
        error = nil
    }
    
    func stopCamera() {
        guard let captureSession = captureSession else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.stopRunning()
        }
        
        isScanning = false
    }
    
    // MARK: - Public Scanning Interface
    func scanBarcode() async throws -> String {
        guard isAuthorized else {
            throw CameraError.notAuthorized
        }
        
        try setupCamera()
        
        return await withCheckedContinuation { continuation in
            // Set up completion handler
            let originalRequest = barcodeRequest
            barcodeRequest = VNDetectBarcodesRequest { [weak self] request, error in
                guard let self = self,
                      let results = request.results as? [VNBarcodeObservation],
                      let firstResult = results.first,
                      let payload = firstResult.payloadStringValue else {
                    continuation.resume(throwing: CameraError.scanFailed)
                    return
                }
                
                DispatchQueue.main.async {
                    self.scannedCode = payload
                    self.isScanning = false
                    self.stopCamera()
                    continuation.resume(returning: payload)
                }
            }
            
            barcodeRequest?.symbologies = originalRequest?.symbologies ?? []
            
            startCamera()
            
            // Timeout after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if self.isScanning {
                    self.stopCamera()
                    continuation.resume(throwing: CameraError.timeout)
                }
            }
        }
    }
    
    // MARK: - Preview Layer
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let captureSession = captureSession else { return nil }
        
        if videoPreviewLayer == nil {
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
        }
        
        return videoPreviewLayer
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let request = barcodeRequest else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Camera Errors
enum CameraError: Error, LocalizedError {
    case notAuthorized
    case setupFailed
    case noCameraAvailable
    case inputError
    case outputError
    case scanFailed
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access is required for barcode scanning"
        case .setupFailed:
            return "Failed to setup camera"
        case .noCameraAvailable:
            return "No camera available on this device"
        case .inputError:
            return "Failed to setup camera input"
        case .outputError:
            return "Failed to setup camera output"
        case .scanFailed:
            return "Failed to scan barcode"
        case .timeout:
            return "Scanning timed out"
        }
    }
}

// MARK: - Mock Scanner for Development
extension CameraManager {
    func mockScanBarcode() async throws -> String {
        // Simulate scanning delay
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Return a mock barcode
        let mockBarcodes = [
            "123456789",
            "987654321",
            "456789123",
            "789123456"
        ]
        
        return mockBarcodes.randomElement() ?? "123456789"
    }
} 