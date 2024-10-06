import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let transactionManager = TransactionManager.shared

    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // アプリ起動時にトランザクションを処理する
        transactionManager.processTransactionsOnAppLaunch()
        return true
    }
}
