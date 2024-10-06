import Foundation

struct TransactionModel: Identifiable, Codable {
    var id = UUID()
    var pageID: String?
    var amount: Double
    var memo: String
    var date: Date
    var tags: [String]
    var isSubscription: Bool
    var subscriptionPeriod: Int?
    var isIncome: Bool
    var fixedCostID: UUID?  // 固定費IDを追加

    // カスタムイニシャライザを追加
    init(pageID: String?, amount: Double, memo: String, date: Date, tags: [String], isSubscription: Bool, subscriptionPeriod: Int?, isIncome: Bool, fixedCostID: UUID? = nil) {
        self.pageID = pageID
        self.amount = amount
        self.memo = memo
        self.date = date
        self.tags = tags
        self.isSubscription = isSubscription
        self.subscriptionPeriod = subscriptionPeriod
        self.isIncome = isIncome
        self.fixedCostID = fixedCostID  // nilまたは指定されたUUID
    }
}
