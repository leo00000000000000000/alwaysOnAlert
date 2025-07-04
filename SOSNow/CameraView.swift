
//
//  CameraView.swift
//  SOSNow
//
//  Created by Leo Ricaborda on 7/2/25.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Binding var capturedImage: UIImage?
    @Binding var shouldCapturePhoto: Bool
    @Binding var cameraPosition: AVCaptureDevice.Position
    var onCameraSwitchComplete: (() -> Void)?

    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        if uiViewController.currentCameraPosition != cameraPosition {
            uiViewController.updateCameraPosition(position: cameraPosition) { _ in
                self.onCameraSwitchComplete?()
            }
        }
        if shouldCapturePhoto {
            uiViewController.capturePhoto()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func didCaptureImage(_ image: UIImage) {
            parent.onCapture(image)
            parent.capturedImage = image
        }

        func cameraDidSwitch(ready: Bool) {
            // This delegate method is no longer needed for camera readiness
        }
    }
}

protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(_ image: UIImage)
    func cameraDidSwitch(ready: Bool)
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    weak var delegate: CameraViewControllerDelegate?
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    private var currentCameraInput: AVCaptureDeviceInput?
    var currentCameraPosition: AVCaptureDevice.Position = .back
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var isSessionRunning = false

    var shouldCapturePhoto: Bool = false {
        didSet {
            if shouldCapturePhoto {
                print("CameraViewController: shouldCapturePhoto set to true. Calling capturePhoto().")
                capturePhoto()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sessionQueue.async {
            self.setupCamera()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async {
            self.captureSession.startRunning()
            self.isSessionRunning = self.captureSession.isRunning
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            self.captureSession.stopRunning()
            self.isSessionRunning = self.captureSession.isRunning
        }
        super.viewWillDisappear(animated)
    }

    func setupCamera(position: AVCaptureDevice.Position = .back) {
        print("CameraViewController: Setting up camera for position: \(position.rawValue)")
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        print("CameraViewController: All available video devices:")
        for device in AVCaptureDevice.devices(for: .video) {
            print("  - Name: \(device.localizedName), Position: \(device.position.rawValue), Type: \(device.deviceType.rawValue)")
        }

        var videoDevice: AVCaptureDevice?
        for device in AVCaptureDevice.devices(for: .video) {
            if device.position == position {
                videoDevice = device
                break
            }
        }
        guard let videoDevice = videoDevice else {
            print("CameraViewController: Unable to access camera for position: \(position.rawValue)")
            return
        }
        print("CameraViewController: Found video device: \(videoDevice.localizedName)")

        do {
            let input = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                self.currentCameraInput = input
                self.currentCameraPosition = position // Update currentCameraPosition here
                print("CameraViewController: Added camera input for position: \(position.rawValue)")
            } else {
                print("CameraViewController: Cannot add input for position: \(position.rawValue)")
            }

            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                print("CameraViewController: Added photo output.")
            }

            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.videoGravity = .resizeAspectFill
                self.previewLayer.frame = self.view.bounds
                self.view.layer.addSublayer(self.previewLayer)
                print("CameraViewController: Added preview layer.")
            }
        } catch let error {
            print("CameraViewController: Error setting up camera: \(error.localizedDescription)")
        }
    }

    func updateCameraPosition(position: AVCaptureDevice.Position, completion: ((Bool) -> Void)? = nil) {
        sessionQueue.async {
            guard self.currentCameraPosition != position else { 
                completion?(true)
                return
            }

            print("CameraViewController: Attempting to update camera position to: \(position.rawValue)")
            self.captureSession.beginConfiguration()

            if let currentInput = self.currentCameraInput {
                self.captureSession.removeInput(currentInput)
                print("CameraViewController: Removed current camera input.")
            }

            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position)
            guard let videoDevice = discoverySession.devices.first else {
                print("CameraViewController: Unable to access camera for position: \(position.rawValue) during update.")
                self.captureSession.commitConfiguration()
                completion?(false)
                return
            }
            print("CameraViewController: Found video device for update: \(videoDevice.localizedName) with position: \(videoDevice.position.rawValue)")

            do {
                let input = try AVCaptureDeviceInput(device: videoDevice)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    self.currentCameraInput = input
                    self.currentCameraPosition = position
                    print("CameraViewController: Successfully added new camera input for position: \(position.rawValue)")
                } else {
                    print("CameraViewController: Cannot add new input for position: \(position.rawValue)")
                }
                self.captureSession.commitConfiguration()
                print("CameraViewController: Committed session configuration.")
                DispatchQueue.main.async {
                    completion?(true)
                }
            } catch {
                print("CameraViewController: Error changing camera position: \(error.localizedDescription)")
                self.captureSession.commitConfiguration()
                completion?(false)
            }
        }
    }

    func capturePhoto() {
        sessionQueue.async {
            guard self.isSessionRunning else {
                print("CameraViewController: Session not running, cannot capture photo.")
                return
            }
            print("CameraViewController: capturePhoto() called.")
            let photoSettings: AVCapturePhotoSettings
            if #available(iOS 11.0, *) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            } else {
                photoSettings = AVCapturePhotoSettings()
            }
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("CameraViewController: Error capturing photo: \(error.localizedDescription)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("CameraViewController: Could not get image data.")
            return
        }
        print("CameraViewController: Photo captured successfully.")
        delegate?.didCaptureImage(image)
        shouldCapturePhoto = false // Reset the flag after capturing
    }
}
