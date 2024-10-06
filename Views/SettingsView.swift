import SwiftUI

struct SettingsView: View {
    @AppStorage("notionAPIKey") private var notionAPIKey: String = ""
    @AppStorage("databaseID") private var databaseID: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notion 設定")) {
                    // Notion API Key 設定
                    NavigationLink(destination: EditTextView(title: "Notion API Key", text: $notionAPIKey)) {
                        HStack {
                            Text("Notion API Key")
                            Spacer()
                            Text(notionAPIKey.isEmpty ? "未設定" : notionAPIKey)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }

                    // Notion Database ID 設定
                    NavigationLink(destination: EditTextView(title: "Database ID", text: $databaseID)) {
                        HStack {
                            Text("Database ID")
                            Spacer()
                            Text(databaseID.isEmpty ? "未設定" : databaseID)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
            .navigationTitle("設定")
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(notionAPIKey, forKey: "notionAPIKey")
        UserDefaults.standard.set(databaseID, forKey: "databaseID")
    }
}

struct EditTextView: View {
    var title: String
    @Binding var text: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("")) {
                TextField("入力してください", text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }.padding(.top, -10)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline) // ここを追加
        .navigationBarItems(trailing: Button("保存") {
            saveAndDismiss()
        })
    }

    func saveAndDismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

// プレビュー用コード
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
