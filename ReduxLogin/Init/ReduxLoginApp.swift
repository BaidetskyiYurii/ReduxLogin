//
//  ReduxLoginApp.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 14.07.2024.
//

import SwiftUI

@main
struct ReduxLoginApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var store = Store(initialState: AppState(), reducer: Reducer.appReducer())
    @StateObject var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(store)
                .environmentObject(notificationManager)
        }
    }
}
