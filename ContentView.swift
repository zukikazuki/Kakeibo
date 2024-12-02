//
//  ContentView.swift
//  Kakeibo_2
//
//  Created by kazuki fujikawa on 2024/09/28.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var transactionManager: TransactionManager
    var body: some View {
        TabView {
            ExpenseInputView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("収支入力")
                }
            KoteihiView()
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("固定費")
                }
            SettingsView() // ここが設定画面
                            .tabItem {
                                Label("設定", systemImage: "gear")
                            }
        }
    }
}

#Preview {
    ContentView()
}

// this is main
