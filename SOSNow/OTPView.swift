import SwiftUI

struct OTPView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var phoneNumber: String
    @Binding var isShowingOTPView: Bool
    @State private var otp: String = ""
    @State private var generatedOTP: String = ""
    @State private var verificationMessage: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Enter OTP sent to \(appState.selectedCountry.dialCode)\(phoneNumber)")
                .font(.headline)
                .padding()

            TextField("OTP", text: $otp)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            Text("Generated OTP (for testing): \(generatedOTP)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 5)

            if verificationMessage != "Phone number verified!" {
                Button(action: {
                    print("OTPView - Verify OTP button action triggered.")
                    let trimmedOTP = otp.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("OTPView - Verify button tapped. Entered OTP (trimmed): \(trimmedOTP), Generated OTP: \(generatedOTP)")
                    if trimmedOTP == generatedOTP {
                        // Save the phone number
                        appState.userNumber = phoneNumber
                        print("OTPView - Phone number saved to appState.userNumber: \(appState.userNumber)")
                        verificationMessage = "Phone number verified!"
                    } else {
                        verificationMessage = "Invalid OTP. Please try again."
                    }
                }) {
                    Text("Verify OTP")
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                Button(action: {
                    generatedOTP = String(format: "%06d", Int.random(in: 0..<1000000))
                    print("OTPView - Resend OTP tapped. Generated OTP: \(generatedOTP)")
                    verificationMessage = "OTP has been sent."
                }) {
                    Text("Resend OTP")
                }
                .padding()
            } else {
                Button(action: {
                    isShowingOTPView = false
                }) {
                    Text("Done")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Text(verificationMessage)
                .foregroundColor(verificationMessage == "Phone number verified!" ? .green : .red)
        }
        .onAppear {
            // Generate an OTP when the view appears, simulating it being sent
            generatedOTP = String(format: "%06d", Int.random(in: 0..<1000000))
            print("OTPView - onAppear: Generated OTP: \(generatedOTP), phoneNumber: \(phoneNumber), appState.userNumber: \(appState.userNumber)")
            verificationMessage = "OTP has been sent."
        }
        .onDisappear {
            print("OTPView - onDisappear: OTPView was dismissed. phoneNumber: \(phoneNumber), appState.userNumber: \(appState.userNumber)")
        }
    }
}