import SwiftUI

struct ExpenseInputView: View {
    @State private var amount: String = ""
    @State private var memo: String = ""
    @State private var selectedDate: Date = Date() // 支払い日
    @State private var isIncome = false // 収入かどうかを選択するためのフラグ
    
    // タグ関連
    @State private var showTagSheet = false
    @State private var selectedTags: [String] = [] // 選択されたタグ
    
    // 収入と支出に応じたタグリスト
    @State private var incomeTags: [String] = []
    @State private var expenseTags: [String] = []
    
    // 現在のタグリスト
    var currentTags: [String] {
        return isIncome ? incomeTags : expenseTags
    }
    
    @State private var newTag: String = "" // 新しいタグ入力用
    @State private var showDuplicateTagAlert = false // 重複アラート用

    @StateObject private var transactionManager = TransactionManager.shared


    var body: some View {
        VStack {
            // 収入と支出の切り替えバー
            Picker("収入 / 支出", selection: $isIncome) {
                Text("支出").tag(false)
                Text("収入").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 250)  // 横幅を200に制限
            .onChange(of: isIncome) {
                selectedTags = []  // 収入と支出を切り替えたらタグをリセット
            }
            
            // フォーム風のカスタムUI
            VStack(spacing: 0) {
                // 金額・メモ入力部分を白い背景で囲む
                VStack(spacing: 0) {
                    // 金額入力
                    HStack {
                                    CustomTextField(text: $amount, placeholder: "金額", keyboardType: .decimalPad)
                                        .multilineTextAlignment(.leading)
                                        .padding(.trailing, 20)
                                        .frame(maxWidth: .infinity)
                                }
                    .padding()  // 全体に適切な余白
                    .customHeight()
                    customDivider()
                    // タグ選択
                    HStack {
                        Text("タグ").customLeadingPadding()
                        Spacer()
                        Button(action: {
                            showTagSheet.toggle()
                        }) {
                            Text(selectedTags.isEmpty ? "選択してください" : selectedTags.joined(separator: ", "))
                                .foregroundColor(.gray).customTrailingPadding()
                        }
                    }
                    .customHeight()
                    customDivider()

                    // 支払い日の選択
                    HStack {
                        Text("日付").customLeadingPadding()
                        Spacer()
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden().customTrailingPadding()
                    }
                    .customHeight()
                    customDivider()

                    // メモ入力
                    HStack {
                        TextField("メモを入力", text: $memo)
                            .doneButtonToolbar()
                            .multilineTextAlignment(.leading)  // 左揃え
                            .padding(.leading, 0)  // TextFieldの左側の余白もなし
                    }
.padding().customHeight()
                }
                .background(Color.white)  // 内部を白に設定
                .cornerRadius(20)  // 内部の角を丸くする
                .padding()

                // 金額入力部分と追加ボタンの間にスペースと背景を追加
                VStack {
                    
                }
                .padding(.horizontal)
                
                // 保存ボタン部分
                Button(action: {
                    let newTransaction = TransactionModel(
                        pageID: nil,
                        amount: Double(amount) ?? 0,
                        memo: memo,
                        date: selectedDate,
                        tags: selectedTags,
                        isSubscription: false,
                        subscriptionPeriod: nil,
                        isIncome: isIncome
                    )
                    transactionManager.saveTransaction(transaction: newTransaction)
                    resetForm()
                }) {
                    Text(isIncome ? "収入を追加" : "支出を追加")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 15)
                }
                .padding(.top, 10)
                .padding(.horizontal)  // 横幅を持たせる
            }
            .background(Color(.systemGray6))  // 全体の外側背景色を薄い灰色に設定
            .cornerRadius(20)  // 全体の角を丸く
            .padding(.horizontal)
            .padding(.bottom, 5)

            // トランザクションリストの表示
            List {
                Section(header: Text("取引履歴")) {
                    ForEach(transactionManager.transactions.filter { $0.isIncome == isIncome && !$0.isSubscription }.sorted(by: { $0.date > $1.date }) ) { transaction in
                        HStack {
                            VStack(alignment: .leading) {
                                // 料金を表示
                                Text("¥\(transaction.amount, specifier: "%.0f")")
                                    .font(.headline)
                                
                                // タグを四角形のボックスで表示
                                HStack {
                                    ForEach(transaction.tags, id: \.self) { tag in
                                        Text(tag)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                            .font(.subheadline)
                                    }
                                }
                                
                                // 日付を表示
                                Text(formattedDate(transaction.date))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                    }
                    .onDelete(perform: transactionManager.deleteTransaction)  // 削除処理
                }
            }
            .background(Color(.systemGray6))  // 背景色を設定
            .cornerRadius(20)  // 背景を丸くする
            .padding(.horizontal)
        }
        .onAppear {
            loadTags()
        }
        .onChange(of: incomeTags) {
            saveTags()
        }
        .onChange(of: expenseTags) {
            saveTags()
        }
        .padding()
        .sheet(isPresented: $showTagSheet) {
            TagSelectionView(
                tags: Binding(get: { currentTags }, set: { newValue in
                    if isIncome {
                        incomeTags = newValue
                    } else {
                        expenseTags = newValue
                    }
                }),
                selectedTags: $selectedTags,
                showDuplicateTagAlert: $showDuplicateTagAlert,
                newTag: $newTag
            )
        }
    }
    // タグを保存するメソッド
        func saveTags() {
            UserDefaults.standard.set(incomeTags, forKey: "IncomeTags")
            UserDefaults.standard.set(expenseTags, forKey: "ExpenseTags")
        }

        // タグを読み込むメソッド
        func loadTags() {
            if let loadedIncomeTags = UserDefaults.standard.array(forKey: "IncomeTags") as? [String] {
                incomeTags = loadedIncomeTags
            } else {
                incomeTags = ["給料", "ボーナス"]
            }

            if let loadedExpenseTags = UserDefaults.standard.array(forKey: "ExpenseTags") as? [String] {
                expenseTags = loadedExpenseTags
            } else {
                expenseTags = ["生活費", "娯楽", "交通費"]
            }
        }

    // フォームをリセットする関数
    func resetForm() {
        amount = ""
        memo = ""
        selectedTags = []
        selectedDate = Date()  // 現在の日付にリセット
        UIApplication.shared.dismissKeyboard()
    }

    // 日付のフォーマット
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

