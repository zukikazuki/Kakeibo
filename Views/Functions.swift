import SwiftUI

struct DoneButtonToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(UIViewWrapper())
    }
}

struct UIViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return UIView()  // 空の UIView を返す
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // ビュー階層が構築された後に処理を行う
        if let textField = findTextField(in: uiView) {
            addDoneButtonTo(textField: textField)
        }
    }

    // UITextField を探索する関数
    func findTextField(in view: UIView) -> UITextField? {
        for subview in view.subviews {
            if let tf = subview as? UITextField {
                return tf
            } else if let found = findTextField(in: subview) {
                return found
            }
        }
        return nil
    }

    // UITextField にツールバーを追加する関数
    func addDoneButtonTo(textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: textField, action: #selector(textField.resignFirstResponder))
        toolbar.items = [doneButton]
        textField.inputAccessoryView = toolbar
    }
}


struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.delegate = context.coordinator

        // キーボードに「完了」ボタンを追加
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        toolbar.items = [doneButton]
        textField.inputAccessoryView = toolbar

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        @objc func doneButtonTapped() {
            parent.hideKeyboard()
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.text = textField.text ?? ""
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}




extension View {
    func doneButtonToolbar() -> some View {
        self.modifier(DoneButtonToolbarModifier())
    }
    
    func customDivider(paddingLeft: CGFloat = 15) -> some View {
        Divider()
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.leading, paddingLeft)
    }
    func customHeight(_ height: CGFloat = 45) -> some View {
            self
                .frame(height: height)  // デフォルトで50の高さを設定
    }
    func customTrailingPadding(_ padding: CGFloat = 20) -> some View {
            self
                .padding(.trailing, padding)  // デフォルトで右側に20ptの余白を追加
    }
    func customLeadingPadding(_ padding: CGFloat = 16) -> some View {
            self
                .padding(.leading, padding)  // デフォルトで左側に15ptの余白を追加
        }
}


extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


