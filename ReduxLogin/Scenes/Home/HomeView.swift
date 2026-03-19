//
//  HomeView.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 21.07.2024.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var store: Store<AppState, AppAction>
    @EnvironmentObject private var notificationManager: NotificationManager
    
    var body: some View {
        VStack {
            title
           
            logOutButton
            
            logOutButtonAndDelete
        }
        .task {
            await notificationManager.sendPushNotification()
        }
        .onChange(of: store.state.isLoggedOut) { oldValue, newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
                store.send(.signOut(.back))
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { store.state.loginError != nil },
            set: { _ in store.send(.clearLoginError) }
        )) {
            Alert(
                title: Text("Login Error"),
                message: Text(store.state.loginError ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    store.send(.clearLoginError)
                }
            )
        }
        .background(MovingShapesView())
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: Views
private extension HomeView {
    var title: some View {
        Text("You successfully signed in")
            .font(.largeTitle)
            .padding(.top, 100)
            .padding()
    }
    
    var logOutButtonAndDelete: some View {
        Button(action: {
            store.send(.signOut(.signOutAndDelete))
        }) {
            HStack {
                Image(systemName: "trash")
                    .font(.title2)
                
                Text("Log Out and Delete Account")
                    .font(.system(size: 18, weight: .medium, design: .default))
            }
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .foregroundColor(.red)
            .padding()
        }
    }
    
    var logOutButton: some View {
        Button(action: {
            store.send(.signOut(.signOut))
        }) {
            HStack {
                Image(systemName: "trash")
                    .font(.title2)
                
                Text("Log Out")
                    .font(.system(size: 18, weight: .medium, design: .default))
            }
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .foregroundColor(.red)
            .padding()
        }
        .padding(.top)
    }
}

#Preview {
    let store = Store(initialState: AppState(), reducer: Reducer.appReducer())
    
    return HomeView()
        .environmentObject(store)
}
