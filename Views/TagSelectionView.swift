import SwiftUI
//  TagSelectionView.swift
//  Kakeibo_2
//
//  Created by kazuki fujikawa on 2024/09/28.
//
// タグ選択のビュー（共通化）
struct TagSelectionView: View {
    @Binding var tags: [String]
    @Binding var selectedTags: [String]
    @Binding var showDuplicateTagAlert: Bool
    @Binding var newTag: String
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // 上部に選択されたタグを表示
                if !selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedTags, id: \.self) { tag in
                                Text(tag)
                                    .padding(.horizontal)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        if let index = selectedTags.firstIndex(of: tag) {
                                            selectedTags.remove(at: index)
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
                
                List {
                    Section(header: Text("既存のタグを選択")) {
                        ForEach(tags, id: \.self) { tag in
                            HStack {
                                Text(tag)
                                Spacer()
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let index = selectedTags.firstIndex(of: tag) {
                                    selectedTags.remove(at: index)
                                } else {
                                    selectedTags.append(tag)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            tags.remove(atOffsets: indexSet)
                        }
                    }
                    
                    // 新しいタグの追加部分
                    Section(header: Text("新しいタグを追加")) {
                        TextField("新しいタグを追加", text: $newTag)
                        Button(action: {
                            if !newTag.isEmpty {
                                if tags.contains(newTag) {
                                    showDuplicateTagAlert = true
                                } else {
                                    tags.append(newTag)
                                    selectedTags.append(newTag)
                                    newTag = ""
                                }
                            }
                        }) {
                            Text("タグを追加")
                        }
                        .alert(isPresented: $showDuplicateTagAlert) {
                            Alert(title: Text("エラー"), message: Text("同じタグが既に存在します"), dismissButton: .default(Text("OK")))
                        }
                    }
                }
            }
            .navigationBarTitle("タグ選択", displayMode: .inline)
            .navigationBarItems(trailing: Button("閉じる") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
