import SwiftUI
import UIKit

struct PhoneNumberInputView: UIViewRepresentable {
    @Binding var phoneNumber: String // This will now hold only the national number
    @Binding var isValidNumber: Bool
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = .phonePad
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange), for: .editingChanged)
        textField.textAlignment = .left
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = phoneNumber
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PhoneNumberInputView

        init(_ parent: PhoneNumberInputView) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            let nationalNumber = textField.text ?? ""
            parent.phoneNumber = nationalNumber
            // Simplified validation: check if national number is not empty
            parent.isValidNumber = !nationalNumber.isEmpty
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Allow only digits
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
    }
}