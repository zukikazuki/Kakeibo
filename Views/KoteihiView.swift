import SwiftUI

struct KoteihiView: View {
    @State private var amount: String = ""
    @State private var memo: String = ""
    @State private var paymentCycle: Int = 1 // 支払い間隔（月単位）
    @State private var selectedDate: Date = Date() // 支払い日
    @State private var isIncome: Bool = false
    
    // タグ関連
    @State private var showTagSheet = false
    @State private var selectedTags: [String] = [] // 選択されたタグ
    @State private var existingTags: [String] = [] // 固定費用のタグ
    @State private var newTag: String = "" // 新しいタグ入力用
    @State private var showDuplicateTagAlert = false // 重複アラート用

    @StateObject private var transactionManager = TransactionManager.shared


    var body: some View {
        VStack {
            // フォーム風のカスタムUI
            VStack(spacing: 0) {
                // 金額・メモ入力部分を白い背景で囲む
                VStack(spacing: 0) {
                    // 金額入力
                    HStack {
                        CustomTextField(text: $amount, placeholder: "金額", keyboardType: .decimalPad)
                            .multilineTextAlignment(.leading)  // 左揃えに変更
                            .padding(.trailing, 20)  // 右に少し余白を追加
                            .frame(maxWidth: .infinity)  // TextFieldの幅を調整
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
                    HStack {
                        Text("支払い周期")
                        Spacer()
                        Menu {
                            ForEach(1..<13) { cycle in
                                Button(action: {
                                    paymentCycle = cycle
                                }) {
                                    Text("\(cycle)ヶ月")
                                        .foregroundColor(.black)
                                }
                            }
                        } label: {
                            Text("\(paymentCycle)ヶ月")
                                .foregroundColor(.black)
                                    .padding(.vertical, 7)  // 縦方向の余白を小さく
                                    .padding(.horizontal, 20)  // 横方向の余白を大きく
                                    .background(Color(.systemGray6))  // 背景を灰色に設定
                                    .cornerRadius(10)  // 角を丸くする
                                    .frame(maxWidth: .infinity, alignment: .trailing)  // 右寄せにして横幅を広げる
                            
                        }

                                        .customTrailingPadding()
                                    }
                    .padding().customHeight()
                    customDivider()
                    // メモ入力
                    HStack {
                        TextField("メモを入力", text: $memo)
                            .doneButtonToolbar()
                            .multilineTextAlignment(.leading)  // 左揃え
                            .padding(.leading, 15).frame(maxWidth: .infinity)  // TextFieldの左側の余白もなし
                    }.customHeight()
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
                    let fixedCostID = UUID()
                    let newTransaction = TransactionModel(
                        pageID: nil,
                        amount: Double(amount) ?? 0,
                        memo: memo,
                        date: selectedDate,
                        tags: selectedTags,
                        isSubscription: true,
                        subscriptionPeriod: paymentCycle,
                        isIncome: isIncome,
                        fixedCostID: fixedCostID
                    )
                    transactionManager.saveTransaction(transaction: newTransaction)
                    resetForm()
                }) {
                    Text("固定費を追加")
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
                    ForEach(transactionManager.transactions.filter { $0.isIncome == isIncome && $0.isSubscription}.sorted(by: { $0.date > $1.date }), id: \.id) { transaction in  // 'id' を明示
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
                        .swipeActions(edge: .trailing) {
                            // すべて削除（完全削除）
                            Button(role: .destructive) {
                                transactionManager.deleteAllRelatedTransactions(for: transaction)
                            } label: {
                                Label("すべて削除", systemImage: "trash")
                            }

                            // 将来の更新を停止（サブスク終了）
                            Button {
                                transactionManager.cancelFutureSubscription(for: transaction)
                            } label: {
                                Label("更新停止", systemImage: "xmark.circle")
                            }
                            .tint(.orange)  // 別の色に変更
                        }
                    }
                }
            }
            .background(Color(.systemGray6))  // 背景色を設定
            .cornerRadius(20)  // 背景を丸くする
            .padding(.horizontal)
        }.onAppear {
            loadTags()
        }
        .onChange(of: existingTags) {
            saveTags()  // タグを保存
        }

        .padding()
        .sheet(isPresented: $showTagSheet) {
            TagSelectionView(
                tags: $existingTags,
                selectedTags: $selectedTags,
                showDuplicateTagAlert: $showDuplicateTagAlert,
                newTag: $newTag
            )
        }
    }

    func resetForm() {
        amount = ""
        memo = ""
        selectedTags = []
        selectedDate = Date()  // 現在の日付にリセット
        paymentCycle = 1
        UIApplication.shared.dismissKeyboard()
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    func saveTags() {
        UserDefaults.standard.set(existingTags, forKey: "FixedCostTags")
    }

    func loadTags() {
        if let loadedTags = UserDefaults.standard.array(forKey: "FixedCostTags") as? [String] {
            existingTags = loadedTags
        } else {
            existingTags = ["家賃", "光熱費", "通信費", "保険"]
        }
    }

}


struct KoteihiView_Previews: PreviewProvider {
    static var previews: some View {
        KoteihiView()
    }
}
