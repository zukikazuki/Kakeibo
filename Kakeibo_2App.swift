//
//  Kakeibo_2App.swift
//  Kakeibo_2
//
//  Created by kazuki fujikawa on 2024/09/28.
//

import SwiftUI

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var transactionManager = TransactionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

