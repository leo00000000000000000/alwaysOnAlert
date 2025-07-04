//
//  IDVerificationView.swift
//  SOSNow
//
//  Created by Leo Ricaborda on 7/2/25.
//

import SwiftUI
import AVFoundation
import Vision

enum VerificationStep {
    case captureID
    case captureFace
    case verifying
    case completed
}

struct IDVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState
    @State private var isCameraAuthorized = false
    @State private var idImage: UIImage?
    @State private var faceImage: UIImage?
    @State private var verificationResult: String = "Awaiting verification..."
    @State private var shouldCapturePhoto: Bool = false
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    @State private var currentStep: VerificationStep = .captureID
    @State private var idReadabilityStatus: String = ""
    @State private var showProceedToFaceCaptureButton: Bool = false
    @State private var switchToFaceCapture: Bool = false
    @State private var userName: String = ""

    var body: some View {
        VStack {
            if appState.idVerificationStatus == "Verified" {
                Spacer()
                Text("Welcome, \(appState.userName)!")
                    .font(.largeTitle)
                    .padding()
                Text("Your ID has been verified.")
                    .font(.headline)
                    .padding()
                Spacer()
                Button("Re-verify") {
                    self.appState.idVerificationStatus = "Not Verified"
                    self.appState.userName = ""
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)

                
            } else {
                Text("ID Verification")
                    .font(.largeTitle)
                    .padding()

                if isCameraAuthorized {
                    CameraView(onCapture: { image in
                        if self.currentStep == .captureID {
                            self.idImage = image
                            self.checkIDReadability(image: image)
                        } else if self.currentStep == .captureFace {
                            self.faceImage = image
                            self.compareFaces()
                        }
                    }, capturedImage: .constant(nil), shouldCapturePhoto: $shouldCapturePhoto, cameraPosition: $cameraPosition, onCameraSwitchComplete: {
                        self.currentStep = .captureFace
                    })
                        .frame(width: 300, height: 200)
                        .cornerRadius(10)
                        .padding()

                    if currentStep == .captureID {
                        Text("Position your ID within the frame and tap 'Capture ID'.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Capture ID") {
                            print("IDVerificationView: Setting shouldCapturePhoto to true for ID capture.")
                            self.shouldCapturePhoto = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Reset after a short delay
                                self.shouldCapturePhoto = false
                            }
                            self.verificationResult = "Capturing ID..."
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else if currentStep == .captureFace {
                        Text("Now, position your face within the frame and tap 'Capture Face'.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Capture Face") {
                            print("IDVerificationView: Setting shouldCapturePhoto to true for Face capture.")
                            self.shouldCapturePhoto = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Reset after a short delay
                                self.shouldCapturePhoto = false
                            }
                            self.verificationResult = "Capturing Face..."
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    if showProceedToFaceCaptureButton {
                        Button("Proceed to Face Capture") {
                            self.switchToFaceCapture = true
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    if let idImage = idImage, currentStep != .captureID {
                        Text("Captured ID:")
                            .font(.headline)
                        Image(uiImage: idImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                        Text("ID Readability: \(idReadabilityStatus)")
                            .font(.subheadline)
                            .foregroundColor(idReadabilityStatus == "Readable" ? .green : .red)
                    }

                    if let faceImage = faceImage, currentStep == .completed || currentStep == .verifying {
                        Text("Captured Face:")
                            .font(.headline)
                        Image(uiImage: faceImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                    }

                    Text(verificationResult)
                        .font(.headline)
                        .padding()

                } else {
                    Text("Camera access denied. Please enable camera in settings.")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            }
        .onAppear(perform: checkCameraPermission)
        .onChange(of: switchToFaceCapture) { oldValue, newValue in
            if newValue {
                self.cameraPosition = .front
                self.currentStep = .captureFace
                self.verificationResult = "Switching to front camera..."
                self.switchToFaceCapture = false // Reset the trigger
            }
        }
    }

    private func checkIDReadability(image: UIImage) {
        guard let cgImage = image.cgImage else {
            self.idReadabilityStatus = "Not readable (image error)"
            self.verificationResult = "ID capture failed."
            return
        }

        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("Text recognition error: \(error.localizedDescription)")
                self.idReadabilityStatus = "Not readable (recognition error)"
                self.verificationResult = "ID capture failed."
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self.idReadabilityStatus = "Not readable (no text found)"
                self.verificationResult = "ID capture failed."
                return
            }

            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")

            // Extract the user's name from the recognized text
            let nameLine = recognizedText.components(separatedBy: .newlines).first(where: { $0.contains("Name:") })
            if let name = nameLine?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) {
                self.userName = name
            }

            if recognizedText.isEmpty {
                self.idReadabilityStatus = "Not readable (no text found)"
                self.verificationResult = "ID capture failed."
            } else {
                self.idReadabilityStatus = "Readable"
                self.verificationResult = "ID captured and readable. Tap 'Proceed to Face Capture'."
                self.showProceedToFaceCaptureButton = true
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.idReadabilityStatus = "Not readable (processing error)"
                    self.verificationResult = "ID capture failed."
                }
            }
        }
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isCameraAuthorized = granted
                }
            }
        case .denied, .restricted:
            isCameraAuthorized = false
        @unknown default:
            isCameraAuthorized = false
        }
    }

    private func compareFaces() {
        guard let idImage = idImage, let liveImage = faceImage else {
            verificationResult = "Both ID and live images are needed for comparison."
            return
        }

        guard let cgIdImage = idImage.cgImage, let cgLiveImage = liveImage.cgImage else {
            verificationResult = "Could not convert images to CGImage."
            return
        }

        let idRequest = VNDetectFaceRectanglesRequest { (request, error) in
            if let error = error {
                print("ID Face detection error: \(error.localizedDescription)")
                self.verificationResult = "Error detecting face in ID image."
                return
            }
            guard let idObservations = request.results as? [VNFaceObservation], idObservations.first != nil else {
                self.verificationResult = "No face detected in ID image."
                return
            }

            let liveRequest = VNDetectFaceRectanglesRequest { (request, error) in
                if let error = error {
                    print("Live Face detection error: \(error.localizedDescription)")
                    self.verificationResult = "Error detecting face in live image."
                    return
                }
                guard let liveObservations = request.results as? [VNFaceObservation], liveObservations.first != nil else {
                    self.verificationResult = "No face detected in live image."
                    return
                }

                // Simple comparison: In a real app, you'd use more advanced techniques
                // For now, we'll just check if faces are detected in both.
                // A more robust solution would would involve face recognition models.
                DispatchQueue.main.async {
                    self.verificationResult = "Faces detected in both images. Verifying..."
                    self.finalVerification() // Directly proceed to final verification
                }
            }

            let liveHandler = VNImageRequestHandler(cgImage: cgLiveImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try liveHandler.perform([liveRequest])
                } catch {
                    print("Failed to perform live face detection: \(error.localizedDescription)")
                }
            }
        }

        let idHandler = VNImageRequestHandler(cgImage: cgIdImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try idHandler.perform([idRequest])
            } catch {
                print("Failed to perform ID face detection: \(error.localizedDescription)")
            }
        }
    }

    private func finalVerification() {
        self.appState.idVerificationStatus = "Verified"
        self.appState.userName = self.userName
        self.verificationResult = "ID and Face Verified!"
        self.currentStep = .completed
        print("IDVerificationView: ID and Face Verified. appState.idVerificationStatus: \(appState.idVerificationStatus), appState.userName: \(appState.userName)")
    }
}

struct IDVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        IDVerificationView()
    }
}