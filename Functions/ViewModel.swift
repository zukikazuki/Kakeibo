import Foundation
import SwiftUI
import UIKit
import BackgroundTasks

class TransactionManager: ObservableObject {
    static let shared = TransactionManager() 
    @Published var transactions: [TransactionModel] = []  // トランザクションのリスト
    @Published var scheduledTransactions: [TransactionModel] = []  // 将来のトランザクションのリスト
    @Published var failedTransactions: [TransactionModel] = []  // 送信失敗したトランザクションのリスト
    @AppStorage("notionAPIKey") private var notionAPIKey: String = ""
    @AppStorage("databaseID") private var databaseID: String = ""

    func processDueTransactions() {
        let now = Date()
        var transactionsToProcess: [TransactionModel] = []
        var remainingScheduledTransactions: [TransactionModel] = []
        
        for transaction in scheduledTransactions {
            if transaction.date <= now {
                transactionsToProcess.append(transaction)
            } else {
                remainingScheduledTransactions.append(transaction)
            }
        }
        
        // 期限が来ているトランザクションを処理
        for transaction in transactionsToProcess {
            saveTransaction(transaction: transaction)
            
            // 固定費の場合、次回の支払いをスケジュール
            if transaction.isSubscription, let cycle = transaction.subscriptionPeriod {
                var nextTransaction = transaction
                nextTransaction.date = Calendar.current.date(byAdding: .month, value: cycle, to: transaction.date) ?? Date()
                nextTransaction.fixedCostID = transaction.fixedCostID
                remainingScheduledTransactions.append(nextTransaction)
            }
        }
        
        // スケジュールされたトランザクションを更新
        scheduledTransactions = remainingScheduledTransactions
        saveScheduledTransactions()
    }
    func saveScheduledTransactions() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(scheduledTransactions) {
            UserDefaults.standard.set(encoded, forKey: "ScheduledTransactions")
        }
    }
    func loadScheduledTransactions() {
        if let savedData = UserDefaults.standard.data(forKey: "ScheduledTransactions") {
            let decoder = JSONDecoder()
            if let loadedTransactions = try? decoder.decode([TransactionModel].self, from: savedData) {
                self.scheduledTransactions = loadedTransactions
            }
        }
    }
    func scheduleTransaction(transaction: TransactionModel) {
        var transactionWithFixedCostID = transaction
        transactionWithFixedCostID.fixedCostID = transaction.fixedCostID ?? UUID()
        scheduledTransactions.append(transactionWithFixedCostID)
        saveScheduledTransactions()
    }

    func saveTransaction(transaction: TransactionModel) {
        let now = Date()
        let calendar = Calendar.current

        // 単発のトランザクションの場合
        if !transaction.isSubscription {
            // 単純に現在のトランザクションを保存
            sendToNotion(transaction: transaction) { pageID in
                var savedTransaction = transaction
                savedTransaction.pageID = pageID  // Notionから取得したpageIDをセット
                DispatchQueue.main.async {
                    self.transactions.append(savedTransaction)
                    self.saveTransactions()
                }
            }
            return
        }

        // 以下、固定費の場合の処理
        var currentTransactionDate = transaction.date
        var paymentsToAdd = [TransactionModel]()
        
        let fixedCostID = transaction.fixedCostID ?? UUID()

        // 過去の支払日から現在まで繰り返し処理
        while currentTransactionDate < now {
            // 各トランザクションの新しいインスタンスを生成
            let pastTransaction = TransactionModel(
                pageID: nil,  // NotionのpageIDは後で付与される
                amount: transaction.amount,
                memo: transaction.memo,
                date: currentTransactionDate,  // 正しい支払日を設定
                tags: transaction.tags,
                isSubscription: transaction.isSubscription,
                subscriptionPeriod: transaction.subscriptionPeriod,
                isIncome: transaction.isIncome,
                fixedCostID: fixedCostID
            )
            
            paymentsToAdd.append(pastTransaction)

            // 次の支払日を計算
            currentTransactionDate = calendar.date(byAdding: .month, value: transaction.subscriptionPeriod ?? 1, to: currentTransactionDate) ?? now
        }

        // 過去分をNotionに保存し、ローカルにも追加
        for pastTransaction in paymentsToAdd {
            sendToNotion(transaction: pastTransaction) { pageID in
                var savedTransaction = pastTransaction
                savedTransaction.pageID = pageID  // Notionから取得したpageIDをセット
                DispatchQueue.main.async {
                    self.transactions.append(savedTransaction)  // ローカルにも保存
                    self.saveTransactions()  // ローカル保存を反映
                }
            }
        }
    }

    func retryFailedTransactions() {
            for transaction in failedTransactions {
                sendToNotion(transaction: transaction) { pageID in
                    if let pageID = pageID {
                        var savedTransaction = transaction
                        savedTransaction.pageID = pageID
                        DispatchQueue.main.async {
                            self.transactions.append(savedTransaction)
                            self.failedTransactions.removeAll { $0.id == transaction.id }  // 成功したら削除
                            self.saveTransactions()
                        }
                    }
                }
            }
        }
        
        // 失敗したトランザクションを保存する
        func saveFailedTransactions() {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(failedTransactions) {
                UserDefaults.standard.set(encoded, forKey: "FailedTransactions")
            }
        }
        
        // 失敗したトランザクションをロードする
        func loadFailedTransactions() {
            if let savedData = UserDefaults.standard.data(forKey: "FailedTransactions") {
                let decoder = JSONDecoder()
                if let loadedFailedTransactions = try? decoder.decode([TransactionModel].self, from: savedData) {
                    self.failedTransactions = loadedFailedTransactions
                }
            }
        }



    func saveTransactions() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: "Transactions")
        }
    }
    func loadTransactions() {
        if let savedData = UserDefaults.standard.data(forKey: "Transactions") {
            let decoder = JSONDecoder()
            if let loadedTransactions = try? decoder.decode([TransactionModel].self, from: savedData) {
                self.transactions = loadedTransactions
            }
        }
    }


    // Notionにトランザクションを送信する
    func sendToNotion(transaction: TransactionModel, completion: @escaping (String?) -> Void) {
            let url = URL(string: "https://api.notion.com/v1/pages")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(notionAPIKey)", forHTTPHeaderField: "Authorization")
            request.setValue("2021-05-13", forHTTPHeaderField: "Notion-Version")
            
            let notionPageData: [String: Any] = [
                "parent": ["database_id": databaseID],
                "properties": [
                    "Amount": ["number": transaction.amount],
                    "Memo": ["rich_text": [["text": ["content": transaction.memo]]]],
                    "Date": ["date": ["start": ISO8601DateFormatter().string(from: transaction.date)]],
                    "Tags": ["multi_select": transaction.tags.map { ["name": $0] }],
                    "IsSubscription": ["checkbox": transaction.isSubscription],
                    "PaymentCycle": ["number": transaction.subscriptionPeriod ?? 0],
                    "IsIncome": ["checkbox": transaction.isIncome]
                ]
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: notionPageData, options: [])
            } catch {
                print("Failed to serialize data to JSON: \(error)")
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Failed to send data to Notion: \(error)")
                    // 送信失敗した場合、失敗リストに追加
                    DispatchQueue.main.async {
                        self.failedTransactions.append(transaction)
                        self.saveFailedTransactions()  // 失敗したトランザクションを保存
                    }
                    completion(nil)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Failed to send data, unexpected response: \(response!)")
                    DispatchQueue.main.async {
                        self.failedTransactions.append(transaction)
                        self.saveFailedTransactions()
                    }
                    completion(nil)
                    return
                }
                
                // レスポンスからpage_idを取得する
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let pageID = json["id"] as? String {
                    print("Notion page created with ID: \(pageID)")
                    completion(pageID)  // 成功時にpageIDを返す
                } else {
                    completion(nil)
                }
            }
            
            task.resume()
        }
    
    func processTransactionsOnAppLaunch() {
            loadTransactions()
            loadScheduledTransactions()
            loadFailedTransactions()
            retryFailedTransactions()  // 失敗したトランザクションを再送信
            processDueTransactions()  // 期限が来たトランザクションを処理
        }
    // トランザクションを削除するメソッド
    func deleteTransaction(at offsets: IndexSet) {
        offsets.forEach { index in
            let transaction = transactions[index]
            if let pageID = transaction.pageID {
                // Notionからも削除（アーカイブ）
                deleteFromNotion(pageID: pageID)
            }
            // スケジュールされたトランザクションからも削除
            if let scheduledIndex = scheduledTransactions.firstIndex(where: { $0.id == transaction.id }) {
                scheduledTransactions.remove(at: scheduledIndex)
                saveScheduledTransactions()
            }
        }
        transactions.remove(atOffsets: offsets)  // ローカルのリストから削除
        saveTransactions()  // データを保存
    }
    // 完全削除のメソッド
    func deleteAllRelatedTransactions(for transaction: TransactionModel) {
        guard let fixedCostID = transaction.fixedCostID else {
            return  // 固定費IDがない場合、削除を中断
        }
        
        // 固定費に関連する過去の取引をすべて削除
        let transactionsToDelete = transactions.filter { $0.fixedCostID == fixedCostID }
        
        for transactionToDelete in transactionsToDelete {
            if let pageID = transactionToDelete.pageID {
                // Notionからも削除（過去の取引）
                deleteFromNotion(pageID: pageID)
            }
        }
        
        // ローカルの過去の取引を削除
        transactions.removeAll { $0.fixedCostID == fixedCostID }

        // 将来のスケジュール済みタスクもすべて削除
        scheduledTransactions.removeAll { $0.fixedCostID == fixedCostID }
        
        saveTransactions()
        saveScheduledTransactions()
    }

    // サブスク終了時のメソッド
    func cancelFutureSubscription(for transaction: TransactionModel) {
        guard let fixedCostID = transaction.fixedCostID else {
            return  // 固定費IDがない場合、処理を中断
        }
        
        // 将来のスケジュールされたトランザクションから削除
        scheduledTransactions.removeAll { $0.fixedCostID == fixedCostID }
        
        saveScheduledTransactions()
    }


    // Notionからトランザクションを削除（アーカイブ）する
    func deleteFromNotion(pageID: String) { 
        let url = URL(string: "https://api.notion.com/v1/pages/\(pageID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"  // Notionの削除はPATCHでアーカイブ処理を行う
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(notionAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("2021-05-13", forHTTPHeaderField: "Notion-Version")
        
        let body: [String: Any] = ["archived": true]  // アーカイブ処理
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Failed to serialize data to JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to delete page from Notion: \(error)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to delete page, unexpected response: \(response!)")
                return
            }
            print("Page successfully archived in Notion")
        }
        
        task.resume()
    }
}

