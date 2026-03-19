//
//  NotificationManager.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 30.07.2024.
//

import Foundation
import UserNotifications
import FirebaseMessaging

@MainActor
final class NotificationManager: ObservableObject {
    @Published private(set) var hasPermission = false
    
    init() {
        Task {
            await getAuthStatus()
        }
    }
    
    func request() async {
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await getAuthStatus()
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }
    
    func getAuthStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            hasPermission = true
        default:
            hasPermission = false
        }
    }
    
    func sendPushNotification() async {
        do {
            // Fetch the FCM registration token
            let token = try await getFCMToken()
            print("FCM registration token: \(token)")
            
            // Create the notification payload
            let notificationPayload: [String: Any] = [
                "token": token,  // Use the FCM token of the current device
                "title": "Login Notification",
                "body": "You successfully signed in!"
            ]
            
            // Send the notification request to the cloud function
            try await sendNotification(payload: notificationPayload)
        } catch {
            print("Error sending push notification: \(error)")
        }
    }
}

private extension NotificationManager {
    func getFCMToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Messaging.messaging().token { token, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: NSError(domain: "NotificationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "FCM registration token is nil"]))
                }
            }
        }
    }
    
    func sendNotification(payload: [String: Any]) async throws {
        // Replace YOUR_PROJECT_ID with your actual Firebase project ID
        let url = URL(string: "https://us-central1-testlogin-429317.cloudfunctions.net/sendPushNotification")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert the payload to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                print("Notification sent successfully.")
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No data"
                print("Failed to send notification. Status code: \(httpResponse.statusCode). Response data: \(responseString)")
            }
        } else {
            print("Unexpected response format.")
        }
    }
}
